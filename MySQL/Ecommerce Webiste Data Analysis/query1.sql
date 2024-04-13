select ws.utm_content, count(distinct ws.website_session_id) as sessions, 
count(distinct o.order_id) as orders,

--  this tells that how many orders were generated by a utm content and then of those sessions, how many resulted in orders from the customers

count(distinct o.order_id)/count(distinct ws.website_session_id) * 100 as session_to_order_conversion_rate

-- CVR tells how well the sessions are converting to orders
from website_sessions ws
left join orders o
on o.website_session_id = ws.website_session_id
where ws.website_session_id between 1000 and 2000
group by 1
order by 2 desc;

--  Q 1. Where is the traffic generated on the website seesions are coming from 
-- Breakdown by utm_source, campaign, and referring domain 
select utm_source, utm_campaign, http_referer, count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-04-12'
group by utm_source , utm_campaign, http_referer
order by sessions desc;

-- this resulted in gserach nonbrand generating most of the sessiosn for the website, 
-- we will have to dig deeper

-- Q2. Gsearch nonbrand in the main source of traffic for their website traffic source, 
-- how much are those sessions driving the sales? For that we need to find the session to order conversion rate.
-- If below 4% then the company will dial down the search bids a bit.
-- For that we have calculate conversion rate (CVR) from session to order

select count(distinct ws.website_session_id) as sessions, count(distinct o.order_id) as orders,
count(distinct o.order_id)/ count(distinct ws.website_session_id) * 100 as session_to_order_conversion_rate
from website_sessions ws 
left join orders o
on ws.website_session_id = o.website_session_id
where ws.created_at < '2012-04-14' and utm_source = 'gsearch' and utm_campaign = 'nonbrand';

-- According to this, the CVR is < 4%, so they need to dial down the search bids. 
-- Now, we have to 
-- 1. Monitor the impact of bid reductions, and 
-- 2. Analyze the performance trending by device type in order to refine bidding strategy.

-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- FOR TREND ANALYSIS, USE DATE FUNCTIONS
-- Trend analysis of sessions by week and year

select year(created_at), week(created_at), min(date(created_at)) as week_start,
count(distinct website_session_id) as sessions
from website_sessions
where website_session_id between 100000 and 115000 -- arbitrary number
group by 1, 2;

-- 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Using CASE pivots, that is CASE inside COUNT:
-- We need to differentiate the columns based on the number of orders, 1 or 2, made on particular product_id
-- based on the number of orders made by the customers 

-- INITIAL VERSION TO GET TO THE ACTUAL CODE:
select primary_product_id, order_id, items_purchased,
case 
	when items_purchased = 1 then order_id 
    else null 
end as single_item_orders,
case 
	when items_purchased = 2 then order_id 
    else null
end as two_item_orders
from orders
where order_id between 31000 and 32000 -- arbitrary number
;
 
-- THE FINAL CODE:

select primary_product_id,
count(case 
	when items_purchased = 1 then order_id 
    else null 
end) as single_item_orders,
count(case 
	when items_purchased = 2 then order_id 
    else null
end) as two_item_orders
from orders
where order_id between 31000 and 32000 -- arbitrary number
group by 1;
  
-- Q3. Based on the analyses, the client bid down gsearch nonbrand on 2012-04-15. As of May 10 2012,
-- We need to pull the gsearch nonbrand trended session volume, by week to see if the changes have caused the volume to drop at all?

select min(date(created_at)) as week_start_date, count(distinct website_session_id) as sessions
from website_sessions
where created_at < '2012-05-10' and utm_source = 'gsearch' and utm_campaign = 'nonbrand'
group by week(created_at);

-- According to the results, it did impact the sessions in a negative way meaning they descreased when we lowered the session bidding 
-- This clearly means that gsearch nonbrand is fairly sensitive to bid changes. 
-- The client wants maximum volume but doesnt want to spend more on ads than they can afford. 
-- What to do?

