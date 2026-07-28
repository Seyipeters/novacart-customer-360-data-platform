with current_orders as (

    select
        count(*) as current_order_count

    from {{ ref('int_ecommerce__orders_current') }}

),

payment_summary as (

    select
        count(*) as payment_summary_count

    from {{ ref('int_payment_gateway__order_payment_summary') }}

)

select
    current_orders.current_order_count,
    payment_summary.payment_summary_count

from current_orders
cross join payment_summary

where current_orders.current_order_count
    <> payment_summary.payment_summary_count