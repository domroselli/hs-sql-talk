/* FROM Cartesian product Example */
SELECT store.store_id, address.address
FROM store, address


/* Is there anything wrong with this query? */

SELECT *
FROM Customer;











/*
Depends...                                                                       
If you're doing querying for discovery purposes, it can be a legit form of an ad-hoc query. Of course, an improvement would be
                                                                                 
select * from customer limit 1; -- in SQL Server/mysql, it's SELECT TOP.         
                                --In Oralce it's SELECT ... WHERE ROWNUM = 1     
                                                                                 
Why it's bad in production.                                                      
1. You may not need all the columns for your query. This is bad for performance in several ways:
    * You may be returning more data than you actually need                      
    * This causes more network I/O, more disk I/O, and could circumvent your indexes (more on indexes later)
    * If you use this in a join, it will like fail (more on joins later)         
2. It's lazy and cause code maintenance problems:                                
    * It is not clear what the column dependencies are                           
    * If columns are added to the table, it can cause queries to failure when used with INSERT. For example:
      INSERT foo                                                                 
      SELECT *                                                                   
      FROM bar                                                                   
      If bar changes, and foo doesn't, this query will fail                      
    * There are probably other reasons this is a bad idea, just don't do it.     
*/


/* Additional rows I've added to the customer table */
INSERT INTO customer(store_id, first_name, last_name, email, address_id, activebool, create_date, last_update, active)
VALUES (1, 'DOM', 'ROSELLI', NULL, 5, true, '2006-02-14', '2006-02-15 09:57:20', 1)
      ,(1, 'CRASH', 'BANDICOOT', NULL, 5, true, '2006-02-14', '2006-02-15 09:57:20', 1);

CREATE TABLE invalid_email(email CHARACTER VARYING(50));


/* WHERE Example */
SELECT f.title, f.length
FROM film AS f
WHERE f.length < 90;

/* Comparison Operators
COMPARISON OPERATORS
--------------------
=
<> (!=)
>
<
>=
<=
IS NULL / IS NOT NULL
LIKE / NOT LIKE

You never look for something where it's = NULL. Always where it IS NULL.
The LIKE operator does wild card matching
*/
SELECT email
FROM customer
WHERE email LIKE '%@';


SELECT email
FROM customer
WHERE email = NULL;

SELECT email
FROM customer
WHERE email IS NULL;


/*
BETWEEN
-------
Use to filter on an inclusive range of values
*/

SELECT *
FROM rental
WHERE rental_date BETWEEN '2005-05-01' AND '2005-05-30'
ORDER BY rental_date DESC;

/*
IN
--
Each value in the () is OR'd with the value of each row in the specified column.
*/
SELECT email
FROM invalid_email
WHERE email IN (SELECT email FROM customer);

/* 
Is logically equivalent to:
((email = 'dom@roselli.com') OR (email = NULL) OR ...)

*/

/* What about this? */

SELECT email
FROM invalid_email
WHERE email NOT IN (SELECT email FROM customer);

/*
It is equivalent to:
NOT ((email = 'dom@roselli.com') OR (email = NULL) OR ...)


which by DeMorgan's Law, is equivalent to:
((email != 'dom@roselli.com') AND (email != NULL) AND ...)


!!! Anything AND'd with UNKNOWN (NULL) is either FALSE or UNKNOWN. !!!

Therefore, the entire expression is either UNKNOWN or FALSE
*/


/*
EXISTS
------
EXISTS can only evaluate to either TRUE or FALSE. 
It checks if the row in the table in the FROM clause is 
TRUE or FALSE in the WHREE clause. 

If its TRUE, the row is included in the virtual table returned by the WHERE clause.

For the un-negated case in these examples, they produce the same results as IN.
*/

SELECT email
FROM invalid_email AS e
WHERE EXISTS 
(
    SELECT email
    FROM invalid_email
    WHERE email = 'foofdsfa'
)


SELECT email
FROM invalid_email AS e
WHERE NOT EXISTS 
(
    SELECT email
    FROM invalid_email
    WHERE email = 'foofdsfa'
)

WHERE NOT EXISTS 
(
    SELECT email 
    FROM customer AS c 
    WHERE e.email = c.email
);



/* GROUP BY Example */

/*
    In this query, all the customer rows are placed into the group of store_id, 
    and we apply the COUNT(*) aggregate function to the groups. This effectively 
    means we have partitioned all the rows in the customer table by the various 
    values of store_id, and are counting the number of rows that are in either store_id group.
*/
select count(*)
from customer

SELECT store_id, COUNT(*)
FROM customer
GROUP BY store_id


/* What will this query produce? */
SELECT store_id
FROM customer
GROUP BY store_id