-- Next steps:
-- 1. Continue to monitor volume levels
-- 2. Think about how we could make the campaigns more efficient so that we can increase volume again. 

-- Q4. Conversion rates from session to order by device type. If desktop performance is better than mobile,
-- then the client plans to bid up for desktop specifically to get more volume. 

select ws.device_type, count(distinct ws.website_session_id) as sessions, 
	count(distinct o.order_id) as orders,
	count(distinct o.order_id) /count(distinct ws.website_session_id) as session_to_order_conversion_rate 
from website_sessions ws
left join orders o
	on o.website_session_id = ws.website_session_id
where ws.created_at < '2012-05-11' 
	and utm_source = 'gsearch' 
    and utm_campaign = 'nonbrand'
group by 1;

-- The CVR on desktop was higher than mobile traffic. This led the client to bid more on desktop. When this happens, they should rank higher in auctions, which should lead to sales boost. 
-- Next steps:
-- 1. Analyze volume by device type to see if the bid changes make a material impact. 
-- 2. Continue to look for ways to optimize campaigns. 

-- Q5. The bids on gsearch nonbrand desktop campaigns were increased on 2012-05-19. 
-- Pull weekly trends for both deskptop and mobile to see the impact on volume since 2012-04-15.

select min(date(created_at)) as week_start_date, 
count(distinct case when device_type = 'desktop' then website_session_id else null end) as dtop_sessions,
count(distinct case when device_type = 'mobile' then website_session_id else null end) as mob_sessions  
from website_sessions
where created_at between '2012-04-15' and '2012-06-09' 
and utm_source = 'gsearch' 
and utm_campaign = 'nonbrand'
group by week(created_at);

-- The result of this was that the desktop sessions were indeed increased after the incerase in bidding based on the previous conversion analysis.
-- Next step:
-- 1. Continue to monitor device-level volume and be aware of the impact bid levels has
-- 2. Continue to monitor the conversion performace at the device-level to optimize spend

-- 8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888 
-- Till now we were able to do traffic analysis, that is where the traffic in our website is coming from. 
-- Now, we will shift to the website analysis.  

-- Using temporary table for multi step analyses in the quest to find the top entry pages

-- Here, we wanted to extract the way a user jumps from one page to another, and the sequence of that jump
-- To extract sessions, each one is represented by website session id
DROP TEMPORARY TABLE IF EXISTS first_pageview;
create temporary table first_pageview
select website_session_id,
	min(website_pageview_id) as min_pageview_id
from website_pageviews
where website_pageview_id < 1000 -- arbitrary
group by website_session_id;

select * from first_pageview;

select wp.pageview_url as landing_page, -- aka "entry page"
count(distinct fp.website_session_id) as sessions_hitting_this_lander
from first_pageview fp
left join website_pageviews wp
on fp.min_pageview_id = wp.website_pageview_id
group by wp.pageview_url;

-- Q6. Working with now website manager, whos asked to pull the most-viewed website pages, ranked by session volume.

select pageview_url, count(distinct website_pageview_id) as page_views
from website_pageviews
where created_at < '2012-06-09'
group by pageview_url
order by 2 desc
;

-- According to the results, the pages that got the most traffic were home, products, and mrfuzzy page
-- need to understand traffic patterns more, and have to look at entry pages.
-- Next steps:
-- 1. Dig into whether this list is also representative of our top entry pages.
-- 2. Analyze the performance of each of our the top pages to look for improvement 

-- Q7. Pull the list of the top entry pages, and rank them on entry volume. 

-- Step 1: Find the first pageview for each session
-- Step 2: Find the url the customer saw on that first pageview

drop temporary table if exists landing_on_website;
create temporary table landing_on_website
select website_session_id, min(website_pageview_id) as landing_session_id
from website_pageviews
where created_at < '2012-06-12'
group by 1
;

select * from landing_on_website;

select 	
	wp.pageview_url as landing_page_url, 
	count(distinct wp.website_pageview_id) as landing_page
