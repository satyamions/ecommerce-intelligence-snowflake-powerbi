//Purely for finding business insights to use for powerbi
    
USE ROLE ECOMMERCE_DEVELOPER;
USE WAREHOUSE ECOMMERCE_WH;
USE DATABASE ECOMMERCE_DB;
USE SCHEMA ANALYTICS;


SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    SUM(total_payment_value) AS total_revenue,
    AVG(total_payment_value) AS avg_order_value,
    AVG(delivery_days) AS avg_delivery_days,
    AVG(average_review_score) AS avg_review_score
FROM FACT_ORDERS
WHERE order_status = 'delivered';


SELECT
    d.year,
    d.month_number,
    d.month_name,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.total_payment_value) AS revenue,
    AVG(f.total_payment_value) AS avg_order_value
FROM FACT_ORDERS f
JOIN DIM_DATE d
    ON f.date_key = d.date_key
WHERE f.order_status = 'delivered'
GROUP BY
    d.year,
    d.month_number,
    d.month_name
ORDER BY
    d.year,
    d.month_number;

SELECT
    CASE
        WHEN lifetime_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS customers
FROM DIM_CUSTOMER
GROUP BY customer_type;


SELECT
    COUNT_IF(lifetime_orders > 1) AS repeat_customers,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT_IF(lifetime_orders > 1) * 100.0 / COUNT(*),
        2
    ) AS repeat_customer_rate_pct
FROM DIM_CUSTOMER;


SELECT
    p.product_category,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.price) AS product_revenue,
    SUM(f.freight_value) AS freight_value,
    SUM(f.gross_item_value) AS gross_value
FROM FACT_ORDER_ITEMS f
JOIN DIM_PRODUCT p
    ON f.product_id = p.product_id
GROUP BY p.product_category
ORDER BY product_revenue DESC;


SELECT
    CASE
        WHEN is_late_delivery = TRUE THEN 'Late'
        WHEN is_late_delivery = FALSE THEN 'On time / early'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS orders,
    AVG(average_review_score) AS avg_review_score
FROM FACT_ORDERS
WHERE order_status = 'delivered'
GROUP BY delivery_status
ORDER BY orders DESC;


SELECT
    CASE
        WHEN is_late_delivery = TRUE THEN 'Late'
        WHEN is_late_delivery = FALSE THEN 'On time / early'
        ELSE 'Unknown'
    END AS delivery_status,
    COUNT(*) AS orders,
    ROUND(AVG(delivery_days), 2) AS avg_delivery_days,
    ROUND(AVG(average_review_score), 2) AS avg_review_score
FROM FACT_ORDERS
WHERE order_status = 'delivered'
GROUP BY delivery_status
ORDER BY orders DESC;


SELECT
    AVG(
        DATEDIFF(
            'day',
            order_estimated_delivery_date,
            order_delivered_customer_date
        )
    ) AS avg_delivery_variance_days
FROM FACT_ORDERS
WHERE order_status = 'delivered';


SELECT
    l.state,
    COUNT(DISTINCT f.order_id) AS orders,
    SUM(f.total_payment_value) AS revenue,
    AVG(f.total_payment_value) AS avg_order_value,
    AVG(f.delivery_days) AS avg_delivery_days,
    AVG(f.average_review_score) AS avg_review_score
FROM FACT_ORDERS f
JOIN DIM_LOCATION l
    ON f.zip_code_prefix = l.zip_code_prefix
WHERE f.order_status = 'delivered'
GROUP BY l.state
ORDER BY revenue DESC;


WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        MAX(date_key) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(total_payment_value) AS monetary
    FROM FACT_ORDERS
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
),

rfm_base AS (
    SELECT
        customer_unique_id,

        DATEDIFF(
            'day',
            last_order_date,
            (SELECT MAX(date_key) FROM FACT_ORDERS)
        ) AS recency,

        frequency,
        monetary
    FROM customer_metrics
)

SELECT *
FROM rfm_base
ORDER BY monetary DESC
LIMIT 20;


WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        MAX(date_key) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(total_payment_value) AS monetary
    FROM FACT_ORDERS
    WHERE order_status = 'delivered'
      AND total_payment_value IS NOT NULL
    GROUP BY customer_unique_id
),

rfm_base AS (
    SELECT
        customer_unique_id,
        DATEDIFF(
            'day',
            last_order_date,
            (SELECT MAX(date_key)
             FROM FACT_ORDERS
             WHERE order_status = 'delivered')
        ) AS recency,
        frequency,
        monetary
    FROM customer_metrics
),

