-- Active: 1790414987768@@127.0.0.1@5432@superstore
Create DATABASE superstore;
CREATE Table customers(
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50)
);
CREATE TABLE products(
    product_id VARCHAR(20) PRIMARY KEY,
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(100)
);
CREATE TABLE orders(
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) REFERENCES customers(customer_id),
    product_id VARCHAR(20) REFERENCES products(product_id),
    order_date DATE,
    ship_date DATE,
    sales FLOAT,
    quantity INT,
    discount FLOAT,
    profit FLOAT
);

SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM orders;


SELECT o.order_id, c.customer_name, o.sales
FROM orders o
JOIN customers c
ON o.customer_id = c.customer_id
WHERE o.sales > 500
ORDER BY o.sales DESC;

SELECT o.order_id, c.customer_name, p.category, o.sales
FROM orders o
INNER JOIN customers c
ON o.customer_id = c.customer_id
INNER JOIN products p
ON o.product_id = p.product_id;

SELECT c.region, SUM(o.sales) AS total_sales
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT p.product_name, COALESCE(SUM(o.sales), 0) AS total_sales
FROM products p
LEFT JOIN orders o
ON p.product_id = o.product_id
GROUP BY p.product_name;

SELECT c.customer_name, o.order_id, o.sales
FROM customers c
FULL OUTER JOIN orders o
ON c.customer_id = o.customer_id;

SELECT c.region, SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT c.customer_name, COUNT(o.order_id) AS order_count
FROM customers c
LEFT JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

SELECT p.category, AVG(o.discount) AS average_discount
FROM products p
JOIN orders o
ON p.product_id = o.product_id
GROUP BY p.category;

SELECT c.customer_name, SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING SUM(o.sales) > 2000;