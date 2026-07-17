"""Generate customer and anonymous website event data."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd


DEVICE_TYPES = [
    "DESKTOP",
    "MOBILE",
    "TABLET",
]

TRAFFIC_SOURCES = [
    "DIRECT",
    "ORGANIC_SEARCH",
    "PAID_SEARCH",
    "SOCIAL_MEDIA",
    "EMAIL",
    "AFFILIATE",
]

BROWSERS = [
    "CHROME",
    "SAFARI",
    "EDGE",
    "FIREFOX",
]

EVENT_PATHS = [
    ["PAGE_VIEW"],
    ["PAGE_VIEW", "PRODUCT_VIEW"],
    ["PAGE_VIEW", "PRODUCT_VIEW", "ADD_TO_CART"],
    [
        "PAGE_VIEW",
        "PRODUCT_VIEW",
        "ADD_TO_CART",
        "CHECKOUT_STARTED",
    ],
]


def _find_active_campaigns(
    campaigns: pd.DataFrame,
    event_date: date,
) -> list[str]:
    """Return campaign IDs active on the supplied date."""

    campaign_dates = campaigns.copy()

    campaign_dates["parsed_start_date"] = pd.to_datetime(
        campaign_dates["start_date"]
    ).dt.date

    campaign_dates["parsed_end_date"] = pd.to_datetime(
        campaign_dates["end_date"]
    ).dt.date

    active_campaigns = campaign_dates.loc[
        (
            campaign_dates["parsed_start_date"]
            <= event_date
        )
        & (
            campaign_dates["parsed_end_date"]
            >= event_date
        ),
        "campaign_id",
    ]

    return list(active_campaigns)


def generate_web_events(
    customers: pd.DataFrame,
    products: pd.DataFrame,
    orders: pd.DataFrame,
    order_items: pd.DataFrame,
    campaigns: pd.DataFrame,
    record_count: int,
    seed: int,
    as_of_date: date,
    lookback_days: int,
    anonymous_event_rate: float,
) -> pd.DataFrame:
    """Generate web sessions and event-level activity."""

    if customers.empty:
        raise ValueError("Customer data cannot be empty.")

    if products.empty:
        raise ValueError("Product data cannot be empty.")

    if record_count <= 0:
        raise ValueError(
            "Web-event record count must be greater than zero."
        )

    if lookback_days <= 0:
        raise ValueError(
            "Web-event lookback days must be greater than zero."
        )

    if not 0 <= anonymous_event_rate <= 1:
        raise ValueError(
            "Anonymous-event rate must be between 0 and 1."
        )

    random_generator = random.Random(seed + 7000)

    customer_ids = list(customers["customer_id"])

    active_products = products.loc[
        products["is_active"] == True  # noqa: E712
    ]

    product_ids = list(active_products["product_id"])

    earliest_event_date = (
        as_of_date - timedelta(days=lookback_days)
    )

    recent_orders = orders.copy()

    recent_orders["parsed_order_date"] = pd.to_datetime(
        recent_orders["order_date"]
    ).dt.date

    recent_orders = recent_orders.loc[
        recent_orders["parsed_order_date"]
        >= earliest_event_date
    ]

    orders_by_customer: dict[str, list[dict[str, object]]] = {}

    for order in recent_orders.to_dict(orient="records"):
        customer_id = str(order["customer_id"])

        orders_by_customer.setdefault(
            customer_id,
            [],
        ).append(order)

    items_by_order: dict[str, list[dict[str, object]]] = {}

    for item in order_items.to_dict(orient="records"):
        order_id = str(item["order_id"])

        items_by_order.setdefault(
            order_id,
            [],
        ).append(item)

    event_records: list[dict[str, object]] = []

    session_number = 1
    event_number = 1

    while len(event_records) < record_count:
        session_id = f"SESS{session_number:010d}"

        is_anonymous = (
            random_generator.random()
            < anonymous_event_rate
        )

        customer_id = (
            None
            if is_anonymous
            else random_generator.choice(customer_ids)
        )

        purchase_order = None
        purchase_item = None

        can_create_purchase = (
            customer_id is not None
            and customer_id in orders_by_customer
            and random_generator.random() < 0.18
        )

        if can_create_purchase:
            purchase_order = random_generator.choice(
                orders_by_customer[customer_id]
            )

            order_id = str(purchase_order["order_id"])

            purchase_items = items_by_order.get(
                order_id,
                [],
            )

            if purchase_items:
                purchase_item = random_generator.choice(
                    purchase_items
                )

        if purchase_order is not None and purchase_item is not None:
            purchase_timestamp = pd.Timestamp(
                purchase_order["order_timestamp"]
            ).to_pydatetime()

            session_start = (
                purchase_timestamp
                - timedelta(
                    minutes=random_generator.randint(5, 45)
                )
            )

            selected_product_id = str(
                purchase_item["product_id"]
            )

            event_path = [
                "PAGE_VIEW",
                "PRODUCT_VIEW",
                "ADD_TO_CART",
                "CHECKOUT_STARTED",
                "PURCHASE",
            ]

        else:
            event_date = (
                earliest_event_date
                + timedelta(
                    days=random_generator.randint(
                        0,
                        lookback_days,
                    )
                )
            )

            session_start = datetime.combine(
                event_date,
                time(
                    hour=random_generator.randint(0, 23),
                    minute=random_generator.randint(0, 59),
                    second=random_generator.randint(0, 59),
                ),
            )

            selected_product_id = (
                random_generator.choice(product_ids)
            )

            event_path = random_generator.choices(
                EVENT_PATHS,
                weights=[20, 35, 30, 15],
                k=1,
            )[0]

        device_type = random_generator.choices(
            DEVICE_TYPES,
            weights=[45, 48, 7],
            k=1,
        )[0]

        traffic_source = random_generator.choices(
            TRAFFIC_SOURCES,
            weights=[22, 28, 16, 14, 12, 8],
            k=1,
        )[0]

        active_campaign_ids = _find_active_campaigns(
            campaigns=campaigns,
            event_date=session_start.date(),
        )

        campaign_id = None

        if (
            active_campaign_ids
            and random_generator.random() < 0.30
        ):
            campaign_id = random_generator.choice(
                active_campaign_ids
            )

        current_timestamp = session_start

        for event_type in event_path:
            if len(event_records) >= record_count:
                break

            current_timestamp += timedelta(
                seconds=random_generator.randint(20, 300)
            )

            order_id = None

            if event_type == "PURCHASE":
                order_id = str(
                    purchase_order["order_id"]
                )

            page_url = "/"

            if event_type in {
                "PRODUCT_VIEW",
                "ADD_TO_CART",
            }:
                page_url = (
                    f"/products/{selected_product_id.lower()}"
                )

            elif event_type == "CHECKOUT_STARTED":
                page_url = "/checkout"

            elif event_type == "PURCHASE":
                page_url = "/order-confirmation"

            arrival_delay_hours = (
                random_generator.choices(
                    [0, 1, 2, 6, 12, 24],
                    weights=[55, 18, 10, 8, 6, 3],
                    k=1,
                )[0]
            )

            record_arrived_at = (
                current_timestamp
                + timedelta(hours=arrival_delay_hours)
            )

            event_records.append(
                {
                    "event_id": (
                        f"EVT{event_number:012d}"
                    ),
                    "session_id": session_id,
                    "customer_id": customer_id,
                    "anonymous_id": (
                        f"ANON{session_number:010d}"
                        if customer_id is None
                        else None
                    ),
                    "event_type": event_type,
                    "product_id": (
                        selected_product_id
                        if event_type
                        in {
                            "PRODUCT_VIEW",
                            "ADD_TO_CART",
                            "CHECKOUT_STARTED",
                            "PURCHASE",
                        }
                        else None
                    ),
                    "order_id": order_id,
                    "campaign_id": campaign_id,
                    "device_type": device_type,
                    "browser": random_generator.choice(
                        BROWSERS
                    ),
                    "traffic_source": traffic_source,
                    "page_url": page_url,
                    "event_timestamp": (
                        current_timestamp.isoformat()
                    ),
                    "record_arrived_at": (
                        record_arrived_at.isoformat()
                    ),
                }
            )

            event_number += 1

        session_number += 1

    return pd.DataFrame(event_records)
