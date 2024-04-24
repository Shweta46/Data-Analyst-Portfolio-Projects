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

-- Gsearch lander test starting pageview id
select min(website_pageview_id)
from website_pageviews
where pageview_url = '/lander-1'
;

-- a. Finding the landing pageview ids of the sessions
drop temporary table if exists first_pageview_id;
create temporary table first_pageview_id
select 
	website_pageviews.website_session_id, 
	min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
left join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at <'2012-07-28' -- prescribed by the assignment
    and website_pageviews.website_pageview_id >= 23504 -- first pageview id of lander-1
    and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
group by 1
;

-- If I include the pageview url here only, then the group by statement has to include that too, 
-- thats wont give us the min pageview id of each session that is landing pageview id of that session 
-- You are grouping by both website_pageviews.website_session_id and website_pageviews.pageview_url. 

-- This means that for each unique combination of website_session_id and pageview_url, 
-- you are finding the minimum website_pageview_id that satisfies your conditions.

select * from first_pageview_id;

-- b. Bringing in the landing page of each session and limiting those to just /home and /lander-1
drop temporary table if exists nonbrand_test_sessions_w_landing_pages;
create temporary table nonbrand_test_sessions_w_landing_pages
select 
	first_pageview_id.website_session_id,
    website_pageviews.pageview_url as landing_page    
from first_pageview_id
left join website_pageviews
on website_pageviews.website_pageview_id = first_pageview_id.min_pageview_id
where website_pageviews.pageview_url in ('/home', '/lander-1')
;

select * from nonbrand_test_sessions_w_landing_pages;

-- c. creating table to bring in orders

drop temporary table if exists nonbrand_test_sessions_w_orders;
create temporary table nonbrand_test_sessions_w_orders
select 
	nonbrand_test_sessions_w_landing_pages.website_session_id, 
    nonbrand_test_sessions_w_landing_pages.landing_page,
    orders.order_id as order_id
from nonbrand_test_sessions_w_landing_pages
left join orders
	on orders.website_session_id = nonbrand_test_sessions_w_landing_pages.website_session_id
;

select * from nonbrand_test_sessions_w_orders;

-- d. Find the differences between conversion rates

select 
	landing_page,
    count(distinct website_session_id) as sessions,
    count(distinct order_id) as orders,
    count(distinct order_id)/ count(distinct website_session_id) as conv_rate
from nonbrand_test_sessions_w_orders
group by 1
;

-- e. Finding the most recent pageview for gsearch nonbrand where the traffic was sent to /home
select
	max(website_sessions.website_session_id) as most_recent_gsearch_nonbrand_home_pageview
from website_sessions
left join website_pageviews
	on website_pageviews.website_session_id = website_sessions.website_session_id
where utm_source = 'gsearch'
	and utm_campaign = 'nonbrand'
    and pageview_url = '/home'
    and website_sessions.created_at < '2012-11-27'
;

-- max website id = 17145. Since this, all the incoming traffic has been rerouted elsewhere

-- Finding the number of sessions since the last /home page landing session 

select 
	count(website_session_id) as sessions_since_test
from website_sessions
where created_at < '2012-11-27'
	and website_session_id > 17145 -- limiting count of session and counting from the last home session
	and utm_source = 'gsearch'
    and utm_campaign = 'nonbrand'
;
-- 22972 sessions since the test
-- 22972 x (difference between the CVR of /lander-1 and /home) to see the incremenet in session to order 
-- 22972 x (0.0406 - 0.0318) = 202 incremental orders since 29th July
-- Roughly 4 months have passed, so 202/4 = 50
-- meaning atleast 50 extra orders per month. 

-- 7. For the landing page test we analyzed previously, show a full conversion funnel from each of the two pages to orders. You can use the same time period you analyzed last time (Jun 19 - Jul 28).

select 
	website_sessions.website_session_id,
    website_pageviews.pageview_url,
    case when pageview_url = '/home' then 1 else 0 end as homepage,
    case when pageview_url = '/lander-1' then 1 else 0 end as custom_lander,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page,
    case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
    case when pageview_url = '/billing' then 1 else 0 end as billing_page,
    case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thankyou_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where website_sessions.utm_source = 'gsearch'
	and website_sessions.utm_campaign = 'nonbrand'
    and website_sessions.created_at < '2012-07-28'
		and website_sessions.created_at > '2012-06-19'
order by
	website_sessions.website_session_id,
    website_pageviews.created_at
;
		














-- 8. To quantify the impact of the billing test, analyze the lift generated from the test (Sep 10 - Nov 10), in terms of revenue per billing page session, and then pull the number of billing page sessions for the past month to understand monthly impact. 

