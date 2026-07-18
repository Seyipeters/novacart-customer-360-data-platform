"""Validate generated source exports and upload them to Amazon S3."""

from __future__ import annotations

import hashlib
import re
import shutil
from pathlib import Path

import boto3
import pandas as pd
from botocore.exceptions import ClientError

from ingestion.config.settings import settings


# Only the most important source-level validation rules.
REQUIRED_KEYS = {
    "customers": ["customer_id"],
    "products": ["product_id"],
    "orders": ["order_id", "customer_id"],
    "order_items": ["order_item_id", "order_id", "product_id"],
    "payments": ["payment_id", "order_id"],
    "returns": ["return_id", "order_id", "order_item_id"],
    "inventory_daily": [
        "inventory_date",
        "warehouse_id",
        "product_id",
    ],
    "campaigns": ["campaign_id"],
    "web_events": ["event_id", "session_id"],
}


def calculate_checksum(file_path: Path) -> str:
    """Return the SHA-256 checksum of a file."""

    checksum = hashlib.sha256()

    with file_path.open("rb") as source_file:
        for chunk in iter(lambda: source_file.read(8192), b""):
            checksum.update(chunk)

    return checksum.hexdigest()


def get_dataset_name(file_path: Path) -> str:
    """Remove the date suffix from a generated CSV filename."""

    return re.sub(
        r"_\d{8}$",
        "",
        file_path.stem,
    )


def validate_file(
    file_path: Path,
    dataset_name: str,
) -> list[str]:
    """Run basic validation and return discovered errors."""

    errors: list[str] = []

    try:
        dataframe = pd.read_csv(file_path)
    except Exception as error:
        return [f"CSV could not be read: {error}"]

    if dataframe.empty:
        errors.append("File contains no records.")
        return errors

    required_keys = REQUIRED_KEYS.get(dataset_name)

    if required_keys is None:
        errors.append(
            f"No validation rules configured for {dataset_name}."
        )
        return errors

    missing_columns = [
        column
        for column in required_keys
        if column not in dataframe.columns
    ]

    if missing_columns:
        errors.append(
            "Missing key columns: "
            + ", ".join(missing_columns)
        )

        return errors

    null_key_rows = dataframe[
        required_keys
    ].isna().any(axis=1).sum()

    if null_key_rows:
        errors.append(
            f"{null_key_rows} rows contain null key values."
        )

    duplicate_rows = dataframe.duplicated(
        subset=required_keys,
        keep=False,
    ).sum()

    if duplicate_rows:
        errors.append(
            f"{duplicate_rows} rows contain duplicate keys."
        )

    return errors


def build_s3_key(file_path: Path) -> str:
    """Create the S3 key while preserving the partition structure."""

    relative_path = file_path.relative_to(
        settings.generated_directory
    )

    return f"raw/{relative_path.as_posix()}"


def object_already_uploaded(
    s3_client,
    bucket_name: str,
    object_key: str,
    checksum: str,
) -> bool:
    """Check whether the same file version already exists in S3."""

    try:
        response = s3_client.head_object(
            Bucket=bucket_name,
            Key=object_key,
        )
    except ClientError as error:
        error_code = error.response["Error"]["Code"]

        if error_code in {"404", "NoSuchKey", "NotFound"}:
            return False

        raise

    existing_checksum = response.get(
        "Metadata",
        {},
    ).get("sha256")

    return existing_checksum == checksum


def reject_file(
    file_path: Path,
    dataset_name: str,
) -> Path:
    """Copy an invalid file into the rejected-data folder."""

    rejected_directory = (
        settings.rejected_directory / dataset_name
    )

    rejected_directory.mkdir(
        parents=True,
        exist_ok=True,
    )

    rejected_path = (
        rejected_directory / file_path.name
    )

    shutil.copy2(file_path, rejected_path)

    return rejected_path


def main() -> None:
    """Validate and upload all source CSV files."""

    bucket_name = settings.s3_bucket_name
    print(f"Target S3 bucket: {bucket_name}")
    print(f"AWS region: {settings.aws_region}")
    print()
    if not bucket_name:
        raise ValueError(
            "S3_BUCKET_NAME is missing from .env."
        )

    source_files = sorted(
        settings.generated_directory.rglob("*.csv")
    )

    if not source_files:
        raise FileNotFoundError(
            "No CSV files were found under data/generated."
        )

    s3_client = boto3.client(
        "s3",
        region_name=settings.aws_region,
    )

    uploaded_count = 0
    skipped_count = 0
    rejected_count = 0

    for file_path in source_files:
        dataset_name = get_dataset_name(file_path)

        errors = validate_file(
            file_path=file_path,
            dataset_name=dataset_name,
        )

        if errors:
            rejected_count += 1

            rejected_path = reject_file(
                file_path=file_path,
                dataset_name=dataset_name,
            )

            print(f"REJECTED: {dataset_name}")

            for error in errors:
                print(f"  - {error}")

            print(f"  Copy: {rejected_path}")
            continue

        checksum = calculate_checksum(file_path)
        object_key = build_s3_key(file_path)

        if object_already_uploaded(
            s3_client=s3_client,
            bucket_name=bucket_name,
            object_key=object_key,
            checksum=checksum,
        ):
            skipped_count += 1
            print(f"SKIPPED:  s3://{bucket_name}/{object_key}")
            continue

        s3_client.upload_file(
            str(file_path),
            bucket_name,
            object_key,
            ExtraArgs={
                "Metadata": {
                    "sha256": checksum,
                    "dataset": dataset_name,
                }
            },
        )

        uploaded_count += 1
        print(f"UPLOADED: s3://{bucket_name}/{object_key}")

    print()
    print("S3 ingestion summary")
    print(f"Uploaded: {uploaded_count}")
    print(f"Skipped:  {skipped_count}")
    print(f"Rejected: {rejected_count}")

    if rejected_count:
        raise SystemExit(
            "One or more files failed validation."
        )


if __name__ == "__main__":
    main()