from landing_on_website lw
left join website_pageviews wp
on lw.landing_session_id = wp.website_pageview_id
group by 1
order by 2 desc;

-- This means that every customer for the first time is seeing the home page only. 
-- The focus should be on improving the home page. 
-- Next steps:
-- 1. Analyze landing page performance, for the homepage specifically.
-- 2. Think about whether or not the homepage is the best initial experience for all customers.

-- 8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- BUSINESS CONTEXT: We want to see landing page performance for a certain time period
-- Step 1: Find the first website_pageview_id for relevant sessions
-- Step 2: Identify the landing page of each session
-- Step 3: Counting pageviews for each session, to identify the "bounces"
-- Step 4: Summarizing total sessions and bounced sessions, by LP

-- 1. 
select 
	website_pageviews.website_session_id, 
	min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
inner join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
and website_sessions.created_at between '2014-01-01' and '2014-02-01' -- arbitrary
group by website_pageviews.website_session_id;

-- FOR ME: the above and below queries are producing the same result, I dont know why the inner join was necessary here
-- The below one is simpler and doesnt use the inner join thing, lets just consider what the manager told us to consider here, that is the inner join function

-- REASONING:
-- Both queries will give you the same result if each session has at least one page view within the specified date range. 
-- However, if there are sessions in the website_sessions table that do not have any corresponding page views in the website_pageviews table, the first query would exclude these sessions from the result set, while the second query would include them but with a NULL value for min_pageview_id.

select website_session_id, min(website_pageview_id) as min_pageview_id
from website_pageviews
where created_at between '2014-01-01' and '2014-02-01' -- arbitrary
group by website_session_id;

-- same query as above, but this time storing the dataset as temporary table
drop temporary table if exists first_pageviews_demo;
create temporary table first_pageviews_demo
select 
	website_pageviews.website_session_id, 
	min(website_pageviews.website_pageview_id) as min_pageview_id
from website_pageviews
inner join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
and website_sessions.created_at between '2014-01-01' and '2014-02-01' -- arbitrary
group by website_pageviews.website_session_id;

select * from first_pageviews_demo;
-- The above helped us link website session id to a single landing page. 

-- 2. Landing page of each session: Relating the landed page id to a url

drop temporary table if exists session_w_landing_page_demo;
create temporary table session_w_landing_page_demo
select
	first_pageviews_demo.website_session_id, website_pageviews.pageview_url as landing_page
-- website pageview is the landing page view and the min pageview id was the first page the user saw when they first entered the website
from first_pageviews_demo
left join website_pageviews
on website_pageviews.website_pageview_id = first_pageviews_demo.min_pageview_id ;

select * from session_w_landing_page_demo;

-- 3.
-- Next, we make a table to include a count of pageviews per session

-- First, collect all the sessions. Then we will limit to bounced sessions and create a temp table 

select sl.website_session_id, sl.landing_page, count(wp.website_pageview_id) as count_of_pages_viewed
from session_w_landing_page_demo sl
left join website_pageviews wp
ON wp.website_session_id = sl.website_session_id
group by sl.website_session_id, sl.landing_page;

-- M.Q. WHY WAS IT IMPPORTANT TO CREATE TEMPORARY TABLE HERE AT ALL?
-- Ans. The thing is that using the below query, I tried to find that if i could do the same with out a temp table. 
-- So for that I finding the count of website pages visited by a particular website session was first done, and I could definitely do it.
-- But, for finding the landing page of those sessions, simple queries didnt suffice. I have had to, in turn, take the help of temp tables.

select website_session_id, count(website_pageview_id)
from website_pageviews
where created_at between '2014-01-01' and '2014-02-01' 
group by website_session_id;

-- 4. 
-- Limiting the sessions where the pages viewed by the user was only one.

