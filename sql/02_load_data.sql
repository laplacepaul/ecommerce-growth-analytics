/*==============================================================
Project      : E-Commerce Growth Analytics
Phase        : Phase 6 - SQL Business Analytics

File         : 02_load_data.sql

Description
------------
Loads engineered warehouse tables into PostgreSQL.

This script is idempotent and may be executed multiple
times without creating duplicate records.

==============================================================*/


-- ============================================================
-- Begin Transaction
-- ============================================================

BEGIN;


-- ============================================================
-- Set Active Schema
-- ============================================================

SET search_path TO analytics;


-- ============================================================
-- Clear Existing Warehouse Data
-- ============================================================

TRUNCATE TABLE
    analytics.fact_orders,
    analytics.dim_customer,
    analytics.dim_product,
    analytics.dim_seller,
    analytics.dim_review;


-- ============================================================
-- Load Customer Dimension
-- ============================================================

COPY analytics.dim_customer (
    customer_unique_id,
    customer_account_count,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    total_customer_orders,
    customer_total_revenue,
    customer_average_order_value,
    first_purchase_date,
    last_purchase_date,
    repeat_customer,
    customer_lifetime_days
)
FROM '/Users/laplace/Documents/work/ecommerce-growth-analytics/data/processed/dim_customer.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);


-- ============================================================
-- Load Product Dimension
-- ============================================================

COPY analytics.dim_product (
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    total_units_sold,
    total_product_revenue,
    total_freight_value,
    average_selling_price,
    unique_orders,
    unique_sellers,
    average_freight_per_unit,
    revenue_per_order,
    product_popularity_rank
)
FROM '/Users/laplace/Documents/work/ecommerce-growth-analytics/data/processed/dim_product.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);


-- ============================================================
-- Load Seller Dimension
-- ============================================================

COPY analytics.dim_seller (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    seller_total_orders,
    seller_total_products,
    seller_total_revenue,
    seller_total_freight,
    seller_average_product_price
)
FROM '/Users/laplace/Documents/work/ecommerce-growth-analytics/data/processed/dim_seller.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);


-- ============================================================
-- Load Review Dimension
-- ============================================================

COPY analytics.dim_review (
    review_key,
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    review_sentiment,
    is_positive_review,
    is_negative_review,
    review_title_length,
    review_message_length,
    has_written_comment,
    review_response_time_hours
)
FROM '/Users/laplace/Documents/work/ecommerce-growth-analytics/data/processed/dim_review.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);


-- ============================================================
-- Load Fact Orders
-- ============================================================

COPY analytics.fact_orders (
    order_id,
    customer_id,
    order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    purchase_year,
    purchase_quarter,
    purchase_month,
    purchase_month_name,
    purchase_week,
    purchase_day,
    purchase_weekday,
    purchase_hour,
    is_weekend_purchase,
    approval_time_hours,
    carrier_pickup_days,
    delivery_duration_days,
    delivery_delay_days,
    is_late_delivery,
    is_early_delivery,
    is_on_time_delivery,
    total_order_value,
    total_freight_value,
    total_items,
    unique_sellers,
    average_item_price,
    average_freight_per_item,
    freight_percentage,
    multiple_seller_order,
    customer_unique_id
)
FROM '/Users/laplace/Documents/work/ecommerce-growth-analytics/data/processed/fact_orders.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE
);


-- ============================================================
-- Commit Transaction
-- ============================================================

COMMIT;


-- ============================================================
-- Verify Loaded Row Counts
-- ============================================================

SELECT
    'fact_orders' AS table_name,
    COUNT(*) AS total_rows
FROM analytics.fact_orders

UNION ALL

SELECT
    'dim_customer',
    COUNT(*)
FROM analytics.dim_customer

UNION ALL

SELECT
    'dim_product',
    COUNT(*)
FROM analytics.dim_product

UNION ALL

SELECT
    'dim_seller',
    COUNT(*)
FROM analytics.dim_seller

UNION ALL

SELECT
    'dim_review',
    COUNT(*)
FROM analytics.dim_review

ORDER BY table_name;