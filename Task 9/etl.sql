/* 
   TASK 9 - Simulate an ETL pipeline in SQL
    */

-- 
-- STAGE 1 - EXTRACT
-- 

DROP TABLE IF EXISTS stg_raw_sales;

CREATE TABLE stg_raw_sales (
    order_id TEXT,
    customer_id TEXT,
    product_id TEXT,
    quantity TEXT,
    price TEXT,
    order_date TEXT
);

INSERT INTO stg_raw_sales VALUES
('1','10','100','2','50','2024-01-10'),
('2','11','101','1','30','2024-01-11'),
('3','12','102',NULL,'40','2024-01-12'),
('4','13','103','2','-99','2024-01-13'),
('5','14','104','3','60','31/02/2024'),      -- Invalid date
('6','15','105','1','20','2024-01-15'),
('7','16','106','2','25','2024-01-16'),
('8','17','107','1',NULL,'2024-01-17'),
('9','18','108','4','80','2024-01-18'),
('10','19','109','2','100','2024-01-19'),
('11','20','110','1','45','2024-01-20'),
('12','21','111','2','55','2024-01-21'),
('13','22','112','3','70','2024-01-22'),
('14','23','113','2','90','2024-01-23'),
('15','24','114','1','15','2024-01-24'),
('16','25','115','2','35','2024-01-25'),
('17','26','116','3','65','2024-01-26'),
('18','27','117','1','75','2024-01-27'),
('19','28','118','2','85','2024-01-28'),
('20','29','119','1','95','2024-01-29'),
('21','30','120','2','50','2024-01-30'),
('22','31','121','1','60','2024-01-31'),
('23','32','122','3','70','2024-02-01'),
('24','33','123','2','80','2024-02-02'),
('25','34','124','1','90','31/02/2024'),      -- Invalid date
('26','35','125','2','-99','2024-02-04'),
('27','36','126',NULL,'40','2024-02-05'),
('28','37','127','2','55','2024-02-06'),
('29','38','128','1','65','2024-02-07'),
('30','39','129','2','75','2024-02-08'),
('1','10','100','2','50','2024-01-10'),        -- Duplicate
('2','11','101','1','30','2024-01-11');        -- Duplicate


-- 
-- FUNCTION: Safe date parser for multiple formats
-- 

CREATE OR REPLACE FUNCTION parse_date_safe(date_str TEXT)
RETURNS DATE AS $$
DECLARE
    parsed DATE;
BEGIN
    IF date_str IS NULL OR TRIM(date_str) = '' THEN
        RETURN NULL;
    END IF;
    
    -- Try YYYY-MM-DD format
    IF date_str ~ '^\d{4}-\d{2}-\d{2}$' THEN
        BEGIN
            parsed := date_str::DATE;
            RETURN parsed;
        EXCEPTION WHEN OTHERS THEN
            RETURN NULL;
        END;
    -- Try DD/MM/YYYY format
    ELSIF date_str ~ '^\d{2}/\d{2}/\d{4}$' THEN
        BEGIN
            parsed := TO_DATE(date_str, 'DD/MM/YYYY');
            -- Additional validation for invalid dates like 31/02/2024
            IF EXTRACT(YEAR FROM parsed) > 1900 THEN
                RETURN parsed;
            ELSE
                RETURN NULL;
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RETURN NULL;
        END;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- 
-- STAGE 2 - TRANSFORM
-- 

DROP TABLE IF EXISTS stg_transformed;

CREATE TABLE stg_transformed AS
WITH cleaned AS (
    SELECT 
        order_id,
        customer_id,
        product_id,
        quantity,
        price,
        order_date,
        
        -- Clean quantity
        CASE 
            WHEN quantity ~ '^[0-9]+$' THEN quantity::INT
            ELSE NULL
        END AS quantity_clean,

        -- Clean price (must be non-negative)
        CASE 
            WHEN price ~ '^-?[0-9]+(\.[0-9]+)?$' 
                 AND price::DECIMAL >= 0
            THEN price::DECIMAL
            ELSE NULL
        END AS price_clean,

        -- Clean date using safe function
        parse_date_safe(order_date) AS order_date_clean

    FROM stg_raw_sales
),

deduped AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY order_date_clean DESC NULLS LAST
        ) AS rn
    FROM cleaned
)

