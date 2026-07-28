with staging_order_items as (

    select
        count(distinct order_item_id) as distinct_order_item_count

    from {{ ref('stg_ecommerce__order_items') }}
    where order_item_id is not null

),

current_order_items as (

    select
        count(*) as current_order_item_count

    from {{ ref('int_ecommerce__order_items_current') }}

)

select
    staging_order_items.distinct_order_item_count,
    current_order_items.current_order_item_count

from staging_order_items
cross join current_order_items

where staging_order_items.distinct_order_item_count
    <> current_order_items.current_order_item_count