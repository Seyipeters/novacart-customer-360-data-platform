with expected_totals as (

    select
        order_id,

        count(*) as expected_order_item_count,

        sum(ordered_quantity)
            as expected_ordered_quantity,

        round(
            sum(order_item_net_amount),
            2
        ) as expected_item_net_amount,

        sum(return_record_count)
            as expected_return_record_count,

        sum(completed_return_quantity)
            as expected_completed_return_quantity,

        sum(pending_return_quantity)
            as expected_pending_return_quantity,

        sum(rejected_return_quantity)
            as expected_rejected_return_quantity,

        round(
            sum(completed_refund_amount),
            2
        ) as expected_completed_refund_amount

    from {{ ref('int_ecommerce__order_item_return_summary') }}
    group by order_id

),

actual_totals as (

    select
        order_id,
        order_item_count,
        total_ordered_quantity,
        total_order_item_net_amount,
        return_record_count,
        completed_return_quantity,
        pending_return_quantity,
        rejected_return_quantity,
        completed_refund_amount

    from {{ ref('int_ecommerce__order_return_summary') }}

)

select
    actual.order_id

from actual_totals actual

inner join expected_totals expected
    on actual.order_id = expected.order_id

where actual.order_item_count
        <> expected.expected_order_item_count

   or actual.total_ordered_quantity
        <> expected.expected_ordered_quantity

   or abs(
        actual.total_order_item_net_amount
        - expected.expected_item_net_amount
      ) >= 0.01

   or actual.return_record_count
        <> expected.expected_return_record_count

   or actual.completed_return_quantity
        <> expected.expected_completed_return_quantity

   or actual.pending_return_quantity
        <> expected.expected_pending_return_quantity

   or actual.rejected_return_quantity
        <> expected.expected_rejected_return_quantity

   or abs(
        actual.completed_refund_amount
        - expected.expected_completed_refund_amount
      ) >= 0.01