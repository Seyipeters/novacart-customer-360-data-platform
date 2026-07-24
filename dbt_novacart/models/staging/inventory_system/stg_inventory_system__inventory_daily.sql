with source as (

    select *
    from {{ source('raw', 'inventory_daily') }}

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
        ) as inventory_source_record_id,

        /* Inventory business key */
        inventory_date,
        trim(warehouse_id) as warehouse_id,
        trim(product_id) as product_id,

        /* Warehouse details */
        trim(warehouse_name) as warehouse_name,
        trim(warehouse_city) as warehouse_city,
        upper(trim(warehouse_country)) as warehouse_country,

        /* Stock movements */
        opening_stock::number(18, 0) as opening_stock,
        received_quantity::number(18, 0) as received_quantity,
        sold_quantity::number(18, 0) as sold_quantity,
        damaged_quantity::number(18, 0) as damaged_quantity,
        closing_stock::number(18, 0) as closing_stock,

        /* Inventory valuation */
        unit_cost::number(18, 2) as unit_cost,
        inventory_value::number(18, 2) as inventory_value,

        /* Inventory flags */
        stockout_flag,
        reorder_flag,

        /* Source timestamp */
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