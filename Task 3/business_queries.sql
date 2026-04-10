--Task 3: Write 10 business questions as SQL

--Q1: List all customers from Germany whose orders total more than €5,000, ordered by total descending.
SELECT 
    c.customer_id,
    c.company_name,
    SUM(od.unit_price * od.quantity * (1 - od.discount)) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
WHERE c.country = 'Germany'
GROUP BY c.customer_id, c.company_name
HAVING SUM(od.unit_price * od.quantity * (1 - od.discount)) > 5000
ORDER BY total_spent DESC;

--Q2: Find the top 5 best-selling products by units sold in the most recent complete year.
SELECT 
    p.product_name,
    SUM(od.quantity) AS total_sold
FROM products p
JOIN order_details od ON p.product_id = od.product_id
JOIN orders o ON od.order_id = o.order_id
WHERE EXTRACT(YEAR FROM o.order_date) = (
    SELECT MAX(EXTRACT(YEAR FROM order_date)) FROM orders
)
GROUP BY p.product_id, p.product_name
ORDER BY total_sold DESC
LIMIT 5;

--Q3: Which product categories have an average unit price above €50?
SELECT 
    c.category_name,
    AVG(p.unit_price) AS avg_price
FROM categories c
JOIN products p ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
HAVING AVG(p.unit_price) > 50;


--Q4: Find all orders that were shipped more than 7 days after the order date.
SELECT 
    order_id,
    order_date,
    shipped_date,
    (shipped_date - order_date) AS days_delay
FROM orders
WHERE shipped_date IS NOT NULL
AND (shipped_date - order_date) > 7;


--Q5: List customers who placed more than 3 orders but whose average order value is below €200.
WITH order_values AS (
    SELECT 
        o.order_id,
        o.customer_id,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS order_total
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_id, o.customer_id
)
SELECT 
    c.company_name,
    COUNT(ov.order_id) AS total_orders,
    AVG(ov.order_total) AS avg_order_value
FROM customers c
JOIN order_values ov ON c.customer_id = ov.customer_id
GROUP BY c.customer_id, c.company_name
HAVING COUNT(ov.order_id) > 3
   AND AVG(ov.order_total) < 200;

   
--Q6: Which months had total revenue above the overall monthly average?
WITH monthly AS (
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
SELECT *
FROM monthly
WHERE revenue > (SELECT AVG(revenue) FROM monthly);


--Q7: Find all products that have never been ordered.
SELECT p.product_name
FROM products p
LEFT JOIN order_details od ON p.product_id = od.product_id
WHERE od.product_id IS NULL;

-- testing product
INSERT INTO products (product_id, product_name, category_id, unit_price, units_in_stock, discontinued)
VALUES (9999, 'TEST PRODUCT', 1, 10, 100, 0);




--Q8: What percentage of orders were delivered on time (shipped within 5 days of the order date)?
SELECT 
    100.0 * SUM(CASE 
        WHEN shipped_date <= order_date + INTERVAL '5 days' 
        THEN 1 ELSE 0 END) 
    / COUNT(*) AS on_time_percentage
FROM orders
WHERE shipped_date IS NOT NULL;


--Q9: Which sales representative had the highest revenue in Q4 of the most recent complete year?
WITH yearly_quarters AS (
    SELECT 
        EXTRACT(YEAR FROM order_date) AS yr,
        EXTRACT(QUARTER FROM order_date) AS q
    FROM orders
    GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
),
complete_years AS (
    SELECT yr
    FROM yearly_quarters
    GROUP BY yr
    HAVING COUNT(DISTINCT q) = 4
),
latest_year AS (
    SELECT MAX(yr) AS yr
    FROM complete_years
),
q4_orders AS (
    SELECT o.*
    FROM orders o
    JOIN latest_year ly 
      ON EXTRACT(YEAR FROM o.order_date) = ly.yr
    WHERE EXTRACT(QUARTER FROM o.order_date) = 4
),
revenue_by_rep AS (
    SELECT 
        e.employee_id,
        e.first_name,
        e.last_name,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS revenue
    FROM employees e
    JOIN q4_orders o ON e.employee_id = o.employee_id
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY e.employee_id, e.first_name, e.last_name
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (ORDER BY revenue DESC) AS rnk
    FROM revenue_by_rep
)
SELECT 
    employee_id,
    first_name,
    last_name,
    revenue
FROM ranked
WHERE rnk = 1;


--Q10: Find the second-highest revenue product in each category.

--subquery version
SELECT *
FROM (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(od.quantity * od.unit_price) AS revenue,
        DENSE_RANK() OVER (
            PARTITION BY p.category_id 
            ORDER BY SUM(od.quantity * od.unit_price) DESC
        ) AS rnk
    FROM products p
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
) sub
WHERE rnk = 2;

--window function
WITH product_revenue AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(od.quantity * od.unit_price) AS revenue
    FROM products p
    JOIN order_details od ON p.product_id = od.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (
               PARTITION BY category_id 
               ORDER BY revenue DESC
           ) AS rnk
    FROM product_revenue
)
SELECT *
FROM ranked
WHERE rnk = 2;


