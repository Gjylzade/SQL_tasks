-- 
-- TASK 5 - REWRITE QUERIES USING CTEs
-- Database: Northwind
-- 

-- Note: sales_quota is a simulated table for NQ3 only

/*
Learning objective:
Practice breaking complex SQL logic into readable and testable steps using CTEs.
Each query includes:
1. Nested version
2. CTE version
3. Short explanation
*/

CREATE TABLE sales_quota (
    sales_rep_id INT,
    year INT,
    quarter INT,
    achievement INT
);
INSERT INTO sales_quota VALUES
(1, 2024, 1, 85),
(1, 2024, 2, 90),
(1, 2024, 3, 88),
(1, 2024, 4, 92),
(2, 2024, 1, 70),
(2, 2024, 2, 82),
(2, 2024, 3, 83),
(2, 2024, 4, 81);

-- 
-- NQ1: Find customers whose total lifetime spend exceeds the average total spend across all
customers.
-- 

-- Nested version
SELECT customer_id, total_spend
FROM (
    SELECT 
        c.customer_id,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
) t
WHERE total_spend > (
    SELECT AVG(total_spend)
    FROM (
        SELECT 
            SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spend
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_details od ON o.order_id = od.order_id
        GROUP BY c.customer_id
    ) x
);

-- CTE version
WITH customer_spend AS (
    SELECT 
        c.customer_id,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spend
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
),
avg_spend AS (
    SELECT AVG(total_spend) AS avg_value
    FROM customer_spend
)
SELECT cs.*
FROM customer_spend cs
JOIN avg_spend a ON cs.total_spend > a.avg_value;

/*
Explanation:
This query finds customers spending above the overall average.
CTEs improve readability by separating aggregation and filtering logic.
Nested version is harder to read and debug.
*/

-- 
-- NQ2: Find the top-selling product in each product category.
-- 

-- Nested version
SELECT *
FROM (
    SELECT 
        c.category_name,
        p.product_name,
        SUM(od.quantity) AS total_sold,
        RANK() OVER (
            PARTITION BY c.category_id 
            ORDER BY SUM(od.quantity) DESC
        ) AS rnk
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY c.category_id, c.category_name, p.product_name
) AS category_product_sales_ranked
WHERE rnk = 1;


-- CTE version
WITH product_sales AS (
    SELECT 
        c.category_id,
        c.category_name,
        p.product_id,
        p.product_name,
        SUM(od.quantity) AS total_sold
    FROM categories c
    JOIN products p ON c.category_id = p.category_id
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY c.category_id, c.category_name, p.product_id, p.product_name
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY category_id ORDER BY total_sold DESC) AS rnk
    FROM product_sales
)
SELECT *
FROM ranked
WHERE rnk = 1;

/*
Explanation:
This query identifies the best-selling product per category.
CTEs separate aggregation and ranking steps, making logic clearer and reusable.
*/

-- 
-- NQ3: Find sales reps who achieved above 80% quota attainment for three or more consecutive quarters.
-- 

-- Note: requires sales_quota table (sales_rep_id, year, quarter, achievement)

-- Nested version
SELECT sales_rep_id
FROM (
    SELECT 
        sales_rep_id,
        year,
        quarter,
        achievement,
        ROW_NUMBER() OVER (
            PARTITION BY sales_rep_id 
            ORDER BY year, quarter
        ) AS rn
    FROM sales_quota
    WHERE achievement >= 80
) AS high_achievement_quarters
GROUP BY sales_rep_id, (year, quarter - rn)
HAVING COUNT(*) >= 3;

-- CTE version (Gap and Islands)
WITH filtered AS (
    SELECT *
    FROM sales_quota
    WHERE achievement >= 80
),
numbered AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY sales_rep_id ORDER BY year, quarter) AS rn
    FROM filtered
),
islands AS (
    SELECT *,
           (quarter - rn) AS grp
    FROM numbered
)
SELECT sales_rep_id
FROM islands
GROUP BY sales_rep_id, grp
HAVING COUNT(*) >= 3;

/*
Explanation:
This query finds sales reps with consistent high performance.
The gap-and-islands technique groups consecutive quarters.
CTE version is more structured and easier to debug than nested logic.
*/

-- 
-- NQ4: Compute each customer&#39;s Recency (days since last order), Frequency (number of orders in the past year), and Monetary value (total spend in the past year) in a single query.
-- 

-- Nested version
SELECT *
FROM (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order,
        COUNT(o.order_id) AS frequency,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
) AS customer_rfm_metrics;


-- CTE version
WITH rfm AS (
    SELECT 
        c.customer_id,
        MAX(o.order_date) AS last_order,
        COUNT(o.order_id) AS frequency,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monetary
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY c.customer_id
)
SELECT *,
       CURRENT_DATE - last_order AS recency_days
FROM rfm;

/*
Explanation:
RFM analysis measures customer behavior:
Recency = last purchase, Frequency = number of orders, Monetary = total spend.
CTEs make this structure reusable for marketing analysis.
*/

-- 
-- NQ5: For each month, show that month&#39;s net revenue alongside the rolling 3-month average.
-- 

-- Nested version
SELECT 
    month,
    revenue,
    AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_avg
FROM (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
) AS monthly_revenue;



-- CTE version
WITH monthly AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT 
    month,
    revenue,
    AVG(revenue) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_avg
FROM monthly;


/*
Explanation:
This query shows monthly revenue trends and smoothing via a rolling average.
CTEs separate aggregation from time-series analytics, improving clarity and maintainability.
*/

