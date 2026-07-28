with current_order_items as (

    select
        count(*) as expected_order_item_count

    from {{ ref('int_ecommerce__order_items_current') }}

),

return_summary as (

    select
        count(*) as actual_order_item_count

    from {{ ref('int_ecommerce__order_item_return_summary') }}

)

select
    current_order_items.expected_order_item_count,
    return_summary.actual_order_item_count

from current_order_items
cross join return_summary

where current_order_items.expected_order_item_count
    <> return_summary.actual_order_item_count