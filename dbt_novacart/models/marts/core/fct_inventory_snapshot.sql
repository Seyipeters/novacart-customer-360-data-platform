with inventory as (

    select 
        product_id,
        latest_inventory_date,
        warehouse_count,

        total_opening_stock,
        total_received_quantity,
        total_sold_quantity,
        total_damaged_quantity,
        total_closing_stock,

        total_inventory_value,
        weighted_average_unit_cost,

        stockout_warehouse_count,
        reorder_warehouse_count,

        has_stockout,
        needs_reorder,

        latest_source_updated_at,
        latest_loaded_at

    from {{ ref ( 'int_inventory_system__product_inventory_summary') }}
),

products as (

    select 
        product_id,
        product_key
       

    from {{ ref('dim_products') }}
),

final as (

    select
        products.product_key,
        inventory.product_id,

        inventory.latest_inventory_date,
        inventory.warehouse_count,

        inventory.total_opening_stock,
        inventory.total_received_quantity,
        inventory.total_sold_quantity,
        inventory.total_damaged_quantity,
        inventory.total_closing_stock,

        inventory.total_inventory_value,
        inventory.weighted_average_unit_cost,

        inventory.stockout_warehouse_count,
        inventory.reorder_warehouse_count,

        inventory.has_stockout,
        inventory.needs_reorder,

        inventory.latest_source_updated_at,
        inventory.latest_loaded_at
        
    from inventory
    left join products 
    on inventory.product_id = products.product_id

)

select *
from final