/*
===============================================================================
Change Over Time Analysis
===============================================================================
Purpose:
    - To track trends, growth, and changes in key metrics over time.
    - For time-series analysis and identifying seasonality.
    - To measure growth or decline over specific periods.

 
===============================================================================
*/
-- Analyse sales performance over time
-- Quick Date Functions

SELECT
    EXTRACT(YEAR FROM order_date) AS order_year,
    SUM(sales_amount) AS total_sales,
    COUNT(DISTINCT customer_key) AS total_customer,
    SUM(quantity) AS total_quantity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY EXTRACT(YEAR FROM order_date)
ORDER BY order_year;

--Calculate the toatal sales per month and running total of sales over the time

select 
order_date,
total_sales,
sum(total_sales) over (order by order_date) as running_total_sales,
round(avg(avg_price) over (order by order_date),1) as avg_running_price
from(
SELECT
    TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS order_date,
	SUM(sales_amount) AS total_sales,
    avg(price) as avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM')
ORDER BY order_date) t
