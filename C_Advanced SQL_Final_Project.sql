/* Project on Maven Fuzzy factory database.
	 Assigment: The company	is meeting with potential investors.
	 Please pull together some data to build a history of the company and show our growth.*/

-- 1. Overall session and order volume for the whole business life till the last completed quarter

SELECT YEAR(website_sessions.created_at) AS year, 
			 QUARTER(website_sessions.created_at) AS quarter,
			 COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
       COUNT(DISTINCT order_id) AS orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at <= '2014-12-31'
GROUP BY 1,2;


-- 2. Show quarterly summary of conversion rates, revenue per order and per session

SELECT YEAR(website_sessions.created_at) AS year, 
			 QUARTER(website_sessions.created_at) AS quarter,
			 COUNT(DISTINCT order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
       SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS rev_session,
       SUM(price_usd)/COUNT(DISTINCT order_id) AS rev_order
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at <= '2014-12-31'
GROUP BY 1,2;


-- 3. Show quarterly summary by channels

SELECT YEAR(website_sessions.created_at) AS year, 
			 QUARTER(website_sessions.created_at) AS quarter,
			 COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS gsearch_nb_orders,
       COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END) AS bsearch_nb_orders,
       COUNT(CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END) AS brand_orders,
       COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END) AS organic_search_orders,
       COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END) AS direct_type_orders
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at <= '2014-12-31'
GROUP BY 1,2;


-- 4. Using above channels, please show sessions to order conversion rates

SELECT YEAR(website_sessions.created_at) AS year, 
			 QUARTER(website_sessions.created_at) AS quarter,
			 COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END)/
				COUNT(CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_nb_crt,
       COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN order_id ELSE NULL END)/
				COUNT(CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_nb_crt,
       COUNT(CASE WHEN utm_campaign = 'brand' THEN order_id ELSE NULL END)/
				COUNT(CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_crt,
       COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN order_id ELSE NULL END)/
				COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_crt,
       COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN order_id ELSE NULL END)/
				COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_crt
FROM website_sessions
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at <= '2014-12-31'
GROUP BY 1,2;

		/* A general growth trend can be spotted on all channels throughout the business life.
			 The first quarter of 2014 seemed the strongest for both brand and organic orders.
       All channels had a sudden growth in the first quarter of 2013 and then another growth, especially for the bsearch nb which also detain the highest crt of all channels.*/


-- 5. Pull monthly trends for revenue and margin by product

SELECT YEAR(created_at) AS year,
			 MONTH(created_at) AS month,
			 SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
       SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
       SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
       SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
       SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS sugarpanda_rev,
       SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
       SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS riverbear_rev,
       SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
       SUM(price_usd) AS tot_revenue,
       SUM(price_usd) - SUM(cogs_usd) AS tot_margin,
       COUNT(DISTINCT order_id) AS tot_orders
FROM order_items

GROUP BY 1,2;

/* February as a surge of sales which may be connected to S.Valentine.
	 Junes is always downtime while May seem to give a kick to sales. */
   

-- 6. Monthly sessions of the products page with ctr to another page and crt from products to order

CREATE TEMPORARY TABLE products_sessions_next_views
SELECT products_views.created_at,
			 products_views.website_session_id,
       MIN(website_pageviews.website_pageview_id) AS page_after_products
FROM (
SELECT created_at,
			 website_pageviews.website_session_id,
       website_pageviews.website_pageview_id
FROM website_pageviews
WHERE pageview_url = '/products'
) AS products_views
LEFT JOIN website_pageviews
	ON products_views.website_session_id = website_pageviews.website_session_id
  AND website_pageviews.website_pageview_id > products_views.website_pageview_id
GROUP BY 1, 2;

SELECT YEAR(products_sessions_next_views.created_at)AS year, 
			 MONTH(products_sessions_next_views.created_at)AS month,
       COUNT(DISTINCT products_sessions_next_views.website_session_id) AS products_page_sessions,
       COUNT(DISTINCT products_sessions_next_views.page_after_products) AS sessions_to_next_page,
			 COUNT(DISTINCT products_sessions_next_views.page_after_products)/
				COUNT(DISTINCT products_sessions_next_views.website_session_id) AS products_ctr,
        COUNT(order_id) AS orders,
			 COUNT(order_id)/COUNT(DISTINCT products_sessions_next_views.website_session_id) AS products_order_crt
FROM products_sessions_next_views
LEFT JOIN orders
	ON products_sessions_next_views.website_session_id = orders.website_session_id
GROUP BY 1,2;
			 

-- 7. Our 4th product became our primary one since Dec 5th, pull sales and cross-sells data by product

CREATE TEMPORARY TABLE primary_products_w_xsell_id
SELECT orders.order_id,
			 orders.primary_product_id,
       orders.created_at,
       order_items.product_id AS cross_sell_id
FROM orders
LEFT JOIN order_items
	ON orders.order_id = order_items.order_id
  AND order_items.is_primary_item = 0
WHERE orders.created_at > '2014-12-05';

SELECT * FROM primary_products_w_xsell_id;

SELECT primary_product_id,
			 COUNT(DISTINCT order_id) AS orders,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 1 THEN order_id ELSE NULL END) AS xsold_p1,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 2 THEN order_id ELSE NULL END) AS xsold_p2,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 3 THEN order_id ELSE NULL END) AS xsold_p3,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 4 THEN order_id ELSE NULL END) AS xsold_p4,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
       COUNT(DISTINCT CASE WHEN cross_sell_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM primary_products_w_xsell_id
GROUP BY 1;


-- Coded by Claudia Carli 