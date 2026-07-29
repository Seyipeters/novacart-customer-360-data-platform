COPY INTO RAW_PRODUCTS (
    product_id,
    sku,
    product_name,
    category,
    subcategory,
    brand,
    unit_cost,
    list_price,
    is_active,
    launch_date,
    updated_at,
    source_file,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        t.$1::VARCHAR,
        t.$2::VARCHAR,
        t.$3::VARCHAR,
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::VARCHAR,
        t.$7::NUMBER(18,2),
        t.$8::NUMBER(18,2),
        t.$9::BOOLEAN,
        t.$10::DATE,
        t.$11::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE (
        FILE_FORMAT => 'NOVACART_DB.RAW.NOVACART_CSV_FORMAT',
        PATTERN => '.*products.*[.]csv([.]gz)?$'
    ) t
)
ON_ERROR = 'ABORT_STATEMENT';