/*==============================================================
Project : E-Commerce Growth Analytics

File    : 01_create_schema.sql

Purpose :
Create the analytical warehouse schema and tables.
==============================================================*/

BEGIN;

-- ============================================================
-- Create Analytics Schema
-- ============================================================

CREATE SCHEMA IF NOT EXISTS analytics;

SET search_path TO analytics;


-- ============================================================
-- Drop Existing Warehouse Tables
-- ============================================================

DROP TABLE IF EXISTS analytics.fact_orders CASCADE;
DROP TABLE IF EXISTS analytics.dim_customer CASCADE;
DROP TABLE IF EXISTS analytics.dim_product CASCADE;
DROP TABLE IF EXISTS analytics.dim_seller CASCADE;
DROP TABLE IF EXISTS analytics.dim_review CASCADE;


-- ============================================================
-- Create Fact Orders Table
-- Grain: One row per customer order
-- ============================================================

CREATE TABLE analytics.fact_orders (

    -- Business identifiers
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_unique_id TEXT,

    -- Order attributes
    order_status TEXT NOT NULL,

    -- Operational timestamps
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    -- Purchase-time features
    purchase_year SMALLINT NOT NULL,
    purchase_quarter SMALLINT NOT NULL,
    purchase_month SMALLINT NOT NULL,
    purchase_month_name TEXT NOT NULL,
    purchase_week SMALLINT NOT NULL,
    purchase_day SMALLINT NOT NULL,
    purchase_weekday TEXT NOT NULL,
    purchase_hour SMALLINT NOT NULL,
    is_weekend_purchase SMALLINT NOT NULL,

    -- Delivery and fulfilment features
    approval_time_hours DOUBLE PRECISION,
    carrier_pickup_days DOUBLE PRECISION,
    delivery_duration_days DOUBLE PRECISION,
    delivery_delay_days DOUBLE PRECISION,
    is_late_delivery SMALLINT NOT NULL,
    is_early_delivery SMALLINT NOT NULL,
    is_on_time_delivery SMALLINT NOT NULL,

    -- Order-value features
    total_order_value NUMERIC(14, 2),
    total_freight_value NUMERIC(14, 2),

    -- These may appear as values such as 1.0 in the CSV
    total_items DOUBLE PRECISION,
    unique_sellers DOUBLE PRECISION,

    average_item_price NUMERIC(14, 2),
    average_freight_per_item NUMERIC(14, 2),
    freight_percentage NUMERIC(10, 4),
    multiple_seller_order SMALLINT,

    -- Audit timestamp
    warehouse_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Business-rule constraints
    CONSTRAINT chk_purchase_quarter
        CHECK (purchase_quarter BETWEEN 1 AND 4),

    CONSTRAINT chk_purchase_month
        CHECK (purchase_month BETWEEN 1 AND 12),

    CONSTRAINT chk_purchase_day
        CHECK (purchase_day BETWEEN 1 AND 31),

    CONSTRAINT chk_purchase_hour
        CHECK (purchase_hour BETWEEN 0 AND 23),

    CONSTRAINT chk_weekend_flag
        CHECK (is_weekend_purchase IN (0, 1)),

    CONSTRAINT chk_late_delivery_flag
        CHECK (is_late_delivery IN (0, 1)),

    CONSTRAINT chk_early_delivery_flag
        CHECK (is_early_delivery IN (0, 1)),

    CONSTRAINT chk_on_time_delivery_flag
        CHECK (is_on_time_delivery IN (0, 1)),

    CONSTRAINT chk_multiple_seller_flag
        CHECK (
            multiple_seller_order IS NULL
            OR multiple_seller_order IN (0, 1)
        ),

    CONSTRAINT chk_total_order_value
        CHECK (
            total_order_value IS NULL
            OR total_order_value >= 0
        ),

    CONSTRAINT chk_total_freight_value
        CHECK (
            total_freight_value IS NULL
            OR total_freight_value >= 0
        ),

    CONSTRAINT chk_total_items
        CHECK (
            total_items IS NULL
            OR total_items >= 0
        ),

    CONSTRAINT chk_unique_sellers
        CHECK (
            unique_sellers IS NULL
            OR unique_sellers >= 0
        )
);


-- ============================================================
-- Create Fact Orders Indexes
-- ============================================================

CREATE INDEX idx_fact_orders_customer_id
    ON analytics.fact_orders (customer_id);

CREATE INDEX idx_fact_orders_customer_unique_id
    ON analytics.fact_orders (customer_unique_id);

CREATE INDEX idx_fact_orders_purchase_timestamp
    ON analytics.fact_orders (order_purchase_timestamp);

CREATE INDEX idx_fact_orders_order_status
    ON analytics.fact_orders (order_status);

CREATE INDEX idx_fact_orders_purchase_year_month
    ON analytics.fact_orders (
        purchase_year,
        purchase_month
    );


-- ============================================================
-- Create Customer Dimension
-- Grain: One row per unique customer
-- ============================================================