/* This is interesting */
SELECT *
FROM customer
GROUP BY store_id, active


/* And this one? */
SELECT store_id, active
FROM customer
GROUP BY store_id

/* Do we need a group by here? */
SELECT MAX(customer_id)
FROM customer

/* Is it okay to have a group by here? */
SELECT MAX(customer_id)
FROM customer
GROUP BY store_id


/* HAVING examples */

/* This will not work! */
SELECT MAX(customer_id)
FROM customer
WHERE MAX(customer_id) < 100


/* But this will! */
SELECT MAX(customer_id)
FROM customer
HAVING MAX(customer_id) > 0


/* What will this query produce? */
SELECT MAX(customer_id)
FROM customer
WHERE customer_id < 100

SELECT customer_id, MAX(customer_id)
FROM customer
GROUP BY customer_id
HAVING MAX(customer_id) < 100
order by customer_id


/* JOINS */

/* CROSS JOIN Example */
SELECT *
FROM customer
CROSS JOIN store

/* Implicit CROSS JOIN */
SELECT *
FROM customer, store


/* INNER JOIN Example */
SELECT C.first_name, C.last_name, C.email, E.email
FROM customer AS C
INNER JOIN invalid_email AS E
    ON C.email = E.email

/* LEFT OUTER JOIN Example */
SELECT C.first_name, C.last_name, C.email, E.email as invalid_email
FROM customer AS C
LEFT OUTER JOIN invalid_email AS E
    ON C.email = E.email
WHERE E.email IS NULL


/* RIGHT OUTER JOIN Example */
SELECT C.first_name, C.last_name, C.email, E.email
FROM customer AS C
RIGHT OUTER JOIN invalid_email AS E
    ON C.email = E.email
--WHERE C.email IS NULL


/* FULL OUTER JOIN Example */
/*
    Just to demonstrate what is related between the two tables 
    
SELECT C.first_name, C.last_name, C.email, E.email
FROM customer AS C
INNER JOIN invalid_email AS E
    ON C.email = E.email

*/

SELECT C.first_name, C.last_name, C.email, E.email
FROM customer AS C
FULL OUTER JOIN invalid_email AS E
    ON C.email = E.email
WHERE (C.email IS NULL OR E.email IS NULL)



/* ON vs WHERE */

/* Here, the preserved rows from the LEFT table get put back into the
   resulting virtulal table on the LEFT OUTER JOIN
*/

SELECT E.email, C.first_name, C.last_name, C.email
FROM invalid_email AS E
JOIN customer AS C
    ON C.email = E.email
    AND C.email = 'MARY.SMITH@sakilacustomer.org'

SELECT E.email, C.first_name, C.last_name, C.email
FROM invalid_email AS E
LEFT OUTER JOIN customer AS C
    ON C.email = E.email
    AND C.email = 'fasfds'

/* Even though perserved rows from the LEFT table are put back into
   the resulting virtual table, the WHERE clause filters them out
*/
SELECT E.email, C.first_name, C.last_name, C.email
FROM invalid_email AS E
INNER JOIN customer AS C
    ON C.email = E.email
WHERE C.email = 'MARY.SMITH@sakilacustomer.org'


/* More JOIN fun */

/* What do you think this query will do? */
SELECT E.email, C.first_name, C.last_name, C.email
FROM invalid_email AS E
LEFT OUTER JOIN customer AS C
    ON E.email = 'MARY.SMITH@sakilacustomer.org'

/* And this? */
SELECT E.email, C.first_name, C.last_name, C.email
FROM invalid_email AS E
LEFT OUTER JOIN customer AS C
    ON E.email = 'dfja;jfd'

/* Sub-Queries */
SELECT S.customer_id, S.last_rental_date, C.first_name || ' ' || C.last_name AS full_name
FROM
(
    SELECT C.customer_id, MAX(R.rental_date) AS last_rental_date
    FROM customer AS C
    JOIN rental AS R
        ON C.customer_id = R.customer_id
    GROUP BY C.customer_id
) AS S
JOIN customer AS C
    ON S.customer_id = C.customer_id


SELECT S2.customer_id, S2.last_rental_date, S2.full_name, A.address
FROM
(
    SELECT S1.customer_id
        , C.address_id
        , S1.last_rental_date, C.first_name || ' ' || C.last_name AS full_name
    FROM
    (
        SELECT C.customer_id, MAX(R.rental_date) AS last_rental_date
        FROM customer AS C
        JOIN rental AS R
            ON C.customer_id = R.customer_id
        GROUP BY C.customer_id
    ) AS S1
    JOIN customer AS C
        ON S1.customer_id = C.customer_id
) AS S2
JOIN address A
    ON S2.address_id = A.address_id
