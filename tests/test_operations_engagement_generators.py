"""Tests for inventory, campaigns, and website events."""

from datetime import date

import numpy as np

from ingestion.generators.campaigns import (
    generate_campaigns,
)
from ingestion.generators.customers import (
    generate_customers,
)
from ingestion.generators.inventory import (
    generate_inventory_snapshots,
)
from ingestion.generators.orders import (
    generate_orders_and_items,
)
from ingestion.generators.products import (
    generate_products,
)
from ingestion.generators.web_events import (
    generate_web_events,
)


TEST_DATE = date(2026, 7, 17)


def create_test_data():
    """Create reusable source datasets."""

    customers = generate_customers(
        record_count=50,
        seed=42,
        as_of_date=TEST_DATE,
    )

    products = generate_products(
        record_count=30,
        seed=42,
        as_of_date=TEST_DATE,
    )

    orders, order_items = generate_orders_and_items(
        customers=customers,
        products=products,
        record_count=200,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        max_items_per_order=5,
    )

    campaigns = generate_campaigns(
        record_count=12,
        seed=42,
        as_of_date=TEST_DATE,
    )

    return (
        customers,
        products,
        orders,
        order_items,
        campaigns,
    )


def test_inventory_grain_is_unique() -> None:
    """Inventory grain must be product, warehouse, and date."""

    _, products, _, _, _ = create_test_data()

    inventory = generate_inventory_snapshots(
        products=products,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=10,
    )

    duplicate_count = inventory.duplicated(
        subset=[
            "inventory_date",
            "warehouse_id",
            "product_id",
        ]
    ).sum()

    assert duplicate_count == 0


def test_inventory_balances_reconcile() -> None:
    """Closing stock must reconcile to inventory movements."""

    _, products, _, _, _ = create_test_data()

    inventory = generate_inventory_snapshots(
        products=products,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=10,
    )

    calculated_closing = (
        inventory["opening_stock"]
        + inventory["received_quantity"]
        - inventory["sold_quantity"]
        - inventory["damaged_quantity"]
    )

    assert np.array_equal(
        inventory["closing_stock"],
        calculated_closing,
    )

    assert (inventory["closing_stock"] >= 0).all()


def test_campaign_dates_and_budgets_are_valid() -> None:
    """Campaign end dates and budgets must be valid."""

    campaigns = generate_campaigns(
        record_count=20,
        seed=42,
        as_of_date=TEST_DATE,
    )

    start_dates = campaigns["start_date"].astype(
        "datetime64[ns]"
    )

    end_dates = campaigns["end_date"].astype(
        "datetime64[ns]"
    )

    assert campaigns["campaign_id"].is_unique
    assert (end_dates >= start_dates).all()
    assert (campaigns["budget_amount"] > 0).all()


def test_web_events_reference_valid_entities() -> None:
    """Web events must use valid customer, product, and order IDs."""

    (
        customers,
        products,
        orders,
        order_items,
        campaigns,
    ) = create_test_data()

    events = generate_web_events(
        customers=customers,
        products=products,
        orders=orders,
        order_items=order_items,
        campaigns=campaigns,
        record_count=1000,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        anonymous_event_rate=0.25,
    )

    known_customers = events.loc[
        events["customer_id"].notna()
    ]

    assert known_customers["customer_id"].isin(
        set(customers["customer_id"])
    ).all()

    product_events = events.loc[
        events["product_id"].notna()
    ]

    assert product_events["product_id"].isin(
        set(products["product_id"])
    ).all()

    purchase_events = events.loc[
        events["event_type"] == "PURCHASE"
    ]

    assert purchase_events["order_id"].notna().all()

    assert purchase_events["order_id"].isin(
        set(orders["order_id"])
    ).all()


def test_web_event_identifiers_are_unique() -> None:
    """Every web event must have a unique event identifier."""

    (
        customers,
        products,
        orders,
        order_items,
        campaigns,
    ) = create_test_data()

    events = generate_web_events(
        customers=customers,
        products=products,
        orders=orders,
        order_items=order_items,
        campaigns=campaigns,
        record_count=500,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        anonymous_event_rate=0.25,
    )

    assert len(events) == 500
    assert events["event_id"].is_unique
    assert events["session_id"].notna().all()


def test_anonymous_events_have_anonymous_ids() -> None:
    """Anonymous events must have a traceable anonymous ID."""

    (
        customers,
        products,
        orders,
        order_items,
        campaigns,
    ) = create_test_data()

    events = generate_web_events(
        customers=customers,
        products=products,
        orders=orders,
        order_items=order_items,
        campaigns=campaigns,
        record_count=1000,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        anonymous_event_rate=0.25,
    )

    anonymous_events = events.loc[
        events["customer_id"].isna()
    ]

    assert not anonymous_events.empty

    assert anonymous_events[
        "anonymous_id"
    ].notna().all()
