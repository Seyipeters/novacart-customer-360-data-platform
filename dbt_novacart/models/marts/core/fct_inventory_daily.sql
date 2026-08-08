with inventory as (

    select
        inventory_date,
        warehouse_id,
        product_id,

        opening_stock,
        received_quantity,
        sold_quantity,
        damaged_quantity,
        closing_stock,

        unit_cost,
        inventory_value,

        stockout_flag,
        reorder_flag,

        source_updated_at,
        loaded_at

    from {{ ref('stg_inventory_system__inventory_daily') }}

),

products as (

    select
        product_id,
        product_key

    from {{ ref('dim_products') }}

),

warehouses as (

    select
        warehouse_id,
        warehouse_key

    from {{ ref('dim_warehouses') }}

),

final as (

    select
        inventory.inventory_date,

        products.product_key,
        inventory.product_id,

        warehouses.warehouse_key,
        inventory.warehouse_id,

        inventory.opening_stock,
        inventory.received_quantity,
        inventory.sold_quantity,
        inventory.damaged_quantity,
        inventory.closing_stock,

        inventory.unit_cost,
        inventory.inventory_value,

        inventory.stockout_flag,
        inventory.reorder_flag,

        inventory.source_updated_at,
        inventory.loaded_at

    from inventory

    left join products
        on inventory.product_id = products.product_id

    left join warehouses
        on inventory.warehouse_id = warehouses.warehouse_id

)

select *
from final