/* Project on Maven Fuzzy Factory database
	 Assigment: tell company growth story in the last 8 months through trends plus current performance */
   
   -- 1. Show gsearch sessions and orders monthly trends

SELECT  MONTH(website_sessions.created_at) AS month,
        COUNT(website_sessions.website_session_id) AS tot_sessions,
        COUNT(orders.order_id) AS tot_orders,
        COUNT(orders.order_id)/COUNT(website_sessions.website_session_id) AS conversion_rate
FROM website_sessions
 LEFT JOIN orders 
 ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
		AND utm_source = 'gsearch'
GROUP BY MONTH(created_at)
;


 -- 2 Show these trends separately for brand and non-brand
 
SELECT  MONTH(website_sessions.created_at) AS month,
        COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS non_brand_sessions,
				COUNT(CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_sessions,
				COUNT(CASE WHEN utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS non_brand_orders,
        COUNT(CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_orders
FROM website_sessions
 LEFT JOIN orders 
 ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
		AND utm_source = 'gsearch'
GROUP BY MONTH(created_at)
;


 -- 3 Show the nonbrand trends by device
 
SELECT  MONTH(website_sessions.created_at) AS month,
        COUNT(CASE WHEN device_type = 'mobile' THEN website_sessions.website_session_id ELSE NULL END) AS Mobile_nonbrand_sessions,
				COUNT(CASE WHEN device_type = 'desktop' THEN website_sessions.website_session_id ELSE NULL END) AS Desktop_nonbrand_sessions,
				COUNT(CASE WHEN device_type = 'mobile' THEN orders.order_id ELSE NULL END) AS Mobile_nonbrand_orders,
        COUNT(CASE WHEN device_type = 'desktop' THEN orders.order_id ELSE NULL END) AS Desktop_nonbrand_orders
FROM website_sessions
 LEFT JOIN orders 
 ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
		AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY MONTH(created_at)
;


 -- 4 Find monthly trends for gsearch vs other channels
 
SELECT MONTH(website_sessions.created_at) AS month,
				COUNT(CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_sessions,
				COUNT(CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_sessions,
				COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_sessions,
        COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_sessions
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY MONTH(created_at)
;


-- 5 Show the monthly conversion rate of the company website

SELECT  MONTH(website_sessions.created_at) AS month,
        COUNT(website_sessions.website_session_id) AS tot_sessions,
        COUNT(orders.order_id) AS tot_orders,
        COUNT(orders.order_id)/COUNT(website_sessions.website_session_id)*100 AS conversion_rate
FROM website_sessions
 LEFT JOIN orders 
 ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at < '2012-11-27'
GROUP BY MONTH(created_at)
;


 -- 6 For gsearch lander test, estimate revenue earning
 
	-- Find first pageview for each session within the test period  
CREATE TEMPORARY TABLE first_pv_test_nb
SELECT DISTINCT website_sessions.website_session_id,
			 MIN(website_pageviews.website_pageview_id) AS first_pageviews,
			 website_pageviews.pageview_url
	FROM website_pageviews
  INNER JOIN website_sessions
		ON website_sessions.website_session_id = website_pageviews.website_session_id
    AND website_sessions.created_at < '2012-07-28'
		AND website_pageviews.website_pageview_id >= 23504
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
	GROUP BY website_session_id;
  
  -- Find which of these sessions converted to orders 
  
CREATE TEMPORARY TABLE test_sessions_orders
SELECT first_pv_test_nb.website_session_id,
				 first_pv_test_nb.pageview_url,
         orders.order_id
	FROM first_pv_test_nb
   LEFT JOIN orders
   ON first_pv_test_nb.website_session_id = orders.website_session_id;
	
  -- Produce summary for these sessions
  
SELECT pageview_url,
			 COUNT(DISTINCT website_session_id) AS sessions,
       COUNT(DISTINCT order_id) AS orders,
       COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id)*100 AS conv_rate
FROM test_sessions_orders
GROUP BY 1;
	 -- Lander-1 had a 0.87% improved conversion rate
  
  -- Find the last session where the first pageview was the old home
  
SELECT MAX(website_sessions.website_session_id)
FROM website_sessions
	LEFT JOIN website_pageviews
  ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
  AND pageview_url = '/home'
  AND website_sessions.created_at < '2012-11-27';
   -- Last /home session was 17145
 
  -- Find the number of sessions occurred between the last home one and now
SELECT COUNT(website_sessions.website_session_id) AS sessions_since_test
FROM website_sessions
WHERE created_at < '2012-11-27'
	AND utm_source = 'gsearch'
  AND utm_campaign = 'nonbrand'
  AND website_session_id > 17145;
   -- 22,972 sessions x .87% additional conversion rate = 200 additional orders in 4 months period (about 50 orders more per month)


-- 7. Analyse full conversion funnel for both landing pages for same period

  -- First I flag all pageviews by session and url

CREATE TEMPORARY TABLE sessions_flagged
SELECT website_session_id,
			 MAX(home_page) AS saw_homepage,
			 MAX(custom_lander) AS saw_custom_lander,
			 MAX(products_page) AS product_made_it,
			 MAX(mrfuzzy_page) AS mrfuzzy_made_it,
       MAX(cart_page) AS cart_made_it,
       MAX(shipping_page) AS shipping_made_it,
       MAX(billing_page) AS billing_made_it,
       MAX(thankyou_page) AS thankyou_made_it
FROM(
	SELECT website_sessions.website_session_id,
				 website_pageviews.pageview_url,
         CASE WHEN pageview_url = '/home' THEN 1 ELSE 0 END AS home_page,
         CASE WHEN pageview_url = '/lander-1' THEN 1 ELSE 0 END AS custom_lander,
         CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
         CASE WHEN pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
         CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
         CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
         CASE WHEN pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
         CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
	LEFT JOIN website_pageviews
		ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.utm_source = 'gsearch'
	AND website_sessions.utm_campaign = 'nonbrand'
  AND website_sessions.created_at BETWEEN '2012-06-19' AND '2012-07-28'
  ORDER BY website_sessions.website_session_id,
					 website_sessions.created_at
) AS pageview_flags
GROUP BY website_session_id
;
 
 -- Now I build the conversion funnel for each landing page by counting the flags per segment
  
SELECT 
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage' 
		WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
		ELSE 'check logic'
	END AS segment,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM sessions_flagged
GROUP BY 1;

  -- Now displaying the same info as clickthrough rates
  
SELECT 
	CASE
		WHEN saw_homepage = 1 THEN 'saw_homepage' 
		WHEN saw_custom_lander = 1 THEN 'saw_custom_lander'
		ELSE 'check logic'
	END AS segment,
	COUNT(DISTINCT website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS lander_ctr,
	COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN product_made_it = 1 THEN website_session_id ELSE NULL END) AS products_crt,
	COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS mrfuzzy_crt,
	COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_crt,
	COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_crt,
	COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_crt
FROM sessions_flagged
GROUP BY 1;


-- 8. Quantify impact of billing test in terms of revenue per page version then calculate total billing ctr per last month

SELECT billing_page_v,
			 COUNT(DISTINCT website_session_id) AS sessions,
			 SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page
FROM(
SELECT website_pageviews.website_session_id,
			 website_pageviews.pageview_url AS billing_page_v,
       orders.order_id,
       orders.price_usd
FROM website_pageviews
 LEFT JOIN orders
 ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at BETWEEN '2012-09-10' AND '2012-11-10'
	AND website_pageviews.pageview_url IN ('/billing','/billing-2')

)AS billing_page_vs_order
GROUP BY 1;
  -- $22,83 old version revenue per billing page view
  -- $31,34 new version revenue per billing page view
  -- LIFT: $8,51 per pageview 
  
SELECT COUNT(website_session_id) AS billing_sessions_las_month
FROM website_pageviews
WHERE pageview_url IN ('/billing','/billing-2')
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27';
-- 1193 total sessions got to a billing page last month
-- Multiplied by the Lift per session at $8,51 
-- VALUE OF BILLING PAGE TEST: $10,000 per month

         
  -- Coded by Claudia Carli       

       

  