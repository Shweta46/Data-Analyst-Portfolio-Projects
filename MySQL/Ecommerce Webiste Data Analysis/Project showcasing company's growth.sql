-- Use SQL to extract and analyze website traffic and performance data from Maven fuzzy factory database to quantify the company's growth, and to tell the story of how you have been able to generate that growth.
-- As an analyst, 
-- 1. The first part of your job is extracting and analyzing the data, and 
-- 2. The next is effectively communicating the story to the shareholders. 
 
 -- For the board meeting, objectives:
 -- 1. Tell the story of company's growth, using trended performance data. 
 -- 2. Use the database to explain some of the details around your growth story, and quantify the revenue impact of some of your wins.
 -- 3. Analyze current performance, and use the data available to assess upcoming oppurtunities. 
 
-- Till 27th Nov 2012 
-- Specific questions that the client needs help with:
-- 1. Gsearch seems to be the biggest driver of the business. Pull monthly trends for gsearch sessions and orders so that we can showcase the growth.

select min(date(website_sessions.created_at)) as monthly, count(distinct website_sessions.website_session_id) as sessions, count(orders.order_id) as orders_,
count(orders.order_id)/count(website_sessions.website_session_id) as session_to_order_cvr 
from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
	and utm_source = 'gsearch'
group by month(website_sessions.created_at)
;

-- 2. Split out nonbrand and brand campaigns separately and see the monthly trends for gsearch to see if brand is picking up at all.

select min(date(website_sessions.created_at)) as dates, count(case when utm_campaign = 'nonbrand' then website_sessions.website_session_id else null end) as nonbrand_sessions, 
count(case when utm_campaign = 'nonbrand' then orders.order_id else null end) as nonbrand_orders,
count(case when utm_campaign = 'brand' then website_sessions.website_session_id else null end) as brand_sessions, 
count(case when utm_campaign = 'brand' then orders.order_id else null end) as brand_orders
from website_sessions
left join orders
on website_sessions.website_session_id = orders. website_session_id
where 
	website_sessions.created_at < '2012-11-27'
	and utm_source = 'gsearch'
	and utm_campaign in ('nonbrand', 'brand')
group by month(website_sessions.created_at)
;

-- 3. Dive into nonbrand gsearch, and pull monthly sessions and orders split by device type. This is to show that we know our traffic sources.

select min(date(website_sessions.created_at)) as months, 
count(case when device_type = 'desktop' then website_sessions.website_session_id else null end) as desktop_session, 
count(case when device_type = 'desktop' then orders.order_id else null end) as desktop_orders, 
count(case when device_type = 'mobile' then website_sessions.website_session_id else null end) as mobile_sessions, 
count(case when device_type = 'mobile' then orders.order_id else null end) as mobile_orders
from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
    and utm_source = 'gsearch'
group by month(website_sessions.created_at)
;

-- 4. Pull monthly trends for gsearch, alongside monthly trends for each of the other channels.

select distinct utm_source, count(website_session_id)
from website_sessions
where created_at < '2012-11-27'
group by 1;

select min(date(website_sessions.created_at)), 
count(case when utm_source = 'gsearch' then website_sessions.website_session_id else null end) as gsearch_sessions,
count(case when utm_source = 'bsearch' then website_sessions.website_session_id else null end) as bsearch_sessions,
count(case when utm_source is null and http_referer is not null then website_sessions.website_session_id else null end) as organic_search_sessions,
count(case when utm_source is null and http_referer is null then website_sessions.website_session_id else null end) as direct_type_in_sessions
from website_sessions
left join orders
on orders.website_session_id = website_sessions.website_session_id
where 
	website_sessions.created_at < '2012-11-27'
group by month(website_sessions.created_at)
;

-- 5. To tell the story of website performance improvements over the course of 8 months, pull session to order conversion rates, by month.
select min(date(website_sessions.created_at)) as months, count(website_sessions.website_session_id) as sessions, count(orders.order_id) as orders,
count(orders.order_id)/count(website_sessions.website_session_id) as session_to_order_cvr
from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
where website_sessions.created_at < '2012-11-27'
group by month(website_sessions.created_at)
;

-- 6. For the gsearch lander test, estimate the revenue that test earned the client. (Hint: Look at the increase in CVR from the test (Jun 19 - Jul 28), 
-- and use nonbrand sessions and revenue since then to calculate incremental value)

-- Gsearch lander test
select min(website_pageview_id)
from website_pageviews
where pageview_url = '/lander-1'
;

select min(date(website_sessions.created_at))as weekly, count(website_sessions.website_session_id) as sessions, count(orders.order_id) as orders,
count(orders.order_id)/ count(website_sessions.website_session_id) as sessions_to_orders_cvr, sum(price_usd) as revenue
from website_sessions
left join orders
on website_sessions.website_session_id = orders.website_session_id
where 
	website_sessions.created_at between '2012-06-19' and '2012-07-28'
    and we
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by week(website_sessions.created_at)
;







-- 7. For the landing page test we analyzed previously, show a full conversion funnel from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 - Jul 28).















-- 8. To quantify the impact of the billing test, analyze the lift generated from the test (Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand monthly impact. 

