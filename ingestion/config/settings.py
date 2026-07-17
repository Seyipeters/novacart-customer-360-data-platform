"""Application settings loaded from environment variables."""

from __future__ import annotations

import os
from datetime import date
from pathlib import Path

from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[2]

load_dotenv(PROJECT_ROOT / ".env")


class Settings:
    """Central project configuration."""

    project_name: str = os.getenv(
        "PROJECT_NAME",
        "novacart-customer-360",
    )

    environment: str = os.getenv(
        "ENVIRONMENT",
        "development",
    )

    aws_region: str = os.getenv(
        "AWS_DEFAULT_REGION",
        "eu-north-1",
    )

    s3_bucket_name: str = os.getenv(
        "S3_BUCKET_NAME",
        "",
    )

    data_generation_seed: int = int(
        os.getenv("DATA_GENERATION_SEED", "42")
    )

    data_as_of_date: date = date.fromisoformat(
        os.getenv("DATA_AS_OF_DATE", date.today().isoformat())
    )

    customer_record_count: int = int(
        os.getenv("CUSTOMER_RECORD_COUNT", "500")
    )

    product_record_count: int = int(
        os.getenv("PRODUCT_RECORD_COUNT", "120")
    )

    data_directory: Path = PROJECT_ROOT / "data"
    generated_directory: Path = data_directory / "generated"
    rejected_directory: Path = data_directory / "rejected"
    archive_directory: Path = data_directory / "archive"
    logs_directory: Path = PROJECT_ROOT / "logs"

    order_record_count: int = int(
        os.getenv("ORDER_RECORD_COUNT", "2500")
    )

    order_lookback_days: int = int(
        os.getenv("ORDER_LOOKBACK_DAYS", "365")
    )

    max_items_per_order: int = int(
        os.getenv("MAX_ITEMS_PER_ORDER", "5")
    )

settings = Settings()
