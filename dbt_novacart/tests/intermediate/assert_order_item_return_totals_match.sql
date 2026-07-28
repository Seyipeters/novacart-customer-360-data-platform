with expected_return_totals as (

    select
        order_item_id,

        count(distinct return_id)
            as expected_return_record_count,

        sum(
            case
                when return_status = 'COMPLETED'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as expected_completed_quantity,

        sum(
            case
                when return_status = 'PENDING'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as expected_pending_quantity,

        sum(
            case
                when return_status = 'REJECTED'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as expected_rejected_quantity,

        round(
            sum(
                case
                    when return_status = 'COMPLETED'
                        then coalesce(refund_amount, 0)
                    else 0
                end
            ),
            2
        ) as expected_completed_refund_amount

    from {{ ref('int_ecommerce__returns_current') }}
    group by order_item_id

),

actual_return_totals as (

    select
        order_item_id,
        return_record_count,
        completed_return_quantity,
        pending_return_quantity,
        rejected_return_quantity,
        completed_refund_amount

    from {{ ref('int_ecommerce__order_item_return_summary') }}
    where has_return_request = true

)

select
    coalesce(
        expected.order_item_id,
        actual.order_item_id
    ) as order_item_id,

    expected.expected_return_record_count,
    actual.return_record_count,

    expected.expected_completed_quantity,
    actual.completed_return_quantity,

    expected.expected_pending_quantity,
    actual.pending_return_quantity,

    expected.expected_rejected_quantity,
    actual.rejected_return_quantity,

    expected.expected_completed_refund_amount,
    actual.completed_refund_amount

from expected_return_totals expected

full outer join actual_return_totals actual
    on expected.order_item_id = actual.order_item_id

where expected.order_item_id is null
   or actual.order_item_id is null
   or expected.expected_return_record_count
      <> actual.return_record_count
   or expected.expected_completed_quantity
      <> actual.completed_return_quantity
   or expected.expected_pending_quantity
      <> actual.pending_return_quantity
   or expected.expected_rejected_quantity
      <> actual.rejected_return_quantity
   or abs(
        expected.expected_completed_refund_amount
        - actual.completed_refund_amount
      ) >= 0.01