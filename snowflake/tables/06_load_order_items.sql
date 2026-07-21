COPY INTO RAW_ORDER_ITEMS (
    order_item_id,
    order_id,
    product_id,
    quantity,
    unit_price,
    gross_amount,
    discount_rate,
    discount_amount,
    net_amount,
    created_at,
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
        t.$4::NUMBER(10,0),
        t.$5::NUMBER(18,2),
        t.$6::NUMBER(18,2),
        t.$7::NUMBER(8,4),
        t.$8::NUMBER(18,2),
        t.$9::NUMBER(18,2),
        t.$10::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_S3_STAGE/ecommerce/order_items/ t
)
ON_ERROR = 'ABORT_STATEMENT';