SELECT *,

    -- Validation status
    CASE 
        WHEN order_id IS NULL OR order_id = '' THEN 'INVALID'
        WHEN customer_id IS NULL OR customer_id = '' THEN 'INVALID'
        WHEN product_id IS NULL OR product_id = '' THEN 'INVALID'
        WHEN quantity_clean IS NULL THEN 'INVALID'
        WHEN price_clean IS NULL THEN 'INVALID'
        WHEN order_date_clean IS NULL THEN 'INVALID'
        WHEN rn > 1 THEN 'DUPLICATE ORDER_ID'
        ELSE 'VALID'
    END AS status,

    -- Rejection reason
    CASE 
        WHEN order_id IS NULL OR order_id = '' THEN 'Missing order_id'
        WHEN customer_id IS NULL OR customer_id = '' THEN 'Missing customer_id'
        WHEN product_id IS NULL OR product_id = '' THEN 'Missing product_id'
        WHEN quantity_clean IS NULL THEN 'Invalid quantity (null or non-numeric)'
        WHEN price_clean IS NULL THEN 'Invalid price (null, non-numeric, or negative)'
        WHEN order_date_clean IS NULL THEN 'Invalid date (wrong format or invalid value like 31/02)'
        WHEN rn > 1 THEN 'Duplicate order_id (older record skipped)'
        ELSE 'OK'
    END AS rejection_reason

FROM deduped;


-- 
-- STAGE 3 - REJECTED TABLE
-- 

DROP TABLE IF EXISTS stg_rejected;

CREATE TABLE stg_rejected AS
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    price,
    order_date,
    rejection_reason,
    CURRENT_TIMESTAMP AS rejected_at
FROM stg_transformed
WHERE status = 'INVALID';


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


-- 
-- RECONCILIATION QUERIES
-- 

-- 1. Pipeline statistics
SELECT 
    'PIPELINE STATISTICS' AS report_section;
    
SELECT 
    'staging' AS stage, 
    COUNT(*) AS row_count,
    NULL::TEXT AS description
FROM stg_raw_sales

UNION ALL

SELECT 
    'valid_transformed', 
    COUNT(*),
    'Rows that passed validation'
FROM stg_transformed WHERE status = 'VALID'

UNION ALL

SELECT 
    'invalid_transformed', 
    COUNT(*),
    'Rows that failed validation'
FROM stg_transformed WHERE status = 'INVALID'

UNION ALL

SELECT 
    'fact_sales', 
    COUNT(*),
    'Rows successfully loaded'
FROM fact_sales

UNION ALL

SELECT 
    'rejected', 
    COUNT(*),
    'Rows logged in rejection table'
FROM stg_rejected;

-- 2. Quality KPI
SELECT 
    'DATA QUALITY KPI' AS report_section;
    
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN status='VALID' THEN 1 ELSE 0 END) AS valid_rows,
    SUM(CASE WHEN status='INVALID' THEN 1 ELSE 0 END) AS invalid_rows,
    ROUND(100.0 * SUM(CASE WHEN status='VALID' THEN 1 ELSE 0 END) / COUNT(*), 2) AS valid_percentage,
    ROUND(100.0 * SUM(CASE WHEN status='INVALID' THEN 1 ELSE 0 END) / COUNT(*), 2) AS invalid_percentage
FROM stg_transformed;

-- 3. Rejection breakdown by reason
SELECT 
    'REJECTION BREAKDOWN' AS report_section;
    
SELECT 
    rejection_reason,
    COUNT(*) AS total,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM stg_rejected), 2) AS percentage
FROM stg_rejected
GROUP BY rejection_reason
ORDER BY total DESC;

-- 4. Sample of rejected records
SELECT 
    'SAMPLE REJECTED RECORDS' AS report_section;
    
SELECT 
    order_id,
    customer_id,
    product_id,
    quantity,
    price,
    order_date,
    rejection_reason
FROM stg_rejected
LIMIT 10;

-- 5. Sample of valid loaded records
SELECT 
    'SAMPLE VALID RECORDS' AS report_section;
    
SELECT 
    order_id,
    customer_id,
    product_id,
    quantity,
    price,
    order_date,
    loaded_at
FROM fact_sales
LIMIT 10;