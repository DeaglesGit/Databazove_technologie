-- Active: 1790414987768@@127.0.0.1@5432@datacraftinglab_db
SELECT * FROM flourmills_sales;

-- Uloha 1
WITH daily_sales AS (
    SELECT sale_date,
           SUM(total_amount) AS total_daily_sales
    FROM flourmills_sales
    GROUP BY sale_date)
SELECT sale_date,
       total_daily_sales
FROM daily_sales
WHERE total_daily_sales > 3000000
ORDER BY total_daily_sales DESC;

-- Uloha 2
WITH category_sales AS (
    SELECT product_category,
           SUM(total_amount) AS total_sales
    FROM flourmills_sales
    GROUP BY product_category)
SELECT product_category,
       total_sales
FROM category_sales
ORDER BY total_sales DESC;

-- Uloha 3
WITH product_sales AS (
    SELECT product_category,
           product_name,
           SUM(total_amount) AS total_product_sales
    FROM flourmills_sales
    GROUP BY product_category, product_name),
ranked_products AS (
    SELECT product_category,
           product_name,
           total_product_sales,
           RANK() OVER (
               PARTITION BY product_category
               ORDER BY total_product_sales DESC
           ) AS category_rank
    FROM product_sales)
SELECT product_category,
       product_name,
       total_product_sales,
       category_rank
FROM ranked_products
WHERE category_rank <= 3
ORDER BY product_category, category_rank;

-- Uloha 4
WITH customer_revenue AS (
    SELECT customer_type,
           SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY customer_type),
revenue_share AS (
    SELECT customer_type,
           revenue,
           SUM(revenue) OVER () AS total_revenue,
           ROUND((revenue * 100.0 / SUM(revenue) OVER ())::numeric, 2) AS revenue_percentage
    FROM customer_revenue)
SELECT customer_type,
       revenue,
       total_revenue,
       revenue_percentage
FROM revenue_share
ORDER BY revenue DESC;

-- Uloha 5
WITH customer_purchases AS (
    SELECT customer_id,
           product_name,
           sale_date,
           total_amount,
           ROW_NUMBER() OVER (
               PARTITION BY customer_id
               ORDER BY sale_date DESC
           ) AS rn
    FROM flourmills_sales)
SELECT customer_id,
       product_name,
       sale_date,
       total_amount
FROM customer_purchases
WHERE rn = 1
ORDER BY customer_id ASC;

-- Uloha 6
WITH RECURSIVE date_range AS (
    SELECT MIN(sale_date) AS start_date,
           MAX(sale_date) AS end_date
    FROM flourmills_sales),
calendar AS (
    SELECT start_date::date AS calendar_date,
           end_date::date AS end_date
    FROM date_range 
    UNION ALL 
    SELECT (calendar_date + INTERVAL '1 day')::date,
           end_date
    FROM calendar
    WHERE calendar_date < end_date)
SELECT calendar_date
FROM calendar
ORDER BY calendar_date ASC;
 
-- pocet riadkov (pocet dni v kalendari):
WITH RECURSIVE date_range AS (
    SELECT MIN(sale_date) AS start_date,
           MAX(sale_date) AS end_date
    FROM flourmills_sales),
calendar AS (
    SELECT start_date::date AS calendar_date,
           end_date::date AS end_date
    FROM date_range
 
    UNION ALL
 
    SELECT (calendar_date + INTERVAL '1 day')::date,
           end_date
    FROM calendar
    WHERE calendar_date < end_date)
SELECT COUNT(*) AS pocet_dni
FROM calendar;

-- Uloha 7
WITH RECURSIVE monthly_sales AS (
    -- krok 1: mesacny predaj
    SELECT DATE_TRUNC('month', sale_date) AS month,
           SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY DATE_TRUNC('month', sale_date)),
numbered_months AS (
    -- krok 2: ocislovanie mesiacov
    SELECT month,
           revenue,
           ROW_NUMBER() OVER (ORDER BY month) AS rn
    FROM monthly_sales),
cumulative_sales AS (
    -- krok 3: rekurzivny kumulativny sucet
    SELECT month,
           revenue,
           rn,
           revenue AS cumulative_revenue
    FROM numbered_months
    WHERE rn = 1
 
    UNION ALL
 
    SELECT n.month,
           n.revenue,
           n.rn,
           c.cumulative_revenue + n.revenue
    FROM cumulative_sales c
    JOIN numbered_months n ON n.rn = c.rn + 1)
SELECT month,
       cumulative_revenue
FROM cumulative_sales
WHERE cumulative_revenue >= 500000000
ORDER BY month
LIMIT 1;