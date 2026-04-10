-- 
-- TASK 1 - DDL (Bookstore Database)
-- 

CREATE DATABASE bookstore_db;

-- NOTE: connect manually depending on DB:
-- PostgreSQL: \c bookstore_db;
-- MySQL: USE bookstore_db;

-- 
-- DROP TABLES (safe re-run)
-- 

DROP TABLE IF EXISTS book_authors;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS authors;
DROP TABLE IF EXISTS customers;

-- 
-- TABLE: AUTHORS
-- Stores information about book authors.
-- Each author can be linked to multiple books via the book_authors bridge table.
-- Names are split into first_name and last_name for better querying and normalization.
-- 
CREATE TABLE authors (
    author_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 
-- TABLE: BOOKS
-- Stores all book-related information including ISBN, title, genre, price, and stock.
-- ISBN is UNIQUE to ensure each book is uniquely identifiable.
-- Price and stock have CHECK constraints to prevent invalid business data (no negative values).
-- 
CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    isbn VARCHAR(20) UNIQUE NOT NULL,
    title VARCHAR(255) NOT NULL,
    genre VARCHAR(100),
    price DECIMAL(10,2) NOT NULL CHECK (price > 0),
    stock INT NOT NULL DEFAULT 0 CHECK (stock >= 0),
    published_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 
-- TABLE: CUSTOMERS
-- Stores customer information such as name, email, and city.
-- Email is UNIQUE to prevent duplicate accounts.
-- This table is used as the main reference for all orders placed in the system.
-- 
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    city VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 
-- TABLE: ORDERS
-- Represents a purchase transaction made by a customer.
-- Each order belongs to exactly one customer (one-to-many relationship).
-- order_date tracks when the purchase was made, and total_amount stores the order total.
-- Foreign key ensures referential integrity with customers table.
-- 
CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_amount DECIMAL(10,2) DEFAULT 0,

    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- 
-- TABLE: ORDER ITEMS
-- Stores individual book items inside each order (line-level details).
-- This allows one order to contain multiple books.
-- unit_price and quantity are stored to preserve historical pricing at time of purchase.
-- Links orders and books tables in a many-to-many transactional structure.
--
CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    book_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL CHECK (unit_price > 0),

    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,

    FOREIGN KEY (book_id)
        REFERENCES books(book_id)
);

-- 
-- TABLE: BOOK_AUTHORS (MANY TO MANY)
-- Bridge table that implements many-to-many relationship between books and authors.
-- A single book can have multiple authors, and an author can write multiple books.
-- Composite primary key ensures no duplicate book-author pairs exist.
-- 
CREATE TABLE book_authors (
    book_id INT NOT NULL,
    author_id INT NOT NULL,

    PRIMARY KEY (book_id, author_id),

    FOREIGN KEY (book_id)
        REFERENCES books(book_id)
        ON DELETE CASCADE,

    FOREIGN KEY (author_id)
        REFERENCES authors(author_id)
        ON DELETE CASCADE
);

-- 
-- INDEXES (performance improvement)
-- 

CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_order_date ON orders(order_date);
CREATE INDEX idx_order_items_book_id ON order_items(book_id);
