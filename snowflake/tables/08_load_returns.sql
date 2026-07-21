--RAW RETURNS LOADING
COPY INTO RAW_RETURNS (
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
    FROM @NOVACART_S3_STAGE/ecommerce/returns/ t
)
ON_ERROR = 'ABORT_STATEMENT';

DESC TABLE RAW_RETURNS;

--Vlidate row counts and primary keys
SELECT
    COUNT(*) AS total_returns,
    COUNT(DISTINCT return_id) AS unique_returns,
    COUNT(DISTINCT order_id) AS orders_with_returns,
    COUNT(DISTINCT customer_id) AS customers_with_returns,
    COUNT(DISTINCT product_id) AS returned_products,
    COUNT(DISTINCT source_file) AS source_files
FROM RAW_RETURNS;

SELECT
    COUNT_IF(return_id IS NULL) AS null_return_ids,
    COUNT_IF(order_id IS NULL) AS null_order_id,
    COUNT_IF(order_item_id IS NULL) AS null_order_item_id,
     COUNT_IF(customer_id IS NULL) AS null_customer_ids,
    COUNT_IF(product_id IS NULL) AS null_product_ids,
    COUNT(*) - COUNT(DISTINCT return_id) AS           duplicate_return_ids
FROM RAW_RETURNS;  

--Inspect return ststuses and reasons
SELECT
    return_status,
    COUNT(*) AS returns,
    SUM(return_quantity) AS returned_units,
    SUM(refund_amount) AS refund_amount
FROM RAW_RETURNS
GROUP BY return_status
ORDER BY returns DESC;

SELECT
    return_reason,
    COUNT(*) AS returns,
    SUM(refund_amount) AS refund_amount
FROM RAW_RETURNS
GROUP BY return_reason
ORDER BY returns DESC;

--Validating relationships
--Returns must reference valid orders and it must also reference valid order items 
SELECT COUNT(*) AS orphan_return_orders
FROM RAW_RETURNS r
LEFT JOIN RAW_ORDERS o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS orphan_return_items
FROM RAW_RETURNS r
LEFT JOIN RAW_ORDER_ITEMS oi
    ON r.order_item_id = oi.order_item_id
WHERE oi.order_item_id IS NULL;

--returns must reference valid customers
SELECT COUNT(*) AS invalid_return_customers
FROM RAW_RETURNS r
LEFT JOIN RAW_CUSTOMERS c
    ON r.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

--Returns must reference valid products
SELECT COUNT(*) AS invalid_return_products
FROM RAW_RETURNS r
LEFT JOIN RAW_PRODUCTS p
    ON r.product_id = p.product_id
WHERE p.product_id IS NULL;

--check return timing
--return should not happen before the original date
SELECT COUNT(*) AS returns_before_orders
FROM RAW_RETURNS r
JOIN RAW_ORDERS o
    ON r.order_id = o.order_id
WHERE r.return_date < o.order_date;
