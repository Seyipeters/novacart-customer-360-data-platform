select
    inventory_source_record_id,
    inventory_date,
    warehouse_id,
    product_id,
    closing_stock,
    stockout_flag

from {{ ref('stg_inventory_system__inventory_daily') }}

where (
        stockout_flag = true
        and closing_stock <> 0
    )

   or (
        stockout_flag = false
        and closing_stock = 0
    )