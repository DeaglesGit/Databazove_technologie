-- Active: 1790414987768@@127.0.0.1@5432@superstore
-- Active: 1790414987768@@127.0.0.1@5432@superstore
-- Uloha 1
CREATE VIEW high_value_customers AS
SELECT c.customer_id,
       c.customer_name,
       SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.sales) > 2000;
 
SELECT *
FROM high_value_customers;
 
SELECT COUNT(*) FROM high_value_customers;
 
 
-- Uloha 2
CREATE VIEW regional_monthly_sales AS
SELECT c.region,
       DATE_TRUNC('month', o.order_date) AS month,
       SUM(o.sales) AS monthly_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region, DATE_TRUNC('month', o.order_date);
 
-- vysledok pre region West
SELECT *
FROM regional_monthly_sales
WHERE region = 'West'
ORDER BY month;
 
 
-- Uloha 3
CREATE VIEW analyst_orders AS
SELECT order_id,
       customer_id,
       product_id,
       sales,
       quantity,
       discount
FROM orders;
 
SELECT *
FROM analyst_orders;
 
 
-- Uloha 4
CREATE INDEX idx_orders_customer_id
ON orders(customer_id);
 
SELECT *
FROM orders
WHERE customer_id = 'C001';
 
 
-- Uloha 5
CREATE INDEX idx_orders_order_date
ON orders(order_date);
 
SELECT DATE_TRUNC('month', order_date) AS month,
       SUM(sales) AS total_sales
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month ASC;
 
 
-- Uloha 6
CREATE INDEX idx_orders_region_category
ON orders(customer_id, order_date);
 
SELECT o.order_id,
       o.customer_id,
       c.customer_name,
       c.region,
       o.order_date,
       o.sales,
       o.profit
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE c.region = 'West'
AND o.order_date >= '2024-01-01';
 


-- Uloha 7
EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 'C001';
 
 
-- Uloha 9
CREATE OR REPLACE PROCEDURE apply_regional_discount(region_name VARCHAR, discount_rate FLOAT)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE orders o
    SET sales = o.sales * (1 - discount_rate)
    FROM customers c
    WHERE o.customer_id = c.customer_id
      AND c.region = region_name;
 
    RAISE NOTICE 'Zlava % bola aplikovana na region %', discount_rate, region_name;
END;
$$;
 
CALL apply_regional_discount('West', 0.10);

-- DATABAZA retail_sales 
 
CREATE DATABASE retail_sales;
 
ALTER DATABASE retail_sales SET datestyle TO 'ISO, MDY';
 
CREATE TABLE orders (
    order_id    VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    product_id  VARCHAR(20) NOT NULL,
    order_date  DATE NOT NULL,
    region      VARCHAR(20) NOT NULL,
    category    VARCHAR(50) NOT NULL,
    ship_mode   VARCHAR(30) NOT NULL,
    sales       NUMERIC(12,2) NOT NULL,
    profit      NUMERIC(12,2) NOT NULL
);

 
SELECT *
FROM orders;
 
 
-- Uloha 8
CREATE OR REPLACE PROCEDURE get_customer_sales(p_customer_id VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT SUM(sales) INTO total
    FROM orders
    WHERE customer_id = p_customer_id;
    RAISE NOTICE 'Zakaznik: %, celkovy predaj: %', p_customer_id, total;
END;
$$;
 
CALL get_customer_sales('C001');

 
-- Uloha 10
CREATE OR REPLACE PROCEDURE get_sales_between(start_date DATE, end_date DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    total NUMERIC;
BEGIN
    SELECT SUM(sales) INTO total
    FROM orders
    WHERE order_date BETWEEN start_date AND end_date;
    RAISE NOTICE 'Od: %, do: %, celkovy predaj: %', start_date, end_date, total;
END;
$$;

CALL get_sales_between('2024-01-01', '2024-03-31');