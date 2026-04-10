--TASK 4 : Multi-table join challenge

--Create sales representatives table
CREATE TABLE sales_reps (
    rep_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    region VARCHAR(50)
);

-- Insert sample sales representatives data
INSERT INTO sales_reps (first_name, last_name, region) VALUES
('Arber', 'Hoxha', 'Europe'),
('John', 'Smith', 'USA'),
('Elira', 'Gashi', 'Balkans');

-- Add a new column to link each order with a sales representative
ALTER TABLE orders
ADD COLUMN rep_id INT;

-- Add foreign key constraint to ensure data integrity
ALTER TABLE orders
ADD CONSTRAINT fk_sales_rep
FOREIGN KEY (rep_id) REFERENCES sales_reps(rep_id);

-- Assign sales representatives to orders based on customer groups 
UPDATE orders SET rep_id = 1 WHERE customer_id IN (1,2,3);
UPDATE orders SET rep_id = 2 WHERE customer_id IN (4,5,6);
UPDATE orders SET rep_id = 3 WHERE customer_id IN (7,8,9);

-- Query 1: Order total per order with customer and sales rep
SELECT 
    o.order_id,
    c.first_name AS customer_first_name,
    c.last_name AS customer_last_name,
    sr.first_name AS rep_first_name,
    sr.last_name AS rep_last_name,
    SUM(oi.quantity * oi.unit_price) AS order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN sales_reps sr ON o.rep_id = sr.rep_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, c.first_name, c.last_name, sr.first_name, sr.last_name;


-- Query 2: show all customers
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    COUNT(o.order_id) AS total_orders
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


-- Query 3 : Customer activity status (derived, not stored)
SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    CASE WHEN COUNT(o.order_id) = 0 THEN 'INACTIVE'
         ELSE 'ACTIVE'
    END AS customer_status
FROM customers c
LEFT JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name;


-- Query 4: Revenue per sales rep
SELECT 
    sr.rep_id,
    sr.first_name,
    sr.last_name,
    COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS revenue
FROM sales_reps sr
LEFT JOIN orders o ON sr.rep_id = o.rep_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY sr.rep_id, sr.first_name, sr.last_name;


-- Query 5: Full order line report
SELECT 
    o.order_id,
    c.first_name AS customer_first_name,
    c.last_name AS customer_last_name,
    sr.first_name AS rep_name,
    b.title AS book_title,
    oi.quantity,
    oi.unit_price,
    (oi.quantity * oi.unit_price) AS line_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN sales_reps sr ON o.rep_id = sr.rep_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN books b ON oi.book_id = b.book_id;


-- Query 6: Customers with no orders 
SELECT c.customer_id,
       c.first_name,
       c.last_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.customer_id IS NULL;

-- Query 7: Products sold vs not sold 
SELECT 
    b.book_id,
    b.title,
    CASE 
        WHEN oi.book_id IS NULL THEN 'NOT SOLD'
        ELSE 'SOLD'
    END AS sales_status
FROM books b
LEFT JOIN order_items oi 
    ON b.book_id = oi.book_id;


-- Query 8: Revenue by region 
SELECT 
    COALESCE(sr.region, 'TOTAL') AS region,
    SUM(oi.quantity * oi.unit_price) AS revenue
FROM sales_reps sr
JOIN orders o ON sr.rep_id = o.rep_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY ROLLUP(sr.region);


-- Query 9: Customers with orders on same date 
UPDATE orders SET order_date = '2024-01-10' WHERE order_id IN (1,2);
UPDATE orders SET order_date = '2024-01-11' WHERE order_id IN (3,4);

SELECT 
    o1.order_date,
    c1.first_name || ' ' || c1.last_name AS customer_1,
    c2.first_name || ' ' || c2.last_name AS customer_2
FROM orders o1
JOIN orders o2 
  ON o1.order_date = o2.order_date
 AND o1.order_id < o2.order_id
JOIN customers c1 ON o1.customer_id = c1.customer_id
JOIN customers c2 ON o2.customer_id = c2.customer_id
ORDER BY o1.order_date;




