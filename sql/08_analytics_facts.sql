USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA ANALYTICS;

//analytics ready orders table
CREATE OR REPLACE TABLE FACT_ORDERS AS

WITH payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value,
        COUNT(*) AS payment_records,
        MAX(payment_installments) AS max_installments
    FROM ECOMMERCE_DB.STAGING.STG_PAYMENTS
    GROUP BY order_id
),

review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score,
        COUNT(*) AS review_records,
        MAX(IFF(has_review_comment, 1, 0)) AS has_review_comment
    FROM ECOMMERCE_DB.STAGING.STG_REVIEWS
    GROUP BY order_id
)

SELECT
    o.order_id,

    c.customer_unique_id,
    c.zip_code_prefix,

    o.order_date AS date_key,
    o.order_status,

    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    o.delivery_days,
    o.estimated_delivery_days,
    o.is_late_delivery,

    p.total_payment_value,
    p.payment_records,
    p.max_installments,

    r.average_review_score,
    r.review_records,
    r.has_review_comment

FROM ECOMMERCE_DB.STAGING.STG_ORDERS o

JOIN ECOMMERCE_DB.STAGING.STG_CUSTOMERS c
    ON o.customer_id = c.customer_id

LEFT JOIN payment_summary p
    ON o.order_id = p.order_id

LEFT JOIN review_summary r
    ON o.order_id = r.order_id;


//analytics ready items table
CREATE OR REPLACE TABLE FACT_ORDER_ITEMS AS
SELECT
    oi.order_id,
    oi.order_item_id,

    oi.product_id,
    oi.seller_id,

    o.order_date AS date_key,

    oi.shipping_limit_date,

    oi.price,
    oi.freight_value,
    oi.gross_item_value

FROM ECOMMERCE_DB.STAGING.STG_ORDER_ITEMS oi

JOIN ECOMMERCE_DB.STAGING.STG_ORDERS o
    ON oi.order_id = o.order_id;


//analytics ready payments table
CREATE OR REPLACE TABLE FACT_PAYMENTS AS
SELECT
    p.order_id,
    p.payment_sequential,

    o.order_date AS date_key,

    p.payment_type,
    p.payment_installments,
    p.payment_value

FROM ECOMMERCE_DB.STAGING.STG_PAYMENTS p

JOIN ECOMMERCE_DB.STAGING.STG_ORDERS o
    ON p.order_id = o.order_id;