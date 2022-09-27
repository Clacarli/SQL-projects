SELECT * FROM inventory_non_normalized;

/*  1. Only one big table present, the data is not normalized. There is mixed info about inventory, film, ratings, stores
		2. I would create 3 tables: Inventory, Film and Store
    3. Create the new schema and tables accordingly
*/

--  4.Populate table with records from old table

INSERT INTO inventory (inventory_id,film_id,store_id,rental_rate)
		SELECT inventory_id,
					 film_id,
					 store_id,
					 rental_rate 
FROM mavenmoviesmini.inventory_non_normalized;

INSERT INTO film (film_id,title,description,release_year,rating)
		SELECT film_id,
					 title,
           description,
           release_year,
           rating 
FROM mavenmoviesmini.inventory_non_normalized;

INSERT INTO store (store_id,manager_first_name,manager_last_name,store_address,store_city,store_district)
	SELECT DISTINCT store_id,
                  store_manager_first_name,
                  store_manager_last_name,
                  store_address,
                  store_city,
                  store_district
FROM mavenmoviesmini.inventory_non_normalized;

SELECT * FROM inventory;
SELECT * FROM film;
SELECT * FROM store;

--  5.Verify necessary keys and costraints are applied

/*  6. Summary and report of technical work to non-technical clients:
			 Starting from a unique table of conetnt which was difficult to explore and query, I created 3 separate tables based on the data type.
       Now the content is categorised by inventory, film and store information where the inventory table holds the link to the other 2 and with simple joins all queries can easily be written.
*/