rfm_scored AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
)

SELECT
    *,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'

        WHEN r_score >= 3 AND f_score >= 4
            THEN 'Loyal Customers'

        WHEN r_score >= 4 AND f_score <= 2
            THEN 'Recent Customers'

        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
            THEN 'At Risk'

        WHEN r_score <= 2 AND f_score <= 2
            THEN 'Hibernating'

        ELSE 'Potential Loyalists'
    END AS rfm_segment
FROM rfm_scored;


WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        MAX(date_key) AS last_order_date,
        COUNT(DISTINCT order_id) AS frequency,
        SUM(total_payment_value) AS monetary
    FROM FACT_ORDERS
    WHERE order_status = 'delivered'
      AND total_payment_value IS NOT NULL
    GROUP BY customer_unique_id
),

rfm_base AS (
    SELECT
        customer_unique_id,
        DATEDIFF(
            'day',
            last_order_date,
            (SELECT MAX(date_key)
             FROM FACT_ORDERS
             WHERE order_status = 'delivered')
        ) AS recency,
        frequency,
        monetary
    FROM customer_metrics
),

rfm_scored AS (
    SELECT
        *,
        6 - NTILE(5) OVER (ORDER BY recency ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),

rfm_segmented AS (
    SELECT
        *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
                THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 4
                THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2
                THEN 'Recent Customers'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
                THEN 'At Risk'
            WHEN r_score <= 2 AND f_score <= 2
                THEN 'Hibernating'
            ELSE 'Potential Loyalists'
        END AS rfm_segment
    FROM rfm_scored
)

SELECT
    rfm_segment,
    COUNT(*) AS customers,
    ROUND(AVG(recency), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM rfm_segmented
GROUP BY rfm_segment
ORDER BY customers DESC;


SELECT
    l.state,
    COUNT(*) AS delivered_orders,

    COUNT_IF(f.is_late_delivery = TRUE) AS late_orders,

    ROUND(
        COUNT_IF(f.is_late_delivery = TRUE) * 100.0 / COUNT(*),
        2
    ) AS late_delivery_rate_pct,

    ROUND(AVG(f.delivery_days), 2) AS avg_delivery_days,

    ROUND(AVG(f.average_review_score), 2) AS avg_review_score

FROM FACT_ORDERS f

JOIN DIM_LOCATION l
    ON f.zip_code_prefix = l.zip_code_prefix

WHERE f.order_status = 'delivered'

GROUP BY l.state

HAVING COUNT(*) >= 100

ORDER BY late_delivery_rate_pct DESC;



SELECT
    p.product_category,

    COUNT(DISTINCT f.order_id) AS orders,

    COUNT(DISTINCT CASE
        WHEN o.is_late_delivery = TRUE
        THEN f.order_id
    END) AS late_orders,

    ROUND(
        COUNT(DISTINCT CASE
            WHEN o.is_late_delivery = TRUE
            THEN f.order_id
        END) * 100.0
        / COUNT(DISTINCT f.order_id),
        2
    ) AS late_delivery_rate_pct,

    ROUND(AVG(o.average_review_score), 2) AS avg_review_score

FROM FACT_ORDER_ITEMS f

JOIN FACT_ORDERS o
    ON f.order_id = o.order_id

JOIN DIM_PRODUCT p
    ON f.product_id = p.product_id

WHERE o.order_status = 'delivered'

GROUP BY p.product_category

HAVING COUNT(DISTINCT f.order_id) >= 100

ORDER BY late_delivery_rate_pct DESC;



SELECT
    d.year_month,

    COUNT(DISTINCT f.order_id) AS orders,

    ROUND(SUM(f.total_payment_value), 2) AS revenue,

    ROUND(AVG(f.total_payment_value), 2) AS avg_order_value

FROM FACT_ORDERS f

JOIN DIM_DATE d
    ON f.date_key = d.date_key

WHERE f.order_status = 'delivered'
  AND d.date_key BETWEEN '2017-01-01' AND '2018-08-31'

GROUP BY d.year_month

ORDER BY d.year_month;



WITH monthly_sales AS (
    SELECT
        d.year_month,
        SUM(f.total_payment_value) AS revenue
    FROM FACT_ORDERS f
    JOIN DIM_DATE d
        ON f.date_key = d.date_key
    WHERE f.order_status = 'delivered'
      AND d.date_key BETWEEN '2017-01-01' AND '2018-08-31'
    GROUP BY d.year_month
)

SELECT
    year_month,
    ROUND(revenue, 2) AS revenue,

    ROUND(
        (
            revenue
            - LAG(revenue) OVER (ORDER BY year_month)
        )
        / NULLIF(
            LAG(revenue) OVER (ORDER BY year_month),
            0
        )
        * 100,
        2
    ) AS mom_growth_pct

FROM monthly_sales

ORDER BY year_month;



SELECT
    d.month_number,
    d.month_name,

    SUM(CASE
        WHEN d.year = 2017
        THEN f.total_payment_value
    END) AS revenue_2017,

    SUM(CASE
        WHEN d.year = 2018
        THEN f.total_payment_value
    END) AS revenue_2018

FROM FACT_ORDERS f

JOIN DIM_DATE d
    ON f.date_key = d.date_key

WHERE f.order_status = 'delivered'
  AND d.month_number BETWEEN 1 AND 8

GROUP BY
    d.month_number,
    d.month_name

ORDER BY d.month_number;



CREATE OR REPLACE TABLE RFM_CUSTOMERS AS

WITH customer_metrics AS (

    SELECT
        customer_unique_id,

        MAX(date_key) AS last_order_date,

        COUNT(DISTINCT order_id) AS frequency,

        SUM(total_payment_value) AS monetary

    FROM FACT_ORDERS

    WHERE order_status = 'delivered'
      AND total_payment_value IS NOT NULL

    GROUP BY customer_unique_id
),

rfm_base AS (

    SELECT
        customer_unique_id,

        DATEDIFF(
            'day',
            last_order_date,
            (
                SELECT MAX(date_key)
                FROM FACT_ORDERS
                WHERE order_status = 'delivered'
            )
        ) AS recency,

        frequency,
        monetary

    FROM customer_metrics
),

percentiles AS (

    SELECT
        *,

        CUME_DIST() OVER (
            ORDER BY recency DESC
        ) AS recency_percentile,

        CUME_DIST() OVER (
            ORDER BY monetary ASC
        ) AS monetary_percentile

    FROM rfm_base
),

rfm_scored AS (

    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,

        CASE
            WHEN recency_percentile <= 0.20 THEN 1
            WHEN recency_percentile <= 0.40 THEN 2
            WHEN recency_percentile <= 0.60 THEN 3
            WHEN recency_percentile <= 0.80 THEN 4
            ELSE 5
        END AS r_score,

        CASE
            WHEN frequency = 1 THEN 1
            WHEN frequency = 2 THEN 3
            WHEN frequency BETWEEN 3 AND 4 THEN 4
            ELSE 5
        END AS f_score,

        CASE
            WHEN monetary_percentile <= 0.20 THEN 1
            WHEN monetary_percentile <= 0.40 THEN 2
            WHEN monetary_percentile <= 0.60 THEN 3
            WHEN monetary_percentile <= 0.80 THEN 4
            ELSE 5
        END AS m_score

    FROM percentiles
)

SELECT
    *,

    CASE
        WHEN r_score >= 4
         AND f_score >= 4
         AND m_score >= 4
            THEN 'Champions'

        WHEN f_score >= 3
         AND r_score >= 3
            THEN 'Loyal Customers'

        WHEN r_score >= 4
         AND f_score = 1
            THEN 'Recent Customers'

        WHEN r_score <= 2
         AND f_score >= 3
            THEN 'At Risk'

        WHEN r_score <= 2
         AND f_score = 1
            THEN 'Hibernating'

        WHEN r_score >= 3
         AND m_score >= 3
            THEN 'Potential Loyalists'

        ELSE 'Needs Attention'
    END AS rfm_segment

FROM rfm_scored;



SELECT
    frequency,
    f_score,
    COUNT(*) AS customers
FROM RFM_CUSTOMERS
GROUP BY
    frequency,
    f_score
ORDER BY frequency;


SELECT
    rfm_segment,
    COUNT(*) AS customers,
    ROUND(AVG(recency), 1) AS avg_recency_days,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM RFM_CUSTOMERS
GROUP BY rfm_segment
ORDER BY customers DESC;


SELECT
    MIN(frequency) AS min_frequency,
    MAX(frequency) AS max_frequency,
    AVG(frequency) AS avg_frequency
FROM RFM_CUSTOMERS
WHERE rfm_segment = 'Loyal Customers';
