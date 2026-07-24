select 
    order_item_source_record_id,
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    gross_amount,
    discount_rate,
    discount_amount,
    net_amount
from {{ ref('stg_ecommerce__order_items') }}
where quantity <= 0
    or unit_price < 0
    or gross_amount < 0
    or discount_rate > 1
    or discount_amount < 0
    or net_amount < 0
    or abs (
        gross_amount - round(quantity * unit_price, 2)
    ) > 0.01

    or abs (
        discount_amount - round(gross_amount * discount_rate, 2)
    ) > 0.01

    or abs (
        net_amount - round(gross_amount - discount_amount, 2)
    ) > 0.01