-- Active: 1790414987768@@127.0.0.1@5432@retail
CREATE DATABASE retail;

CREATE TABLE retail_sales (
    invoice_no VARCHAR(20),
    stock_code VARCHAR(50),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(10, 2),
    customer_id INTEGER,
    country VARCHAR(100)
);

SELECT * FROM retail_sales;

-- Uloha 2
SELECT customer_id,
       invoice_no,
       invoice_date,
       quantity,
       unit_price,
       quantity * unit_price AS revenue,
       SUM(quantity * unit_price) OVER (
           PARTITION BY customer_id
           ORDER BY invoice_date
           RANGE BETWEEN INTERVAL '14 days' PRECEDING AND CURRENT ROW
       ) AS revenue_last_14_days
FROM retail_sales
WHERE customer_id IS NOT NULL
ORDER BY customer_id, invoice_date;

-- Uloha 3
SELECT stock_code,
       country,
       invoice_date,
       quantity,
       ROUND(AVG(quantity) OVER (
           PARTITION BY stock_code, country
           ORDER BY invoice_date
           RANGE BETWEEN INTERVAL '7 days' PRECEDING AND CURRENT ROW
       ), 2) AS avg_quantity_7_days
FROM retail_sales
WHERE quantity > 1
ORDER BY stock_code, country, invoice_date;

-- Uloha 4
WITH unique_orders AS (
    SELECT customer_id,
           invoice_no,
           MIN(invoice_date) AS invoice_date
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id, invoice_no),
orders_with_next AS (
    SELECT customer_id,
           invoice_no,
           invoice_date,
           LEAD(invoice_date) OVER (
               PARTITION BY customer_id
               ORDER BY invoice_date
           ) AS next_invoice_date
    FROM unique_orders)
SELECT customer_id,
       invoice_no,
       invoice_date,
       next_invoice_date,
       next_invoice_date::date - invoice_date::date AS days_to_next_invoice
FROM orders_with_next
WHERE next_invoice_date IS NOT NULL
ORDER BY days_to_next_invoice DESC;

-- Uloha 5
WITH price_changes AS (
    SELECT stock_code,
           invoice_no,
           invoice_date,
           LAG(unit_price) OVER (
               PARTITION BY stock_code
               ORDER BY invoice_date
           ) AS previous_price,
           unit_price AS current_price
    FROM retail_sales)
SELECT stock_code,
       invoice_no,
       invoice_date,
       previous_price,
       current_price,
       current_price - previous_price AS price_difference
FROM price_changes
WHERE previous_price IS NOT NULL
  AND current_price <> previous_price
ORDER BY invoice_date ASC;

-- Uloha 6
WITH customer_sales AS (
    SELECT customer_id,
           SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id)
SELECT customer_id,
       total_amount,
       NTILE(4) OVER (ORDER BY total_amount DESC) AS sales_quartile
FROM customer_sales
ORDER BY total_amount DESC;
 
-- pocet zaznamov:
WITH customer_sales AS (
    SELECT customer_id,
           SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id)
SELECT COUNT(*) FROM customer_sales;

-- Uloha 7
WITH monthly_sales AS (
    SELECT country,
           DATE_TRUNC('month', invoice_date) AS month,
           SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    GROUP BY country, DATE_TRUNC('month', invoice_date))
SELECT country,
       month,
       total_amount,
       NTILE(4) OVER (
           PARTITION BY country
           ORDER BY total_amount DESC
       ) AS sales_quartile
FROM monthly_sales
ORDER BY country, month ASC;

-- Uloha 8
WITH numbered_purchases AS (
    SELECT customer_id,
           invoice_no,
           invoice_date,
           stock_code,
           description,
           quantity,
           unit_price,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY invoice_date ASC
           ) AS rn
    FROM retail_sales
    WHERE customer_id IS NOT NULL)
SELECT customer_id,
       invoice_no,
       invoice_date,
       stock_code,
       description,
       quantity,
       unit_price
FROM numbered_purchases
WHERE rn = 1
ORDER BY customer_id ASC;

-- Uloha 9
WITH ranked_items AS (
    SELECT invoice_no,
           stock_code,
           description,
           quantity,
           unit_price,
           quantity * unit_price AS amount,
           ROW_NUMBER() OVER (
               PARTITION BY invoice_no
               ORDER BY quantity * unit_price DESC
           ) AS row_num
    FROM retail_sales)
SELECT invoice_no,
       stock_code,
       description,
       quantity,
       unit_price,
       amount,
       row_num
FROM ranked_items
WHERE row_num <= 3 --AND stock_code = '22632' AND invoice_no = '536366'
ORDER BY invoice_no, row_num;
 

-- Uloha 10
WITH customer_monthly_sales AS (
    SELECT country,
           DATE_TRUNC('month', invoice_date) AS month,
           customer_id,
           SUM(quantity * unit_price) AS total_amount
    FROM retail_sales
    WHERE customer_id IS NOT NULL
    GROUP BY country, DATE_TRUNC('month', invoice_date), customer_id),
ranked_customers AS (
    SELECT country,
           month,
           customer_id,
           total_amount,
           DENSE_RANK() OVER (
               PARTITION BY country, month
               ORDER BY total_amount DESC
           ) AS sales_rank
    FROM customer_monthly_sales)
SELECT country,
       month,
       customer_id,
       total_amount,
       sales_rank
FROM ranked_customers
WHERE sales_rank <= 5
ORDER BY country, month, sales_rank, customer_id;

-- Uloha 11
WITH ranked_prices AS (
    SELECT invoice_no,
           stock_code,
           description,
           quantity,
           unit_price,
           DENSE_RANK() OVER (
               PARTITION BY invoice_no
               ORDER BY unit_price DESC
           ) AS price_rank
    FROM retail_sales)
SELECT invoice_no,
       stock_code,
       description,
       quantity,
       unit_price,
       price_rank
FROM ranked_prices
WHERE price_rank <= 5
ORDER BY invoice_no, price_rank, stock_code;
 
-- pocet zaznamov:
WITH ranked_prices AS (
    SELECT invoice_no,
           stock_code,
           DENSE_RANK() OVER (
               PARTITION BY invoice_no
               ORDER BY unit_price DESC
           ) AS price_rank
    FROM retail_sales)
SELECT COUNT(*) FROM ranked_prices WHERE price_rank <= 5;