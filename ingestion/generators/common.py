"""Shared utilities for NovaCart source-data generators."""

from __future__ import annotations

import hashlib
from datetime import date
from pathlib import Path

import pandas as pd

from ingestion.config.settings import settings


def build_partitioned_path(
    source_system: str,
    dataset_name: str,
    as_of_date: date,
    extension: str = "csv",
) -> Path:
    """Build a date-partitioned local path that mirrors the future S3 layout."""

    output_directory = (
        settings.generated_directory
        / source_system
        / dataset_name
        / f"year={as_of_date.year}"
        / f"month={as_of_date.month:02d}"
        / f"day={as_of_date.day:02d}"
    )

    output_directory.mkdir(parents=True, exist_ok=True)

    filename = (
        f"{dataset_name}_{as_of_date.strftime('%Y%m%d')}.{extension}"
    )

    return output_directory / filename


def write_csv(dataframe: pd.DataFrame, output_path: Path) -> Path:
    """Write a DataFrame to CSV without an index column."""

    dataframe.to_csv(output_path, index=False)
    return output_path


def calculate_file_checksum(file_path: Path) -> str:
    """Calculate a SHA-256 checksum for duplicate-file detection."""

    sha256_hash = hashlib.sha256()

    with file_path.open("rb") as file:
        for chunk in iter(lambda: file.read(8192), b""):
            sha256_hash.update(chunk)

    return sha256_hash.hexdigest()
