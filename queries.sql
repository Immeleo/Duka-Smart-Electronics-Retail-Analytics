
/*## 7. Business rules — 
Most mistakes in this project come from skipping this section.
| Measure | Formula |
|---|---|
| **Revenue** | `quantity * unit_price * (1 - discount / 100)` |
| **Cost** | `quantity * cost_price` |
| **Profit** | `revenue - cost` |
| **Profit margin %** | `profit / NULLIF(revenue,0) * 100` — use `NULLIF(revenue, 0)` so you never divide by zero |

Note:
1. **Money questions use Completed orders only.** Revenue, cost, profit, spending and averages count
   only `order_status = 'Completed'`, unless a question says otherwise. Pending orders are not paid
   yet; cancelled ones never will be.
2. **Order counts include every order**, whatever its status ("how many orders" means all of them).
3. **Customer counts count distinct customers.**
4. **"Today" is the latest `order_date` in the data**, not your computer's date — so everyone gets the
   same answer. Get it with `SELECT MAX(order_date) FROM orders`.
5. **Months** mean year *and* month — January 2025 and January 2026 are different months. Use
   `DATE_TRUNC('month', order_date)`.
6. Round money to 2 decimal places with `ROUND(…, 2)`.
***/

--### Section A — SQL fundamentals (Q1–Q10)
--*Concepts:* `SELECT`, `WHERE`, `DISTINCT`, `ORDER BY`, `LIMIT`, `LIKE`, `BETWEEN`
--Q1. Retrieve all customer records.
Select * from customers;

--Q2. Display customer names, cities, and segments.
Select customer_name, city,customer_segment
from customers;

--Q3. Find customers living in Nairobi.
select * from customers
where city = 'Nairobi';

--Q4. Find customers registered after January 1, 2025.
select *  from customers
where registration_date > '2025-01-01';

--Q5. Display all unique customer cities.
select distinct city
from customers;

--Q6. Retrieve the 10 most recent orders.
select * from orders
order by order_date desc
limit 10;

--Q7. Find orders with unit prices above KSh 10,000.
select * from orders
where unit_price > 10000;

--Q8. Find customers whose names start with A.
select * from customers
where customer_name Like 'A%';

---Q9. Retrieve orders with quantities between 2 and 5.
select * from orders
where quantity between 2 and 5;

--Q10. Find orders paid through M-Pesa.
select * from orders
where payment_method = 'M-Pesa';


--### Section B — Aggregation and grouping (Q11–Q20)
--*Concepts:* `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, `HAVING`, `ROUND`
--SELECT group_column, SUM(...) AS total
--FROM table WHERE row_condition
--GROUP BY group_column
--HAVING SUM(...) > 1000;      -- HAVING filters groups; WHERE filters rows

--Q11. Count all customers.
select count(*) as no_of_customers
from customers;

--Q12. Count all orders.
select count(*) as total_orders
from orders;

--Q13. Calculate completed-order revenue.--Revenue = quantity * unit_price * (1 - discount / 100)` 
select round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue
from orders
where order_status = 'Completed';

--Q14. Calculate the average completed-order value.
select round(avg(quantity*unit_price*(1-discount/100.0)),2) as avg_completed_order_value
from orders
where order_status = 'Completed';

--Q15. Find the highest and lowest product prices.
select max(unit_price) as highest_prod_price,
		min(unit_price) as lowest_prod_price 
from orders;

--Q16. Calculate revenue by product category.
select product_category,
	round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue_per_category
from orders
where order_status = 'Completed'
group by product_category;

--Q17. Count customers by city.
select city, count(distinct customer_id) as no_of_customers
from customers
group by city;

--Q18. Calculate quantity sold by product.
select product_name,sum(quantity) as total_prod_sold
from orders
where order_status = 'Completed'
group by product_name;

--Q19. Find categories generating more than KSh 100,000 in revenue.
select product_category,
	round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue_per_category
from orders
where order_status = 'Completed'
group by product_category
having round(sum(quantity*unit_price*(1-discount/100.0)),2) > 100000;

--Q20. Calculate the percentage of cancelled orders.--using 100.0 tells postgres we are working with floating_point division
select round(100.0* 
		count(*) FILTER (where order_status = 'Cancelled')/
		count(*),
		2) as pct_cancelled
from orders;

--### Section C — Joins and customer analytics (Q21–Q28)
--*Concepts:* `INNER JOIN`, `LEFT JOIN`, `GROUP BY`, `HAVING`
--SELECT c.customer_name, o.order_id
--FROM customers c
--JOIN orders o ON o.customer_id = c.customer_id;      -- only customers WITH orders
-- LEFT JOIN keeps every customer; those without orders get NULLs on the orders side

