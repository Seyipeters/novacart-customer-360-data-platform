"""Tests for NovaCart order and order-item generation."""

from datetime import date

import numpy as np

from ingestion.generators.customers import generate_customers
from ingestion.generators.orders import generate_orders_and_items
from ingestion.generators.products import generate_products


TEST_DATE = date(2026, 7, 17)


def create_test_transactions():
    """Create reusable test datasets."""

    customers = generate_customers(
        record_count=30,
        seed=42,
        as_of_date=TEST_DATE,
    )

    products = generate_products(
        record_count=20,
        seed=42,
        as_of_date=TEST_DATE,
    )

    return generate_orders_and_items(
        customers=customers,
        products=products,
        record_count=100,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        max_items_per_order=5,
    )


def test_orders_have_valid_customer_relationships() -> None:
    """Every order must reference a valid customer."""

    customers = generate_customers(
        record_count=30,
        seed=42,
        as_of_date=TEST_DATE,
    )

    products = generate_products(
        record_count=20,
        seed=42,
        as_of_date=TEST_DATE,
    )

    orders, _ = generate_orders_and_items(
        customers=customers,
        products=products,
        record_count=100,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        max_items_per_order=5,
    )

    valid_customer_ids = set(customers["customer_id"])

    assert orders["order_id"].is_unique
    assert orders["customer_id"].isin(valid_customer_ids).all()


def test_order_items_have_valid_relationships() -> None:
    """Every order item must reference valid orders and products."""

    customers = generate_customers(
        record_count=30,
        seed=42,
        as_of_date=TEST_DATE,
    )

    products = generate_products(
        record_count=20,
        seed=42,
        as_of_date=TEST_DATE,
    )

    orders, order_items = generate_orders_and_items(
        customers=customers,
        products=products,
        record_count=100,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=90,
        max_items_per_order=5,
    )

    assert order_items["order_item_id"].is_unique
    assert order_items["order_id"].isin(
        set(orders["order_id"])
    ).all()

    assert order_items["product_id"].isin(
        set(products["product_id"])
    ).all()


def test_every_order_has_at_least_one_item() -> None:
    """Every generated order must have one or more order items."""

    orders, order_items = create_test_transactions()

    item_counts = order_items.groupby("order_id").size()

    assert set(orders["order_id"]) == set(item_counts.index)
    assert (item_counts >= 1).all()


def test_order_amounts_reconcile_to_order_items() -> None:
    """Order totals must match aggregated order-item amounts."""

    orders, order_items = create_test_transactions()

    item_totals = (
        order_items.groupby("order_id")
        .agg(
            calculated_subtotal=("gross_amount", "sum"),
            calculated_discount=("discount_amount", "sum"),
            calculated_net=("net_amount", "sum"),
        )
        .reset_index()
    )

    reconciliation = orders.merge(
        item_totals,
        on="order_id",
        how="left",
        validate="one_to_one",
    )

    assert np.allclose(
        reconciliation["subtotal_amount"],
        reconciliation["calculated_subtotal"],
        atol=0.01,
    )

    assert np.allclose(
        reconciliation["discount_amount"],
        reconciliation["calculated_discount"],
        atol=0.01,
    )

    expected_order_total = (
        reconciliation["calculated_net"]
        + reconciliation["shipping_amount"]
    )

    assert np.allclose(
        reconciliation["order_total"],
        expected_order_total,
        atol=0.01,
    )


def test_transaction_values_are_not_negative() -> None:
    """Monetary and quantity fields must not be negative."""

    orders, order_items = create_test_transactions()

    assert (orders["order_total"] >= 0).all()
    assert (orders["subtotal_amount"] >= 0).all()
    assert (orders["shipping_amount"] >= 0).all()

    assert (order_items["quantity"] > 0).all()
    assert (order_items["unit_price"] > 0).all()
    assert (order_items["net_amount"] >= 0).all()
