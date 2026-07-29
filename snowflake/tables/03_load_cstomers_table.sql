COPY INTO RAW_CUSTOMERS (
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
    FROM @NOVACART_DB.RAW.NOVACART_S3_STAGE (
        FILE_FORMAT => 'NOVACART_DB.RAW.NOVACART_CSV_FORMAT',
        PATTERN => '.*customers.*[.]csv([.]gz)?$'
    ) t
)
ON_ERROR = 'ABORT_STATEMENT';