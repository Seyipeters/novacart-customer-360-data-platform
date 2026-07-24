select 
    order_source_record_id,
    order_id,
    item_count,
    total_quantity,
    subtotal_amount,
    discount_amount,
    shipping_amount,
    order_total

from {{ ref('stg_ecommerce__orders') }}

where item_count < 0
    or total_quantity < 0
    or subtotal_amount < 0
    or discount_amount < 0
    or shipping_amount < 0
    or order_total < 0
    or discount_amount > subtotal_amount
    or abs(
        order_total - (subtotal_amount - discount_amount + shipping_amount)
    ) > 0.01