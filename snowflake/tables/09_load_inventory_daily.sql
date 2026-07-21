--Inventory Table load
COPY INTO RAW_INVENTORY_DAILY (
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
    FROM @NOVACART_S3_STAGE/inventory_system/inventory_daily/ t  
)
ON_ERROR = 'ABORT_STATEMENT';

-- Check missing key values
SELECT
    COUNT_IF(inventory_date IS NULL) AS null_inventory_dates,
    COUNT_IF(warehouse_id IS NULL) AS null_warehouse_ids,
    COUNT_IF(product_id IS NULL) AS null_product_ids
FROM RAW_INVENTORY_DAILY;

--Validate stock quantities 
SELECT
    COUNT_IF(opening_stock < 0) AS negative_opening_stock,
    COUNT_IF(received_quantity < 0) AS negative_received_quantity,
    COUNT_IF(sold_quantity < 0) AS negative_sold_quantity,
    COUNT_IF(damaged_quantity < 0) AS negative_damaged_quantity,
    COUNT_IF(closing_stock < 0) AS negative_closing_stock,
    COUNT_IF(unit_cost < 0) AS negative_unit_cost,
    COUNT_IF(inventory_value < 0) AS negative_inventory_value
FROM RAW_INVENTORY_DAILY;

--Validate stock movement equation
SELECT COUNT(*) AS stock_balance_mismatches
FROM RAW_INVENTORY_DAILY
WHERE closing_stock <>
      opening_stock
      + received_quantity
      - sold_quantity
      - damaged_quantity;
