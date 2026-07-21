USE ROLE NOVACART_ENGINEER;
USE WAREHOUSE NOVACART_WH;
USE DATABASE NOVACART_DB;
USE SCHEMA RAW;


/* ============================================================
   1. CRM CUSTOMERS
   Grain: One row per CRM customer record
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_CUSTOMERS (
    customer_id                VARCHAR(30),
    first_name                 VARCHAR(100),
    last_name                  VARCHAR(100),
    email                      VARCHAR(255),
    phone                      VARCHAR(100),
    city                       VARCHAR(100),
    region                     VARCHAR(150),
    country                    VARCHAR(100),
    postal_code                VARCHAR(30),
    registration_date          DATE,
    loyalty_status             VARCHAR(30),
    acquisition_channel        VARCHAR(100),
    is_active                  BOOLEAN,
    updated_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   2. PRODUCTS
   Grain: One row per product
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_PRODUCTS (
    product_id                 VARCHAR(30),
    sku                        VARCHAR(100),
    product_name               VARCHAR(255),
    category                   VARCHAR(100),
    subcategory                VARCHAR(100),
    brand                      VARCHAR(100),
    unit_cost                  NUMBER(18, 2),
    list_price                 NUMBER(18, 2),
    is_active                  BOOLEAN,
    launch_date                DATE,
    updated_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   3. ORDERS
   Grain: One row per order
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_ORDERS (
    order_id                   VARCHAR(30),
    customer_id                VARCHAR(30),
    order_timestamp            TIMESTAMP_NTZ,
    order_date                 DATE,
    order_status               VARCHAR(30),
    sales_channel              VARCHAR(50),
    shipping_city              VARCHAR(100),
    shipping_region            VARCHAR(150),
    shipping_country           VARCHAR(100),
    currency                   VARCHAR(10),
    item_count                 NUMBER(10, 0),
    total_quantity             NUMBER(10, 0),
    subtotal_amount            NUMBER(18, 2),
    discount_amount            NUMBER(18, 2),
    shipping_amount            NUMBER(18, 2),
    order_total                NUMBER(18, 2),
    updated_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   4. ORDER ITEMS
   Grain: One row per product line within an order
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_ORDER_ITEMS (
    order_item_id              VARCHAR(30),
    order_id                   VARCHAR(30),
    product_id                 VARCHAR(30),
    quantity                   NUMBER(10, 0),
    unit_price                 NUMBER(18, 2),
    gross_amount               NUMBER(18, 2),
    discount_rate              NUMBER(8, 4),
    discount_amount            NUMBER(18, 2),
    net_amount                 NUMBER(18, 2),
    created_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   5. PAYMENTS
   Grain: One row per payment attempt
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_PAYMENTS (
    payment_id                 VARCHAR(30),
    order_id                   VARCHAR(30),
    payment_attempt_number     NUMBER(10, 0),
    payment_method             VARCHAR(50),
    payment_status             VARCHAR(30),
    payment_amount             NUMBER(18, 2),
    captured_amount            NUMBER(18, 2),
    currency                   VARCHAR(10),
    payment_timestamp          TIMESTAMP_NTZ,
    gateway_reference          VARCHAR(100),
    failure_reason             VARCHAR(100),
    record_arrived_at          TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   6. RETURNS
   Grain: One row per returned order item
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_RETURNS (
    return_id                  VARCHAR(30),
    order_id                   VARCHAR(30),
    order_item_id              VARCHAR(30),
    customer_id                VARCHAR(30),
    product_id                 VARCHAR(30),
    return_date                DATE,
    return_quantity            NUMBER(10, 0),
    return_reason              VARCHAR(100),
    return_status              VARCHAR(30),
    refund_amount              NUMBER(18, 2),
    currency                   VARCHAR(10),
    created_at                 TIMESTAMP_NTZ,
    record_arrived_at          TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   7. DAILY INVENTORY
   Grain: One row per product, warehouse and date
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_INVENTORY_DAILY (
    inventory_date             DATE,
    warehouse_id               VARCHAR(30),
    warehouse_name             VARCHAR(150),
    warehouse_city             VARCHAR(100),
    warehouse_country          VARCHAR(100),
    product_id                 VARCHAR(30),
    opening_stock              NUMBER(18, 0),
    received_quantity          NUMBER(18, 0),
    sold_quantity              NUMBER(18, 0),
    damaged_quantity           NUMBER(18, 0),
    closing_stock              NUMBER(18, 0),
    unit_cost                  NUMBER(18, 2),
    inventory_value            NUMBER(18, 2),
    stockout_flag              BOOLEAN,
    reorder_flag               BOOLEAN,
    updated_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   8. MARKETING CAMPAIGNS
   Grain: One row per campaign
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_CAMPAIGNS (
    campaign_id                VARCHAR(30),
    campaign_name              VARCHAR(255),
    campaign_channel           VARCHAR(50),
    campaign_objective         VARCHAR(100),
    target_segment             VARCHAR(100),
    start_date                 DATE,
    end_date                   DATE,
    budget_amount              NUMBER(18, 2),
    currency                   VARCHAR(10),
    campaign_status            VARCHAR(30),
    updated_at                 TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);


/* ============================================================
   9. WEB EVENTS
   Grain: One row per website event
   ============================================================ */

CREATE TABLE IF NOT EXISTS RAW_WEB_EVENTS (
    event_id                   VARCHAR(40),
    session_id                 VARCHAR(40),
    customer_id                VARCHAR(30),
    anonymous_id               VARCHAR(40),
    event_type                 VARCHAR(50),
    product_id                 VARCHAR(30),
    order_id                   VARCHAR(30),
    campaign_id                VARCHAR(30),
    device_type                VARCHAR(30),
    browser                    VARCHAR(30),
    traffic_source             VARCHAR(50),
    page_url                   VARCHAR(1000),
    event_timestamp            TIMESTAMP_NTZ,
    record_arrived_at          TIMESTAMP_NTZ,

    source_file                VARCHAR(1000),
    source_file_row_number     NUMBER(38, 0),
    source_file_content_key    VARCHAR(255),
    source_file_last_modified  TIMESTAMP_NTZ,
    loaded_at                  TIMESTAMP_LTZ
);