CREATE TABLE analytics.dim_customer (

    -- Business identifier
    customer_unique_id TEXT PRIMARY KEY,

    -- Customer attributes
    customer_account_count INTEGER NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state TEXT,

    -- Customer behavioural metrics
    total_customer_orders INTEGER NOT NULL,
    customer_total_revenue NUMERIC(14, 2),
    customer_average_order_value NUMERIC(14, 2),

    -- Customer lifecycle dates
    first_purchase_date TIMESTAMP,
    last_purchase_date TIMESTAMP,

    -- Customer behaviour indicators
    repeat_customer SMALLINT NOT NULL,
    customer_lifetime_days INTEGER NOT NULL,

    -- Audit timestamp
    warehouse_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Business-rule constraints
    CONSTRAINT chk_customer_account_count
        CHECK (customer_account_count >= 1),

    CONSTRAINT chk_total_customer_orders
        CHECK (total_customer_orders >= 0),

    CONSTRAINT chk_customer_total_revenue
        CHECK (
            customer_total_revenue IS NULL
            OR customer_total_revenue >= 0
        ),

    CONSTRAINT chk_customer_average_order_value
        CHECK (
            customer_average_order_value IS NULL
            OR customer_average_order_value >= 0
        ),

    CONSTRAINT chk_repeat_customer
        CHECK (repeat_customer IN (0, 1)),

    CONSTRAINT chk_customer_lifetime_days
        CHECK (customer_lifetime_days >= 0),

    CONSTRAINT chk_customer_purchase_dates
        CHECK (
            first_purchase_date IS NULL
            OR last_purchase_date IS NULL
            OR last_purchase_date >= first_purchase_date
        )
);


-- ============================================================
-- Create Customer Dimension Indexes
-- ============================================================

CREATE INDEX idx_dim_customer_state
    ON analytics.dim_customer (customer_state);

CREATE INDEX idx_dim_customer_city
    ON analytics.dim_customer (customer_city);

CREATE INDEX idx_dim_customer_zip_code
    ON analytics.dim_customer (customer_zip_code_prefix);

CREATE INDEX idx_dim_customer_repeat_status
    ON analytics.dim_customer (repeat_customer);


-- ============================================================
-- Create Product Dimension
-- Grain: One row per product
-- ============================================================

CREATE TABLE analytics.dim_product (

    -- Business identifier
    product_id TEXT PRIMARY KEY,

    -- Product descriptive attributes
    product_category_name TEXT,

    -- These fields contain values such as 40.0 in the CSV
    product_name_length DOUBLE PRECISION,
    product_description_length DOUBLE PRECISION,
    product_photos_qty DOUBLE PRECISION,

    -- Product physical attributes
    product_weight_g DOUBLE PRECISION,
    product_length_cm DOUBLE PRECISION,
    product_height_cm DOUBLE PRECISION,
    product_width_cm DOUBLE PRECISION,

    -- Product performance metrics
    -- Aggregated counts may also be exported as decimal-looking values
    total_units_sold DOUBLE PRECISION NOT NULL,
    total_product_revenue NUMERIC(14, 2) NOT NULL,
    total_freight_value NUMERIC(14, 2) NOT NULL,
    average_selling_price NUMERIC(14, 2) NOT NULL,
    unique_orders DOUBLE PRECISION NOT NULL,
    unique_sellers DOUBLE PRECISION NOT NULL,
    average_freight_per_unit NUMERIC(14, 2) NOT NULL,
    revenue_per_order NUMERIC(14, 2) NOT NULL,
    product_popularity_rank INTEGER NOT NULL,

    -- Audit timestamp
    warehouse_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Business-rule constraints
    CONSTRAINT chk_product_name_length
        CHECK (
            product_name_length IS NULL
            OR product_name_length >= 0
        ),

    CONSTRAINT chk_product_description_length
        CHECK (
            product_description_length IS NULL
            OR product_description_length >= 0
        ),

    CONSTRAINT chk_product_photos_qty
        CHECK (
            product_photos_qty IS NULL
            OR product_photos_qty >= 0
        ),

    CONSTRAINT chk_product_weight
        CHECK (
            product_weight_g IS NULL
            OR product_weight_g >= 0
        ),

    CONSTRAINT chk_product_length
        CHECK (
            product_length_cm IS NULL
            OR product_length_cm >= 0
        ),

    CONSTRAINT chk_product_height
        CHECK (
            product_height_cm IS NULL
            OR product_height_cm >= 0
        ),

    CONSTRAINT chk_product_width
        CHECK (
            product_width_cm IS NULL
            OR product_width_cm >= 0
        ),

    CONSTRAINT chk_total_units_sold
        CHECK (total_units_sold >= 0),

    CONSTRAINT chk_total_product_revenue
        CHECK (total_product_revenue >= 0),

    CONSTRAINT chk_product_freight_value
        CHECK (total_freight_value >= 0),

    CONSTRAINT chk_average_selling_price
        CHECK (average_selling_price >= 0),

    CONSTRAINT chk_product_unique_orders
        CHECK (unique_orders >= 0),

    CONSTRAINT chk_product_unique_sellers
        CHECK (unique_sellers >= 0),

    CONSTRAINT chk_average_freight_per_unit
        CHECK (average_freight_per_unit >= 0),

    CONSTRAINT chk_revenue_per_order
        CHECK (revenue_per_order >= 0),

    CONSTRAINT chk_product_popularity_rank
        CHECK (product_popularity_rank >= 1)
);


