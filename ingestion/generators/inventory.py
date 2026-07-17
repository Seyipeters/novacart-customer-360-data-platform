"""Generate daily product inventory snapshots."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd


WAREHOUSES = [
    {
        "warehouse_id": "WH001",
        "warehouse_name": "Nordic Central",
        "city": "Helsinki",
        "country": "Finland",
    },
    {
        "warehouse_id": "WH002",
        "warehouse_name": "Continental Hub",
        "city": "Berlin",
        "country": "Germany",
    },
    {
        "warehouse_id": "WH003",
        "warehouse_name": "Western Europe Hub",
        "city": "Amsterdam",
        "country": "Netherlands",
    },
]


def generate_inventory_snapshots(
    products: pd.DataFrame,
    seed: int,
    as_of_date: date,
    lookback_days: int,
) -> pd.DataFrame:
    """Generate inventory snapshots by product, warehouse, and date."""

    if products.empty:
        raise ValueError("Product data cannot be empty.")

    if lookback_days <= 0:
        raise ValueError(
            "Inventory lookback days must be greater than zero."
        )

    random_generator = random.Random(seed + 5000)

    active_products = products.loc[
        products["is_active"] == True  # noqa: E712
    ]

    if active_products.empty:
        raise ValueError("At least one active product is required.")

    start_date = (
        as_of_date - timedelta(days=lookback_days - 1)
    )

    snapshot_records: list[dict[str, object]] = []

    for product in active_products.to_dict(orient="records"):
        for warehouse in WAREHOUSES:
            current_stock = random_generator.randint(20, 180)

            for day_offset in range(lookback_days):
                inventory_date = (
                    start_date + timedelta(days=day_offset)
                )

                opening_stock = current_stock

                received_quantity = random_generator.choices(
                    [0, random_generator.randint(10, 80)],
                    weights=[72, 28],
                    k=1,
                )[0]

                available_stock = (
                    opening_stock + received_quantity
                )

                maximum_sales = min(15, available_stock)

                sold_quantity = random_generator.randint(
                    0,
                    maximum_sales,
                )

                stock_after_sales = (
                    available_stock - sold_quantity
                )

                damaged_quantity = random_generator.choices(
                    [
                        0,
                        min(
                            random_generator.randint(1, 2),
                            stock_after_sales,
                        ),
                    ],
                    weights=[94, 6],
                    k=1,
                )[0]

                closing_stock = (
                    opening_stock
                    + received_quantity
                    - sold_quantity
                    - damaged_quantity
                )

                current_stock = closing_stock

                unit_cost = round(
                    float(product["unit_cost"]),
                    2,
                )

                snapshot_records.append(
                    {
                        "inventory_date": (
                            inventory_date.isoformat()
                        ),
                        "warehouse_id": (
                            warehouse["warehouse_id"]
                        ),
                        "warehouse_name": (
                            warehouse["warehouse_name"]
                        ),
                        "warehouse_city": warehouse["city"],
                        "warehouse_country": (
                            warehouse["country"]
                        ),
                        "product_id": product["product_id"],
                        "opening_stock": opening_stock,
                        "received_quantity": received_quantity,
                        "sold_quantity": sold_quantity,
                        "damaged_quantity": damaged_quantity,
                        "closing_stock": closing_stock,
                        "unit_cost": unit_cost,
                        "inventory_value": round(
                            closing_stock * unit_cost,
                            2,
                        ),
                        "stockout_flag": closing_stock == 0,
                        "reorder_flag": closing_stock < 15,
                        "updated_at": datetime.combine(
                            inventory_date,
                            time(hour=23, minute=59),
                        ).isoformat(),
                    }
                )

    return pd.DataFrame(snapshot_records)