drop temporary table if exists bounced_sessions_only;
CREATE temporary TABLE bounced_sessions_only
select sl.website_session_id, sl.landing_page, 
count(website_pageviews.website_pageview_id) as count_of_pages_viewed
from session_w_landing_page_demo sl
left join website_pageviews 
ON website_pageviews.website_session_id = sl.website_session_id
group by sl.website_session_id, sl.landing_page
having count(website_pageviews.website_pageview_id) = 1;

select * from bounced_sessions_only;

-- Relating the website sessions to the landing page, and then seeing which ones have bounced sessions in them

select sl.landing_page,
sl.website_session_id, 
bs.website_session_id as bounced_website_session_id
from session_w_landing_page_demo sl
left join bounced_sessions_only bs
on sl.website_session_id = bs.website_session_id
order by sl.website_session_id
;

-- final output: Run a count of records, group by landing page and then we will add bounce rate column

select 
	sl.landing_page, 
    count(distinct sl.website_session_id) as sessions, 
    count(distinct bs.website_session_id) as bounced_website_session_id,
        count(distinct bs.website_session_id)/count(distinct sl.website_session_id) as bounce_rate
from session_w_landing_page_demo sl
left join bounced_sessions_only bs
on sl.website_session_id = bs.website_session_id
group by sl.landing_page
;

-- So, the steps that were used to come to this are totally fine. First, with respect to the sessions,
-- found the landing page. 
-- Now that we have a single landing page, could find the url of that landing page.
-- Then, getting back to the original table, can find the total pages viewed by the individual website_session_id.
-- There is more but I get it now

-- So, there are other metrics that will tell you and it doesnt necessarily mean that if the bounce rates are high then you should do something about that
-- Some pages are only ads, others just home pages.alter

-- Q8. From the previous analysis, we saw that all the traffic is landing on the homepage. We should check how that landing page is perfoming.
-- Pull the bounce rates for traffic landing on the homepage. 
-- Represent sessions, bounced sessions, and % of sessions which bounced.
-- Limit the day to before June 14, 2012.

-- 1. Landing page id

-- TABLE 1

drop temporary table if exists min_pageview_id;
create temporary table min_pageview_id
select website_session_id, min(website_pageview_id) as landing_page_id
from website_pageviews
where created_at < '2012-06-14'
group by 1
;
select * from min_pageview_id;

-- 2. Page url corresponding to the landing pages

-- TABLE 2

drop temporary table if exists landing_page_url;
create temporary table landing_page_url
select count(distinct mp.landing_page_id) as sessions, wp.pageview_url as url
from website_pageviews wp
right join min_pageview_id mp
on wp.website_pageview_id = mp.landing_page_id
where created_at < '2012-06-14'
group by 2
;

select * from landing_page_url;

-- 3. Calculating bounced sessions
-- find the total pageview_id of those sessions whose landing page was /home

-- TABLE 3

drop temporary table if exists bounced;
create temporary table bounced
select mp.website_session_id as bounced_sessions, count(wp.website_pageview_id)
from website_pageviews wp
left join min_pageview_id mp
on wp.website_session_id = mp.website_session_id
where created_at < '2012-06-14'
group by 1
having count(wp.website_pageview_id) = 1;

select * from bounced;

select bounced_sessions, min(website_pageview_id), pageview_url
from bounced 
left join website_pageviews wp
on bounced.bounced_sessions = wp.website_session_id
group by 1,3
;

-- TABLE 4

drop temporary table if exists bounced_sessions;
create temporary table bounced_sessions
select count(bounced_sessions) as bounced_sessions, pageview_url as landing_page
from bounced 
left join website_pageviews wp
on bounced.bounced_sessions = wp.website_session_id
group by 2
;
select * from bounced_sessions;

-- Total sessions that landed on home page and the sessions that bounced
select lp.sessions, bounced_sessions, bounced_sessions/lp.sessions as bounce_rate
from bounced_sessions bs
join landing_page_url lp
on lp.url = bs.landing_page
; 

