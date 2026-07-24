with source as (

    select *
    from {{ source('raw', 'order_items') }}
),
cleaned as (

    select

        /* Identifier for the exact physical source record */
        sha2(
            concat_ws(
                '|',
                coalesce(source_file_content_key, ''),
                source_file_row_number::varchar
            ),
            256
        ) as order_item_source_record_id,

        /* Business identifier for the order */
        trim(order_item_id) as order_item_id,
        trim(order_id) as order_id,
        trim(product_id) as product_id,

        /* Quantity and pricing */
        quantity::number(10,0) as quantity,
        unit_price::number(18, 2) as unit_price,
        gross_amount::number(18, 2) as gross_amount,
        discount_rate::number(8, 4) as discount_rate,
        discount_amount::number(18, 2) as discount_amount,
        net_amount::number(18, 2) as net_amount,

        /* Source Timestamp */
        created_at as source_created_at,

        /* Ingestion metadata */
        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from source
)
select *

from cleaned


