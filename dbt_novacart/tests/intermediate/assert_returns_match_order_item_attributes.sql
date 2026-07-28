with returns as (

    select
        return_id,
        order_id,
        order_item_id,
        product_id

    from {{ ref('int_ecommerce__returns_current') }}

),

order_items as (

    select
        order_item_id,
        order_id,
        product_id

    from {{ ref('int_ecommerce__order_items_current') }}

)

select
    returns.return_id,
    returns.order_item_id,

    returns.order_id as return_order_id,
    order_items.order_id as order_item_order_id,

    returns.product_id as return_product_id,
    order_items.product_id as order_item_product_id

from returns

inner join order_items
    on returns.order_item_id = order_items.order_item_id

where returns.order_id <> order_items.order_id
   or returns.product_id <> order_items.product_id