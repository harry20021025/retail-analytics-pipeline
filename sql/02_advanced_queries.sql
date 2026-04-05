-- ================================================
-- FILE 2: Advanced SQL — Window Functions
-- Project: Retail Analytics Pipeline
-- Author: Hariom Dixit
-- ================================================

USE retail_analytics;

-- Month over Month Revenue Growth
WITH monthly_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
        ROUND(SUM(oi.price), 2) AS revenue
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)
SELECT 
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) / 
        LAG(revenue) OVER (ORDER BY month) * 100, 
    2) AS growth_pct
FROM monthly_revenue
ORDER BY month;

-- Customer Ranking by Spending
SELECT 
    o.customer_id,
    ROUND(SUM(oi.price), 2) AS total_spent,
    COUNT(DISTINCT o.order_id) AS total_orders,
    RANK() OVER (ORDER BY SUM(oi.price) DESC) AS spending_rank
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY o.customer_id
ORDER BY spending_rank
LIMIT 20;

-- Delivery Performance
SELECT 
    o.order_id,
    o.customer_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    DATE(o.order_delivered_customer_date) AS delivered_date,
    DATE(o.order_estimated_delivery_date) AS estimated_date,
    DATEDIFF(
        o.order_delivered_customer_date, 
        o.order_purchase_timestamp
    ) AS actual_days,
    CASE 
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date 
        THEN 'Late'
        ELSE 'On Time'
    END AS delivery_status
FROM olist_orders_dataset o
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL;