with source as (

    select *
    from {{ source('raw', 'payments') }}

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
        ) as payment_source_record_id,

        /* Business identifiers */
        trim(payment_id) as payment_id,
        trim(order_id) as order_id,

        /* Payment attempt information */
        payment_attempt_number::number(10, 0)
            as payment_attempt_number,

        upper(trim(payment_method)) as payment_method,
        upper(trim(payment_status)) as payment_status,

        /* Financial values */
        payment_amount::number(18, 2) as payment_amount,
        captured_amount::number(18, 2) as captured_amount,
        upper(trim(currency)) as currency,

        /* Payment timing */
        payment_timestamp,

        /* Gateway information */
        nullif(trim(gateway_reference), '')
            as gateway_reference,

        nullif(trim(failure_reason), '')
            as failure_reason,

        record_arrived_at as source_record_arrived_at,

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