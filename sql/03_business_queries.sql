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