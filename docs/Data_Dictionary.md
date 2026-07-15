# Customers Table

## Business Purpose

Stores customer identity and geographic information for every order placed on the Olist platform.

---

## Table Grain

One row represents one customer record associated with an order.

---

## Primary Key

customer_id

---

## Foreign Keys

None

---

## Business Identifier

customer_unique_id

This identifier represents the actual customer and may appear across multiple customer records.

---

## Location Attributes

- customer_zip_code_prefix
- customer_city
- customer_state

---

## Data Quality Assessment

- Missing Values: None
- Duplicate Rows: None
- Data Quality: Excellent