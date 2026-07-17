"""Tests for CRM customer and product generators."""

from datetime import date

from ingestion.generators.customers import generate_customers
from ingestion.generators.products import generate_products


TEST_DATE = date(2026, 7, 17)


def test_customer_generator_creates_expected_records() -> None:
    """Verify customer count, IDs and required columns."""

    customers = generate_customers(
        record_count=25,
        seed=42,
        as_of_date=TEST_DATE,
    )

    required_columns = {
        "customer_id",
        "first_name",
        "last_name",
        "email",
        "city",
        "country",
        "registration_date",
        "loyalty_status",
        "acquisition_channel",
        "is_active",
        "updated_at",
    }

    assert len(customers) == 25
    assert required_columns.issubset(customers.columns)
    assert customers["customer_id"].is_unique
    assert customers["email"].is_unique
    assert customers["customer_id"].notna().all()


def test_product_generator_creates_valid_prices() -> None:
    """Verify product IDs and pricing rules."""

    products = generate_products(
        record_count=25,
        seed=42,
        as_of_date=TEST_DATE,
    )

    assert len(products) == 25
    assert products["product_id"].is_unique
    assert products["sku"].is_unique
    assert (products["list_price"] > 0).all()
    assert (products["unit_cost"] > 0).all()
    assert (
        products["list_price"] >= products["unit_cost"]
    ).all()


def test_generators_are_deterministic() -> None:
    """The same seed should reproduce the same records."""

    first_run = generate_customers(
        record_count=10,
        seed=42,
        as_of_date=TEST_DATE,
    )

    second_run = generate_customers(
        record_count=10,
        seed=42,
        as_of_date=TEST_DATE,
    )

    assert first_run.equals(second_run)
