"""Application settings loaded from environment variables."""

from __future__ import annotations

import os
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

    data_directory: Path = PROJECT_ROOT / "data"
    generated_directory: Path = data_directory / "generated"
    rejected_directory: Path = data_directory / "rejected"
    archive_directory: Path = data_directory / "archive"
    logs_directory: Path = PROJECT_ROOT / "logs"


settings = Settings()
