select
    source_file,
    inventory_date,
    warehouse_id,
    product_id,
    count(*) as record_count

from {{ ref('stg_inventory_system__inventory_daily') }}

group by
    source_file,
    inventory_date,
    warehouse_id,
    product_id

having count(*) > 1