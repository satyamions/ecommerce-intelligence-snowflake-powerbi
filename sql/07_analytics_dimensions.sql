USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA ANALYTICS;

//creating product table
CREATE OR REPLACE TABLE DIM_PRODUCT AS
SELECT
    product_id,
    product_category,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,
    product_volume_cm3
FROM ECOMMERCE_DB.STAGING.STG_PRODUCTS;

//seller table
CREATE OR REPLACE TABLE DIM_SELLER AS
SELECT
    seller_id,
    zip_code_prefix,
    seller_city,
    seller_state
FROM ECOMMERCE_DB.STAGING.STG_SELLERS;

//loaction table
CREATE OR REPLACE TABLE DIM_LOCATION AS
SELECT
    zip_code_prefix,
    city,
    state,
    latitude,
    longitude
FROM ECOMMERCE_DB.STAGING.STG_GEOLOCATION;

//customers table
CREATE OR REPLACE TABLE DIM_CUSTOMER AS
SELECT
    c.customer_unique_id,
    MIN(o.order_purchase_timestamp) AS first_order_timestamp,
    MAX(o.order_purchase_timestamp) AS last_order_timestamp,
    COUNT(DISTINCT o.order_id) AS lifetime_orders
FROM ECOMMERCE_DB.STAGING.STG_CUSTOMERS c
JOIN ECOMMERCE_DB.STAGING.STG_ORDERS o
    ON c.customer_id = o.customer_id
GROUP BY c.customer_unique_id;

//date table making
CREATE OR REPLACE TABLE DIM_DATE AS
WITH date_range AS (
    SELECT
        DATEADD(
            day,
            SEQ4(),
            (SELECT MIN(order_date) FROM ECOMMERCE_DB.STAGING.STG_ORDERS)
        ) AS date_day
    FROM TABLE(
        GENERATOR(
            ROWCOUNT => 800
        )
    )
)
SELECT
    date_day AS date_key,
    YEAR(date_day) AS year,
    QUARTER(date_day) AS quarter_number,
    'Q' || QUARTER(date_day) AS quarter,
    MONTH(date_day) AS month_number,
    MONTHNAME(date_day) AS month_name,
    TO_CHAR(date_day, 'YYYY-MM') AS year_month,
    DAY(date_day) AS day_of_month,
    DAYOFWEEK(date_day) AS day_of_week_number,
    DAYNAME(date_day) AS day_name
FROM date_range
WHERE date_day <= (
    SELECT MAX(order_date)
    FROM ECOMMERCE_DB.STAGING.STG_ORDERS
);