--Q21. Display orders with customer names and cities.
select o.order_id,o.order_date,o.order_status,c.customer_name,c.city
from orders o
join customers c on o.customer_id = c.customer_id;

--Q22. Calculate total spending by customer.
select c.customer_name,c.customer_id,
	round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as total_spending
from orders o
join customers c using(customer_id)
where order_status = 'Completed'
group by c.customer_name,c.customer_id;

--Q23. Identify customers who have never ordered.
select c.* 
from customers c
left join orders o using(customer_id)
where order_id is null
order by city;

--Q24. Find the 10 highest-spending customers.
select c.customer_name,c.customer_id,
	round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as total_spending
from orders o
join customers c using(customer_id)
where order_status = 'Completed'
group by c.customer_name,c.customer_id
order by total_spending DESC
limit 10;

--Q25. Calculate revenue by customer city.
select c.city,
	round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as revenue_by_city
from orders o
join customers c using(customer_id)
where order_status = 'Completed'
group by c.city
order by revenue_by_city Desc;

--Q26. Identify customers with more than five orders.
select c.*, count(order_id) as no_of_orders
from customers c
join orders o using(customer_id)
group by c.customer_name,c.customer_id
having count(order_id) > 5
order by no_of_orders DESC;

/*Q27. Calculate average customer spending by segment.Tip: first find each customer's total, then average those totals per segment. Say in a
comment how you defined it. I have subquery concept to achieve this.
*/
select customer_segment, 
		round(avg(total_spending),2) as avg_expenditure_by_segment
from (select c.customer_name,
	c.customer_segment,
	round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as total_spending
	from orders o
	join customers c using(customer_id)
	where order_status = 'Completed'
	group by c.customer_name,c.customer_segment
	) as customer_totals
group by customer_segment
order by avg_expenditure_by_segment Desc;

--Q28. Identify the most popular category among VIP customers.
select o.product_category,count(o.order_id) as total_orders
from orders o
join customers c using(customer_id)
where c.customer_segment = 'VIP'
group by o.product_category
order by total_orders DESC
limit 1;

/*
### Section D — Subqueries and CTEs (Q29–Q34)
*Concepts:* subqueries, `WITH` (CTEs), nested aggregation
```sql
WITH step_one AS (
    SELECT customer_id, SUM(...) AS total FROM orders GROUP BY customer_id
)
SELECT * FROM step_one WHERE total > (SELECT AVG(total) FROM step_one);
```
*Tip for Q32:* `COUNT(DISTINCT product_category)`. *Q34:* subtracting dates gives a number of days:
`DATE '2026-09-30' - DATE '2026-09-01'` is `29`
*/

--Q29. Find customers spending above the average total spending per purchasing customer.
with customer_totals AS(
	select
		c.customer_name,c.customer_id,
		round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as total_spending
	from orders o
	join customers c using(customer_id)
	where order_status = 'Completed'
	group by c.customer_name,c.customer_id
)
select customer_name,customer_id,
		total_spending
from customer_totals
where total_spending > (select avg(total_spending) from customer_totals)
order by total_spending DESC;

--Q30. Find products priced above the overall average unit price.
select product_name,product_category,unit_price
from orders
where unit_price > (
			select avg(unit_price) as avg_unit_price
			from orders
);

--Q31. Use a CTE to identify the three highest-revenue months.
with revenue_each_month as (
	select 
		to_char(order_date, 'YYYY-MM') as months, 
		round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue
	from orders 
	where order_status = 'Completed'
	group by months
)
select months, revenue
from revenue_each_month
order by revenue desc
limit 3;

--Q32. Find customers purchasing from at least three categories.
with customer_category_count as(
	select c.customer_id,c.customer_name, 
	count(distinct o.product_category) as no_of_categories
	from customers c
	join orders o using(customer_id)
	group by c.customer_id,c.customer_name
)
select 
	customer_id,customer_name, no_of_categories
	from customer_category_count
	where no_of_categories >=3
;

--Q33. Use a CTE to calculate category revenue, cost, profit, and profit margin.
-- Revenue = quantity * unit_price * (1 - discount / 100)
-- Cost = quantity * cost_price
-- Profit = revenue - cost
-- Profit margin % =  profit / NULLIF(revenue,0) * 100.0 — use `NULLIF(revenue, 0)` so you never divide by zero 
with category_financials as (
	select product_category,
			sum(quantity*unit_price*(1-discount/100.0)) as revenue,
			sum(quantity*cost_price) as total_cost
	from orders
	where order_status = 'Completed'
	group by product_category
)
select
	product_category,
	round(revenue,2) as revenue,
	round(total_cost, 2) as total_cost,
	round(revenue-total_cost,2) as profit,
	round((revenue-total_cost)/NULLIF(revenue,0)*100.0,2) as profit_margin
from category_financials;

