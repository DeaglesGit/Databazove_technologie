-- Active: 1790414987768@@127.0.0.1@5432@datacraftinglab_db
Create DATABASE datacraftinglab_db;

CREATE TABLE flourmills_sales (
    sales_id INTEGER PRIMARY KEY,
    sale_date DATE,
    region VARCHAR(100),
    state VARCHAR(100),
    product_category VARCHAR(100),
    product_name VARCHAR(150),
    customer_type VARCHAR(100),
    customer_id INTEGER,
    quantity_sold INTEGER,
    unit_price NUMERIC(10, 2),
    discount_rate INTEGER,
    payment_method VARCHAR(100),
    sales_rep VARCHAR(150),
    warehouse VARCHAR(100),
    delivery_status VARCHAR(100),
    order_channel VARCHAR(100),
    batch_number INTEGER,
    production_date DATE,
    total_amount NUMERIC(10, 2));

SELECT * FROM flourmills_sales;

SELECT product_name, total_amount
FROM flourmills_sales
WHERE total_amount > (
SELECT AVG(total_amount)
FROM flourmills_sales);

SELECT *
FROM flourmills_sales
WHERE product_category = (
SELECT product_category
FROM flourmills_sales
GROUP BY product_category
ORDER BY SUM(total_amount) DESC LIMIT 1)
ORDER BY sales_id ASC;

SELECT
product_name,
total_amount,
(SELECT AVG(total_amount)
FROM flourmills_sales) AS avg_amount
FROM flourmills_sales
WHERE total_amount = 9511208.41;

SELECT
product_name,
total_amount,
total_amount / (
SELECT SUM(total_amount)
FROM flourmills_sales) AS amount_share
FROM flourmills_sales;

SELECT monthly_sales
FROM (
SELECT
EXTRACT(MONTH FROM sale_date) AS month,
SUM(total_amount) AS monthly_sales
FROM flourmills_sales
GROUP BY EXTRACT(MONTH FROM sale_date)) AS monthly_summary
WHERE month = 8;

SELECT
product_category,
total_sales
FROM (
SELECT
product_category,
SUM(total_amount) AS total_sales
FROM flourmills_sales
GROUP BY product_category) AS category_sales
WHERE total_sales > 50000000
ORDER BY total_sales DESC;

SELECT COUNT(*)
FROM flourmills_sales AS s
WHERE s.total_amount > (
SELECT AVG(s2.total_amount)
FROM flourmills_sales AS s2
WHERE s2.product_category = s.product_category);

SELECT
s.product_name,
s.region,
s.total_amount, (
SELECT MIN(s2.total_amount)
FROM flourmills_sales AS s2
WHERE s2.region = s.region
) AS region_min_amount
FROM flourmills_sales AS s;

SELECT *
FROM flourmills_sales AS s
WHERE EXISTS (
SELECT 1
FROM flourmills_sales AS s2
WHERE s2.product_name = s.product_name
GROUP BY s2.product_name
HAVING COUNT(DISTINCT EXTRACT(MONTH FROM s2.sale_date)) > 1);

SELECT *
FROM flourmills_sales AS s
WHERE EXISTS (
SELECT 1
FROM flourmills_sales AS s2
WHERE s2.product_category = s.product_category
AND s2.total_amount > 200000);

SELECT DISTINCT s.product_category
FROM flourmills_sales AS s
WHERE EXISTS (
SELECT 1
FROM flourmills_sales AS s2
WHERE s2.product_category = s.product_category
GROUP BY s2.product_category
HAVING COUNT(DISTINCT s2.region) > 3);

SELECT *
FROM flourmills_sales AS s
WHERE EXISTS (
SELECT 1
FROM flourmills_sales AS s2
WHERE s2.region = s.region
AND EXTRACT(YEAR FROM s2.sale_date) = 2024);

SELECT COUNT(DISTINCT s.product_category)
FROM flourmills_sales AS s
WHERE NOT EXISTS (
SELECT 1
FROM flourmills_sales AS s2
WHERE s2.product_category = s.product_category
AND s2.total_amount > 500000);