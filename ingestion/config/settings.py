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

    payment_retry_rate: float = float(
        os.getenv("PAYMENT_RETRY_RATE", "0.06")
    )

    processing_payment_failure_rate: float = float(
        os.getenv("PROCESSING_PAYMENT_FAILURE_RATE", "0.15")
    )

    return_rate: float = float(
        os.getenv("RETURN_RATE", "0.08")
    )

    max_return_days: int = int(
        os.getenv("MAX_RETURN_DAYS", "30")
    )

    inventory_lookback_days: int = int(
        os.getenv("INVENTORY_LOOKBACK_DAYS", "30")
    )

    campaign_record_count: int = int(
        os.getenv("CAMPAIGN_RECORD_COUNT", "24")
    )

    web_event_record_count: int = int(
        os.getenv("WEB_EVENT_RECORD_COUNT", "20000")
    )

    web_event_lookback_days: int = int(
        os.getenv("WEB_EVENT_LOOKBACK_DAYS", "90")
    )

    anonymous_event_rate: float = float(
        os.getenv("ANONYMOUS_EVENT_RATE", "0.25")
    )
settings = Settings()
