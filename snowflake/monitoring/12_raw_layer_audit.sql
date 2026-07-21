USE ROLE NOVACART_ENGINEER;
USE WAREHOUSE NOVACART_WH;
USE DATABASE NOVACART_DB;
USE SCHEMA AUDIT;

CREATE OR REPLACE VIEW AUDIT.VW_RAW_TABLE_AUDIT AS

SELECT
    'CUSTOMERS' AS dataset_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_business_keys,
    COUNT(*) - COUNT(DISTINCT customer_id) AS duplicate_business_keys,
    COUNT_IF(customer_id IS NULL) AS null_business_keys,
    COUNT(DISTINCT source_file) AS source_files,
    MIN(loaded_at) AS first_loaded_at,
    MAX(loaded_at) AS last_loaded_at
FROM RAW.RAW_CUSTOMERS

UNION ALL

SELECT
    'PRODUCTS',
    COUNT(*),
    COUNT(DISTINCT product_id),
    COUNT(*) - COUNT(DISTINCT product_id),
    COUNT_IF(product_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_PRODUCTS

UNION ALL

SELECT
    'ORDERS',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id),
    COUNT_IF(order_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_ORDERS

UNION ALL

SELECT
    'ORDER_ITEMS',
    COUNT(*),
    COUNT(DISTINCT order_item_id),
    COUNT(*) - COUNT(DISTINCT order_item_id),
    COUNT_IF(order_item_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_ORDER_ITEMS

UNION ALL

SELECT
    'PAYMENTS',
    COUNT(*),
    COUNT(DISTINCT payment_id),
    COUNT(*) - COUNT(DISTINCT payment_id),
    COUNT_IF(payment_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_PAYMENTS

UNION ALL

SELECT
    'RETURNS',
    COUNT(*),
    COUNT(DISTINCT return_id),
    COUNT(*) - COUNT(DISTINCT return_id),
    COUNT_IF(return_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_RETURNS

UNION ALL

SELECT
    'INVENTORY_DAILY',
    COUNT(*),
    COUNT(
        DISTINCT CONCAT_WS(
            '|',
            TO_VARCHAR(inventory_date),
            warehouse_id,
            product_id
        )
    ),
    COUNT(*) - COUNT(
        DISTINCT CONCAT_WS(
            '|',
            TO_VARCHAR(inventory_date),
            warehouse_id,
            product_id
        )
    ),
    COUNT_IF(
        inventory_date IS NULL
        OR warehouse_id IS NULL
        OR product_id IS NULL
    ),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_INVENTORY_DAILY

UNION ALL

SELECT
    'CAMPAIGNS',
    COUNT(*),
    COUNT(DISTINCT campaign_id),
    COUNT(*) - COUNT(DISTINCT campaign_id),
    COUNT_IF(campaign_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_CAMPAIGNS

UNION ALL

SELECT
    'WEB_EVENTS',
    COUNT(*),
    COUNT(DISTINCT event_id),
    COUNT(*) - COUNT(DISTINCT event_id),
    COUNT_IF(event_id IS NULL),
    COUNT(DISTINCT source_file),
    MIN(loaded_at),
    MAX(loaded_at)
FROM RAW.RAW_WEB_EVENTS;
