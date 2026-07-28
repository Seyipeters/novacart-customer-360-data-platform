with current_orders as (

    select
        order_id,
        order_total,
        currency as order_currency

    from {{ ref('int_ecommerce__orders_current') }}

),

current_payments as (

    select
        payment_source_record_id,
        payment_id,
        order_id,
        payment_attempt_number,
        payment_method,
        payment_status,
        payment_amount,
        captured_amount,
        currency,
        payment_timestamp,
        gateway_reference,
        failure_reason,
        source_record_arrived_at,
        loaded_at

    from {{ ref('int_payment_gateway__payments_current') }}

),

ranked_payment_attempts as (

    select
        *,

        row_number() over (
            partition by order_id
            order by
                payment_attempt_number desc,
                payment_timestamp desc,
                source_record_arrived_at desc,
                loaded_at desc,
                payment_id desc
        ) as latest_attempt_rank

    from current_payments

),

payment_aggregates as (

    select
        order_id,

        count(distinct payment_id)
            as payment_attempt_count,

        min(payment_timestamp)
            as first_payment_timestamp,

        max(payment_timestamp)
            as last_payment_activity_at,

        sum(payment_amount)
            as total_requested_amount_across_attempts,

        sum(captured_amount)
            as total_captured_amount,

        max(payment_attempt_number)
            as highest_payment_attempt_number

    from current_payments
    group by order_id

),

latest_payment_attempt as (

    select
        order_id,

        payment_id
            as latest_payment_id,

        payment_attempt_number
            as latest_payment_attempt_number,

        payment_method
            as latest_payment_method,

        payment_status
            as latest_payment_status,

        payment_amount
            as latest_requested_amount,

        captured_amount
            as latest_captured_amount,

        currency
            as payment_currency,

        payment_timestamp
            as latest_payment_timestamp,

        gateway_reference
            as latest_gateway_reference,

        failure_reason
            as latest_failure_reason

    from ranked_payment_attempts
    where latest_attempt_rank = 1

),

final as (

    select
        orders.order_id,
        orders.order_total,
        orders.order_currency,

        coalesce(aggregates.payment_attempt_count, 0)
            as payment_attempt_count,

        aggregates.first_payment_timestamp,
        aggregates.last_payment_activity_at,

        coalesce(
            aggregates.total_requested_amount_across_attempts,
            0
        ) as total_requested_amount_across_attempts,

        coalesce(
            aggregates.total_captured_amount,
            0
        ) as total_captured_amount,

        coalesce(
            aggregates.highest_payment_attempt_number,
            0
        ) as highest_payment_attempt_number,

        latest.latest_payment_id,
        latest.latest_payment_attempt_number,
        latest.latest_payment_method,
        latest.latest_payment_status,
        latest.latest_requested_amount,
        latest.latest_captured_amount,
        latest.payment_currency,
        latest.latest_payment_timestamp,
        latest.latest_gateway_reference,
        latest.latest_failure_reason,

        round(
            orders.order_total
            - coalesce(aggregates.total_captured_amount, 0),
            2
        ) as outstanding_balance,

        case
            when aggregates.order_id is null
                then 'NO_PAYMENT'

            when coalesce(aggregates.total_captured_amount, 0) = 0
                then 'UNPAID'

            when abs(
                aggregates.total_captured_amount
                - orders.order_total
            ) < 0.01
                then 'PAID'

            when aggregates.total_captured_amount
                < orders.order_total
                then 'UNDERPAID'

            else 'OVERPAID'
        end as payment_reconciliation_status,

        case
            when latest.payment_currency is null
                then false

            when latest.payment_currency
                <> orders.order_currency
                then true

            else false
        end as currency_mismatch_flag

    from current_orders orders

    left join payment_aggregates aggregates
        on orders.order_id = aggregates.order_id

    left join latest_payment_attempt latest
        on orders.order_id = latest.order_id

)

select *
from final