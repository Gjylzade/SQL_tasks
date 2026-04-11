
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

