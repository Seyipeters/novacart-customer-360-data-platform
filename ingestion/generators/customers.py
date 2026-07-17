"""Generate realistic CRM customer records."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd
from faker import Faker


LOCATIONS = [
    ("Helsinki", "Uusimaa", "Finland"),
    ("Espoo", "Uusimaa", "Finland"),
    ("Tampere", "Pirkanmaa", "Finland"),
    ("Turku", "Southwest Finland", "Finland"),
    ("Kuopio", "North Savo", "Finland"),
    ("Stockholm", "Stockholm County", "Sweden"),
    ("Gothenburg", "Västra Götaland", "Sweden"),
    ("Malmö", "Skåne", "Sweden"),
    ("Copenhagen", "Capital Region", "Denmark"),
    ("Aarhus", "Central Denmark", "Denmark"),
    ("Berlin", "Berlin", "Germany"),
    ("Munich", "Bavaria", "Germany"),
    ("Hamburg", "Hamburg", "Germany"),
    ("Amsterdam", "North Holland", "Netherlands"),
    ("Rotterdam", "South Holland", "Netherlands"),
    ("Paris", "Île-de-France", "France"),
    ("Lyon", "Auvergne-Rhône-Alpes", "France"),
    ("Madrid", "Community of Madrid", "Spain"),
    ("Barcelona", "Catalonia", "Spain"),
    ("Warsaw", "Masovian", "Poland"),
    ("Kraków", "Lesser Poland", "Poland"),
]

ACQUISITION_CHANNELS = [
    "Organic Search",
    "Paid Search",
    "Social Media",
    "Email",
    "Referral",
    "Affiliate",
]

LOYALTY_STATUSES = [
    "Bronze",
    "Silver",
    "Gold",
    "Platinum",
]

EMAIL_DOMAINS = [
    "gmail.com",
    "outlook.com",
    "yahoo.com",
    "proton.me",
]


def generate_customers(
    record_count: int,
    seed: int,
    as_of_date: date,
) -> pd.DataFrame:
    """Generate deterministic CRM customer records."""

    random_generator = random.Random(seed)
    Faker.seed(seed)
    faker = Faker("en_US")

    customers: list[dict[str, object]] = []

    earliest_registration_date = as_of_date - timedelta(days=5 * 365)
    latest_registration_date = as_of_date - timedelta(days=1)

    for customer_number in range(1, record_count + 1):
        first_name = faker.first_name()
        last_name = faker.last_name()

        city, region, country = random_generator.choice(LOCATIONS)

        registration_date = faker.date_between_dates(
            date_start=earliest_registration_date,
            date_end=latest_registration_date,
        )

        registration_datetime = datetime.combine(
            registration_date,
            time.min,
        )

        end_datetime = datetime.combine(
            as_of_date,
            time.max,
        )

        updated_at = faker.date_time_between_dates(
            datetime_start=registration_datetime,
            datetime_end=end_datetime,
        )

        customer_id = f"CUST{customer_number:06d}"

        email_username = (
            f"{first_name}.{last_name}.{customer_number}"
            .lower()
            .replace(" ", "")
            .replace("'", "")
        )

        customers.append(
            {
                "customer_id": customer_id,
                "first_name": first_name,
                "last_name": last_name,
                "email": (
                    f"{email_username}@"
                    f"{random_generator.choice(EMAIL_DOMAINS)}"
                ),
                "phone": faker.phone_number(),
                "city": city,
                "region": region,
                "country": country,
                "postal_code": faker.postcode(),
                "registration_date": registration_date.isoformat(),
                "loyalty_status": random_generator.choices(
                    LOYALTY_STATUSES,
                    weights=[45, 30, 18, 7],
                    k=1,
                )[0],
                "acquisition_channel": random_generator.choices(
                    ACQUISITION_CHANNELS,
                    weights=[30, 20, 18, 12, 12, 8],
                    k=1,
                )[0],
                "is_active": random_generator.random() < 0.92,
                "updated_at": updated_at.isoformat(),
            }
        )

    return pd.DataFrame(customers)
