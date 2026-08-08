with order_items as (

    select
        order_item_id,
        order_id,
        product_id,

        quantity,
        unit_price,
        gross_amount,
        discount_rate,
        discount_amount,
        net_amount,

        source_created_at,
        loaded_at

    from {{ ref ('int_ecommerce__order_items_current') }}

),

products as (

    select 
        product_id,
        product_key

    from {{ ref('dim_products') }}
),

orders as (

    select
        order_id,
        customer_id

    from {{ ref ('int_ecommerce__orders_current') }}
),

customers as (

    select 
        customer_id,
        customer_key

    from {{ ref('dim_customers') }}
),

final as (

    select 
        order_items.order_item_id,
        order_items.order_id,

        products.product_key,
        order_items.product_id,

        customers.customer_key,
        orders.customer_id,

        order_items.quantity,
        order_items.unit_price,
        order_items.gross_amount,
        order_items.discount_rate,
        order_items.discount_amount,
        order_items.net_amount,
         case
            when order_items.discount_amount > 0
                then true
            else false
        end as has_discount,

        order_items.source_created_at,
        order_items.loaded_at

    from order_items
    left join products on order_items.product_id = products.product_id
    left join orders on order_items.order_id = orders.order_id
    left join customers on orders.customer_id = customers.customer_id

)



select *
from final