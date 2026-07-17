"""Generate NovaCart payment and return datasets."""

from __future__ import annotations

import pandas as pd

from ingestion.config.settings import settings
from ingestion.generators.common import (
    build_partitioned_path,
    calculate_file_checksum,
    write_csv,
)
from ingestion.generators.payments_returns import (
    generate_payments,
    generate_returns,
)


def main() -> None:
    """Load transactions and generate payments and returns."""

    orders_path = build_partitioned_path(
        source_system="ecommerce",
        dataset_name="orders",
        as_of_date=settings.data_as_of_date,
    )

    order_items_path = build_partitioned_path(
        source_system="ecommerce",
        dataset_name="order_items",
        as_of_date=settings.data_as_of_date,
    )

    if not orders_path.exists():
        raise FileNotFoundError(
            "Orders file was not found. "
            "Run generate_transaction_data first."
        )

    if not order_items_path.exists():
        raise FileNotFoundError(
            "Order-items file was not found. "
            "Run generate_transaction_data first."
        )

    orders = pd.read_csv(orders_path)
    order_items = pd.read_csv(order_items_path)

    payments = generate_payments(
        orders=orders,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
        retry_rate=settings.payment_retry_rate,
        processing_failure_rate=(
            settings.processing_payment_failure_rate
        ),
    )

    returns = generate_returns(
        orders=orders,
        order_items=order_items,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
        return_rate=settings.return_rate,
        max_return_days=settings.max_return_days,
    )

    payments_path = build_partitioned_path(
        source_system="payment_gateway",
        dataset_name="payments",
        as_of_date=settings.data_as_of_date,
    )

    returns_path = build_partitioned_path(
        source_system="ecommerce",
        dataset_name="returns",
        as_of_date=settings.data_as_of_date,
    )

    write_csv(payments, payments_path)
    write_csv(returns, returns_path)

    print("Payment and return generation completed.")
    print()

    print(f"Payment attempts generated: {len(payments):,}")
    print(f"Payments file: {payments_path}")
    print(
        "Payments checksum: "
        f"{calculate_file_checksum(payments_path)}"
    )
    print()

    print(f"Returns generated: {len(returns):,}")
    print(f"Returns file: {returns_path}")
    print(
        "Returns checksum: "
        f"{calculate_file_checksum(returns_path)}"
    )
    print()

    print(
        "Captured payments: "
        f"€{payments['captured_amount'].sum():,.2f}"
    )

    print(
        "Completed refunds: "
        f"€{returns['refund_amount'].sum():,.2f}"
    )


if __name__ == "__main__":
    main()
