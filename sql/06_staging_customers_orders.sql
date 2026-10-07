USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA STAGING;

//cleaning customers table
CREATE OR REPLACE TABLE STG_CUSTOMERS AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code_prefix,
    INITCAP(TRIM(customer_city)) AS customer_city,
    UPPER(TRIM(customer_state)) AS customer_state
FROM ECOMMERCE_DB.RAW.RAW_CUSTOMERS;

//cleaning and making substantial changes to orders table
CREATE OR REPLACE TABLE STG_ORDERS AS
SELECT
    order_id,
    customer_id,
    LOWER(TRIM(order_status)) AS order_status,
    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    CAST(order_purchase_timestamp AS DATE) AS order_date,
    YEAR(order_purchase_timestamp) AS order_year,
    MONTH(order_purchase_timestamp) AS order_month,
    QUARTER(order_purchase_timestamp) AS order_quarter,
    
    DATEDIFF(
        'day',
        order_purchase_timestamp,
        order_delivered_customer_date
    ) AS delivery_days,
    DATEDIFF(
        'day',
        order_purchase_timestamp,
        order_estimated_delivery_date
    ) AS estimated_delivery_days,

    CASE
        WHEN order_delivered_customer_date IS NULL
            THEN NULL
        WHEN order_delivered_customer_date >
             order_estimated_delivery_date
            THEN TRUE
        ELSE FALSE
    END AS is_late_delivery
FROM ECOMMERCE_DB.RAW.RAW_ORDERS;

//cleaning and making substantial changes to products table
CREATE OR REPLACE TABLE STG_PRODUCTS AS
SELECT
    p.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'Unknown'
    ) AS product_category,
    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.product_length_cm
        * p.product_height_cm
        * p.product_width_cm
        AS product_volume_cm3

FROM ECOMMERCE_DB.RAW.RAW_PRODUCTS p
LEFT JOIN ECOMMERCE_DB.RAW.RAW_CATEGORY_TRANSLATION t
    ON p.product_category_name = t.product_category_name;

//cleaning sellers
CREATE OR REPLACE TABLE STG_SELLERS AS
SELECT
    seller_id,
    seller_zip_code_prefix AS zip_code_prefix,
    INITCAP(TRIM(seller_city)) AS seller_city,
    UPPER(TRIM(seller_state)) AS seller_state
FROM ECOMMERCE_DB.RAW.RAW_SELLERS;

//cleaning order items
CREATE OR REPLACE TABLE STG_ORDER_ITEMS AS
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    shipping_limit_date,
    price,
    freight_value,

    price + freight_value AS gross_item_value

FROM ECOMMERCE_DB.RAW.RAW_ORDER_ITEMS;

//cleaning payments
CREATE OR REPLACE TABLE STG_PAYMENTS AS
SELECT
    order_id,
    payment_sequential,
    LOWER(TRIM(payment_type)) AS payment_type,
    payment_installments,
    payment_value
FROM ECOMMERCE_DB.RAW.RAW_PAYMENTS;

//review cleaning
USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA STAGING;

CREATE OR REPLACE TABLE STG_REVIEWS AS
SELECT
    review_id,
    order_id,
    review_score,

    NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
    NULLIF(TRIM(review_comment_message), '') AS review_comment_message,

    review_creation_date,
    review_answer_timestamp,

    CASE
        WHEN review_comment_message IS NULL
          OR TRIM(review_comment_message) = ''
            THEN FALSE
        ELSE TRUE
    END AS has_review_comment

FROM ECOMMERCE_DB.RAW.RAW_REVIEWS;

//geoloaction cleaning
CREATE OR REPLACE TABLE STG_GEOLOCATION AS
SELECT
    geolocation_zip_code_prefix AS zip_code_prefix,

    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude,

    MODE(geolocation_city) AS city,
    MODE(geolocation_state) AS state

FROM ECOMMERCE_DB.RAW.RAW_GEOLOCATION

GROUP BY geolocation_zip_code_prefix;

select * from stg_geolocation;