/*==============================================================
Project : E-Commerce Growth Analytics
Phase   : Phase 6 - Business SQL Analytics

File    : 03_business_queries.sql

Purpose :
Answer strategic business questions using the PostgreSQL
analytical warehouse.
==============================================================*/

SET search_path TO analytics;


-- ============================================================
-- Business Question 1
-- How has monthly revenue changed over time?
-- ============================================================
-- Note:
-- The analysis excludes incomplete launch and closing periods.
-- The stable reporting window runs from January 2017
-- through August 2018.

WITH monthly_performance AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::DATE AS purchase_month,

        COUNT(order_id) AS total_orders,

        ROUND(
            SUM(total_order_value),
            2
        ) AS monthly_revenue,

        ROUND(
            AVG(total_order_value),
            2
        ) AS average_order_value

    FROM analytics.fact_orders

    WHERE
        total_order_value IS NOT NULL
        AND order_purchase_timestamp >= DATE '2017-01-01'
        AND order_purchase_timestamp < DATE '2018-09-01'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )
)

SELECT
    purchase_month,
    total_orders,
    monthly_revenue,
    average_order_value,

    ROUND(
        (
            monthly_revenue
            - LAG(monthly_revenue) OVER (
                ORDER BY purchase_month
            )
        )
        / NULLIF(
            LAG(monthly_revenue) OVER (
                ORDER BY purchase_month
            ),
            0
        )
        * 100,
        2
    ) AS revenue_growth_percent

FROM monthly_performance

ORDER BY purchase_month;


-- ============================================================
-- Business Question 2
-- Which months generated the highest revenue?
-- ============================================================
-- The same stable reporting window is used so that incomplete
-- months do not distort the ranking.

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::DATE AS purchase_month,

        COUNT(order_id) AS total_orders,

        ROUND(
            SUM(total_order_value),
            2
        ) AS monthly_revenue,

        ROUND(
            AVG(total_order_value),
            2
        ) AS average_order_value

    FROM analytics.fact_orders

    WHERE
        total_order_value IS NOT NULL
        AND order_purchase_timestamp >= DATE '2017-01-01'
        AND order_purchase_timestamp < DATE '2018-09-01'

    GROUP BY
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )
)

SELECT
    purchase_month,
    total_orders,
    monthly_revenue,
    average_order_value,

    DENSE_RANK() OVER (
        ORDER BY monthly_revenue DESC
    ) AS revenue_rank

FROM monthly_revenue

ORDER BY
    revenue_rank,
    purchase_month

LIMIT 10;


-- ============================================================
-- Business Question 3
-- Which customer states generate the highest revenue?
-- ============================================================

SELECT
    customer.customer_state,

    COUNT(DISTINCT orders.order_id) AS total_orders,

    COUNT(DISTINCT orders.customer_unique_id) AS total_customers,

    ROUND(
        SUM(orders.total_order_value),
        2
    ) AS total_revenue,

    ROUND(
        AVG(orders.total_order_value),
        2
    ) AS average_order_value,

    ROUND(
        SUM(orders.total_order_value)
        /
        COUNT(DISTINCT orders.customer_unique_id),
        2
    ) AS revenue_per_customer

FROM analytics.fact_orders AS orders

INNER JOIN analytics.dim_customer AS customer

ON orders.customer_unique_id =
   customer.customer_unique_id

WHERE
    orders.total_order_value IS NOT NULL

GROUP BY
    customer.customer_state

ORDER BY
    total_revenue DESC;


-- ============================================================
-- Product Analytics
-- Business Question 4
-- Which product categories generate the highest revenue?
-- ============================================================

SELECT

    product.product_category_name,

    COUNT(product.product_id) AS total_products,

    ROUND(
        SUM(product.total_units_sold)::NUMERIC,
        0
    ) AS total_units_sold,

    ROUND(
        SUM(product.total_product_revenue),
        2
    ) AS total_revenue,

    ROUND(
        AVG(product.average_selling_price),
        2
    ) AS average_selling_price,

    ROUND(
        AVG(product.average_freight_per_unit),
        2
    ) AS average_freight_per_unit,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(product.total_product_revenue) DESC
    ) AS revenue_rank