-- Results: The bounce rate is about 60% when a customer lands on home page. It is pretty high for a paid search. 
-- So, the client decided to put together a custom landing page for seach and see if that performs better.

-- Next steps:
-- 1. Keep an eye on bounce rates, which represent a major area of improvement. 
-- 2. Help the client measure and analyze a new page that they think will improve performance, and analyze the results of an A/B split test against the homepage.

-- Q9. Based on bounce rate analysis, a new custom landing page (/lander-1) in a 50/50 test against homepage (/home) for gsearch nonbrand traffic.
-- Pull the bounce rates for the two groups to evaluate the new page. Make sure to just look at the time period where /lander-1 was getting traffic for a comparison fair.
-- Date: 28/07/2012

-- 1. Find the initial created_at and initital pageview_id for lander-1. Isolate this result for the second part.
-- 2. The table should include landing_page, total_sessions, bounced_sessions, and bounce_rates.

select min(created_at) as first_created_at, min(website_pageview_id) as first_pageview_id
from website_pageviews
where created_at < '2012-07-28' and pageview_url = '/lander-1';

-- 1. Finding the sessions with landing page as lander-1 or home
drop temporary table if exists landing_page2;
create temporary table landing_page2
select website_pageviews.website_session_id, 
min(website_pageviews.website_pageview_id) as landing_page_id, pageview_url
from website_pageviews
inner join website_sessions
on website_sessions.website_session_id = website_pageviews.website_session_id
where website_pageviews.created_at < '2012-07-28' and website_pageview_id > 23504
and utm_source = 'gsearch'
and utm_campaign = 'nonbrand'
and (pageview_url = '/lander-1' or pageview_url = '/home')
group by 1, 3;

select * from landing_page2;

select landing_page2.pageview_url, count(website_pageviews.website_session_id) as total_sessions
from website_pageviews
right join landing_page2
on website_pageviews.website_session_id = landing_page2.website_session_id
group by 1;

-- 2. Find the total number of bounced sessions in the website sessions
drop temporary table if exists bounced2;
create temporary table bounced2
select website_session_id, count(website_pageview_id) as bounced
from website_pageviews
where created_at < '2012-07-28' and website_pageview_id > 23504
group by 1
having count(website_pageview_id) = 1
;

select * from bounced2;

select lp.pageview_url, count(lp.website_session_id) as total_sessions, count(b.website_session_id) as bounced,
count(b.website_session_id)/count(lp.website_session_id) as bounce_rate
from landing_page2 lp
left join bounced2 b
on b.website_session_id = lp.website_session_id
group by 1 
order by 4 desc;

-- Results: The custom lander has lower bounce rate than home page, so it is a success.
-- Next steps:
-- 1. Help the client confirm that traffic is all running to the new custom lander after campaign updates.
-- 2. Keep an eye on bounce rates and help the team look for other areas to test and optimize.  

-- Q10. Landing page trend analysis. 
-- Pull the volume of paid search nonbrand traffic landing on /home and /lander-1, trended weekly since June 1st. This is done to confirm if the traffic is all routed correctly.
-- Pull overall paid search bounce rate trended weekly. This is to make sure lander change has improved the overall picture. 

-- 1. The nonbrand traffic
drop temporary table if exists nonbrand_traffic;
create temporary table nonbrand_traffic
select created_at, website_session_id, utm_campaign, utm_source
from website_sessions
where created_at > '2012-06-01' and created_at < '2012-08-31'
and utm_campaign = 'nonbrand' 
and utm_source = 'gsearch'
;

select * from nonbrand_traffic;

-- 2. Finding the home or lander landing page of nonbrand traffic 
drop temporary table if exists landing_page;
create temporary table landing_page
select nt.created_at as created_at, nt.website_session_id as website_session_id, 
min(website_pageview_id) as landing_age_id, pageview_url
from website_pageviews
inner join nonbrand_traffic nt
on nt.website_session_id = website_pageviews.website_session_id
where (pageview_url = '/home' or pageview_url = '/lander-1')
group by 1, 2, 4
;

