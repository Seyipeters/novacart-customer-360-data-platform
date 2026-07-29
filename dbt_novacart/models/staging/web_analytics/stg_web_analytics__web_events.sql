with source as (

    select *
    from {{ source('raw', 'web_events') }}

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
        ) as web_event_source_record_id,

        /* Event identifiers */
        trim(event_id) as event_id,
        trim(session_id) as session_id,

        /* Nullable business identifiers */
        nullif(trim(customer_id), '') as customer_id,
        nullif(trim(product_id), '') as product_id,
        nullif(trim(campaign_id), '') as campaign_id,
        nullif(trim(anonymous_id), '') as anonymous_id,
        nullif(trim(order_id), '') as order_id,

        /* Event timing */
        event_timestamp,
        event_timestamp::date as event_date,

        /* Event information */
        upper(trim(event_type)) as event_type,
        trim(page_url) as page_url,

        /* Technical and acquisition information */
        upper(trim(device_type)) as device_type,
        upper(trim(browser)) as browser,
        upper(trim(traffic_source)) as traffic_source,

        /* Source timing */
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