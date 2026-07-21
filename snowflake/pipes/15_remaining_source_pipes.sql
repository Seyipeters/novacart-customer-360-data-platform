USE ROLE NOVACART_ENGINEER;
USE DATABASE NOVACART_DB;
USE SCHEMA RAW;

CREATE PIPE IF NOT EXISTS PIPE_RETURNS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads return CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_RETURNS (
    return_id,
    order_id,
    order_item_id,
    customer_id,
    product_id,
    return_date,
    return_quantity,
    return_reason,
    return_status,
    refund_amount,
    currency,
    created_at,
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
        t.$3::VARCHAR,
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::DATE,
        t.$7::NUMBER(10,0),
        t.$8::VARCHAR,
        t.$9::VARCHAR,
        t.$10::NUMBER(18,2),
        t.$11::VARCHAR,
        t.$12::TIMESTAMP_NTZ,
        t.$13::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/ecommerce/returns/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_INVENTORY_DAILY
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads daily inventory CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_INVENTORY_DAILY (
    inventory_date,
    warehouse_id,
    warehouse_name,
    warehouse_city,
    warehouse_country,
    product_id,
    opening_stock,
    received_quantity,
    sold_quantity,
    damaged_quantity,
    closing_stock,
    unit_cost,
    inventory_value,
    stockout_flag,
    reorder_flag,
    updated_at,
    source_file,
    source_file_row_number,
    source_file_content_key,
    source_file_last_modified,
    loaded_at
)
FROM (
    SELECT
        t.$1::DATE,
        t.$2::VARCHAR,
        t.$3::VARCHAR,
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::VARCHAR,
        t.$7::NUMBER(18,0),
        t.$8::NUMBER(18,0),
        t.$9::NUMBER(18,0),
        t.$10::NUMBER(18,0),
        t.$11::NUMBER(18,0),
        t.$12::NUMBER(18,2),
        t.$13::NUMBER(18,2),
        t.$14::BOOLEAN,
        t.$15::BOOLEAN,
        t.$16::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/inventory_system/inventory_daily/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_CAMPAIGNS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads marketing campaign CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_CAMPAIGNS (
    campaign_id,
    campaign_name,
    campaign_channel,
    campaign_objective,
    target_segment,
    start_date,
    end_date,
    budget_amount,
    currency,
    campaign_status,
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
        t.$6::DATE,
        t.$7::DATE,
        t.$8::NUMBER(18,2),
        t.$9::VARCHAR,
        t.$10::VARCHAR,
        t.$11::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/marketing_platform/campaigns/ t
)
ON_ERROR = 'SKIP_FILE';

CREATE PIPE IF NOT EXISTS PIPE_WEB_EVENTS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads web event CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_WEB_EVENTS (
    event_id,
    session_id,
    customer_id,
    anonymous_id,
    event_type,
    product_id,
    order_id,
    campaign_id,
    device_type,
    browser,
    traffic_source,
    page_url,
    event_timestamp,
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
        NULLIF(TRIM(t.$3::VARCHAR), ''),
        NULLIF(TRIM(t.$4::VARCHAR), ''),
        t.$5::VARCHAR,
        NULLIF(TRIM(t.$6::VARCHAR), ''),
        NULLIF(TRIM(t.$7::VARCHAR), ''),
        NULLIF(TRIM(t.$8::VARCHAR), ''),
        t.$9::VARCHAR,
        t.$10::VARCHAR,
        t.$11::VARCHAR,
        t.$12::VARCHAR,
        t.$13::TIMESTAMP_NTZ,
        t.$14::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/web_analytics/web_events/ t
)
ON_ERROR = 'SKIP_FILE';

SHOW PIPES IN SCHEMA NOVACART_DB.RAW;
SELECT
    "name" AS pipe_name,
    "notification_channel" AS sqs_queue_arn
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
WHERE "name" IN (
    'PIPE_RETURNS',
    'PIPE_INVENTORY_DAILY',
    'PIPE_CAMPAIGNS',
    'PIPE_WEB_EVENTS'
)
ORDER BY "name";


