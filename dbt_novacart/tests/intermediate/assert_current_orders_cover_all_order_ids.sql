with current_orders as (

    select count(*) as current_order_count
    from {{ ref('int_ecommerce__orders_current') }}

),

staging_orders as (

    select count(distinct order_id) as staging_order_id_count
    from {{ ref('stg_ecommerce__orders') }}

)

select
    current_orders.current_order_count,
    staging_orders.staging_order_id_count
from current_orders
cross join staging_orders
where current_orders.current_order_count <> staging_orders.staging_order_id_count
