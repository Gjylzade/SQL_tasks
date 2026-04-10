-- TASK 3 - Write 10 business questions as SQL

-- Query 1: Find the top 5 customers who spent the most money
SELECT c.first_name, c.last_name,
       SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 5;

-- Query 2: Find the best-selling book based on quantity sold
SELECT b.title,
       SUM(oi.quantity) AS total_sold
FROM books b
JOIN order_items oi ON b.book_id = oi.book_id
GROUP BY b.book_id, b.title
ORDER BY total_sold DESC
LIMIT 1;

-- Query 3: Calculate the average price of books per genre
SELECT genre,
       AVG(price) AS avg_price
FROM books
GROUP BY genre;

-- Query 4: Find customers who have placed at least 2 orders
SELECT c.first_name, c.last_name,
       COUNT(o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COUNT(o.order_id) >= 2;

-- Query 5: Calculate monthly revenue from completed orders
SELECT DATE_TRUNC('month', o.order_date) AS month,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;

-- Query 6: Find books that have never been sold
SELECT b.title
FROM books b
LEFT JOIN order_items oi ON b.book_id = oi.book_id
WHERE oi.book_id IS NULL;

-- Query 7: Calculate total sales per book genre
SELECT b.genre,
       SUM(oi.quantity * oi.unit_price) AS total_sales
FROM books b
JOIN order_items oi ON b.book_id = oi.book_id
GROUP BY b.genre;


-- Query 8: Find the most expensive book in the store
SELECT title, price
FROM books
ORDER BY price DESC
LIMIT 1;

-- Query 9: Find orders with a total value greater than 20€
SELECT o.order_id,
       SUM(oi.quantity * oi.unit_price) AS total_value
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id
HAVING SUM(oi.quantity * oi.unit_price) > 20;

-- Query 10: Find the author with the most books
SELECT a.first_name,
       a.last_name,
       COUNT(ba.book_id) AS total_books
FROM authors a
JOIN book_authors ba ON a.author_id = ba.author_id
GROUP BY a.author_id, a.first_name, a.last_name
ORDER BY total_books DESC
LIMIT 1;
