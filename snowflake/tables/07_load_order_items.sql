COPY INTO RAW_PAYMENTS (
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
    FROM @NOVACART_S3_STAGE/payment_gateway/payments/ t
)
ON_ERROR = 'ABORT_STATEMENT';

--Check null and dublicate keys
SELECT 
    COUNT_IF(payment_id IS NULL) AS null_payment_ids,
    COUNT_IF(order_id IS NULL) AS null_order_ids,
    COUNT(*) -COUNT(DISTINCT payment_id) AS dublicate_payment_ids
FROM RAW_PAYMENTS;

--Inspect payment statuses and methods
SELECT 
    payment_status,
    COUNT(*) AS payment_attempts,
    SUM(payment_amount) AS attempted_payment,
    SUM(captured_amount) AS captured_amount,
FROM RAW_PAYMENTS
GROUP BY payment_status
ORDER BY payment_attempts DESC;

SELECT 
payment_method,
COUNT(*) AS payment_attempts,
SUM(captured_amount) AS captured_amount,
FROM RAW_PAYMENTS
GROUP BY payment_method
ORDER BY payment_attempts DESC;

--Check payment quality rules
SELECT
    COUNT_IF(payment_attempt_number <= 0)
        AS invalid_attempt_numbers,

    COUNT_IF(payment_amount < 0)
        AS negative_payment_amounts,

    COUNT_IF(captured_amount < 0)
        AS negative_captured_amounts,

    COUNT_IF(captured_amount > payment_amount)
        AS captured_above_attempted,

    COUNT_IF(record_arrived_at < payment_timestamp)
        AS invalid_arrival_times
FROM RAW_PAYMENTS;

SELECT
    payment_id,
    order_id,
    payment_attempt_number,
    payment_status,
    payment_amount,
    captured_amount,
    failure_reason
FROM RAW_PAYMENTS
WHERE captured_amount > payment_amount
   OR payment_amount < 0
   OR captured_amount < 0;

--Validation of order relationships
SELECT COUNT(*) AS orphan_payments
FROM RAW_PAYMENTS p
LEFT JOIN RAW_ORDERS o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;
