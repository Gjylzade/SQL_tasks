-- =========================================
-- J1: INNER JOIN - orders + customers
-- =========================================
SELECT 
    o.order_id,
    c.full_name AS customer_name,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS total_value
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY o.order_id, c.full_name;

-- =========================================
-- J2: LEFT JOIN - all customers incl. no orders
-- =========================================
SELECT 
    c.customer_id,
    c.full_name,
    o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id;

-- =========================================
-- J3: mismatched sales rep using bridge table
-- =========================================
SELECT 
    o.order_id,
    o.customer_id,
    o.sales_rep_id AS order_rep,
    a.sales_rep_id AS assigned_rep
FROM orders o
JOIN sales_rep_assignments a 
    ON o.customer_id = a.customer_id
WHERE o.sales_rep_id IS DISTINCT FROM a.sales_rep_id;

-- =========================================
-- J4: FULL order line report (5 tables)
-- =========================================
SELECT 
    o.order_id,
    c.full_name AS customer,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount,
    (oi.quantity * oi.unit_price * (1 - oi.discount)) AS line_total,
    sr.full_name AS sales_rep,
    sr.region
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
JOIN products p ON p.product_id = oi.product_id
JOIN sales_reps sr ON sr.sales_rep_id = o.sales_rep_id;

-- =========================================
-- J5: products in history but removed (FULL OUTER JOIN concept)
-- =========================================
SELECT 
    COALESCE(p.product_name, 'MISSING PRODUCT') AS product_name,
    oi.order_item_id
FROM products p
FULL OUTER JOIN order_items oi 
    ON p.product_id = oi.product_id
WHERE p.product_id IS NULL 
   OR oi.product_id IS NULL;


-- =========================================
-- J6: Self join - customers in same city
-- =========================================
SELECT 
    c1.full_name AS customer1,
    c2.full_name AS customer2,
    c1.city
FROM customers c1
JOIN customers c2 
    ON c1.city = c2.city
   AND c1.customer_id < c2.customer_id;

-- =========================================
-- J7: LEFT JOIN = NOT IN logic
-- =========================================
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi 
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- =========================================
-- J8: Revenue by region (ROLLUP)
-- =========================================
SELECT 
    sr.country,
    sr.region,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount)) AS revenue
FROM sales_reps sr
JOIN orders o ON o.sales_rep_id = sr.sales_rep_id
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY ROLLUP (sr.country, sr.region);