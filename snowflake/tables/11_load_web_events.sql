--Load RAW_EVENTS TABLE
COPY INTO RAW_WEB_EVENTS (
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
        t.$3::VARCHAR,
        t.$4::VARCHAR,
        t.$5::VARCHAR,
        t.$6::VARCHAR,
        t.$7::VARCHAR,
        t.$8::VARCHAR,
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
    FROM @NOVACART_S3_STAGE/web_analytics/web_events/ t
)
ON_ERROR = 'ABORT_STATEMENT';

--Validate row count and identifiers
SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT event_id) AS unique_events,
    COUNT(DISTINCT session_id) AS unique_sessions,
    COUNT(DISTINCT customer_id) AS identified_customers,
    COUNT(DISTINCT source_file) AS source_files
FROM RAW_WEB_EVENTS;

--Check null and duplicate keys 
SELECT
    COUNT_IF(event_id IS NULL) AS null_event_ids,
    COUNT_IF(session_id IS NULL) AS null_session_ids,
    COUNT_IF(event_type IS NULL) AS null_event_types,
    COUNT_IF(event_timestamp IS NULL) AS null_event_timestamps,
    COUNT(*) - COUNT(DISTINCT event_id) AS duplicate_event_ids
FROM RAW_WEB_EVENTS;

--Inspect Event Types
SELECT
    event_type,
    COUNT(*) AS events,
    COUNT(DISTINCT session_id) AS sessions,
    COUNT(DISTINCT customer_id) AS customers
FROM RAW_WEB_EVENTS
GROUP BY event_type
ORDER BY events DESC;

--Inspect devices and traffic sources
SELECT
    device_type,
    COUNT(*) AS events,
    COUNT(DISTINCT session_id) AS sessions
FROM RAW_WEB_EVENTS
GROUP BY device_type
ORDER BY events DESC;

SELECT
    traffic_source,
    COUNT(*) AS events,
    COUNT(DISTINCT session_id) AS sessions
FROM RAW_WEB_EVENTS
GROUP BY traffic_source
ORDER BY events DESC;

--Validate event timing
SELECT
    COUNT_IF(record_arrived_at < event_timestamp)
        AS arrival_before_event,

    COUNT_IF(record_arrived_at IS NULL)
        AS missing_arrival_timestamp
FROM RAW_WEB_EVENTS;

--Measure Ingestion Delay
SELECT
    MIN(DATEDIFF('second', event_timestamp, record_arrived_at))
        AS minimum_delay_seconds,

    AVG(DATEDIFF('second', event_timestamp, record_arrived_at))
        AS average_delay_seconds,

    MAX(DATEDIFF('second', event_timestamp, record_arrived_at))
        AS maximum_delay_seconds
FROM RAW_WEB_EVENTS;

--Validate user identity
SELECT
    COUNT_IF(
        customer_id IS NULL
        AND anonymous_id IS NULL
    ) AS events_without_identity
FROM RAW_WEB_EVENTS;

--Inspect website journeys
SELECT
    session_id,
    event_timestamp,
    event_type,
    product_id,
    order_id,
    campaign_id,
    page_url
FROM RAW_WEB_EVENTS
WHERE session_id IN (
    SELECT session_id
    FROM RAW_WEB_EVENTS
    GROUP BY session_id
    HAVING COUNT(*) >= 3
    LIMIT 5
)
ORDER BY session_id, event_timestamp;
