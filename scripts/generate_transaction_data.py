"""Generate NovaCart order and order-item transaction data."""

from __future__ import annotations

import pandas as pd

from ingestion.config.settings import settings
from ingestion.generators.common import (
    build_partitioned_path,
    calculate_file_checksum,
    write_csv,
)
from ingestion.generators.orders import generate_orders_and_items


def main() -> None:
    """Load master data and generate transaction datasets."""

    customer_path = build_partitioned_path(
        source_system="crm",
        dataset_name="customers",
        as_of_date=settings.data_as_of_date,
    )

    product_path = build_partitioned_path(
        source_system="ecommerce",
        dataset_name="products",
        as_of_date=settings.data_as_of_date,
    )

    if not customer_path.exists():
        raise FileNotFoundError(
            "Customer master file was not found. "
            "Run generate_master_data first."
        )

    if not product_path.exists():
        raise FileNotFoundError(
            "Product master file was not found. "
            "Run generate_master_data first."
        )

    customers = pd.read_csv(customer_path)
    products = pd.read_csv(product_path)

    orders, order_items = generate_orders_and_items(
        customers=customers,
        products=products,
        record_count=settings.order_record_count,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
        lookback_days=settings.order_lookback_days,
        max_items_per_order=settings.max_items_per_order,
    )

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

    write_csv(orders, orders_path)
    write_csv(order_items, order_items_path)

    print("NovaCart transaction-data generation completed.")
    print()

    print(f"Orders generated: {len(orders):,}")
    print(f"Orders file: {orders_path}")
    print(
        "Orders checksum: "
        f"{calculate_file_checksum(orders_path)}"
    )
    print()

    print(f"Order items generated: {len(order_items):,}")
    print(f"Order-items file: {order_items_path}")
    print(
        "Order-items checksum: "
        f"{calculate_file_checksum(order_items_path)}"
    )
    print()

    print(
        "Order revenue: "
        f"€{orders['order_total'].sum():,.2f}"
    )


if __name__ == "__main__":
    main()
