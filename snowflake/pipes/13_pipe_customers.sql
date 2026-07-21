USE ROLE NOVACART_ENGINEER;
USE DATABASE NOVACART_DB;
USE SCHEMA RAW;

CREATE PIPE IF NOT EXISTS PIPE_CUSTOMERS
    AUTO_INGEST = TRUE
    COMMENT = 'Automatically loads CRM customer CSV files from S3'
AS
COPY INTO NOVACART_DB.RAW.RAW_CUSTOMERS (
        customer_id,
    first_name,
    last_name,
    email,
    phone,
    city,
    region,
    country,
    postal_code,
    registration_date,
    loyalty_status,
    acquisition_channel,
    is_active,
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
        t.$7::VARCHAR,
        t.$8::VARCHAR,
        t.$9::VARCHAR,
        t.$10::DATE,
        t.$11::VARCHAR,
        t.$12::VARCHAR,
        t.$13::BOOLEAN,
        t.$14::TIMESTAMP_NTZ,
        METADATA$FILENAME,
        METADATA$FILE_ROW_NUMBER,
        METADATA$FILE_CONTENT_KEY,
        METADATA$FILE_LAST_MODIFIED,
        METADATA$START_SCAN_TIME
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE/crm/customers/ t  
)
ON_ERROR = 'SKIP_FILE';

SHOW PIPES LIKE 'PIPE_CUSTOMERS'
IN SCHEMA NOVACART_DB.RAW;

SELECT SYSTEM$PIPE_STATUS(
    'NOVACART_DB.RAW.PIPE_CUSTOMERS'
);

SELECT COUNT(*) AS customer_count_before
FROM NOVACART_DB.RAW.RAW_CUSTOMERS;


SELECT
    customer_id,
    first_name,
    last_name,
    registration_date,
    source_file,
    loaded_at
FROM NOVACART_DB.RAW.RAW_CUSTOMERS
WHERE customer_id LIKE 'CUSTP%'
ORDER BY loaded_at DESC;

SELECT COUNT(*) AS customer_count_after
FROM NOVACART_DB.RAW.RAW_CUSTOMERS;

--check snowpipe status and history
SELECT SYSTEM$PIPE_STATUS(
    'NOVACART_DB.RAW.PIPE_CUSTOMERS'
);

SELECT
    file_name,
    status,
    row_parsed,
    row_count,
    error_count,
    first_error_message,
    last_load_time
FROM TABLE(
    NOVACART_DB.INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'RAW_CUSTOMERS',
        START_TIME => DATEADD(
            'hour',
            -2,
            CURRENT_TIMESTAMP()
        )
    )
)
ORDER BY last_load_time DESC;
