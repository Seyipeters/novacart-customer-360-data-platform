"""Generate payment attempts, product returns, and refunds."""

from __future__ import annotations

import random
from datetime import date, datetime, time, timedelta

import pandas as pd


PAYMENT_METHODS = [
    "CREDIT_CARD",
    "DEBIT_CARD",
    "PAYPAL",
    "MOBILE_PAY",
    "BANK_TRANSFER",
]

PAYMENT_FAILURE_REASONS = [
    "INSUFFICIENT_FUNDS",
    "CARD_DECLINED",
    "EXPIRED_CARD",
    "GATEWAY_TIMEOUT",
    "AUTHENTICATION_FAILED",
]

RETURN_REASONS = [
    "DAMAGED_ITEM",
    "WRONG_ITEM",
    "NOT_AS_DESCRIBED",
    "SIZE_OR_FIT",
    "CHANGED_MIND",
    "DEFECTIVE_PRODUCT",
]


def generate_payments(
    orders: pd.DataFrame,
    seed: int,
    as_of_date: date,
    retry_rate: float,
    processing_failure_rate: float,
) -> pd.DataFrame:
    """Generate payment-attempt records for each order."""

    if orders.empty:
        raise ValueError("Order data cannot be empty.")

    if not 0 <= retry_rate <= 1:
        raise ValueError("Payment retry rate must be between 0 and 1.")

    if not 0 <= processing_failure_rate <= 1:
        raise ValueError(
            "Processing payment failure rate must be between 0 and 1."
        )

    random_generator = random.Random(seed + 3000)

    payment_records: list[dict[str, object]] = []
    payment_number = 1

    as_of_datetime = datetime.combine(as_of_date, time.max)

    sorted_orders = orders.sort_values("order_id")

    for order in sorted_orders.to_dict(orient="records"):
        order_id = str(order["order_id"])
        order_status = str(order["order_status"])
        order_total = round(float(order["order_total"]), 2)

        order_timestamp = pd.Timestamp(
            order["order_timestamp"]
        ).to_pydatetime()

        payment_method = random_generator.choices(
            PAYMENT_METHODS,
            weights=[38, 22, 15, 15, 10],
            k=1,
        )[0]

        if order_status in {"COMPLETED", "SHIPPED"}:
            if random_generator.random() < retry_rate:
                payment_statuses = ["FAILED", "PAID"]
            else:
                payment_statuses = ["PAID"]

        elif order_status == "PROCESSING":
            if (
                random_generator.random()
                < processing_failure_rate
            ):
                payment_statuses = ["FAILED"]
            else:
                payment_statuses = ["PENDING"]

        else:
            payment_statuses = ["CANCELLED"]

        previous_payment_timestamp = order_timestamp

        for attempt_number, payment_status in enumerate(
            payment_statuses,
            start=1,
        ):
            payment_delay_minutes = random_generator.randint(
                1,
                30 if attempt_number == 1 else 120,
            )

            payment_timestamp = (
                previous_payment_timestamp
                + timedelta(minutes=payment_delay_minutes)
            )

            payment_timestamp = min(
                payment_timestamp,
                as_of_datetime,
            )

            previous_payment_timestamp = payment_timestamp

            payment_amount = (
                0.00
                if payment_status == "CANCELLED"
                else order_total
            )

            captured_amount = (
                payment_amount
                if payment_status == "PAID"
                else 0.00
            )

            failure_reason = (
                random_generator.choice(
                    PAYMENT_FAILURE_REASONS
                )
                if payment_status == "FAILED"
                else None
            )

            arrival_delay_hours = random_generator.choices(
                [0, 1, 2, 6, 12, 24, 48],
                weights=[40, 20, 13, 10, 8, 6, 3],
                k=1,
            )[0]

            record_arrived_at = min(
                payment_timestamp
                + timedelta(hours=arrival_delay_hours),
                as_of_datetime,
            )

            payment_records.append(
                {
                    "payment_id": (
                        f"PAY{payment_number:010d}"
                    ),
                    "order_id": order_id,
                    "payment_attempt_number": attempt_number,
                    "payment_method": payment_method,
                    "payment_status": payment_status,
                    "payment_amount": payment_amount,
                    "captured_amount": captured_amount,
                    "currency": order["currency"],
                    "payment_timestamp": (
                        payment_timestamp.isoformat()
                    ),
                    "gateway_reference": (
                        f"GTW-{payment_number:012d}"
                    ),
                    "failure_reason": failure_reason,
                    "record_arrived_at": (
                        record_arrived_at.isoformat()
                    ),
                }
            )

            payment_number += 1

    return pd.DataFrame(payment_records)


