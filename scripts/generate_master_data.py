"""Generate NovaCart customer and product master data."""

from __future__ import annotations

from ingestion.config.settings import settings
from ingestion.generators.common import (
    build_partitioned_path,
    calculate_file_checksum,
    write_csv,
)
from ingestion.generators.customers import generate_customers
from ingestion.generators.products import generate_products


def main() -> None:
    """Generate and save master datasets."""

    customers = generate_customers(
        record_count=settings.customer_record_count,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
    )

    products = generate_products(
        record_count=settings.product_record_count,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
    )

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

    write_csv(customers, customer_path)
    write_csv(products, product_path)

    print("NovaCart master-data generation completed.")
    print()
    print(f"Customers generated: {len(customers):,}")
    print(f"Customer file: {customer_path}")
    print(
        "Customer checksum: "
        f"{calculate_file_checksum(customer_path)}"
    )
    print()
    print(f"Products generated: {len(products):,}")
    print(f"Product file: {product_path}")
    print(
        "Product checksum: "
        f"{calculate_file_checksum(product_path)}"
    )


if __name__ == "__main__":
    main()
