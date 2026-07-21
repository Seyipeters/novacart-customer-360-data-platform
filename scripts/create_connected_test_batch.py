"""Create a small connected NovaCart batch for end-to-end pipeline testing."""

from __future__ import annotations

import argparse
import csv
from datetime import date
from pathlib import Path
from typing import Any


GENERATED_ROOT = Path("data/generated")


def write_csv(
    relative_directory: str,
    dataset: str,
    batch_date: date,
    columns: list[str],
    rows: list[list[Any]],
) -> Path:
    """Write one partitioned CSV without overwriting an existing batch."""

    date_compact = batch_date.strftime("%Y%m%d")

    output_path = (
        GENERATED_ROOT
        / relative_directory
        / f"year={batch_date:%Y}"
        / f"month={batch_date:%m}"
        / f"day={batch_date:%d}"
        / f"{dataset}_{date_compact}.csv"
    )

    if output_path.exists():
        raise FileExistsError(
            f"{output_path} already exists. "
            "Use a different batch date instead of overwriting it."
        )

    output_path.parent.mkdir(parents=True, exist_ok=True)

    with output_path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.writer(file)
        writer.writerow(columns)
        writer.writerows(rows)

    print(f"Created {dataset:<18} rows={len(rows):<3} {output_path}")
    return output_path


