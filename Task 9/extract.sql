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