select * from landing_page;

-- 3. Bouced sessions
drop temporary table if exists bounced_sessions3;
create temporary table bounced_sessions3
select nt.created_at as created_at, nt.website_session_id as website_session_id, 
count(wp.website_pageview_id) as bounced_sessions
from website_pageviews wp
left join nonbrand_traffic nt
on nt.website_session_id = wp.website_session_id
group by 1, 2
having count(wp.website_pageview_id) = 1
;

select * from bounced_sessions3;

-- 4. final after bounced sessions
select lp.created_at, lp.website_session_id, bs.bounced_sessions, 
lp.pageview_url,
(case when lp.pageview_url = '/home' then lp.pageview_url else null end) as home_sessions,
(case when lp.pageview_url = '/lander-1' then lp.pageview_url else null end) as lander_sessions 
from bounced_sessions3 bs
right join landing_page lp
on lp.website_session_id = bs.website_session_id
;

select min(date(lp.created_at)), 
count(distinct bs.bounced_sessions)/ count(distinct lp.website_session_id) * 100 as bounce_rate, 
count(case when lp.pageview_url = '/home' then lp.pageview_url else null end) as home_sessions,
count(case when lp.pageview_url = '/lander-1' then lp.pageview_url else null end) as lander_sessions 
from bounced_sessions3 bs
right join landing_page lp
on lp.website_session_id = bs.website_session_id
group by week(lp.created_at)
;

-- Results:
-- The client finally switched over to the custom lander, and the bounce rates are down too.
-- Next steps:
-- 1. The analysis helped improve the business
-- 2. Optimizing the website 

-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- CONVERSION FUNNELS:
-- 1. Build mini conversion funnel, from /lander-2 to /cart
-- 2. Know how many reach each step, and also dropoff rates
-- 3. Looking at /lander-2 traffic only
-- 4. Looking at customers who like Mr Fuzzy only

-- STEP 1: Select all pageviews for relevant sessions
-- STEP 2: Identify each relevant pageview as the specific funnel step
-- STEP 3: Create the session-level conversion funnel view
-- STEP 4: Aggregate the data to assess funnel performance

select 
	website_sessions.website_session_id, 
	website_pageviews.pageview_url, 
    website_pageviews.created_at as pageview_created_at
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at between '2014-01-01' and '2014-02-01' -- random timeframe for demo
	and website_pageviews.pageview_url in 
    ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
    -- creating only a 4 step funnel to make things easier
order by website_sessions.website_session_id
;

-- 1. Returning 1 that is flagging the pages to see how far the sessions reach
select 
	website_sessions.website_session_id, 
	website_pageviews.pageview_url, 
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page
    -- all the three of the cases are mutually exclusive, that is no one session can be present for more than two pages at the same time
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at between '2014-01-01' and '2014-02-01' -- random timeframe for demo
	and website_pageviews.pageview_url in 
    ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
    -- creating only a 4 step funnel to make things easier
order by website_sessions.website_session_id
;

-- 2. Subquering the above query inside another query and then creating a temporary table out of it
drop temporary table if exists session_made_it_to_what_level;
create temporary table session_made_it_to_what_level
select 
	website_session_id, -- for each session, we are seeing if that session made it to the specific pages
    max(products_page) as made_it_to_product,
    max(mrfuzzy_page) as made_it_to_mrfuzzy,
    max(cart_page) as made_it_to_cart
from(
select 
	website_sessions.website_session_id, 
	website_pageviews.pageview_url, 
    website_pageviews.created_at as pageview_created_at,
    case when pageview_url = '/products' then 1 else 0 end as products_page,
    case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
    case when pageview_url = '/cart' then 1 else 0 end as cart_page
from website_sessions
	left join website_pageviews
		on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at between '2014-01-01' and '2014-02-01' -- random timeframe for demo
	and website_pageviews.pageview_url in 
    ('/lander-2', '/products', '/the-original-mr-fuzzy', '/cart')
    -- creating only a 4 step funnel to make things easier
order by website_sessions.website_session_id
)as pageview_level
group by 1 -- to see the if a particular made it individual pages or not 
;

