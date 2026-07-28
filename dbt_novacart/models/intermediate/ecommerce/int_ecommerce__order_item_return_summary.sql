with current_order_items as (

    select
        order_item_id,
        order_id,
        product_id,
        quantity as ordered_quantity,
        net_amount as order_item_net_amount

    from {{ ref('int_ecommerce__order_items_current') }}

),

current_returns as (

    select
        return_id,
        order_id,
        order_item_id,
        customer_id,
        product_id,
        return_date,
        return_quantity,
        return_reason,
        return_status,
        refund_amount,
        currency,
        source_created_at,
        loaded_at

    from {{ ref('int_ecommerce__returns_current') }}

),

ranked_returns as (

    select
        *,

        row_number() over (
            partition by order_item_id
            order by
                return_date desc,
                source_created_at desc,
                loaded_at desc,
                return_id desc
        ) as latest_return_rank

    from current_returns

),

return_aggregates as (

    select
        order_item_id,

        count(distinct return_id)
            as return_record_count,

        sum(
            case
                when return_status = 'COMPLETED' then 1
                else 0
            end
        ) as completed_return_record_count,

        sum(
            case
                when return_status = 'PENDING' then 1
                else 0
            end
        ) as pending_return_record_count,

        sum(
            case
                when return_status = 'REJECTED' then 1
                else 0
            end
        ) as rejected_return_record_count,

        sum(coalesce(return_quantity, 0))
            as requested_return_quantity,

        sum(
            case
                when return_status = 'COMPLETED'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as completed_return_quantity,

        sum(
            case
                when return_status = 'PENDING'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as pending_return_quantity,

        sum(
            case
                when return_status = 'REJECTED'
                    then coalesce(return_quantity, 0)
                else 0
            end
        ) as rejected_return_quantity,

        round(
            sum(
                case
                    when return_status = 'COMPLETED'
                        then coalesce(refund_amount, 0)
                    else 0
                end
            ),
            2
        ) as completed_refund_amount,

        min(return_date)
            as first_return_date,

        max(return_date)
            as latest_return_date

    from current_returns
    group by order_item_id

),

latest_return as (

    select
        order_item_id,

        return_id
            as latest_return_id,

        return_reason
            as latest_return_reason,

        return_status
            as latest_return_status,

        currency
            as return_currency,

        source_created_at
            as latest_return_created_at

    from ranked_returns
    where latest_return_rank = 1

),

final as (

    select
        order_items.order_item_id,
        order_items.order_id,
        order_items.product_id,
        order_items.ordered_quantity,
        order_items.order_item_net_amount,

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

        latest.latest_return_id,
        latest.latest_return_reason,
        latest.latest_return_status,
        latest.return_currency,
        latest.latest_return_created_at,

        greatest(
            order_items.ordered_quantity
            - coalesce(aggregates.completed_return_quantity, 0),
            0
        ) as retained_quantity,

        round(
            coalesce(aggregates.completed_return_quantity, 0)
            / nullif(order_items.ordered_quantity, 0),
            4
        ) as completed_return_rate,

        case
            when aggregates.order_item_id is not null
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
                aggregates.completed_return_quantity,
                0
            ) > order_items.ordered_quantity
                then true
            else false
        end as completed_return_quantity_exceeds_ordered_flag

    from current_order_items order_items

    left join return_aggregates aggregates
        on order_items.order_item_id = aggregates.order_item_id

    left join latest_return latest
        on order_items.order_item_id = latest.order_item_id

)

select *
from final