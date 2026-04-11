-- 
-- TASK 4 - MULTI TABLE JOIN CHALLENGE
-- Database: e-commerce
-- 

CREATE DATABASE e-commerce;

\c e-commerce;

-- 
-- TABLES
-- 

CREATE TABLE sales_reps (
    sales_rep_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    region VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    country VARCHAR(50),
    sales_rep_id INT REFERENCES sales_reps(sales_rep_id)
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    active BOOLEAN DEFAULT TRUE
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    sales_rep_id INT REFERENCES sales_reps(sales_rep_id),
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount DECIMAL(4,2) DEFAULT 0
);

-- Bridge table 
CREATE TABLE sales_rep_assignments (
    assignment_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    sales_rep_id INT REFERENCES sales_reps(sales_rep_id),
    start_date DATE,
    end_date DATE
);

-- 
-- SAMPLE DATA
-- 

INSERT INTO sales_reps (full_name, region, country) VALUES
('Arben Krasniqi', 'West', 'Kosovo'),
('Elira Gashi', 'East', 'Kosovo');

INSERT INTO customers (full_name, city, country, sales_rep_id) VALUES
('Arta Hoxha', 'Prishtina', 'Kosovo', 1),
('Blerim Krasniqi', 'Prizren', 'Kosovo', 1),
('Sara Bytyqi', 'Peja', 'Kosovo', 2),
('Jon Morina', 'Prishtina', 'Kosovo', NULL);

INSERT INTO products (product_name, unit_price) VALUES
('Laptop', 800),
('Mouse', 20),
('Keyboard', 50),
('Monitor', 200);

INSERT INTO products (product_name, unit_price)
VALUES ('iphone', 999);

INSERT INTO orders (customer_id, sales_rep_id, order_date) VALUES
(1, 1, '2025-01-10'),
(2, 1, '2025-01-11'),
(3, 2, '2025-01-12');

INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES
(1, 1, 1, 800, 0),
(1, 2, 2, 20, 0.1),
(2, 3, 1, 50, 0),
(3, 4, 2, 200, 0.05);

INSERT INTO sales_rep_assignments (customer_id, sales_rep_id, start_date, end_date) VALUES
(1, 1, '2024-01-01', '2024-12-31'),
(1, 2, '2025-01-01', NULL);


INSERT INTO sales_rep_assignments (customer_id, sales_rep_id, start_date, end_date) VALUES
(1, 2, '2024-01-01', NULL),  -- mismatch (intentional)
(2, 1, '2024-01-01', NULL),  -- mismatch
(3, 2, '2024-01-01', NULL),
(4, 1, '2024-01-01', NULL);