select * from session_made_it_to_what_level;

-- 3. Total sessions and their made it pages
select 
	count(website_session_id), 
	count(case when made_it_to_product = 1 then website_session_id else null end) as to_products,
    count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end) as to_mrfuzzy,
    count(case when made_it_to_cart = 1 then website_session_id else null end) as to_cart
from session_made_it_to_what_level
;

-- 4. Translating the above counts to click rate for final output that is how much percentage of the session is clicking upto a particular page
select 
	count(website_session_id) as sessions, 
	count(case when made_it_to_product = 1 then website_session_id else null end)/count(website_session_id) 
    as clicked_upto_products -- or lander_clickthrough_rate since it arrived here from the landing page 
    ,
    count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end)/count(case when made_it_to_product = 1 then website_session_id else null end)
    as clicked_upto_mrfuzzy -- or product_clickthrough_rate since it arrived at this page from products page
    ,
    count(case when made_it_to_cart = 1 then website_session_id else null end)/count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end)
    as clicket_upto_cart -- or mr_fuzzy_clickthrough_rate 
from session_made_it_to_what_level
;
 
-- Q11. To understand where the client is losing gsearch visitors between the new /lander-1 page and placing an order.
-- Build a full conversion funnel, analyzing how many customers make it to each step. 
-- Start with /lander-1, and build the funnel all the way to the '/thank you' page.
-- Between 5th August 2012 and 5th September 2012

select website_sessions.website_session_id, website_pageviews.website_pageview_id, pageview_url, 
(case when pageview_url = '/lander-1' then 1 else 0 end) as lander1,
(case when pageview_url = '/products' then 1 else 0 end) as products, 
(case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end) as mrfuzzy,
(case when pageview_url = '/cart' then 1 else 0 end) as cart,
(case when pageview_url = '/shipping' then 1 else 0 end) as shipping,
(case when pageview_url = '/billing' then 1 else 0 end) as billing,
(case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end) as thankyou
from website_sessions
left join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at between '2012-08-05' and '2012-09-05'
	and utm_source = 'gsearch' 
    and utm_campaign = 'nonbrand'
    and website_pageviews.pageview_url in ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
group by 1, 2, 3
order by 1
;

drop temporary table if exists lander1_session_made_it_to_what_level;
create temporary table lander1_session_made_it_to_what_level
select 
	website_session_id, -- for each session, we are seeing if that session made it to the specific pages
    max(products) as made_it_to_product,
    max(mrfuzzy) as made_it_to_mrfuzzy,
    max(cart) as made_it_to_cart,
    max(shipping) as made_it_to_shipping,
    max(billing) as made_it_to_billing,
    max(thankyou) as made_it_to_thankyou
from(
select website_sessions.website_session_id, website_pageviews.website_pageview_id, pageview_url, 
(case when pageview_url = '/lander-1' then 1 else 0 end) as lander1,
(case when pageview_url = '/products' then 1 else 0 end) as products, 
(case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end) as mrfuzzy,
(case when pageview_url = '/cart' then 1 else 0 end) as cart,
(case when pageview_url = '/shipping' then 1 else 0 end) as shipping,
(case when pageview_url = '/billing' then 1 else 0 end) as billing,
(case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end) as thankyou
from website_sessions
left join website_pageviews
on website_sessions.website_session_id = website_pageviews.website_session_id
where 
	website_sessions.created_at between '2012-08-05' and '2012-09-05'
	and utm_source = 'gsearch' 
    and utm_campaign = 'nonbrand'
    and website_pageviews.pageview_url in ('/lander-1', '/products', '/the-original-mr-fuzzy', '/cart', '/shipping', '/billing', '/thank-you-for-your-order')
group by 1, 2, 3
order by 1)
as gsearch_nonbrand
group by 1 -- to see the if a particular made it individual pages or not 
;

