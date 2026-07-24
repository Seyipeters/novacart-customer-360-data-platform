with source as (
    select *
    from {{ source('raw', 'returns') }}
), 
 
cleaned as (
    select 

        /* Identifier for exact physical source record */
        sha2(
            concat_ws(
                '|',
                coalesce(source_file_content_key, ''),
                source_file_row_number::varchar
            ),
            256
        ) as return_source_record_id,

        /* Business identifiers */
        trim(return_id) as return_id,
        trim(order_id) as order_id,
        trim(order_item_id) as order_item_id,
        trim(customer_id) as customer_id,
        trim(product_id) as product_id,

        /* Return details */
        return_date,
        return_quantity::number(10,0) as return_quantity,
        upper(trim(return_reason)) as return_reason,
        upper(trim(return_status)) as return_status,

        /* Financial details */
        refund_amount::number(18,2) as refund_amount,
        upper(trim(currency)) as currency,

        /* Source timestamps */
        created_at as source_created_at,
        source_file,
        source_file_row_number,
        source_file_content_key,
        source_file_last_modified,
        loaded_at

    from source

)

select *
from cleaned