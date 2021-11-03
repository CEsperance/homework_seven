-- 1. Create a new column called “status” in the rental table that uses a case statement to indicate if a film was returned late, early, or on time. 
-- -- create a view of select case when and alais it. Join it to rental table and select all columns 
DROP VIEW IF EXISTS Rental_Status;
CREATE VIEW Rental_Status AS
SELECT rental_id,
CASE 
WHEN rental_duration > date_part('day', return_date - rental_date) THEN 'Returned Early' 
WHEN rental_duration < date_part('day', return_date - rental_date) THEN 'Returned Late'
WHEN rental_duration = date_part('day', return_date - rental_date) THEN 'Returned on time'
END AS status
FROM film AS f
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id; 

SELECT *
FROM rental
INNER JOIN rental_status
ON rental.rental_id = rental_status.rental_id;

/* A view of the case statement was created and aliased as Rental_Status. The case statment was created to
go through the conditions of if a rental was returned early, late, or on timeRental_status was joined with
the rental table on the rental_id column (rental_id field was added to the rental_status view so that
both tables have a field in common). All columns were selected. By doing this, the Status column
was added to the rental table.*/

--2. Show the total payment amounts for people who live in Kansas City or Saint Louis. 
SELECT SUM(amount) AS total_payment, c2.city, p.customer_id
FROM payment AS p
INNER JOIN customer AS c1
ON p.customer_id = c1.customer_id
INNER JOIN address AS a
ON c1.address_id = a.address_id 
INNER JOIN city AS c2
ON a.city_id = c2.city_id
WHERE city = 'Saint Louis' OR city = 'Kansas City'
GROUP BY c2.city, p.customer_id;

/* Selected the total payment amounts for those who live in Kansas City or Saint Louis and customer_id. 
Four tables were joined to to get the necessary columns: payment aliased as p, customer aliased as c1, address aliased as a, 
and city aliased as c2. WHERE clause filtered the cities to be Saint Louis or Kansas City, 
and the results were GROUPED BY city column from city table.*/

--3. How many films are in each category? 
--Why do you think there is a table for category and a table for film category?
SELECT name AS Genre_Category, COUNT(title)
FROM film AS f
INNER JOIN film_category AS fc
ON f.film_id = fc.film_id
INNER JOIN category AS c
ON fc.category_id = c.category_id
GROUP BY Genre_Category;
/* There is a table for category category (Genre) data because it holds information that's only specific
the various categories(genre) that the stores have. Film category table is specific to the relationship
between films and categories. It's important that each table has a specific focus. */

--4. Show a roster for the staff that includes their email, address, city, and country (not ids)

SELECT staff_id, email, address, city, country
FROM staff AS s
INNER JOIN address AS a
ON s.address_id = a.address_id
INNER JOIN city AS c1
ON a.city_id = c1.city_id
INNER JOIN country AS c2
ON c1.country_id = c2.country_id; 

/* Four tables were joined to obtain staff_id, email, address, city, and country. An inner join was used
to join the tables on a similar field. The fields selected are displayed in the output. */

--5. Show the film_id, title, and length for the movies that were returned from May 15 to 31, 2005
SELECT f.film_id, title, length
FROM film AS f
INNER JOIN inventory AS i
ON f.film_id = i.film_id
INNER JOIN rental AS r
ON i.inventory_id = r.inventory_id
WHERE return_date BETWEEN '2005/05/15' AND '2005/05/31';

/* Film_id from the film table, title and length were selected. Film, inventory, and rental table are
joined using inner joins. The return date was filtered using a WHERE clause, BETWEEN keyword used to specify
values in the date range, AND keyword used with BETWEEN to combine multiple conditions. */

--6. Write a subquery to show which movies are rented below the average price for all movies. 
--SELECT AVG(rental_rate) 
--FROM film;