select * from lander1_session_made_it_to_what_level;

select 
	count(website_session_id), 
	count(case when made_it_to_product = 1 then website_session_id else null end) as to_products,
	count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end) as to_mrfuzzy,
    count(case when made_it_to_cart = 1 then website_session_id else null end) as to_cart, 
    count(case when made_it_to_shipping = 1 then website_session_id else null end) as to_shipping,
    count(case when made_it_to_billing = 1 then website_session_id else null end) as to_billing,
    count(case when made_it_to_thankyou = 1 then website_session_id else null end) as to_thankyou 
from lander1_session_made_it_to_what_level
;

select 
	count(website_session_id), 
    count(case when made_it_to_product = 1 then website_session_id else null end)/count(website_session_id) as lander_clickthrough,
    count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end)/count(case when made_it_to_product = 1 then website_session_id else null end) as products_clickthrough,
	count(case when made_it_to_cart = 1 then website_session_id else null end)/count(case when made_it_to_mrfuzzy = 1 then website_session_id else null end) as mrfuzzy_clickthrough, 
	count(case when made_it_to_shipping = 1 then website_session_id else null end)/count(case when made_it_to_cart = 1 then website_session_id else null end) as cart_click_through,
	count(case when made_it_to_billing = 1 then website_session_id else null end)/count(case when made_it_to_shipping = 1 then website_session_id else null end) as shipping_click_through,
	count(case when made_it_to_thankyou = 1 then website_session_id else null end)/count(case when made_it_to_billing = 1 then website_session_id else null end) as billing_click_through
from lander1_session_made_it_to_what_level
;

-- Results:
-- The client should focus on lander, mrfuzzy, and billing page. Will modify billing page soon.
-- Next steps:
-- 1. Help the client analyze the billing page test they plan to run.
-- 2. Continue to look for oppurtunities to improve customer conversion rates. 


-- Q12. The client updated the billing page based on the funnel analysis. Check whether /billing-2 is doing better than the original /billing page.
-- What percentages of those orders end up placing an order. Run this test for all traffic, not just for search visitors.

-- 1. Start the analysis from the date when the first time /billing_2 was seen.
select min(created_at) as first_created_at, min(website_pageview_id) as  first_pv_id
from website_pageviews
where pageview_url = '/billing-2'
;

-- So, analyze the data from pageview_id 53550, to the date 10th November 2012

drop temporary;
select pageview_url, count(website_session_id)
from website_pageviews
where
	created_at < '2012-11-10'
    and website_pageview_id > 53550
	and pageview_url in ('/billing', '/billing-2')
group by 1
;


drop temporary table if exists bills;
create temporary table bills
select pageview_url, website_session_id
from website_pageviews
where
	created_at < '2012-11-10'
    and website_pageview_id > 53550
	and pageview_url in ('/billing', '/billing-2')
group by 1, 2
order by 2
;

select * from bills;

select bills.pageview_url, count(bills.website_session_id),
count(case when website_pageviews.pageview_url = '/thank-you-for-your-order' then website_pageviews.website_session_id else null end) as orders
from website_pageviews
right join bills
on website_pageviews.website_session_id = bills.website_session_id
where
	created_at < '2012-11-10'
    and website_pageview_id > 53550
    and website_pageviews.pageview_url in ('/billing', '/billing-2', '/thank-you-for-your-order')
group by 1
;



select bills.pageview_url, count(bills.website_session_id),
count(case when website_pageviews.pageview_url = '/thank-you-for-your-order' then website_pageviews.website_session_id else null end) as orders
from
(
select pageview_url, count(website_session_id)
from website_pageviews
where
	created_at < '2012-11-10'
    and website_pageview_id > 53550
	and pageview_url in ('/billing', '/billing-2')
group by 1
) as count
right join on
group by 1
;


















