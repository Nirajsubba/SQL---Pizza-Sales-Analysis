create database CrustPizza;
use CrustPizza;

create table pizza_type(
pizza_type_id varchar(255) Primary Key,
name varchar(255),
category varchar(255),
ingredients varchar(255)
);

create table orders(
order_id varchar(255)  Primary Key,
order_date varchar(255),
order_time varchar(255)
);

create table pizzas(
pizza_id varchar(255) primary key,
pizza_type_id varchar (255),
size varchar(255),
price varchar(255),
foreign key (pizza_type_id) references pizza_type(pizza_type_id)
);

create table order_detail(
order_details_id varchar(255) primary key,
order_id varchar(255),
pizza_id varchar(255),
quantity varchar(255),
foreign key (order_id) references orders(order_id),
foreign key (pizza_id) references pizzas(pizza_id)
);


-- clean the data (type casting)

-- convert price to decimal
 alter table crustpizza.pizzas
 modify price decimal(10,2);

-- convert qunatity to Integer

alter table crustpizza.order_detail
modify quantity int unsigned;

-- convert order date


 -- convert order id
alter table crustpizza.orders
modify order_id int unsigned;

-- convert order_details id
alter table crustpizza.order_detail
modify order_details_id int unsigned;

-- convert order_details_id
alter table crustpizza.order_detail
modify order_id int unsigned;

-- 1. Retrieve the total number of orders placed.

select count(o1.order_id) as total_order_placed
from crustpizza.orders o1;

-- 2. Calculate the total revenue generated from pizza sales.

select sum(p1.price * d1.quantity) as total_revenue
from crustpizza.pizzas p1
join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id;


-- 3. Identify the highest-priced pizza.

select p2.name, p1.size, p1.price
from crustpizza.pizzas p1
inner join crustpizza.pizza_type p2
on p1.pizza_type_id = p2.pizza_type_id
where price = (select max(p3.price)
from crustpizza.pizzas p3
);

-- 4. Identify the most common pizza size ordered.

select p1.size, count(*) as total_orders
from crustpizza.pizzas p1
inner join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id
group by p1.size
order by total_orders desc
limit 1;

-- 5. List the top 5 most ordered pizza types along with their quantities.

select t1.name, sum(d1.quantity) as total_order
from crustpizza.pizza_type t1
join crustpizza.pizzas p1
on p1.pizza_type_id = t1.pizza_type_id
join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id
group by t1.name
order by total_order desc
limit 5;

-- 6. Determine the distribution of orders by hour of the day.

select hour(o1.order_time) as order_hour,
count(*) as total_orders
from crustpizza.orders o1
group by order_hour
order by order_hour;


-- 7. calculate the average number of pizzas ordered per day.

select round(avg(x.total_pizzas))  as Average_pizza_per_day
from
(select str_to_date(o1.order_date, '%Y-%c-%e') as Order_date, sum(d1.quantity) as total_pizzas
from crustpizza.orders o1
inner join crustpizza.order_detail d1
on d1.order_id = o1.order_id
group by str_to_date(o1.order_date, '%Y-%c-%e')) x;


-- 8. Determine the top 3 most ordered pizza types based on revenue.

select pt1.pizza_type_id, pt1.name, round(sum(p1.price * d1.quantity))  as total_revenue
from crustpizza.pizza_type pt1
inner join crustpizza.pizzas p1
on pt1.pizza_type_id = p1.pizza_type_id
inner join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id
group by pt1.pizza_type_id
order by total_revenue desc
limit 3;

-- 9. Calculate the percentage contribution of each pizza type to total revenue.

with total_revenue as (
select sum(p1.price * d1.quantity) as total
from crustpizza.pizzas p1
inner join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id
),

individual_revenue as (
select pt1.pizza_type_id,pt1.name, sum(p1.price * d1.quantity) as total
from crustpizza.pizza_type pt1
inner join crustpizza.pizzas p1
on pt1.pizza_type_id = p1.pizza_type_id
inner join crustpizza.order_detail d1
on d1.pizza_id = p1.pizza_id
group by pt1.pizza_type_id,pt1.name
)

select ir.pizza_type_id, ir.name,
ir.total,
round(ir.total / tr.total * 100, 2) as percentage_contribution
from total_revenue tr
cross join individual_revenue ir
order by percentage_contribution desc;


-- 10. Analyze the cumulative revenue generated over time.

with daily_revenue as (
  select 
    STR_TO_DATE(o.order_date, '%Y-%c-%e') as order_date,
    ROUND(SUM(p.price * d.quantity), 2) as daily_revenue
  from crustpizza.orders o
  inner join crustpizza.order_detail d 
  on d.order_id = o.order_id
  inner join crustpizza.pizzas p 
  on p.pizza_id = d.pizza_id
  group by STR_TO_DATE(o.order_date, '%Y-%c-%e')
  )
  
  select order_date, daily_revenue ,
  sum(daily_revenue) over(order by order_date) as cumulative_revenue
  from daily_revenue
  order by order_date;


-- 11. Determine the top 3 most ordered pizza types based on revenue for each pizza category.

with pizza_revenue as (
  select 
    pt.category,
    pt.name as pizza_name,
    pt.pizza_type_id,
    sum(p.price * d.quantity) as revenue
  from crustpizza.pizza_type pt
  join crustpizza.pizzas p on pt.pizza_type_id = p.pizza_type_id
  join crustpizza.order_detail d on d.pizza_id = p.pizza_id
  group by pt.category, pt.pizza_type_id, pt.name
),
ranked_pizzas as (
  select *,
    rank() over (partition by category order by revenue desc) AS rank_in_category
  from pizza_revenue
)

select 
  category,
  pizza_name,
  revenue
from ranked_pizzas
where rank_in_category <= 3
order by category, revenue desc;
