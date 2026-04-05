-- ================================================
-- FILE 3: RFM Customer Segmentation
-- Project: Retail Analytics Pipeline
-- Author: Hariom Dixit
-- ================================================

USE retail_analytics;

-- RFM Calculation
-- Export result as rfm_output.csv for Python
WITH rfm_base AS (
    SELECT
        o.customer_id,
        MAX(o.order_purchase_timestamp) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.price), 2) AS monetary
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY o.customer_id
)
SELECT 
    customer_id,
    last_purchase_date,
    DATEDIFF('2018-10-01', last_purchase_date) AS recency_days,
    frequency,
    monetary
FROM rfm_base
ORDER BY monetary DESC;