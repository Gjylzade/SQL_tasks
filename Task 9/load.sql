
-- 
-- STAGE 4 - LOAD (with idempotency)
-- 

DROP TABLE IF EXISTS fact_sales;

CREATE TABLE fact_sales (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT,
    product_id TEXT,
    quantity INT,
    price DECIMAL(10,2),
    order_date DATE,
    loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CHECK (quantity > 0),
    CHECK (price > 0)
);

INSERT INTO fact_sales (
    order_id,
    customer_id,
    product_id,
    quantity,
    price,
    order_date
)
SELECT
    order_id,
    customer_id,
    product_id,
    quantity_clean,
    price_clean,
    order_date_clean
FROM stg_transformed
WHERE status = 'VALID'
AND rn = 1
ON CONFLICT (order_id) DO NOTHING;

