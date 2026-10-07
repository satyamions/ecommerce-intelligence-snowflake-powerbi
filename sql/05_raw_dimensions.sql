USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA RAW;

//products
CREATE OR REPLACE TABLE RAW_PRODUCTS (
    product_id                         VARCHAR(32),
    product_category_name              VARCHAR,
    product_name_lenght                NUMBER,
    product_description_lenght         NUMBER,
    product_photos_qty                 NUMBER,
    product_weight_g                   NUMBER,
    product_length_cm                  NUMBER,
    product_height_cm                  NUMBER,
    product_width_cm                   NUMBER
);

//loading
COPY INTO RAW_PRODUCTS
FROM @OLIST_STAGE/olist_products_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

//sellers
CREATE OR REPLACE TABLE RAW_SELLERS (
    seller_id                VARCHAR(32),
    seller_zip_code_prefix   NUMBER(5,0),
    seller_city              VARCHAR,
    seller_state             VARCHAR(2)
);

//loading
COPY INTO RAW_SELLERS
FROM @OLIST_STAGE/olist_sellers_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

//category-translation
CREATE OR REPLACE TABLE RAW_CATEGORY_TRANSLATION (
    product_category_name          VARCHAR,
    product_category_name_english  VARCHAR
);

//loading
COPY INTO RAW_CATEGORY_TRANSLATION
FROM @OLIST_STAGE/product_category_name_translation.csv
ON_ERROR = 'ABORT_STATEMENT';

//reviews
CREATE OR REPLACE TABLE RAW_REVIEWS (
    review_id                VARCHAR(32),
    order_id                 VARCHAR(32),
    review_score             NUMBER,
    review_comment_title     VARCHAR,
    review_comment_message   VARCHAR,
    review_creation_date     TIMESTAMP_NTZ,
    review_answer_timestamp  TIMESTAMP_NTZ
);

//loading
COPY INTO RAW_REVIEWS
FROM @OLIST_STAGE/olist_order_reviews_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

//geolocation
CREATE OR REPLACE TABLE RAW_GEOLOCATION (
    geolocation_zip_code_prefix  NUMBER(5,0),
    geolocation_lat              FLOAT,
    geolocation_lng              FLOAT,
    geolocation_city             VARCHAR,
    geolocation_state            VARCHAR(2)
);

//loading
COPY INTO RAW_GEOLOCATION
FROM @OLIST_STAGE/olist_geolocation_dataset.csv
ON_ERROR = 'ABORT_STATEMENT';

select * from raw_geolocation;