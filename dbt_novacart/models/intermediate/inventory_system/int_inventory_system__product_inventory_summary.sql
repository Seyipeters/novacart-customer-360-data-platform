with current_inventory as (

    select *
    from {{ ref('int_inventory_system__inventory_current') }}

),

product_inventory_summary as (

    select
        product_id,

        max(inventory_date) as latest_inventory_date,

        count(distinct warehouse_id) as warehouse_count,

        sum(opening_stock) as total_opening_stock,
        sum(received_quantity) as total_received_quantity,
        sum(sold_quantity) as total_sold_quantity,
        sum(damaged_quantity) as total_damaged_quantity,
        sum(closing_stock) as total_closing_stock,

        round(sum(inventory_value), 2) as total_inventory_value,

        coalesce(
            round(
                sum(inventory_value)
                / nullif(sum(closing_stock), 0),
                2
            ),
            0
        ) as weighted_average_unit_cost,

        count_if(stockout_flag) as stockout_warehouse_count,
        count_if(reorder_flag) as reorder_warehouse_count,

        count_if(stockout_flag) > 0 as has_stockout,
        count_if(reorder_flag) > 0 as needs_reorder,

        max(source_updated_at) as latest_source_updated_at,
        max(loaded_at) as latest_loaded_at

    from current_inventory

    group by product_id

)

select *
from product_inventory_summary