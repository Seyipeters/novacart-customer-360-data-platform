with source as (

    select *
    from {{ source('raw', 'products') }}

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
        ) as product_source_record_id,

        /* Business identifiers */
        trim(product_id) as product_id,
        upper(trim(sku)) as sku,

        /* Product attributes */
        trim(product_name) as product_name,
        upper(trim(category)) as category,
        upper(trim(subcategory)) as subcategory,
        upper(trim(brand)) as brand,

        /* Financial attributes */
        unit_cost::number(18, 2) as unit_cost,
        list_price::number(18, 2) as list_price,

        /* Status and dates */
        is_active,
        launch_date,
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