FROM analytics.dim_product AS product

WHERE product.product_category_name IS NOT NULL

GROUP BY
    product.product_category_name

ORDER BY
    total_revenue DESC

LIMIT 10;


-- ============================================================
-- Seller Analytics
-- Business Question 5
-- Which sellers generate the highest revenue?
-- ============================================================

SELECT

    seller_id,

    seller_total_orders,

    seller_total_products,

    ROUND(
        seller_total_revenue,
        2
    ) AS total_revenue,

    ROUND(
        seller_total_freight,
        2
    ) AS total_freight,

    ROUND(
        seller_average_product_price,
        2
    ) AS average_product_price,

    DENSE_RANK() OVER (
        ORDER BY seller_total_revenue DESC
    ) AS revenue_rank

FROM analytics.dim_seller

ORDER BY
    seller_total_revenue DESC

LIMIT 20;


-- ============================================================
-- Seller Analytics
-- Business Question 6
-- Which sellers contribute the largest share of company revenue?
-- ============================================================

WITH seller_revenue AS (

    SELECT
        seller_id,
        seller_total_orders,
        seller_total_products,
        seller_total_revenue,

        SUM(seller_total_revenue) OVER () AS company_revenue

    FROM analytics.dim_seller

)

SELECT

    seller_id,

    seller_total_orders,

    seller_total_products,

    ROUND(
        seller_total_revenue,
        2
    ) AS seller_revenue,

    ROUND(
        (
            seller_total_revenue
            /
            company_revenue
        ) * 100,
        2
    ) AS revenue_contribution_percent,

    DENSE_RANK() OVER (
        ORDER BY seller_total_revenue DESC
    ) AS revenue_rank

FROM seller_revenue

ORDER BY
    seller_revenue DESC

LIMIT 20;

-- ============================================================
-- Logistics Analytics
-- Business Question 7
-- How well is the company performing on deliveries?
-- ============================================================

SELECT

    COUNT(order_id) AS total_orders,

    SUM(is_on_time_delivery) AS on_time_orders,

    SUM(is_late_delivery) AS late_orders,

    SUM(is_early_delivery) AS early_orders,

    ROUND(
        AVG(delivery_duration_days)::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(delivery_delay_days)::NUMERIC,
        2
    ) AS average_delivery_delay_days,

    ROUND(
        (
            SUM(is_on_time_delivery)::NUMERIC
            /
            COUNT(order_id)
        ) * 100,
        2
    ) AS on_time_delivery_percent,

    ROUND(
        (
            SUM(is_late_delivery)::NUMERIC
            /
            COUNT(order_id)
        ) * 100,
        2
    ) AS late_delivery_percent,

    ROUND(
        (
            SUM(is_early_delivery)::NUMERIC
            /
            COUNT(order_id)
        ) * 100,
        2
    ) AS early_delivery_percent

FROM analytics.fact_orders

WHERE
    delivery_duration_days IS NOT NULL;



-- ============================================================
-- Customer Satisfaction Analytics
-- Business Question 8
-- How are customer review scores distributed?
-- ============================================================

