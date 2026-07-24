

with source as (

    select *
    from {{ source('raw', 'orders') }}

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
        ) as order_source_record_id,

        /* Business identifiers */
        trim(order_id) as order_id,
        trim(customer_id) as customer_id,

        /* Order timing */
        order_timestamp,
        order_date,

        /* Order attributes */
        upper(trim(order_status)) as order_status,
        upper((trim(sales_channel))) as sales_channel,

        /* Shipping Location */
        trim(shipping_city) as shipping_city,
        trim(shipping_region) as shipping_region,
        trim(shipping_country) as shipping_country,

        /* Currency and Quantity */
        upper(trim(currency)) as currency,
        item_count::number(10,0) as item_count,
        total_quantity::number(10,0) as total_quantity,

        /* Financial attributes */
        subtotal_amount::number(18, 2) as subtotal_amount,
        discount_amount::number(18, 2) as discount_amount,
        shipping_amount::number(18, 2) as shipping_amount,
        order_total::number(18, 2) as order_total,

        /* source timestamp */
        updated_at as source_updated_at,

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

