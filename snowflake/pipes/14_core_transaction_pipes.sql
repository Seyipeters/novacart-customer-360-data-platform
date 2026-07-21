USE ROLE NOVACART_ENGINEER;
USE DATABASE NOVACART_DB;
USE SCHEMA RAW;

CREATE PIPE IF NOT EXISTS PIPE_PRODUCTS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads product CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_PRODUCTS (
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
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/ecommerce/products/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_ORDERS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads order CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_ORDERS (
    order_id,
    customer_id,
    order_timestamp,
    order_date,
    order_status,
    sales_channel,
    shipping_city,
    shipping_region,
    shipping_country,
    currency,
    item_count,
    total_quantity,
    subtotal_amount,
    discount_amount,
    shipping_amount,
    order_total,
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
        t.$3::TIMESTAMP_NTZ,
        t.$4::DATE,
        t.$5::VARCHAR,
        t.$6::VARCHAR,
        t.$7::VARCHAR,
        t.$8::VARCHAR,
        t.$9::VARCHAR,
        t.$10::VARCHAR,
        t.$11::NUMBER(10,0),
        t.$12::NUMBER(10,0),
        t.$13::NUMBER(18,2),
        t.$14::NUMBER(18,2),
        t.$15::NUMBER(18,2),
        t.$16::NUMBER(18,2),
        t.$17::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/ecommerce/orders/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_ORDER_ITEMS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads order-item CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_ORDER_ITEMS (
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
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/ecommerce/order_items/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_PAYMENTS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads payment-attempt CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_PAYMENTS (
    payment_id,
    order_id,
    payment_attempt_number,
    payment_method,
    payment_status,
    payment_amount,
    captured_amount,
    currency,
    payment_timestamp,
    gateway_reference,
    failure_reason,
    record_arrived_at,
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
        t.$3::NUMBER(10,0),
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::NUMBER(18,2),
        t.$7::NUMBER(18,2),
        t.$8::VARCHAR,
        t.$9::TIMESTAMP_NTZ,
        t.$10::VARCHAR,
        NULLIF(TRIM(t.$11::VARCHAR), ''),
        t.$12::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/payment_gateway/payments/ t
)
ON_ERROR = 'SKIP_FILE';

SHOW PIPES IN SCHEMA NOVACART_DB.RAW;

SELECT
    "name" AS pipe_name,
    "notification_channel" AS sqs_queue_arn,
    "definition"
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN (
    'PIPE_PRODUCTS',
    'PIPE_ORDERS',
    'PIPE_ORDER_ITEMS',
    'PIPE_PAYMENTS'
)
ORDER BY "name";

--check pipe statuses
SELECT
    'PIPE_PRODUCTS' AS pipe_name,
    PARSE_JSON(
        SYSTEM$PIPE_STATUS(
            'NOVACART_DB.RAW.PIPE_PRODUCTS'
        )
    ) AS pipe_status

UNION ALL

SELECT
    'PIPE_ORDERS',
    PARSE_JSON(
        SYSTEM$PIPE_STATUS(
            'NOVACART_DB.RAW.PIPE_ORDERS'
        )
    )

UNION ALL

SELECT
    'PIPE_ORDER_ITEMS',
    PARSE_JSON(
        SYSTEM$PIPE_STATUS(
            'NOVACART_DB.RAW.PIPE_ORDER_ITEMS'
        )
    )

UNION ALL

SELECT
    'PIPE_PAYMENTS',
    PARSE_JSON(
        SYSTEM$PIPE_STATUS(
            'NOVACART_DB.RAW.PIPE_PAYMENTS'
        )
    );