SELECT

    review_score,

    COUNT(*) AS total_reviews,

    ROUND(
        COUNT(*)::NUMERIC
        * 100
        / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_reviews

FROM analytics.dim_review

GROUP BY
    review_score

ORDER BY
    review_score DESC;


-- ============================================================
-- Customer Satisfaction Analytics
-- Business Question 9
-- What percentage of reviews are positive vs negative?
-- ============================================================

SELECT

    SUM(is_positive_review) AS positive_reviews,

    SUM(is_negative_review) AS negative_reviews,

    COUNT(review_id) AS total_reviews,

    ROUND(
        (
            SUM(is_positive_review)::NUMERIC
            /
            COUNT(review_id)
        ) * 100,
        2
    ) AS positive_review_percent,

    ROUND(
        (
            SUM(is_negative_review)::NUMERIC
            /
            COUNT(review_id)
        ) * 100,
        2
    ) AS negative_review_percent

FROM analytics.dim_review;


-- ============================================================
-- Customer Satisfaction Analytics
-- Business Question 10
-- Do late deliveries lead to lower review scores?
-- ============================================================

SELECT
    CASE
        WHEN orders.is_late_delivery = 1
            THEN 'Late Delivery'
        ELSE
            'On Time / Early'
    END AS delivery_status,

    COUNT(DISTINCT orders.order_id) AS total_orders,

    COUNT(review.review_key) AS total_reviews,

    ROUND(
        AVG(review.review_score)::NUMERIC,
        2
    ) AS average_review_score,

    ROUND(
        AVG(orders.delivery_duration_days)::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        AVG(orders.delivery_delay_days)::NUMERIC,
        2
    ) AS average_delivery_delay_days,

    ROUND(
        AVG(orders.total_order_value),
        2
    ) AS average_order_value

FROM analytics.fact_orders AS orders

INNER JOIN analytics.dim_review AS review
    ON orders.order_id = review.order_id

WHERE
    orders.delivery_duration_days IS NOT NULL

GROUP BY
    CASE
        WHEN orders.is_late_delivery = 1
            THEN 'Late Delivery'
        ELSE
            'On Time / Early'
    END

ORDER BY
    average_review_score DESC;

-- ============================================================
-- Executive Analytics
-- Business Question 11
-- What are the company's core business KPIs?
-- ============================================================

SELECT

    COUNT(order_id) AS total_orders,

    COUNT(DISTINCT customer_unique_id) AS total_customers,

    ROUND(
        SUM(total_order_value),
        2
    ) AS total_revenue,

    ROUND(
        AVG(total_order_value),
        2
    ) AS average_order_value,

    ROUND(
        AVG(delivery_duration_days)::NUMERIC,
        2
    ) AS average_delivery_days,

    ROUND(
        (
            SUM(is_late_delivery)::NUMERIC
            /
            COUNT(order_id)
        ) * 100,
        2
    ) AS late_delivery_percent

FROM analytics.fact_orders

WHERE
    total_order_value IS NOT NULL;


-- ============================================================
-- Executive Analytics
-- Business Question 12
-- What is the overall business health scorecard?
-- ============================================================

WITH order_kpis AS (
    SELECT
        COUNT(order_id) AS total_orders,
        COUNT(DISTINCT customer_unique_id) AS total_customers,
        SUM(total_order_value) AS total_revenue,
        AVG(total_order_value) AS average_order_value,
        AVG(delivery_duration_days) AS average_delivery_days,
        (
            SUM(is_late_delivery)::NUMERIC
            / COUNT(order_id)
        ) * 100 AS late_delivery_percent

    FROM analytics.fact_orders

    WHERE total_order_value IS NOT NULL
),

review_kpis AS (
    SELECT
        AVG(review_score) AS average_review_score,
        (
            SUM(is_positive_review)::NUMERIC
            / COUNT(review_id)
        ) * 100 AS positive_review_percent,
        (
            SUM(is_negative_review)::NUMERIC
            / COUNT(review_id)
        ) * 100 AS negative_review_percent

    FROM analytics.dim_review
)

SELECT
    'Total Revenue' AS kpi_name,
    ROUND(total_revenue, 2)::TEXT AS kpi_value
FROM order_kpis

UNION ALL

SELECT
    'Total Orders',
    total_orders::TEXT
FROM order_kpis

UNION ALL

SELECT
    'Total Customers',
    total_customers::TEXT
FROM order_kpis

UNION ALL

SELECT
    'Average Order Value',
    ROUND(average_order_value, 2)::TEXT
FROM order_kpis

UNION ALL

SELECT
    'Average Delivery Days',
    ROUND(average_delivery_days::NUMERIC, 2)::TEXT
FROM order_kpis

UNION ALL

SELECT
    'Late Delivery Rate (%)',
    ROUND(late_delivery_percent, 2)::TEXT
FROM order_kpis

UNION ALL

SELECT
    'Average Review Score',
    ROUND(average_review_score::NUMERIC, 2)::TEXT
FROM review_kpis

UNION ALL

SELECT
    'Positive Review Rate (%)',
    ROUND(positive_review_percent, 2)::TEXT
FROM review_kpis

UNION ALL

SELECT
    'Negative Review Rate (%)',
    ROUND(negative_review_percent, 2)::TEXT
FROM review_kpis;