--Q34. Find customers whose LATEST COMPLETED ORDER is more than 90 days before the LATEST ORDER DATE in the dataset.
with customer_latest_order as (
	select c.customer_id,
		c.customer_name,
		Max(o.order_date) as latest_order_date
from customers c
join orders o using(customer_id)
where order_status = 'Completed'
group by c.customer_id,c.customer_name
),
dataset_latest_order AS(
	select 
		max(o.order_date) as max_dataset_date
	from orders o
)
select cl.customer_id,
		cl.customer_name,
		cl.latest_order_date, 
		(dl.max_dataset_date - cl.latest_order_date) AS days_since_last_order
from customer_latest_order cl
CROSS JOIN dataset_latest_order dl 
where (dl.max_dataset_date - cl.latest_order_date) > 90
order by days_since_last_order desc; 

/*### Section E — Window functions (Q35–Q42)

Concepts: OVER, PARTITION BY,ROW_NUMBER, RANK, DENSE_RANK, LAG, NTILE

```sql
SELECT customer_id, order_date,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS n
FROM orders;
-- RANK leaves gaps after ties (1,1,3); DENSE_RANK does not (1,1,2)
-- running total:  SUM(x) OVER (ORDER BY month)
-- previous row:   LAG(x) OVER (ORDER BY month)
```
Tip: for monthly questions, build a `monthly` CTE (month, revenue) first, then apply the window
function to it. *Q42:* `SUM(SUM(x)) OVER ()` is the grand total next to each group.
*/

--Q35. Rank customers by spending using `RANK()`.
select c.customer_id,c.customer_name,
		round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2)as total_expenditure,
		rank() over(order by sum(o.quantity*o.unit_price*(1-o.discount/100.0)) desc) as spending_rank
from customers c
join orders o using(customer_id)
where o.order_status = 'Completed'
group by c.customer_id,c.customer_name;

--Q36. Number each customer's orders by recency using `ROW_NUMBER()`.
select c.customer_id, 
		c.customer_name,
		o.order_id,
		o.product_name,
		o.order_date,
		row_number() over(partition by customer_id order by order_date DESC) as rank_by_recency
from customers c
join orders o using(customer_id)
where o.order_status = 'Completed';

--Q37. Rank products within categories using `DENSE_RANK()`
select product_category,
		product_name,
		dense_rank() over(partition by product_category order by product_name ASC) as category_rank
from orders
group by product_category, product_name;

--Q38. Calculate cumulative monthly revenue.
with monthly_revenue as (
	select 
		to_char(order_date, 'YYYY-MM') as order_month,
		round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue
	from orders
	WHERE order_status = 'Completed'
	group by order_month
)
select 
	order_month,
	sum(revenue) over(order by order_month asc) as cumulative_monthly_revenue
from monthly_revenue;

--Q39. Compare monthly revenue using `LAG()`.
with monthly_revenue as (
	select 
		to_char(order_date, 'YYYY-MM') as order_month,
		round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue
	from orders
	WHERE order_status = 'Completed'
	group by order_month
)
select order_month,
		revenue as current_revenue,
		LAG(revenue, 1) OVER (ORDER BY order_month) as previous_month,
from monthly_revenue;
--Q40. Calculate month-over-month revenue growth (%).
with monthly_revenue as (
	select 
		to_char(order_date, 'YYYY-MM') as order_month,
		round(sum(quantity*unit_price*(1-discount/100.0)),2) as revenue
	from orders
	WHERE order_status = 'Completed'
	group by order_month
)
select order_month,
		revenue as current_revenue,
		LAG(revenue, 1) OVER (ORDER BY order_month) as previous_month,
		(revenue - LAG(revenue, 1) OVER (ORDER BY order_month)) as revenue_difference,
		round((revenue - LAG(revenue, 1) OVER (ORDER BY order_month)) / 
			NULLIF(LAG(revenue, 1) OVER (ORDER BY order_month), 0)
			* 100.0
			,2) AS month_growth_pct
from monthly_revenue;

--Q41. Divide customers into four spending groups using `NTILE(4)`.
with customer_spending as(
	select c.customer_name,
		c.customer_id,
		round(sum(o.quantity*o.unit_price*(1-o.discount/100.0)),2) as total_spent
	from orders o
	join customers c using(customer_id)
	where order_status = 'Completed'
	group by c.customer_name,c.customer_id
)
select 
	customer_name,
	customer_id,
	total_spent,
	NTILE(4) OVER (ORDER BY total_spent DESC) AS spending_group
from customer_spending

--Q42. Calculate each category's share of total revenue using window functions.
--SUM(SUM(x)) OVER () is the grand total next to each group.
with category_revenue as (
	select product_category,
		sum(quantity*unit_price*(1-discount/100.0)) as revenue_per_category
	from orders
	where order_status = 'Completed'
	group by product_category
)
select 
	product_category,
	round(revenue_per_category,2) as category_revenue,
	sum(round(revenue_per_category,2)) over() as grant_total,
	round(100.0*revenue_per_category/
		sum(revenue_per_category) over(),
		2) as share_of_total
