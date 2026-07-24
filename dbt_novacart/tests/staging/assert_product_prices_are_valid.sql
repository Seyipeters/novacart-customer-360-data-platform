select 
    product_source_record_id,
    product_id,
    sku,
    unit_cost,
    list_price

from {{ ref('stg_ecommerce__products') }}
where unit_cost < 0
    or list_price < 0
    or list_price < unit_cost