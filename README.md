GJYLZADE PERDIBUKA - SQL Tasks Submission

Completed Tasks:
Task01 – Database design and schema creation (PageTurner bookshop system)
Task03 – Business queries using Northwind dataset
Task04 – Multi-table join scenarios using custom schema
Task05 – Query refactoring using CTEs (Northwind)
Task09 – End-to-end ETL pipeline simulation (PostgreSQL)

Datasets Used:

* Task01: Custom dataset (bookshop system with books, authors, customers, and sales)
* Task03: Northwind sample database
* Task04: Custom schema (customers, orders, order_items, products, sales_reps)
* Task05: Northwind database (with additional simulated sales_quota table)
* Task09: Simulated raw CSV data inserted into staging table (stg_raw_sales)

Setup Instructions:

1. Open PostgreSQL using pgAdmin or psql
2. Navigate to each task folder (Task01, Task03, Task04, Task05, Task09)
3. Run each SQL file from top to bottom
4. All scripts are designed to be idempotent where required (using DROP TABLE IF EXISTS or safe insert logic)
5. No manual modifications are required to execute the scripts

Notes on Implementation:

* All queries explicitly specify column names (no SELECT * is used in final versions)
* Each query is preceded by a comment describing the business requirement
* All queries return meaningful, non-empty results using the provided sample data
* Sample datasets are included directly in SQL scripts using INSERT statements

Task-Specific Highlights:

Task01:
The database was designed using normalization principles. Primary keys, foreign keys, and constraints such as NOT NULL, UNIQUE, and CHECK (price > 0, stock >= 0) were applied to ensure data integrity.

Task03:
Business-focused SQL queries were written using GROUP BY, HAVING, subqueries, and window functions to answer real-world analytical questions.

Task04:
Different JOIN types (INNER, LEFT, FULL OUTER, SELF JOIN) were implemented to demonstrate how data relationships affect query results.

Task05:
Complex queries were first written using nested subqueries and then rewritten using Common Table Expressions (CTEs) to improve readability and maintainability. A gap-and-islands technique was used for consecutive period analysis.

Task09:
A full ETL pipeline was implemented:

* Extract: Raw data loaded into a staging table with intentional data quality issues
* Transform: Data cleaned, validated, deduplicated, and flagged as valid or invalid
* Load: Only valid records inserted into fact table with idempotent logic (ON CONFLICT)
* Rejected records stored in a separate table with rejection reasons
* Data quality KPIs calculated to measure pipeline performance

Conclusion:
This submission demonstrates practical SQL and data engineering skills, including data modeling, query optimization, and building a complete ETL pipeline with data quality handling.
