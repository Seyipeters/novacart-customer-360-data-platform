"""Tests for payment-attempt and return generation."""

from datetime import date

import numpy as np

from ingestion.generators.customers import generate_customers
from ingestion.generators.orders import (
    generate_orders_and_items,
)
from ingestion.generators.payments_returns import (
    generate_payments,
    generate_returns,
)
from ingestion.generators.products import generate_products


TEST_DATE = date(2026, 7, 17)


def create_test_data():
    """Create reusable transaction, payment, and return data."""

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
        record_count=300,
        seed=42,
        as_of_date=TEST_DATE,
        lookback_days=180,
        max_items_per_order=5,
    )

    payments = generate_payments(
        orders=orders,
        seed=42,
        as_of_date=TEST_DATE,
        retry_rate=0.10,
        processing_failure_rate=0.15,
    )

    returns = generate_returns(
        orders=orders,
        order_items=order_items,
        seed=42,
        as_of_date=TEST_DATE,
        return_rate=0.10,
        max_return_days=30,
    )

    return orders, order_items, payments, returns


def test_every_order_has_a_payment_attempt() -> None:
    """Every order must have at least one payment attempt."""

    orders, _, payments, _ = create_test_data()

    assert set(orders["order_id"]) == set(
        payments["order_id"]
    )


def test_completed_orders_have_paid_attempts() -> None:
    """Completed and shipped orders need a paid payment."""

    orders, _, payments, _ = create_test_data()

    completed_order_ids = set(
        orders.loc[
            orders["order_status"].isin(
                ["COMPLETED", "SHIPPED"]
            ),
            "order_id",
        ]
    )

    paid_order_ids = set(
        payments.loc[
            payments["payment_status"] == "PAID",
            "order_id",
        ]
    )

    assert completed_order_ids.issubset(
        paid_order_ids
    )


def test_captured_amounts_are_valid() -> None:
    """Only paid attempts may capture money."""

    _, _, payments, _ = create_test_data()

    paid_payments = payments.loc[
        payments["payment_status"] == "PAID"
    ]

    unpaid_payments = payments.loc[
        payments["payment_status"] != "PAID"
    ]

    assert np.allclose(
        paid_payments["captured_amount"],
        paid_payments["payment_amount"],
        atol=0.01,
    )

    assert (
        unpaid_payments["captured_amount"] == 0
    ).all()


def test_returns_reference_valid_transactions() -> None:
    """Returns must reference existing orders and order items."""

    orders, order_items, _, returns = create_test_data()

    assert returns["return_id"].is_unique

    assert returns["order_id"].isin(
        set(orders["order_id"])
    ).all()

    assert returns["order_item_id"].isin(
        set(order_items["order_item_id"])
    ).all()


def test_return_quantities_do_not_exceed_purchases() -> None:
    """Returned quantity must not exceed purchased quantity."""

    _, order_items, _, returns = create_test_data()

    reconciliation = returns.merge(
        order_items[
            [
                "order_item_id",
                "quantity",
                "net_amount",
            ]
        ],
        on="order_item_id",
        how="left",
        validate="one_to_one",
    )

    assert (
        reconciliation["return_quantity"]
        <= reconciliation["quantity"]
    ).all()

    maximum_refund = (
        reconciliation["net_amount"]
        / reconciliation["quantity"]
        * reconciliation["return_quantity"]
    )

    assert (
        reconciliation["refund_amount"]
        <= maximum_refund + 0.01
    ).all()


def test_returns_only_use_completed_orders() -> None:
    """Only completed orders should create return records."""

    orders, _, _, returns = create_test_data()

    return_orders = returns.merge(
        orders[["order_id", "order_status"]],
        on="order_id",
        how="left",
        validate="many_to_one",
    )

    assert (
        return_orders["order_status"] == "COMPLETED"
    ).all()
