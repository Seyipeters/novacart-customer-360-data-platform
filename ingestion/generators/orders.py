"""Generate realistic e-commerce orders and order items."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd
from faker import Faker


ORDER_STATUSES = [
    "COMPLETED",
    "SHIPPED",
    "PROCESSING",
    "CANCELLED",
]

SALES_CHANNELS = [
    "WEB",
    "MOBILE_APP",
    "MARKETPLACE",
]

DISCOUNT_RATES = [
    0.00,
    0.05,
    0.10,
    0.15,
    0.20,
]


def generate_orders_and_items(
    customers: pd.DataFrame,
    products: pd.DataFrame,
    record_count: int,
    seed: int,
    as_of_date: date,
    lookback_days: int,
    max_items_per_order: int,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Generate orders with valid customer and product relationships."""

    if customers.empty:
        raise ValueError("Customer data cannot be empty.")

    if products.empty:
        raise ValueError("Product data cannot be empty.")

    if record_count <= 0:
        raise ValueError("Order record count must be greater than zero.")

    if max_items_per_order <= 0:
        raise ValueError("Maximum items per order must be greater than zero.")

    random_generator = random.Random(seed + 2000)

    Faker.seed(seed + 2000)
    faker = Faker("en_US")

    customer_records = customers.to_dict(orient="records")

    active_products = products.loc[
        products["is_active"] == True  # noqa: E712
    ]

    if active_products.empty:
        raise ValueError("At least one active product is required.")

    product_records = active_products.to_dict(orient="records")

    earliest_order_date = as_of_date - timedelta(days=lookback_days)

    orders: list[dict[str, object]] = []
    order_items: list[dict[str, object]] = []

    order_item_number = 1

    for order_number in range(1, record_count + 1):
        customer = random_generator.choice(customer_records)

        order_date = earliest_order_date + timedelta(
            days=random_generator.randint(0, lookback_days)
        )

        order_timestamp = datetime.combine(
            order_date,
            time(
                hour=random_generator.randint(0, 23),
                minute=random_generator.randint(0, 59),
                second=random_generator.randint(0, 59),
            ),
        )

        order_id = f"ORD{order_number:08d}"

        order_status = random_generator.choices(
            ORDER_STATUSES,
            weights=[58, 22, 14, 6],
            k=1,
        )[0]

        sales_channel = random_generator.choices(
            SALES_CHANNELS,
            weights=[58, 32, 10],
            k=1,
        )[0]

        selected_item_count = random_generator.randint(
            1,
            min(max_items_per_order, len(product_records)),
        )

        selected_products = random_generator.sample(
            product_records,
            k=selected_item_count,
        )

        discount_rate = random_generator.choices(
            DISCOUNT_RATES,
            weights=[55, 18, 15, 8, 4],
            k=1,
        )[0]

        subtotal_amount = 0.0
        discount_amount = 0.0
        net_item_amount = 0.0
        total_quantity = 0

        for product in selected_products:
            quantity = random_generator.choices(
                [1, 2, 3],
                weights=[72, 22, 6],
                k=1,
            )[0]

            unit_price = round(float(product["list_price"]), 2)

            gross_amount = round(
                quantity * unit_price,
                2,
            )

            line_discount_amount = round(
                gross_amount * discount_rate,
                2,
            )

            line_net_amount = round(
                gross_amount - line_discount_amount,
                2,
            )

            order_items.append(
                {
                    "order_item_id": (
                        f"ITEM{order_item_number:010d}"
                    ),
                    "order_id": order_id,
                    "product_id": product["product_id"],
                    "quantity": quantity,
                    "unit_price": unit_price,
                    "gross_amount": gross_amount,
                    "discount_rate": discount_rate,
                    "discount_amount": line_discount_amount,
                    "net_amount": line_net_amount,
                    "created_at": order_timestamp.isoformat(),
                }
            )

            order_item_number += 1
            subtotal_amount += gross_amount
            discount_amount += line_discount_amount
            net_item_amount += line_net_amount
            total_quantity += quantity

        subtotal_amount = round(subtotal_amount, 2)
        discount_amount = round(discount_amount, 2)
        net_item_amount = round(net_item_amount, 2)

        if net_item_amount >= 100:
            shipping_amount = 0.00
        else:
            shipping_amount = random_generator.choice(
                [4.99, 6.99, 8.99]
            )

        order_total = round(
            net_item_amount + shipping_amount,
            2,
        )

        updated_at = faker.date_time_between_dates(
            datetime_start=order_timestamp,
            datetime_end=datetime.combine(
                as_of_date,
                time.max,
            ),
        )

        orders.append(
            {
                "order_id": order_id,
                "customer_id": customer["customer_id"],
                "order_timestamp": order_timestamp.isoformat(),
                "order_date": order_date.isoformat(),
                "order_status": order_status,
                "sales_channel": sales_channel,
                "shipping_city": customer["city"],
                "shipping_region": customer["region"],
                "shipping_country": customer["country"],
                "currency": "EUR",
                "item_count": selected_item_count,
                "total_quantity": total_quantity,
                "subtotal_amount": subtotal_amount,
                "discount_amount": discount_amount,
                "shipping_amount": shipping_amount,
                "order_total": order_total,
                "updated_at": updated_at.isoformat(),
            }
        )

    return (
        pd.DataFrame(orders),
        pd.DataFrame(order_items),
    )
