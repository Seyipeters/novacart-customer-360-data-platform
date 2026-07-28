with ranked_order_items as (

    select
        *,

        row_number() over (
            partition by order_item_id
            order by
                loaded_at desc,
                source_file_last_modified desc,
                source_created_at desc,
                source_file_row_number desc,
                order_item_source_record_id desc
        ) as record_rank

    from {{ ref('stg_ecommerce__order_items') }}

),

current_order_items as (

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
        net_amount,

        source_created_at,

        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from ranked_order_items
    where record_rank = 1

)

select *
from current_order_items