from category_revenue;

/*### Section F — Advanced business intelligence (Q43–Q46)
Concepts: views, PL/pgSQL functions, CASE, reporting queries
```sql
CREATE OR REPLACE VIEW my_view AS SELECT ...;
CREATE OR REPLACE FUNCTION my_function(p_id INTEGER)
RETURNS NUMERIC LANGUAGE plpgsql AS $$
DECLARE v_result NUMERIC;
BEGIN
    SELECT ... INTO v_result FROM ... WHERE id = p_id;
    RETURN v_result;
END;
$$;
SELECT CASE WHEN x >= 100 THEN 'High' WHEN x >= 50 THEN 'Medium' ELSE 'Low' END ...
```
*/

--Q43. Create a `monthly_sales_summary` view (month, orders, revenue, cost, profit). Then `SELECT` from it.
create or replace view monthly_sales_summary as 
	with category_financials as (
		select product_category,
				count(order_id) as total_orders,
				to_char(order_date,'yyyy-mm') as year_month,
				sum(quantity*unit_price*(1-discount/100.0)) as revenue,
				sum(quantity*cost_price) as total_cost
		from orders
		where order_status = 'Completed'
		group by product_category,year_month
	)
	select
		product_category,
		year_month,
		total_orders,
		round(revenue,2) as revenue,
		round(total_cost, 2) as total_cost,
		round(revenue-total_cost,2) as profit,
		round((revenue-total_cost)/NULLIF(revenue,0)*100.0,2) as profit_margin
	from category_financials
;

--Selecting from the summary view
select * 
from monthly_sales_summary;

/*
Q44. Create a PostgreSQL function that returns completed-order revenue for a supplied customer ID. Show
    it working for one customer **and** for an ID that does not exist (it should return 0, not NULL).
*/
create or replace function get_customer_revenue(p_customer_id int)
returns numeric 
language sql
as $$
select 
    coalesce(
        sum(quantity * unit_price * (1 - discount / 100.0)), 
        0.00
    )
from orders
where customer_id = p_customer_id
  and order_status = 'Completed';
$$;

-- using the function
SELECT get_customer_revenue(100) AS revenue;


/*
Q45. Segment customers into High, Medium and Low Value. **Explain why you chose your thresholds** — for
    example percentiles, or round KSh amounts based on what the data looks like.
*/
-- Step 1: Calculate total completed revenue per customer
with customer_revenue as (
    select 
        customer_id,
        sum(quantity * unit_price * (1 - discount / 100.0)) as total_spent
    from orders
    where order_status = 'Completed'
    group by customer_id
),
-- step 2: assign customers into 3 equal-sized tiers
tiered_customers as (
    select 
        customer_id,
        total_spent,
        ntile(3) over (order by total_spent desc) as tier_rank
    from customer_revenue
)
-- step 3: map tier numbers to clear business labels
select 
    customer_id,
    round(total_spent, 2) as total_spent,
    case tier_rank
        when 1 then 'High Value (VIP)'
        when 2 then 'Medium Value'
        when 3 then 'Low Value'
    end as value_segment
from tiered_customers
order by total_spent desc;

/*
46. Produce a management report: the top five customers, top five products, the most profitable
    category, and the lowest-revenue month.
*/
--the top five customers
select c.customer_name,
	   c.customer_id,
        round(sum(o.quantity * o.unit_price * (1 - o.discount / 100.0)),2) as total_spent
from orders o
join customers c using(customer_id)
where order_status = 'Completed'
group by c.customer_name,c.customer_id
order by total_spent Desc
limit 5;
	
--top five products
select product_name,
        round(sum(quantity * unit_price * (1 - discount / 100.0)),2) as total_revenue
from orders
where order_status = 'Completed'
group by product_name
order by total_revenue Desc
limit 5;

--the most profitable category (Cost = quantity * cost_price|| Profit = revenue - cost|)
select product_category,
		sum(quantity*cost_price) as prod_cost,
        round(sum(quantity * unit_price * (1 - discount / 100.0)),2) as total_revenue,
		round(sum(quantity * unit_price * (1 - discount / 100.0))-sum(quantity*cost_price),2) as profit
from orders
where order_status = 'Completed'
group by product_category
order by profit Desc
limit 1;

--the lowest-revenue month
select to_char(order_date,'yyyy-mm') as revenue_month,
        round(sum(quantity * unit_price * (1 - discount / 100.0)),2) as total_revenue
from orders
where order_status = 'Completed'
group by revenue_month
order by total_revenue asc
limit 1;