SELECT title, rental_rate
FROM film
WHERE rental_rate < (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate;

/* Subquery was created to find the average rental rate from the film table. This subquery is nested inside
another query using parantheses; the subquery is used in the WHERE clause as an expression
The subquery is executed first, then the its result is passed to the outer query. The outer query is
then executed. */

--7. Write a join statement to show which movies are rented below the average price for all movies.

SELECT f1.title, f1.rental_rate 
FROM film AS f1 
CROSS JOIN film AS f2
GROUP BY f1.title, f1.rental_rate
HAVING f1.rental_rate < AVG(f2.rental_rate);

/* Title and rental rate were selected from film table. The film table was given two different aliases since it's being joined with itself.
Every row in f1 was joined with f2 and returned the rows whose movies were rented below the average rental
rate. Including the HAVING clause is added to filter an aggregate function (WHERE will not work). HAVING also 
causes the CROSS JOIN to produce same result as an INNER JOIN*/


--8. Perform an explain plan on 6 and 7, and describe what you’re seeing and important ways they differ.

EXPLAIN ANALYZE
SELECT title, rental_rate
FROM film
WHERE rental_rate < (SELECT AVG(rental_rate) FROM film)
ORDER BY rental_rate; 

/* Sort  (actual time=1.091..1.121 rows=341 loops=1)
 - The actual time represents the startup time: 1.091, the maximum time is 147.80, and the rows returned are 341.
Aggregate  (actual time=0.510..0.511 rows=1 loops=1)
- the 
Seq Scan on film film_1  (cost=0.00..64.00 rows=1000 width=6) (actual time=0.002..0.234 rows=1000 loops=1)
Seq Scan on film  (cost=0.00..66.50 rows=333 width=21) (actual time=0.542..0.890 rows=341 loops=1)Total query run time is 113 msec. From the film table
Execution Time: 1.861 ms
Total query runtime: 123 msec. 1 row affected.*/

EXPLAIN ANALYZE
SELECT f1.title, f1.rental_rate 
FROM film AS f1 
CROSS JOIN film AS f2
GROUP BY f1.title, f1.rental_rate
HAVING f1.rental_rate < AVG(f2.rental_rate); -- , 
--Seq Scan on film f1  (cost=0.00..64.00 rows=1000 width=21) (actual time=0.006..0.871 rows=1000 loops=1)
--  Seq Scan on film f2  (cost=0.00..64.00 rows=1000 width=6) (actual time=0.003..0.364 rows=1000 loops=1)
--Execution Time: 758.054 ms 

/* Seq Scan on film f1  (cost=0.00..64.00 rows=1000 width=21) (actual time=0.010..2.989 rows=1000 loops=1)
- The startup time for film f1 table is 0.010, max time is 2.989, and returned rows are 1000
Seq Scan on film f2  (cost=0.00..64.00 rows=1000 width=6) (actual time=0.003..0.333 rows=1000 loops=1)
- The startup time for talble film f2 is 0.003,max time is 0.333, and rows returned are 1000
Execution Time: 758.054 ms
Total query runtime: 82 msec and 1 row affected

The subquery has a shorter execution time than the join statement, but a longer total total query runtime than the join statement when you look at the explain plan.*/

--9. With a window function, write a query that shows the film, its duration, and what percentile the duration fits into.
--This may help https://mode.com/sql-tutorial/sql-window-functions/#rank-and-dense_rank 

SELECT film_id, title, length, 
NTILE(10) OVER (ORDER BY length) AS perc_rank
FROM film;

/* Film_id, title, and length were selected from the fil table. NTILE is used to divide
the rows into ten buckets based on the ORDER BY. ORDER BY was used to sort the films duration by length in 
ascending order. */


--10. In under 100 words, explain what the difference is between set-based and procedural programming. Be sure to specify which sql and python are. 

/* Set-based is when groups of data interact with other groups of data. The database engine determines the best possible algorithms or processing logic to do these Procedural programming processes
the data line by line. With set-based programming, you tell a program what you want to know (what to do), not how to do it. Procedural programming tells a program what to
do and how to do it - like Python.*/

-- Find the relationship that is wrong in the data model. Explain why it’s wrong. 
