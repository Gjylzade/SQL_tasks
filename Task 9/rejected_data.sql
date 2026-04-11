
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

