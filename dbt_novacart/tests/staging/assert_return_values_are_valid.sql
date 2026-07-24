select
    return_source_record_id,
    return_id,
    order_id,
    order_item_id,
    return_quantity,
    refund_amount,
    source_file

from {{ ref('stg_ecommerce__returns') }}

where return_quantity <= 0
   or refund_amount < 0
   