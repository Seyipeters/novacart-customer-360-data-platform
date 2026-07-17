"""Generate marketing campaign master data."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd
from faker import Faker


CAMPAIGN_CHANNELS = [
    "EMAIL",
    "PAID_SEARCH",
    "SOCIAL_MEDIA",
    "AFFILIATE",
    "DISPLAY",
]

CAMPAIGN_OBJECTIVES = [
    "CUSTOMER_ACQUISITION",
    "CUSTOMER_RETENTION",
    "REACTIVATION",
    "PRODUCT_LAUNCH",
    "SEASONAL_SALES",
]

TARGET_SEGMENTS = [
    "ALL_CUSTOMERS",
    "NEW_CUSTOMERS",
    "LOYAL_CUSTOMERS",
    "HIGH_VALUE_CUSTOMERS",
    "AT_RISK_CUSTOMERS",
]

CAMPAIGN_THEMES = [
    "Summer Sale",
    "Winter Essentials",
    "Member Rewards",
    "New Collection",
    "Weekend Deals",
    "Customer Appreciation",
    "Back to School",
    "Holiday Offers",
]


def generate_campaigns(
    record_count: int,
    seed: int,
    as_of_date: date,
) -> pd.DataFrame:
    """Generate deterministic marketing campaigns."""

    if record_count <= 0:
        raise ValueError(
            "Campaign record count must be greater than zero."
        )

    random_generator = random.Random(seed + 6000)

    Faker.seed(seed + 6000)
    faker = Faker("en_US")

    campaign_records: list[dict[str, object]] = []

    earliest_start_date = (
        as_of_date - timedelta(days=180)
    )

    for campaign_number in range(1, record_count + 1):
        start_date = faker.date_between_dates(
            date_start=earliest_start_date,
            date_end=as_of_date + timedelta(days=15),
        )

        duration_days = random_generator.randint(7, 45)

        end_date = start_date + timedelta(
            days=duration_days
        )

        if start_date > as_of_date:
            campaign_status = "PLANNED"
        elif end_date < as_of_date:
            campaign_status = "COMPLETED"
        else:
            campaign_status = "ACTIVE"

        campaign_channel = random_generator.choice(
            CAMPAIGN_CHANNELS
        )

        campaign_theme = random_generator.choice(
            CAMPAIGN_THEMES
        )

        budget_amount = round(
            random_generator.uniform(1000, 25000),
            2,
        )

        updated_at = datetime.combine(
            min(as_of_date, end_date),
            time(
                hour=random_generator.randint(8, 18),
                minute=random_generator.randint(0, 59),
            ),
        )

        campaign_records.append(
            {
                "campaign_id": (
                    f"CAMP{campaign_number:05d}"
                ),
                "campaign_name": (
                    f"{campaign_theme} "
                    f"{campaign_channel.replace('_', ' ').title()} "
                    f"{campaign_number:02d}"
                ),
                "campaign_channel": campaign_channel,
                "campaign_objective": (
                    random_generator.choice(
                        CAMPAIGN_OBJECTIVES
                    )
                ),
                "target_segment": (
                    random_generator.choice(
                        TARGET_SEGMENTS
                    )
                ),
                "start_date": start_date.isoformat(),
                "end_date": end_date.isoformat(),
                "budget_amount": budget_amount,
                "currency": "EUR",
                "campaign_status": campaign_status,
                "updated_at": updated_at.isoformat(),
            }
        )

    return pd.DataFrame(campaign_records)
