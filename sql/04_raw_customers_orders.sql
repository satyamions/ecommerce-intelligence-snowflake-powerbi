USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

//customers table
CREATE OR REPLACE TABLE RAW_CUSTOMERS (
    customer_id              VARCHAR(32),
    customer_unique_id       VARCHAR(32),
    customer_zip_code_prefix NUMBER(5,0),
    customer_city            VARCHAR,
    customer_state           VARCHAR(2)
);

//orders table
CREATE OR REPLACE TABLE RAW_ORDERS (
    order_id                       VARCHAR(32),
    customer_id                    VARCHAR(32),
    order_status                   VARCHAR,
    order_purchase_timestamp       TIMESTAMP_NTZ,
    order_approved_at              TIMESTAMP_NTZ,
    order_delivered_carrier_date   TIMESTAMP_NTZ,
    order_delivered_customer_date  TIMESTAMP_NTZ,
    order_estimated_delivery_date  TIMESTAMP_NTZ
);

//loading both customers and orders
COPY INTO RAW_CUSTOMERS
FROM @OLIST_STAGE/olist_customers_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

COPY INTO RAW_ORDERS
FROM @OLIST_STAGE/olist_orders_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

//order-items
CREATE OR REPLACE TABLE RAW_ORDER_ITEMS (
    order_id             VARCHAR(32),
    order_item_id        NUMBER,
    product_id           VARCHAR(32),
    seller_id            VARCHAR(32),
    shipping_limit_date  TIMESTAMP_NTZ,
    price                NUMBER(12,2),
    freight_value        NUMBER(12,2)
);

//loading
COPY INTO RAW_ORDER_ITEMS
FROM @OLIST_STAGE/olist_order_items_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

//payments
CREATE OR REPLACE TABLE RAW_PAYMENTS (
    order_id              VARCHAR(32),
    payment_sequential    NUMBER,
    payment_type          VARCHAR,
    payment_installments  NUMBER,
    payment_value         NUMBER(12,2)
);

//loading
COPY INTO RAW_PAYMENTS
FROM @OLIST_STAGE/olist_order_payments_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

select * from raw_payments;