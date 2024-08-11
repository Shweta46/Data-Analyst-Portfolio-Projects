create table if not exists sales(
invoice_id varchar(30) not null primary key,
branch varchar(5) not null,
city varchar(30) not null,
customer_type varchar(30) not null,
gender varchar(10) not null,
product_line varchar(100) not null,
unit_price decimal(10, 2) not null,
quantity int not null,
VAT float(6, 4) not null,
total decimal(12, 4) not null,
date datetime not null,
time TIME not null,
payment_method varchar(10) not null,
cogs decimal(10, 2) not null,
gross_margin_pct float(11, 9),
gross_income decimal(12, 2) not null,
rating float(2, 1)
);

-- To make sure that no data is null data, we automatically took "not null" as a criteria in the parameters. 
-- So, we are good to go in that aspect. 

-- 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- FEATURE ENGINEERING:

-- a. Add a new column that specifies the time of the day that corresponds to the time of the day, Morning or evening

select time,
(case 
when time between "00:00:00" and "12:00:00" then "Morning"
when time between "12:01:00" and "16:00:00" then "Afternoon"
else "Evening"
end) as time_of_day 
from sales;

alter table sales
add column time_of_day varchar(20);

update sales
set time_of_day = 
case 
when time between "00:00:00" and "12:00:00" then "Morning"
when time between "12:01:00" and "16:00:00" then "Afternoon"
else "Evening"
end;

select *
from sales;

-- b. Add daay of the week to the table:

select date, dayname(date)
from sales;

alter table sales
add column day_name varchar(25);

update sales
set day_name = dayname(date);

select *
from sales;

-- c. Month name:
select date, monthname(date)
from sales;

alter table sales
add column month_name varchar(25);

update sales
set month_name = monthname(date);

select *
from sales;

-- 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- BUSINESS QUESTIONS:

## Generic questions:

-- 1. How many unique cities does the data have

select distinct(city)
from sales;

-- 2. In which city is each branch?

select city, branch
from sales
group by city, branch;

-- OR

select distinct(city), branch
from sales;

### Product

-- 1. How many unique product lines does the data have?

select distinct(product_line)
from sales;

-- 2. What is the most common payment method?

select payment_method, count(payment_method)
from sales
group by payment_method;

-- 3. What is the most selling product line?

select product_line, count(product_line) as freq
from sales
group by product_line
order by freq desc
limit 1;

-- 4. What is the total revenue by month?

select month_name, sum(total) as totalRevenue
from sales
group by month_name
order by totalRevenue desc
;

-- 5. What month had the largest COGS?

select month_name, sum(cogs) as largest_cogs
from sales
group by month_name
order by largest_cogs desc
limit 1;

-- 6. What product line had the largest revenue?

select product_line, sum(total) as totalRevenue
from sales
group by product_line
order by totalRevenue desc
limit 1;

-- 5. What is the city with the largest revenue?

select city, sum(total) as totalRevenue
from sales
group by city
order by totalRevenue desc
limit 1;

-- 6. What product line had the largest VAT?

select product_line, sum(VAT) as totalVAT
from sales
group by product_line
order by totalVAT desc
limit 1;

-- 7. Fetch each product line and add a column to those product line showing "Good", "Bad". 
-- Good if its greater than average sales

select product_line, 
(case 
when quantity > (select avg(quantity) from sales) then 'Good'
else 'Bad'
end) as judge
from sales
group by product_line, judge;

-- 8. Which branch sold more products than average product sold?

select branch, sum(quantity) as qty
from sales
group by branch
having qty > (select avg(quantity) from sales)
order by qty;

-- 9. What is the most common product line by gender?

select gender, product_line, count(gender) as ct
from sales
group by gender, product_line
order by ct desc;

-- 12. What is the average rating of each product line?

select product_line, avg(rating) as av
from sales
group by product_line
order by av desc;

### Sales

-- 1. Number of sales made in each time of the day per weekday

select time_of_day, count(*) as total_sales
from sales
group by time_of_day;

-- 2. Which of the customer types brings the most revenue?

select customer_type, sum(total) as most
from sales
group by customer_type
order by most desc;

-- 3. Which city has the largest tax percent/ VAT (**Value Added Tax**)?

select city, avg(VAT) as VAT
from sales
group by city
order by VAT desc;

-- 4. Which customer type pays the most in VAT?

select customer_type, avg(VAT) as av
from sales
group by customer_type;

### Customer

-- 1. How many unique customer types does the data have?

select count(distinct(customer_type))
from sales;

-- 2. How many unique payment methods does the data have?

select count(distinct(payment_method))
from sales;

-- 3. What is the most common customer type?

select customer_type, count(customer_type) as common
from sales
group by customer_type;

-- 4. Which customer type buys the most?

select customer_type, count(*)
from sales
group by customer_type;

-- 5. What is the gender of most of the customers?

select gender, count(gender)
from sales
group by gender;

-- 6. What is the gender distribution per branch?

select gender, count(*) as gender_ct
from sales
where branch = 'B'
group by gender;

-- OR

SELECT branch,
SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count
FROM sales
GROUP BY branch;

-- OR

SELECT branch, time_of_day, AVG(rating) AS rate
FROM sales
GROUP BY branch, time_of_day
ORDER BY branch, rate DESC;

-- 7. Which time of the day do customers give most ratings?

select time_of_day, avg(rating) as rate
from sales
group by time_of_day
order by rate desc;

-- 8. Which time of the day do customers give most ratings per branch?

select branch, time_of_day, avg(rating) as rate
from sales
group by branch, time_of_day
order by rate desc;

-- 9. Which day of the week has the best avg ratings?

select day_name, avg(rating) as rates
from sales
group by day_name
order by rates desc;

-- 10. Which day of the week has the best average ratings per branch?

SELECT branch, day_name, AVG(rating) AS rate
FROM sales
GROUP BY branch, day_name
ORDER BY branch, rate DESC;






















