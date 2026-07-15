# Phase 1 – Source Data Audit

## Initial Dataset Inventory

The Olist source system consists of nine relational datasets representing customers, orders, products, sellers, payments, reviews, geolocation information, and category translations.

### Key Findings

- The source data contains approximately one million geolocation records, making it the largest dataset.
- The geolocation dataset contains 261,831 duplicate rows and will require detailed investigation during the data-cleaning phase.
- The orders and customers datasets each contain 99,441 records, suggesting a close relationship that requires validation.
- The order items dataset contains more records than the orders dataset, indicating that an order can contain multiple purchased items.
- The payments dataset contains more records than the orders dataset, suggesting that some orders may have multiple payment entries.
- The review dataset contains substantial missing values and will require investigation to determine whether the missing fields are expected or indicate data-quality issues.
- The products and sellers datasets appear to be reference (dimension) tables supporting transactional analysis.
- The product category translation table functions as a lookup table for translating Portuguese product categories into English.

## Preliminary Assessment

The Olist dataset appears to be a normalized relational database rather than a single flat dataset. Further analysis will focus on identifying primary keys, foreign keys, table grain, and business relationships before any transformations or synthetic extensions are introduced.



# Orders Table

## Business Purpose

Stores the lifecycle of every customer order placed on the Olist platform, from purchase through delivery.

## Table Grain

One row represents one order.

## Primary Key

- order_id

## Foreign Key

- customer_id → Customers.customer_id

## Important Business Fields

- order_status
- order_purchase_timestamp
- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date
- order_estimated_delivery_date

## Data Quality

Missing values were identified in operational timestamp columns:

- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date

These fields require further investigation to determine whether the missing values represent valid business scenarios or data-quality issues.
# Orders Table

## Business Purpose

Stores the lifecycle of every customer order placed on the Olist platform, from purchase through delivery.

## Table Grain

One row represents one order.

## Primary Key

- order_id

## Foreign Key

- customer_id → Customers.customer_id

## Important Business Fields

- order_status
- order_purchase_timestamp
- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date
- order_estimated_delivery_date

## Data Quality

Missing values were identified in operational timestamp columns:

- order_approved_at
- order_delivered_carrier_date
- order_delivered_customer_date

These fields require further investigation to determine whether the missing values represent valid business scenarios or data-quality issues.

### Analytical Questions – Order Items

1. What is the average number of items per order?
2. How many orders contain only one item?
3. What is the maximum basket size?
4. Do customers who purchase more items spend more overall?
5. Which products are most frequently purchased together? *(Future analysis)*

### Business Insight

The Products table stores master information about each product. Unlike transactional tables, it does not record purchases. Instead, it provides descriptive and physical attributes that support inventory management, logistics, shipping, pricing analysis, and product categorization.


## Analytical Questions

1. Which sellers generate the highest revenue?
2. Which states have the highest concentration of sellers?
3. Do sellers located closer to customers achieve faster delivery times?
4. Which sellers have the highest average freight cost?
5. Which sellers receive the highest customer ratings?

## Analytical Questions

1. Which payment method is used most frequently?
2. Do customers using installments spend more per order?
3. What is the average payment value by payment type?
4. Are multiple-payment orders common or rare?
5. Which product categories are most frequently purchased using installments?

# Payments

## Analytical Questions

1. Which payment method is used most frequently?
2. Which payment method generates the highest revenue?
3. Do customers using installments spend more per order?
4. How common are multiple-payment orders?
5. Do certain product categories have higher installment usage?

# Order Payments Table

## Business Purpose

Stores the payment transactions associated with customer orders, including payment method, installment count, and payment value.

## Table Grain

One row represents one payment transaction linked to one order.

An order may have more than one payment record when multiple payment methods are used.

## Primary Key

- Composite key: `order_id` + `payment_sequential`

Neither field is guaranteed to be unique on its own, but together they identify one payment record within an order.

## Foreign Key

- `order_id` → `Orders.order_id`

## Important Attributes

- `payment_sequential` — sequence number of the payment within an order
- `payment_type` — method used to pay
- `payment_installments` — number of installments
- `payment_value` — amount recorded for the payment

## Data Quality

- Missing values: None
- Duplicate rows: None
- Initial quality assessment: Strong

## Initial Observations

- Credit card is the most frequently used payment method.
- Boleto is the second most common payment type.
- Debit card usage is lower than both credit card and boleto.
- The `not_defined` or other residual category is the least common.
- The presence of `payment_sequential` confirms that some orders may contain multiple payment transactions.
- Installment information allows analysis of financing behaviour and spending patterns.

## Business Interpretation

High credit-card usage does not automatically mean that the business has poor liquidity.

In many card-payment arrangements, the merchant or marketplace receives settlement from the payment processor before the customer completes all installment payments. The exact timing and fees depend on the commercial agreement.

The main business implications are therefore more likely to include:

- payment-processing fees,
- settlement delays,
- dependency on card networks or processors,
- chargeback risk,
- and the effect of installments on customer spending.

Because the dataset does not include settlement dates or processing fees, conclusions about cash flow cannot be made directly from the available fields.

## Analytical Questions

1. Which payment method is used most frequently?
2. Which payment method generates the highest total payment value?
3. Do customers using credit cards have a higher average payment value?
4. Do customers using more installments spend more per order?
5. How common are orders with multiple payment records?
6. How dependent is the marketplace on credit-card payments?
7. Would encouraging lower-cost payment methods improve profitability?
8. How might payment-method mix affect settlement speed and cash flow?

# Order Reviews

## Initial Observations

- Every review is associated with an order.
- Customer feedback consists of both structured (rating) and unstructured (text) information.
- Missing review titles and review messages are likely to represent customers who submitted only a numerical rating.
- Missing textual feedback should be interpreted as a customer behavior rather than immediately being classified as poor data quality.

## Analytical Questions

1. What is the average review score?
2. Which product categories receive the highest and lowest ratings?
3. Do delayed deliveries result in lower review scores?
4. Are customers who leave written comments more likely to give very high or very low ratings?
5. Which sellers consistently receive the best customer reviews?
6. Does delivery time influence customer satisfaction?

The presence of review scores without written comments suggests that customer engagement exists on different levels. Some customers provide only a numerical rating, while others invest additional effort by leaving written feedback.


# Geoloation

## Analytical Questions

1. Which Brazilian states generate the highest number of orders?
2. Which cities have the highest concentration of customers?
3. Which states have the highest concentration of sellers?
4. Are customers located closer to sellers receiving orders faster?
5. Which regions experience the highest freight costs?
6. Are delivery delays associated with specific geographic regions?
7. Can delivery distance explain customer review scores?

## Cleaning Decision

The Geolocation dataset will not be joined directly to transactional tables.

Instead, it will first be transformed into a standardized lookup table containing one representative geographic record per ZIP code prefix.

This prevents duplicate joins and preserves the integrity of downstream business metrics.

# Category Translation

## Analytical Questions

1. Which translated product categories generate the highest revenue?
2. Which translated categories receive the highest review scores?
3. Which categories experience the highest freight costs?
4. Which categories contribute the largest number of orders?
