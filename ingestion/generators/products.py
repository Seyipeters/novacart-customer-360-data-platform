"""Generate realistic e-commerce product catalogue records."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd
from faker import Faker


PRODUCT_CATALOGUE = {
    "Electronics": {
        "Laptops": (500.00, 1800.00),
        "Smartphones": (250.00, 1300.00),
        "Headphones": (25.00, 350.00),
        "Smart Home": (20.00, 450.00),
    },
    "Home & Kitchen": {
        "Appliances": (35.00, 800.00),
        "Cookware": (15.00, 250.00),
        "Furniture": (80.00, 1200.00),
        "Lighting": (15.00, 300.00),
    },
    "Fashion": {
        "Menswear": (15.00, 300.00),
        "Womenswear": (15.00, 350.00),
        "Shoes": (25.00, 280.00),
        "Accessories": (8.00, 180.00),
    },
    "Beauty": {
        "Skincare": (8.00, 150.00),
        "Haircare": (7.00, 120.00),
        "Fragrance": (20.00, 220.00),
        "Makeup": (6.00, 100.00),
    },
    "Sports & Outdoors": {
        "Fitness": (12.00, 900.00),
        "Cycling": (20.00, 1400.00),
        "Camping": (15.00, 700.00),
        "Team Sports": (10.00, 350.00),
    },
}

BRANDS = [
    "Auron",
    "Velora",
    "Nordiq",
    "Lumexa",
    "TerraPeak",
    "Solvane",
    "Kivora",
    "Arctiq",
]

PRODUCT_DESCRIPTORS = [
    "Essential",
    "Classic",
    "Plus",
    "Pro",
    "Elite",
    "Max",
    "Eco",
    "Premium",
]


def generate_products(
    record_count: int,
    seed: int,
    as_of_date: date,
) -> pd.DataFrame:
    """Generate deterministic product catalogue records."""

    random_generator = random.Random(seed + 1000)
    Faker.seed(seed + 1000)
    faker = Faker("en_US")

    products: list[dict[str, object]] = []

    categories = list(PRODUCT_CATALOGUE.keys())

    earliest_launch_date = as_of_date - timedelta(days=3 * 365)

    for product_number in range(1, record_count + 1):
        category = random_generator.choice(categories)

        subcategories = list(PRODUCT_CATALOGUE[category].keys())
        subcategory = random_generator.choice(subcategories)

        minimum_price, maximum_price = (
            PRODUCT_CATALOGUE[category][subcategory]
        )

        list_price = round(
            random_generator.uniform(minimum_price, maximum_price),
            2,
        )

        unit_cost = round(
            list_price * random_generator.uniform(0.45, 0.72),
            2,
        )

        launch_date = faker.date_between_dates(
            date_start=earliest_launch_date,
            date_end=as_of_date,
        )

        updated_at = faker.date_time_between_dates(
            datetime_start=datetime.combine(launch_date, time.min),
            datetime_end=datetime.combine(as_of_date, time.max),
        )

        brand = random_generator.choice(BRANDS)
        descriptor = random_generator.choice(PRODUCT_DESCRIPTORS)

        product_id = f"PROD{product_number:05d}"

        products.append(
            {
                "product_id": product_id,
                "sku": f"SKU-{category[:3].upper()}-{product_number:05d}",
                "product_name": (
                    f"{brand} {subcategory} {descriptor} "
                    f"{product_number:03d}"
                ),
                "category": category,
                "subcategory": subcategory,
                "brand": brand,
                "unit_cost": unit_cost,
                "list_price": list_price,
                "is_active": random_generator.random() < 0.96,
                "launch_date": launch_date.isoformat(),
                "updated_at": updated_at.isoformat(),
            }
        )

    return pd.DataFrame(products)
