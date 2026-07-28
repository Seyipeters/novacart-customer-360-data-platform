with current_orders as (

    select
        order_id,
        customer_id,
        order_date,
        order_status,
        currency as order_currency,
        order_total

    from {{ ref('int_ecommerce__orders_current') }}

),

order_item_returns as (

    select
        order_item_id,
        order_id,
        ordered_quantity,
        order_item_net_amount,

        return_record_count,
        completed_return_record_count,
        pending_return_record_count,
        rejected_return_record_count,

        requested_return_quantity,
        completed_return_quantity,
        pending_return_quantity,
        rejected_return_quantity,

        completed_refund_amount,

        first_return_date,
        latest_return_date,

        has_return_request,
        has_completed_return,
        has_pending_return

    from {{ ref('int_ecommerce__order_item_return_summary') }}

),

order_return_aggregates as (

    select
        order_id,

        count(*) as order_item_count,

        sum(ordered_quantity)
            as total_ordered_quantity,

        round(
            sum(order_item_net_amount),
            2
        ) as total_order_item_net_amount,

        sum(return_record_count)
            as return_record_count,

        sum(completed_return_record_count)
            as completed_return_record_count,

        sum(pending_return_record_count)
            as pending_return_record_count,

        sum(rejected_return_record_count)
            as rejected_return_record_count,

        sum(
            case
                when has_return_request then 1
                else 0
            end
        ) as return_request_item_count,

        sum(
            case
                when has_completed_return then 1
                else 0
            end
        ) as completed_return_item_count,

        sum(
            case
                when has_pending_return then 1
                else 0
            end
        ) as pending_return_item_count,

        sum(requested_return_quantity)
            as requested_return_quantity,

        sum(completed_return_quantity)
            as completed_return_quantity,

        sum(pending_return_quantity)
            as pending_return_quantity,

        sum(rejected_return_quantity)
            as rejected_return_quantity,

        round(
            sum(completed_refund_amount),
            2
        ) as completed_refund_amount,

        min(first_return_date)
            as first_return_date,

        max(latest_return_date)
            as latest_return_date

    from order_item_returns
    group by order_id

),

final as (

    select
        orders.order_id,
        orders.customer_id,
        orders.order_date,
        orders.order_status,
        orders.order_currency,
        orders.order_total,

        coalesce(
            aggregates.order_item_count,
            0
        ) as order_item_count,

        coalesce(
            aggregates.total_ordered_quantity,
            0
        ) as total_ordered_quantity,

        coalesce(
            aggregates.total_order_item_net_amount,
            0
        ) as total_order_item_net_amount,

        coalesce(
            aggregates.return_record_count,
            0
        ) as return_record_count,

        coalesce(
            aggregates.completed_return_record_count,
            0
        ) as completed_return_record_count,

        coalesce(
            aggregates.pending_return_record_count,
            0
        ) as pending_return_record_count,

        coalesce(
            aggregates.rejected_return_record_count,
            0
        ) as rejected_return_record_count,

        coalesce(
            aggregates.return_request_item_count,
            0
        ) as return_request_item_count,

        coalesce(
            aggregates.completed_return_item_count,
            0
        ) as completed_return_item_count,

        coalesce(
            aggregates.pending_return_item_count,
            0
        ) as pending_return_item_count,

        coalesce(
            aggregates.requested_return_quantity,
            0
        ) as requested_return_quantity,

        coalesce(
            aggregates.completed_return_quantity,
            0
        ) as completed_return_quantity,

        coalesce(
            aggregates.pending_return_quantity,
            0
        ) as pending_return_quantity,

        coalesce(
            aggregates.rejected_return_quantity,
            0
        ) as rejected_return_quantity,

        coalesce(
            aggregates.completed_refund_amount,
            0
        ) as completed_refund_amount,

        aggregates.first_return_date,
        aggregates.latest_return_date,

        round(
            coalesce(
                aggregates.total_order_item_net_amount,
                0
            )
            - coalesce(
                aggregates.completed_refund_amount,
                0
            ),
            2
        ) as net_item_revenue_after_refunds,

        round(
            coalesce(
                aggregates.completed_refund_amount,
                0
            )
            / nullif(
                aggregates.total_order_item_net_amount,
                0
            ),
            4
        ) as completed_refund_rate,

        case
            when coalesce(
                aggregates.return_record_count,
                0
            ) > 0
                then true
            else false
        end as has_return_request,

        case
            when coalesce(
                aggregates.completed_return_record_count,
                0
            ) > 0
                then true
            else false
        end as has_completed_return,

        case
            when coalesce(
                aggregates.pending_return_record_count,
                0
            ) > 0
                then true
            else false
        end as has_pending_return,

        case
            when coalesce(
                aggregates.return_record_count,
                0
            ) = 0
                then 'NO_RETURN'

            when aggregates.completed_return_record_count > 0
             and aggregates.pending_return_record_count = 0
             and aggregates.rejected_return_record_count = 0
                then 'COMPLETED_ONLY'

            when aggregates.pending_return_record_count > 0
             and aggregates.completed_return_record_count = 0
             and aggregates.rejected_return_record_count = 0
                then 'PENDING_ONLY'

            when aggregates.rejected_return_record_count > 0
             and aggregates.completed_return_record_count = 0
             and aggregates.pending_return_record_count = 0
                then 'REJECTED_ONLY'

            else 'MIXED'
        end as order_return_status,

        case
            when coalesce(
                aggregates.completed_refund_amount,
                0
            ) > coalesce(
                aggregates.total_order_item_net_amount,
                0
            )
                then true
            else false
        end as completed_refund_exceeds_item_net_flag

    from current_orders orders

    left join order_return_aggregates aggregates
        on orders.order_id = aggregates.order_id

)

select *
from final