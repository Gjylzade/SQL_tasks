-- TASK 1 - Design and build a database from scratch

CREATE DATABASE bookstore_db;

-- connect to database (IMPORTANT)
\c bookstore_db;

-- DROP TABLES 

DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS customers;


-- TABLES

CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    price DECIMAL(10,2) CHECK (price > 0),
    stock INT CHECK (stock >= 0),
    published_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE book_authors (
    book_id INT,
    author_id INT,
    PRIMARY KEY (book_id, author_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT CHECK (quantity > 0),
    unit_price DECIMAL(10,2) CHECK (unit_price > 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (book_id) REFERENCES books(book_id)
);


-- Data insert

INSERT INTO authors (first_name, last_name) VALUES
('George', 'Orwell'),
('J.K.', 'Rowling'),
('Stephen', 'King'),
('Haruki', 'Murakami'),
('Agatha', 'Christie');

INSERT INTO books (isbn, title, genre, price, stock, published_date) VALUES
('9780451524935', '1984', 'Dystopian', 12.99, 50, '1949-06-08'),
('9780747532743', 'Harry Potter and the Philosopher''s Stone', 'Fantasy', 15.99, 100, '1997-06-26'),
('9781501142970', 'The Shining', 'Horror', 14.50, 40, '1977-01-28'),
('9780307271037', 'Kafka on the Shore', 'Fiction', 13.75, 30, '2002-09-12'),
('9780061120084', 'Murder on the Orient Express', 'Mystery', 11.50, 60, '1934-01-01'),
('9780452284234', 'Animal Farm', 'Political Satire', 10.00, 70, '1945-08-17'),
('9780545582889', 'Harry Potter and the Chamber of Secrets', 'Fantasy', 16.99, 90, '1998-07-02'),
('9780385121675', 'It', 'Horror', 18.50, 25, '1986-09-15'),
('9780679783275', 'Norwegian Wood', 'Fiction', 13.20, 35, '1987-09-04'),
('9780062073488', 'And Then There Were None', 'Mystery', 12.00, 55, '1939-11-06');

INSERT INTO book_authors (book_id, author_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5),
(6, 1),
(7, 2),
(8, 3),
(9, 4),
(10, 5);

INSERT INTO customers (first_name, last_name, email, city) VALUES
('Arta', 'Hoxha', 'arta@example.com', 'Prishtina'),
('Blerim', 'Krasniqi', 'blerim@example.com', 'Prizren'),
('Elira', 'Gashi', 'elira@example.com', 'Peja'),
('Dren', 'Berisha', 'dren@example.com', 'Gjilan'),
('Jon', 'Morina', 'jon@example.com', 'Ferizaj'),
('Sara', 'Bytyqi', 'sara@example.com', 'Mitrovica'),
('Leon', 'Daka', 'leon@example.com', 'Prishtina'),
('Nora', 'Selimi', 'nora@example.com', 'Prizren'),
('Gjylzade', 'Gashi', 'gjyzi@example.com', 'Prizren');

INSERT INTO orders (customer_id, order_date, total_amount) VALUES
(1, '2025-01-10', 25.98),
(2, '2025-01-11', 15.99),
(3, '2025-01-12', 28.00),
(4, '2025-01-13', 11.50),
(5, '2025-01-14', 30.00),
(6, '2025-01-15', 18.50),
(7, '2025-01-16', 22.99),
(8, '2025-01-17', 14.00),
(1, '2025-01-18', 13.75),
(2, '2025-01-19', 16.99),
(3, '2025-01-20', 20.00),
(4, '2025-01-21', 12.00),
(5, '2025-01-22', 19.99),
(6, '2025-01-23', 17.50),
(7, '2025-01-24', 21.00),
(1, '2025-02-10', 30.00),
(2, '2025-02-11', 40.00),
(3, '2025-03-05', 25.00);

INSERT INTO order_items (order_id, book_id, quantity, unit_price) VALUES
(1, 1, 2, 12.99),
(2, 2, 1, 15.99),
(3, 3, 2, 14.00),
(4, 5, 1, 11.50),
(5, 6, 3, 10.00),
(6, 8, 1, 18.50),
(7, 4, 2, 11.50),
(8, 9, 1, 14.00),
(9, 4, 1, 13.75),
(10, 7, 1, 16.99),
(11, 10, 2, 10.00),
(12, 5, 1, 12.00),
(13, 2, 1, 19.99),
(14, 3, 1, 17.50),
(15, 1, 1, 21.00),
(16, 1, 1, 12.99),
(17, 2, 2, 15.99),
(18, 3, 1, 14.50);

-- INDEXES

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_book_id ON order_items(book_id);

-- CHECKS

SELECT COUNT(*) FROM authors;
SELECT COUNT(*) FROM books;
SELECT COUNT(*) FROM book_authors;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
