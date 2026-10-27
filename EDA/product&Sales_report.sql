

with base_query as(
select 
p.product_key,
p.product_name,
p.category,
p.subcategory,
p.cost,
f.customer_key,
f.order_number,
f.order_date,
f.sales_amount,
f.quantity
from gold.dim_products p
left join gold.fact_sales f
on p.product_key = f.product_key
where f.order_date is not null
),

product_aggrigation as(
select 
product_key,
product_name,
category,
subcategory,
cost,
count(distinct customer_key) as total_customer,
count (distinct order_number) as total_orders,
sum(sales_amount) as total_sales,
sum(quantity) as total_quantity,
max(order_date) as last_order_date,
(
(extract (year from max(order_date)) - extract (year from min(order_date))) * 12
+ (extract (month from max(order_date)) - extract (month from min(order_date)))
) as life_span,
SUM(sales_amount) / NULLIF(SUM(quantity), 0)
    AS avg_selling_price
from base_query
group by product_key,
product_name,
category,
subcategory,
cost
)

select 
product_key,
product_name,
category,
subcategory,
cost,
last_order_date,
(
    (EXTRACT(YEAR FROM CURRENT_DATE)
     - EXTRACT(YEAR FROM last_order_date)) * 12
    +
    (EXTRACT(MONTH FROM CURRENT_DATE)
     - EXTRACT(MONTH FROM last_order_date))
) AS recency_month,
case 
     when total_sales > 50000 then 'High-Performer'
     when total_sales >= 50000 then 'Mid-range'
     else 'Low-Performer'
end as product_segment,
life_span,
total_orders,
total_quantity,
total_sales,
avg_selling_price,

-- Average Order Revenue(AOR)
case when total_orders = 0 then 0
   else total_sales / total_orders
   end as avg_order_revenue,

--Average Monthly Revenue 
case when life_span = 0 then total_sales
     else round(total_sales / life_span,2)
	 end as avg_monthly_revenue
   
from product_aggrigation