def generate_returns(
    orders: pd.DataFrame,
    order_items: pd.DataFrame,
    seed: int,
    as_of_date: date,
    return_rate: float,
    max_return_days: int,
) -> pd.DataFrame:
    """Generate returns for eligible completed orders."""

    if orders.empty:
        raise ValueError("Order data cannot be empty.")

    if order_items.empty:
        raise ValueError("Order-item data cannot be empty.")

    if not 0 <= return_rate <= 1:
        raise ValueError("Return rate must be between 0 and 1.")

    if max_return_days <= 0:
        raise ValueError(
            "Maximum return days must be greater than zero."
        )

    random_generator = random.Random(seed + 4000)

    as_of_datetime = datetime.combine(as_of_date, time.max)

    completed_orders = orders.loc[
        orders["order_status"] == "COMPLETED"
    ].copy()

    completed_orders["parsed_order_date"] = pd.to_datetime(
        completed_orders["order_date"]
    ).dt.date

    eligible_orders = completed_orders.loc[
        completed_orders["parsed_order_date"] < as_of_date
    ]

    if eligible_orders.empty or return_rate == 0:
        return pd.DataFrame(
            columns=[
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
            ]
        )

    selected_order_count = max(
        1,
        round(len(eligible_orders) * return_rate),
    )

    selected_order_count = min(
        selected_order_count,
        len(eligible_orders),
    )

    selected_order_ids = random_generator.sample(
        list(eligible_orders["order_id"]),
        k=selected_order_count,
    )

    return_records: list[dict[str, object]] = []
    return_number = 1

    eligible_order_lookup = eligible_orders.set_index(
        "order_id"
    ).to_dict(orient="index")

    for order_id in selected_order_ids:
        order = eligible_order_lookup[order_id]

        matching_items = order_items.loc[
            order_items["order_id"] == order_id
        ]

        item_records = matching_items.to_dict(
            orient="records"
        )

        returned_item_count = random_generator.randint(
            1,
            min(2, len(item_records)),
        )

        selected_items = random_generator.sample(
            item_records,
            k=returned_item_count,
        )

        order_date = order["parsed_order_date"]

        available_return_days = min(
            max_return_days,
            (as_of_date - order_date).days,
        )

        for item in selected_items:
            return_quantity = random_generator.randint(
                1,
                int(item["quantity"]),
            )

            days_after_order = random_generator.randint(
                1,
                available_return_days,
            )

            return_date = (
                order_date
                + timedelta(days=days_after_order)
            )

            return_timestamp = datetime.combine(
                return_date,
                time(
                    hour=random_generator.randint(8, 20),
                    minute=random_generator.randint(0, 59),
                    second=random_generator.randint(0, 59),
                ),
            )

            return_status = random_generator.choices(
                ["COMPLETED", "PENDING", "REJECTED"],
                weights=[80, 15, 5],
                k=1,
            )[0]

            purchased_quantity = int(item["quantity"])
            line_net_amount = float(item["net_amount"])

            refund_per_unit = (
                line_net_amount / purchased_quantity
            )

            refund_amount = (
                round(
                    refund_per_unit * return_quantity,
                    2,
                )
                if return_status == "COMPLETED"
                else 0.00
            )

            arrival_delay_days = random_generator.choices(
                [0, 1, 2, 3, 5],
                weights=[50, 22, 14, 9, 5],
                k=1,
            )[0]

            record_arrived_at = min(
                return_timestamp
                + timedelta(days=arrival_delay_days),
                as_of_datetime,
            )

            return_records.append(
                {
                    "return_id": (
                        f"RET{return_number:010d}"
                    ),
                    "order_id": order_id,
                    "order_item_id": item["order_item_id"],
                    "customer_id": order["customer_id"],
                    "product_id": item["product_id"],
                    "return_date": return_date.isoformat(),
                    "return_quantity": return_quantity,
                    "return_reason": random_generator.choice(
                        RETURN_REASONS
                    ),
                    "return_status": return_status,
                    "refund_amount": refund_amount,
                    "currency": order["currency"],
                    "created_at": (
                        return_timestamp.isoformat()
                    ),
                    "record_arrived_at": (
                        record_arrived_at.isoformat()
                    ),
                }
            )

            return_number += 1

    return pd.DataFrame(return_records)
