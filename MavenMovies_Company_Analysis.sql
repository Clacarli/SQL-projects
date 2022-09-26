-- BUSINESS ANALYSIS OF THE COMPANY MAVEN MOVIES

/* 
1. My partner and I want to come by each of the stores in person and meet the managers. 
Please send over the managers’ names at each store, with the full address 
of each property (street address, district, city, and country please).  
*/ 

SELECT staff.first_name, 
			 staff.last_name, 
       staff.store_id, 
       address.address, 
       address.district, 
       city.city, 
       country.country
FROM staff
	LEFT JOIN address ON staff.address_id = address.address_id
	LEFT JOIN city ON address.city_id = city.city_id
	LEFT JOIN country ON city.country_id = country.country_id;


/*
2.	I would like to get a better understanding of all of the inventory that would come along with the business. 
Please pull together a list of each inventory item you have stocked, including the store_id number, 
the inventory_id, the name of the film, the film’s rating, its rental rate and replacement cost. 
*/

SELECT inventory.inventory_id, 
			 inventory.store_id, 
       film.title, film.rating, 
       film.rental_rate, 
       film.replacement_cost
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id;


/* 
3.	From the same list of films you just pulled, please roll that data up and provide a summary level overview 
of your inventory. We would like to know how many inventory items you have with each rating at each store. 
*/

SELECT inventory.store_id,
			 film.rating,
       COUNT(inventory.inventory_id) AS N_items
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id
GROUP BY film.rating, inventory.store_id
ORDER BY store_id;


/* 
4. Similarly, we want to understand how diversified the inventory is in terms of replacement cost. We want to 
see how big of a hit it would be if a certain category of film became unpopular at a certain store.
We would like to see the number of films, as well as the average replacement cost, and total replacement cost, 
sliced by store and film category. 
*/ 

SELECT store_id, 
			 category.name AS category, 
       COUNT(inventory.inventory_id) AS N_films, 
       AVG(film.replacement_cost), 
       SUM(film.replacement_cost) AS Tot_replace_cost
FROM inventory
	LEFT JOIN film ON inventory.film_id = film.film_id
  LEFT JOIN film_category ON film.film_id = film_category.film_id
  LEFT JOIN category ON category.category_id = film_category.category_id
GROUP BY store_id, category.name
ORDER BY SUM(film.replacement_cost) DESC;


/*
5.	We want to make sure you folks have a good handle on who your customers are. Please provide a list 
of all customer names, which store they go to, whether or not they are currently active, 
and their full addresses – street address, city, and country. 
*/

SELECT DISTINCT customer.customer_id, 
								customer.first_name, 
                customer.last_name, 
                customer.store_id, 
                customer.active, 
                address.address, 
                city.city, 
                country.country
FROM customer
	LEFT JOIN address ON address.address_id = customer.address_id
  LEFT JOIN city ON city.city_id = address.city_id
  LEFT JOIN country ON country.country_id = city.country_id;


/*
6.	We would like to understand how much your customers are spending with you, and also to know 
who your most valuable customers are. Please pull together a list of customer names, their total 
lifetime rentals, and the sum of all payments you have collected from them. It would be great to 
see this ordered on total lifetime value, with the most valuable customers at the top of the list. 
*/

SELECT DISTINCT customer.customer_id, 
								customer.first_name, 
                customer.last_name, 
                COUNT(rental.rental_id) AS total_rentals, 
                SUM(payment.amount) AS total_payment
FROM customer
	LEFT JOIN rental ON rental.customer_id = customer.customer_id
	LEFT JOIN payment ON rental.rental_id = payment.rental_id
GROUP BY customer.customer_id, customer.first_name, customer.last_name
ORDER BY SUM(payment.amount) DESC;

    
/*
7. My partner and I would like to get to know your board of advisors and any current investors.
Could you please provide a list of advisor and investor names in one table? 
Could you please note whether they are an investor or an advisor, and for the investors, 
it would be good to include which company they work with. 
*/

SELECT 'Advisor' AS Type, advisor.first_name, advisor.last_name, '-' AS Company
FROM advisor
UNION 
SELECT 'Investor' AS Type, investor.first_name, investor.last_name, investor.company_name AS Company
FROM investor;


/*
8. We're interested in how well you have covered the most-awarded actors. 
Of all the actors with three types of awards, for what % of them do we carry a film?
And how about for actors with two types of awards? Same questions. 
Finally, how about actors with just one award? 
*/

SELECT 
	CASE 
			WHEN actor_award.awards = 'Emmy, Oscar, Tony ' THEN '3 awards'
      WHEN actor_award.awards IN ('Emmy, Oscar', 'Oscar, Tony', 'Emmy, Tony') THEN '2 awards'
      ELSE '1 award'
	END AS number_awards,
  AVG(CASE WHEN actor_award.actor_id IS NULL THEN 0 ELSE 1 END) * 100 AS pct_in_inventory
FROM actor_award
GROUP BY 
		CASE 
			WHEN actor_award.awards = 'Emmy, Oscar, Tony ' THEN '3 awards'
      WHEN actor_award.awards IN ('Emmy, Oscar', 'Oscar, Tony', 'Emmy, Tony') THEN '2 awards'
      ELSE '1 award'
		END;
    
    
-- Coded by Clacarli
