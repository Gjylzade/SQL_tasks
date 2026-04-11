/* 
   TASK 9 - Simulate an ETL pipeline in SQL
    */

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