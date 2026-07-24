select
    inventory_source_record_id,
    inventory_date,
    warehouse_id,
    product_id,
    opening_stock,
    received_quantity,
    sold_quantity,
    damaged_quantity,
    closing_stock,
    unit_cost,
    inventory_value

from {{ ref('stg_inventory_system__inventory_daily') }}

where opening_stock < 0
   or received_quantity < 0
   or sold_quantity < 0
   or damaged_quantity < 0
   or closing_stock < 0
   or unit_cost < 0
   or inventory_value < 0

   or closing_stock <>
      opening_stock
      + received_quantity
      - sold_quantity
      - damaged_quantity

   or abs(
        inventory_value
        - round(closing_stock * unit_cost, 2)
   ) > 0.01