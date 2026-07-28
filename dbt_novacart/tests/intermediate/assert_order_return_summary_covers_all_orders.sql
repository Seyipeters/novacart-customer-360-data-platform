with current_orders as (

    select count(*) as expected_order_count
    from {{ ref('int_ecommerce__orders_current') }}

),

order_return_summary as (

    select count(*) as actual_order_count
    from {{ ref('int_ecommerce__order_return_summary') }}

)

select
    current_orders.expected_order_count,
    order_return_summary.actual_order_count

from current_orders
cross join order_return_summary

where current_orders.expected_order_count
    <> order_return_summary.actual_order_count