-- ============================================================
-- Create Product Dimension Indexes
-- ============================================================

CREATE INDEX idx_dim_product_category
    ON analytics.dim_product (product_category_name);

CREATE INDEX idx_dim_product_revenue
    ON analytics.dim_product (total_product_revenue);

CREATE INDEX idx_dim_product_units_sold
    ON analytics.dim_product (total_units_sold);

CREATE INDEX idx_dim_product_popularity_rank
    ON analytics.dim_product (product_popularity_rank);


-- ============================================================
-- Create Seller Dimension
-- Grain: One row per seller
-- ============================================================

CREATE TABLE analytics.dim_seller (

    -- Business identifier
    seller_id TEXT PRIMARY KEY,

    -- Seller location attributes
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state TEXT,

    -- Seller performance metrics
    seller_total_orders INTEGER NOT NULL,
    seller_total_products INTEGER NOT NULL,
    seller_total_revenue NUMERIC(14, 2) NOT NULL,
    seller_total_freight NUMERIC(14, 2) NOT NULL,
    seller_average_product_price NUMERIC(14, 2) NOT NULL,

    -- Audit timestamp
    warehouse_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Business-rule constraints
    CONSTRAINT chk_seller_total_orders
        CHECK (seller_total_orders >= 0),

    CONSTRAINT chk_seller_total_products
        CHECK (seller_total_products >= 0),

    CONSTRAINT chk_seller_total_revenue
        CHECK (seller_total_revenue >= 0),

    CONSTRAINT chk_seller_total_freight
        CHECK (seller_total_freight >= 0),

    CONSTRAINT chk_seller_average_product_price
        CHECK (seller_average_product_price >= 0)
);


-- ============================================================
-- Create Seller Dimension Indexes
-- ============================================================

CREATE INDEX idx_dim_seller_state
    ON analytics.dim_seller (seller_state);

CREATE INDEX idx_dim_seller_city
    ON analytics.dim_seller (seller_city);

CREATE INDEX idx_dim_seller_zip_code
    ON analytics.dim_seller (seller_zip_code_prefix);

CREATE INDEX idx_dim_seller_revenue
    ON analytics.dim_seller (seller_total_revenue);

CREATE INDEX idx_dim_seller_total_orders
    ON analytics.dim_seller (seller_total_orders);


-- ============================================================
-- Create Review Dimension
-- Grain: One row per review record associated with one order
-- ============================================================

CREATE TABLE analytics.dim_review (

    -- Warehouse and business identifiers
    review_key INTEGER PRIMARY KEY,
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL,

    -- Review attributes
    review_score SMALLINT NOT NULL,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    review_sentiment TEXT,

    -- Review indicators and engineered features
    is_positive_review SMALLINT NOT NULL,
    is_negative_review SMALLINT NOT NULL,
    review_title_length INTEGER NOT NULL,
    review_message_length INTEGER NOT NULL,
    has_written_comment SMALLINT NOT NULL,
    review_response_time_hours DOUBLE PRECISION,

    -- Audit timestamp
    warehouse_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    -- Business-rule constraints
    CONSTRAINT chk_review_score
        CHECK (review_score BETWEEN 1 AND 5),

    CONSTRAINT chk_review_sentiment
        CHECK (
            review_sentiment IS NULL
            OR review_sentiment IN (
                'Negative',
                'Neutral',
                'Positive'
            )
        ),

    CONSTRAINT chk_positive_review_flag
        CHECK (is_positive_review IN (0, 1)),

    CONSTRAINT chk_negative_review_flag
        CHECK (is_negative_review IN (0, 1)),

    CONSTRAINT chk_review_title_length
        CHECK (review_title_length >= 0),

    CONSTRAINT chk_review_message_length
        CHECK (review_message_length >= 0),

    CONSTRAINT chk_written_comment_flag
        CHECK (has_written_comment IN (0, 1)),

    CONSTRAINT chk_review_response_time
        CHECK (
            review_response_time_hours IS NULL
            OR review_response_time_hours >= 0
        ),

    CONSTRAINT chk_review_timestamps
        CHECK (
            review_creation_date IS NULL
            OR review_answer_timestamp IS NULL
            OR review_answer_timestamp >= review_creation_date
        )
);


-- ============================================================
-- Create Review Dimension Indexes
-- ============================================================

CREATE INDEX idx_dim_review_review_id
    ON analytics.dim_review (review_id);

CREATE INDEX idx_dim_review_order_id
    ON analytics.dim_review (order_id);

CREATE INDEX idx_dim_review_score
    ON analytics.dim_review (review_score);

CREATE INDEX idx_dim_review_sentiment
    ON analytics.dim_review (review_sentiment);

CREATE INDEX idx_dim_review_creation_date
    ON analytics.dim_review (review_creation_date);


COMMIT;