with orders as (

    select 
        order_id,
        customer_id,
        order_timestamp,
        order_date,
        order_status,
        sales_channel,

        shipping_city,
        shipping_region,
        shipping_country,

        currency,
        item_count,
        total_quantity,

        subtotal_amount,
        discount_amount,
        shipping_amount,
        order_total,

        source_updated_at,
        loaded_at

    from {{ ref('int_ecommerce__orders_current') }}
),

customers as (

    select 
    customer_id,
    customer_key

    from {{ ref('dim_customers') }}
),

payments as (

    select
        order_id,
        payment_attempt_count,
        total_captured_amount,
        outstanding_balance,
        latest_payment_method,
        latest_payment_status,
        payment_reconciliation_status,
        currency_mismatch_flag

    from {{ ref('int_payment_gateway__order_payment_summary') }}
),

returns as (

    select
        order_id,
        return_record_count,
        requested_return_quantity,
        completed_return_quantity,
        completed_refund_amount,
        has_return_request,
        has_completed_return,
        has_pending_return,
        order_return_status,
        first_return_date,
        latest_return_date  

    from {{ ref('int_ecommerce__order_return_summary') }}
),

final as (

    select orders.order_id,
        customers.customer_key,
        orders.customer_id,

        orders.order_timestamp,
        orders.order_date,
        orders.order_status,
        orders.sales_channel,

        orders.shipping_city,
        orders.shipping_region,
        orders.shipping_country,

        orders.currency as order_currency,

        orders.item_count,
        orders.total_quantity,

        orders.subtotal_amount,
        orders.discount_amount,
        orders.shipping_amount,
        orders.order_total,
        coalesce(
            payments.payment_attempt_count,
            0
            ) as payment_attempt_count,

        coalesce(
            payments.total_captured_amount,
            0
            ) as total_captured_amount,

        coalesce(
            payments.outstanding_balance,
            orders.order_total
            ) as outstanding_balance,

        payments.latest_payment_method,
        payments.latest_payment_status,

        coalesce(
            payments.payment_reconciliation_status,
            'NO_PAYMENT'
            ) as payment_reconciliation_status,

        coalesce(
            payments.currency_mismatch_flag,
            false
        ) as currency_mismatch_flag,
         coalesce(
            returns.return_record_count,
            0
        ) as return_record_count,

        coalesce(
            returns.requested_return_quantity,
            0
        ) as requested_return_quantity,

        coalesce(
            returns.completed_return_quantity,
            0
        ) as completed_return_quantity,

        coalesce(
            returns.completed_refund_amount,
            0
        ) as completed_refund_amount,

        coalesce(
            payments.total_captured_amount,
            0
        )
        -
        coalesce(
            returns.completed_refund_amount,
            0
        ) as net_captured_revenue_after_refunds,

        coalesce(
            returns.has_return_request,
            false
        ) as has_return_request,

        coalesce(
            returns.has_completed_return,
            false
        ) as has_completed_return,

        coalesce(
            returns.has_pending_return,
            false
        ) as has_pending_return,

        coalesce(
            returns.order_return_status,
            'NO_RETURN'
        ) as order_return_status,

        returns.first_return_date,
        returns.latest_return_date,

        orders.source_updated_at,
        orders.loaded_at

    from orders
    left join customers 
    on orders.customer_id= customers.customer_id

    left join payments 
    on orders.order_id = payments.order_id

    left join returns
    on orders.order_id = returns.order_id
)

select *
from final