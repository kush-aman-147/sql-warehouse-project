/*
===============================================================================
Customer Report
===============================================================================

Purpose:
    - This report consolidates key customer metrics and behaviors

Highlights:
    1. Gathers essential fields such as names, ages, and transaction details.
    2. Segments customers into categories (VIP, Regular, New) and age groups.
    3. Aggregates customer-level metrics:
        - total orders
        - total sales
        - total quantity purchased
        - total products
        - lifespan (in months)
    4. Calculates valuable KPIs:
        - recency (months since last order)
        - average order value
        - average monthly spend
===============================================================================
*/

-- 1.) Basic Query : Retrive all core columns from table

Create View gold.report_customers as
with base_query as(
select 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
concat(c.first_name,' ',c.last_name)as customer_name,
c.customer_key,
c.customer_number,
(
  EXTRACT(year from AGE(current_date,c.birthdate)) 
)as age
from gold.fact_sales f
left join gold.dim_customers c
on f.customer_key = c.customer_key
where order_date is not null)
,
customer_aggrigation as (
-- 2.) Customer Aggrigation: Summerize key matrics at the customer level

select 
customer_key,
customer_number,
customer_name,
age,
count (DISTINCT order_number) as total_order,
sum( sales_amount) as total_sales,
sum(quantity) as total_quantity,
count(DISTINCT product_key) as total_product,
max(order_date) as last_order_date,
(
    (EXTRACT(YEAR FROM MAX(order_date)) -
     EXTRACT(YEAR FROM MIN(order_date))) * 12
    +
    (EXTRACT(MONTH FROM MAX(order_date)) -
     EXTRACT(MONTH FROM MIN(order_date)))
) AS life_span_month
from base_query
group by customer_key,
customer_number,
customer_name,
age)

select 
customer_key,
customer_number,
customer_name,
case 
     when age < 20 then 'Under 20'
	 when age between 20 and 29 then '20-29'
	 when age between 30 and 39 then '30-39'
	 when age between 40 and 49 then '40-49'
	 else '50 above'
end age_group,	 
case 
     when life_span_month >= 12 and total_sales > 5000 then 'VIP'
     when life_span_month >= 12 and total_sales <= 5000 then 'Regular'
      else 'New'
end cust_segmt,
last_order_date,
(CURRENT_DATE - last_order_date) AS recency_days,
  total_order,
  total_sales,
  total_quantity,
  total_product,
 life_span_month,
 -- Average order_value = total_sales / total_order
 case when total_order = 0 then 0
 else total_sales / total_order
 end as Avg_Order_value,

 --compute average_monthly_spend
 case 
      when life_span_month = 0 then total_sales
	  else round(total_sales / life_span_month,2)
end as Avg_monthly_spend	  
 from customer_aggrigation 

 select * from gold.report_customers
