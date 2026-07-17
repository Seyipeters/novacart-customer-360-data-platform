"""Generate inventory, campaign, and website event datasets."""

from __future__ import annotations

import pandas as pd

from ingestion.config.settings import settings
from ingestion.generators.campaigns import (
    generate_campaigns,
)
from ingestion.generators.common import (
    build_partitioned_path,
    calculate_file_checksum,
    write_csv,
)
from ingestion.generators.inventory import (
    generate_inventory_snapshots,
)
from ingestion.generators.web_events import (
    generate_web_events,
)


def load_required_dataset(
    source_system: str,
    dataset_name: str,
) -> pd.DataFrame:
    """Load a previously generated dataset."""

    dataset_path = build_partitioned_path(
        source_system=source_system,
        dataset_name=dataset_name,
        as_of_date=settings.data_as_of_date,
    )

    if not dataset_path.exists():
        raise FileNotFoundError(
            f"{dataset_name} file was not found: "
            f"{dataset_path}"
        )

    return pd.read_csv(dataset_path)


def main() -> None:
    """Generate operational and customer engagement data."""

    customers = load_required_dataset(
        source_system="crm",
        dataset_name="customers",
    )

    products = load_required_dataset(
        source_system="ecommerce",
        dataset_name="products",
    )

    orders = load_required_dataset(
        source_system="ecommerce",
        dataset_name="orders",
    )

    order_items = load_required_dataset(
        source_system="ecommerce",
        dataset_name="order_items",
    )

    campaigns = generate_campaigns(
        record_count=settings.campaign_record_count,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
    )

    inventory = generate_inventory_snapshots(
        products=products,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
        lookback_days=settings.inventory_lookback_days,
    )

    web_events = generate_web_events(
        customers=customers,
        products=products,
        orders=orders,
        order_items=order_items,
        campaigns=campaigns,
        record_count=settings.web_event_record_count,
        seed=settings.data_generation_seed,
        as_of_date=settings.data_as_of_date,
        lookback_days=settings.web_event_lookback_days,
        anonymous_event_rate=(
            settings.anonymous_event_rate
        ),
    )

    inventory_path = build_partitioned_path(
        source_system="inventory_system",
        dataset_name="inventory_daily",
        as_of_date=settings.data_as_of_date,
    )

    campaigns_path = build_partitioned_path(
        source_system="marketing_platform",
        dataset_name="campaigns",
        as_of_date=settings.data_as_of_date,
    )

    web_events_path = build_partitioned_path(
        source_system="web_analytics",
        dataset_name="web_events",
        as_of_date=settings.data_as_of_date,
    )

    write_csv(inventory, inventory_path)
    write_csv(campaigns, campaigns_path)
    write_csv(web_events, web_events_path)

    print("Operations and engagement generation completed.")
    print()

    print(f"Inventory snapshots: {len(inventory):,}")
    print(f"Inventory file: {inventory_path}")
    print(
        "Inventory checksum: "
        f"{calculate_file_checksum(inventory_path)}"
    )
    print()

    print(f"Campaigns generated: {len(campaigns):,}")
    print(f"Campaign file: {campaigns_path}")
    print(
        "Campaign checksum: "
        f"{calculate_file_checksum(campaigns_path)}"
    )
    print()

    print(f"Web events generated: {len(web_events):,}")
    print(f"Web-events file: {web_events_path}")
    print(
        "Web-events checksum: "
        f"{calculate_file_checksum(web_events_path)}"
    )


if __name__ == "__main__":
    main()