def create_batch(batch_date: date) -> None:
    date_text = batch_date.isoformat()
    date_compact = batch_date.strftime("%Y%m%d")

    customer_1 = f"CUSTT{date_compact}01"
    customer_2 = f"CUSTT{date_compact}02"

    product_1 = f"PRODT{date_compact}01"
    product_2 = f"PRODT{date_compact}02"

    order_1 = f"ORDT{date_compact}01"
    order_2 = f"ORDT{date_compact}02"

    item_1 = f"OIT{date_compact}01"
    item_2 = f"OIT{date_compact}02"
    item_3 = f"OIT{date_compact}03"

    campaign_id = f"CAMPT{date_compact}01"

    write_csv(
        "crm/customers",
        "customers",
        batch_date,
        [
            "customer_id",
            "first_name",
            "last_name",
            "email",
            "phone",
            "city",
            "region",
            "country",
            "postal_code",
            "registration_date",
            "loyalty_status",
            "acquisition_channel",
            "is_active",
            "updated_at",
        ],
        [
            [
                customer_1,
                "Elina",
                "Virtanen",
                f"elina.{date_compact}@example.com",
                "+358401110001",
                "Kuopio",
                "North Savo",
                "Finland",
                "70100",
                date_text,
                "SILVER",
                "EMAIL",
                True,
                f"{date_text} 09:00:00",
            ],
            [
                customer_2,
                "Michael",
                "Brown",
                f"michael.{date_compact}@example.com",
                "+358401110002",
                "Helsinki",
                "Uusimaa",
                "Finland",
                "00100",
                date_text,
                "BRONZE",
                "PAID_SEARCH",
                True,
                f"{date_text} 09:05:00",
            ],
        ],
    )

    write_csv(
        "ecommerce/products",
        "products",
        batch_date,
        [
            "product_id",
            "sku",
            "product_name",
            "category",
            "subcategory",
            "brand",
            "unit_cost",
            "list_price",
            "is_active",
            "launch_date",
            "updated_at",
        ],
        [
            [
                product_1,
                f"SKU-T-{date_compact}-01",
                "Nova Wireless Headphones",
                "Electronics",
                "Audio",
                "NovaSound",
                40.00,
                79.99,
                True,
                date_text,
                f"{date_text} 08:00:00",
            ],
            [
                product_2,
                f"SKU-T-{date_compact}-02",
                "Nova USB-C Charger",
                "Electronics",
                "Accessories",
                "NovaPower",
                12.00,
                29.50,
                True,
                date_text,
                f"{date_text} 08:05:00",
            ],
        ],
    )

    write_csv(
        "marketing_platform/campaigns",
        "campaigns",
        batch_date,
        [
            "campaign_id",
            "campaign_name",
            "campaign_channel",
            "campaign_objective",
            "target_segment",
            "start_date",
            "end_date",
            "budget_amount",
            "currency",
            "campaign_status",
            "updated_at",
        ],
        [
            [
                campaign_id,
                "Summer Electronics Test Campaign",
                "EMAIL",
                "CONVERSION",
                "TECH_SHOPPERS",
                date_text,
                "2026-07-31",
                2500.00,
                "EUR",
                "ACTIVE",
                f"{date_text} 08:30:00",
            ]
        ],
    )

    write_csv(
        "ecommerce/orders",
        "orders",
        batch_date,
        [
            "order_id",
            "customer_id",
            "order_timestamp",
            "order_date",
            "order_status",
            "sales_channel",
            "shipping_city",
            "shipping_region",
            "shipping_country",
            "currency",
            "item_count",
            "total_quantity",
            "subtotal_amount",
            "discount_amount",
            "shipping_amount",
            "order_total",
            "updated_at",
        ],
        [
            [
                order_1,
                customer_1,
                f"{date_text} 10:10:00",
                date_text,
                "COMPLETED",
                "WEB",
                "Kuopio",
                "North Savo",
                "Finland",
                "EUR",
                2,
                3,
                138.99,
                8.00,
                5.00,
                135.99,
                f"{date_text} 10:15:00",
            ],
            [
                order_2,
                customer_2,
                f"{date_text} 12:00:00",
                date_text,
                "COMPLETED",
                "WEB",
                "Helsinki",
                "Uusimaa",
                "Finland",
                "EUR",
                1,
                1,
                79.99,
                0.00,
                0.00,
                79.99,
                f"{date_text} 12:05:00",
            ],
        ],
    )

    write_csv(
        "ecommerce/order_items",
        "order_items",
        batch_date,
        [
            "order_item_id",
            "order_id",
            "product_id",
            "quantity",
            "unit_price",
            "gross_amount",
            "discount_rate",
            "discount_amount",
            "net_amount",
            "created_at",
        ],
        [
            [
                item_1,
                order_1,
                product_1,
                1,
                79.99,
                79.99,
                0.10,
                8.00,
                71.99,
                f"{date_text} 10:10:00",
            ],
            [
                item_2,
                order_1,
                product_2,
                2,
                29.50,
                59.00,
                0.00,
                0.00,
                59.00,
                f"{date_text} 10:10:00",
            ],
            [
                item_3,
                order_2,
                product_1,
                1,
                79.99,
                79.99,
                0.00,
                0.00,
                79.99,
                f"{date_text} 12:00:00",
            ],
        ],
    )

    write_csv(
        "payment_gateway/payments",
        "payments",
        batch_date,
        [
            "payment_id",
            "order_id",
            "payment_attempt_number",
            "payment_method",
            "payment_status",
            "payment_amount",
            "captured_amount",
            "currency",
            "payment_timestamp",
            "gateway_reference",
            "failure_reason",
            "record_arrived_at",
        ],
        [
            [
                f"PAYT{date_compact}01",
                order_1,
                1,
                "CARD",
                "SUCCESS",
                135.99,
                135.99,
                "EUR",
                f"{date_text} 10:11:00",
                f"GW-{date_compact}-01",
                "",
                f"{date_text} 10:12:00",
            ],
            [
                f"PAYT{date_compact}02",
                order_2,
                1,
                "MOBILE_PAY",
                "SUCCESS",
                79.99,
                79.99,
                "EUR",
                f"{date_text} 12:01:00",
                f"GW-{date_compact}-02",
                "",
                f"{date_text} 12:02:00",
            ],
        ],
    )

    write_csv(
        "ecommerce/returns",
        "returns",
        batch_date,
        [
            "return_id",
            "order_id",
            "order_item_id",
            "customer_id",
            "product_id",
            "return_date",
            "return_quantity",
            "return_reason",
            "return_status",
            "refund_amount",
            "currency",
            "created_at",
            "record_arrived_at",
        ],
        [
            [
                f"RETT{date_compact}01",
                order_1,
                item_2,
                customer_1,
                product_2,
                date_text,
                1,
                "NOT_NEEDED",
                "APPROVED",
                29.50,
                "EUR",
                f"{date_text} 15:00:00",
                f"{date_text} 15:05:00",
            ]
        ],
    )

    write_csv(
        "inventory_system/inventory_daily",
        "inventory_daily",
        batch_date,
        [
            "inventory_date",
            "warehouse_id",
            "warehouse_name",
            "warehouse_city",
            "warehouse_country",
            "product_id",
            "opening_stock",
            "received_quantity",
            "sold_quantity",
            "damaged_quantity",
            "closing_stock",
            "unit_cost",
            "inventory_value",
            "stockout_flag",
            "reorder_flag",
            "updated_at",
        ],
        [
            [
                date_text,
                "WH_TEST_01",
                "Kuopio Test Warehouse",
                "Kuopio",
                "Finland",
                product_1,
                100,
                0,
                2,
                0,
                98,
                40.00,
                3920.00,
                False,
                False,
                f"{date_text} 23:00:00",
            ],
            [
                date_text,
                "WH_TEST_01",
                "Kuopio Test Warehouse",
                "Kuopio",
                "Finland",
                product_2,
                100,
                0,
                2,
                0,
                98,
                12.00,
                1176.00,
                False,
                False,
                f"{date_text} 23:00:00",
            ],
        ],
    )

    web_event_columns = [
        "event_id",
        "session_id",
        "customer_id",
        "anonymous_id",
        "event_type",
        "product_id",
        "order_id",
        "campaign_id",
        "device_type",
        "browser",
        "traffic_source",
        "page_url",
        "event_timestamp",
        "record_arrived_at",
    ]

    session_1 = f"SES{date_compact}01"
    session_2 = f"SES{date_compact}02"

    write_csv(
        "web_analytics/web_events",
        "web_events",
        batch_date,
        web_event_columns,
        [
            [
                f"EVT{date_compact}001",
                session_1,
                customer_1,
                "",
                "PAGE_VIEW",
                "",
                "",
                campaign_id,
                "MOBILE",
                "CHROME",
                "EMAIL",
                "/home",
                f"{date_text} 09:50:00",
                f"{date_text} 09:50:05",
            ],
            [
                f"EVT{date_compact}002",
                session_1,
                customer_1,
                "",
                "PRODUCT_VIEW",
                product_1,
                "",
                campaign_id,
                "MOBILE",
                "CHROME",
                "EMAIL",
                f"/products/{product_1}",
                f"{date_text} 09:55:00",
                f"{date_text} 09:55:04",
            ],
            [
                f"EVT{date_compact}003",
                session_1,
                customer_1,
                "",
                "ADD_TO_CART",
                product_1,
                "",
                campaign_id,
                "MOBILE",
                "CHROME",
                "EMAIL",
                "/cart",
                f"{date_text} 10:00:00",
                f"{date_text} 10:00:03",
            ],
            [
                f"EVT{date_compact}004",
                session_1,
                customer_1,
                "",
                "ADD_TO_CART",
                product_2,
                "",
                campaign_id,
                "MOBILE",
                "CHROME",
                "EMAIL",
                "/cart",
                f"{date_text} 10:02:00",
                f"{date_text} 10:02:03",
            ],
            [
                f"EVT{date_compact}005",
                session_1,
                customer_1,
                "",
                "PURCHASE",
                "",
                order_1,
                campaign_id,
                "MOBILE",
                "CHROME",
                "EMAIL",
                "/order-confirmation",
                f"{date_text} 10:10:00",
                f"{date_text} 10:10:05",
            ],
            [
                f"EVT{date_compact}006",
                session_2,
                customer_2,
                "",
                "PAGE_VIEW",
                "",
                "",
                "",
                "DESKTOP",
                "EDGE",
                "PAID_SEARCH",
                "/home",
                f"{date_text} 11:40:00",
                f"{date_text} 11:40:04",
            ],
            [
                f"EVT{date_compact}007",
                session_2,
                customer_2,
                "",
                "PRODUCT_VIEW",
                product_1,
                "",
                "",
                "DESKTOP",
                "EDGE",
                "PAID_SEARCH",
                f"/products/{product_1}",
                f"{date_text} 11:45:00",
                f"{date_text} 11:45:04",
            ],
            [
                f"EVT{date_compact}008",
                session_2,
                customer_2,
                "",
                "PURCHASE",
                product_1,
                order_2,
                "",
                "DESKTOP",
                "EDGE",
                "PAID_SEARCH",
                "/order-confirmation",
                f"{date_text} 12:00:00",
                f"{date_text} 12:00:05",
            ],
        ],
    )

    print("\nConnected test batch created successfully.")
    print(f"Batch date: {date_text}")
    print("Datasets: 9")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--batch-date",
        default="2026-07-18",
        help="A fresh partition date in YYYY-MM-DD format.",
    )
    args = parser.parse_args()

    create_batch(date.fromisoformat(args.batch_date))


if __name__ == "__main__":
    main()
