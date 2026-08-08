with payments as (

    select
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

orders as (

    select
        order_id,
        customer_id

    from {{ ref('int_ecommerce__orders_current') }}

),

customers as (

    select
        customer_id,
        customer_key

    from {{ ref('dim_customers') }}

),

final as (

    select
        payments.payment_id,
        payments.order_id,

        customers.customer_key,
        orders.customer_id,

        payments.payment_attempt_number,

        trim(payments.payment_method) as payment_method,
        trim(payments.payment_status) as payment_status,

        payments.payment_amount,
        payments.captured_amount,
        upper(trim(payments.currency)) as currency,

        payments.payment_timestamp,
        payments.payment_timestamp::date as payment_date,

        payments.gateway_reference,
        payments.failure_reason,

        case
            when payments.captured_amount > 0
                then true
            else false
        end as has_captured_amount,

        case
            when payments.failure_reason is not null
                then true
            else false
        end as has_failure_reason,

        payments.source_record_arrived_at,
        payments.loaded_at

    from payments

    left join orders
        on payments.order_id = orders.order_id

    left join customers
        on orders.customer_id = customers.customer_id

)

select *
from final