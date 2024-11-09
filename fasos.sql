--CREATE TABLES AND INSERT DATA
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');



CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');



CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');



CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');



CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);




CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');


select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;


-------------------------------------------------
--------------------BUSINESS QUERIES-------------

-----ROll METRICES-----

--1. How many rolls were ordered?
SELECT * FROM rolls
SELECT * FROM customer_orders
SELECT * FROM driver
SELECT * FROM driver_order
SELECT * FROM rolls_recipes
SELECT * FROM ingredients
	
SELECT COUNT(roll_id) FROM customer_orders

--2. How many unique customer orders were made?
SELECT COUNT(DISTINCT customer_id) 
FROM customer_orders

--3. How many successful orders delivered by each delivery partner?
SELECT driver_id, COUNT(DISTINCT order_id)
FROM driver_order
WHERE pickup_time IS NOT NULL
GROUP BY driver_id

--4. How many each type of roll was delivered?
SELECT customer_orders.roll_id, COUNT(customer_orders.roll_id)
FROM customer_orders
LEFT JOIN driver_order
ON driver_order.order_id = customer_orders.order_id
WHERE driver_order.distance IS NOT NULL
GROUP BY roll_id 
ORDER BY roll_id 

--5. How many Veg and Non Veg rolls were ordered by each customer?
With cp as
	(SELECT customer_id, roll_id, 
	(
CASE 
WHEN roll_id =1 and not_include_items='1' and not_include_items='3' and not_include_items='5' and 
	not_include_items='8' THEN 'veg_roll'
WHEN extra_items_included IN ('1','3','5','8') and roll_id=2 THEN 'Non_Veg'
WHEN not_include_items IS NULL and extra_items_included IS NULL and roll_id =2 Then 'Veg'
WHEN roll_id =1 THEN 'Non_Veg'
	ELSE 'Veg'
END )
	AS roll_type
FROM customer_orders
	GROUP BY customer_id, roll_id, not_include_items, extra_items_included )

SELECT customer_id, 
	SUM
	(CASE 
	WHEN roll_type= 'Veg' THEN 1
	ELSE 0
	END ) AS Veg,
	SUM
	(CASE 
	WHEN roll_type= 'Non_Veg' THEN 1
	ELSE 0
	END ) AS Non_Veg
FROM cp
GROUP BY customer_id
ORDER BY customer_id

--6. What was maximum number of rolls delivered in single order?
SELECT customer_orders.order_id, COUNT(customer_orders.roll_id) as number_rolls
FROM customer_orders
LEFT JOIN driver_order
ON driver_order.order_id = customer_orders.order_id
WHERE driver_order.distance IS NOT NULL
GROUP BY customer_orders.order_id
ORDER BY number_rolls desc
LIMIT 1

--7. For each customer, how many deivered rolls had atleast 1 change and how many had no changes?
WITH temp_customer_orders AS
	(SELECT customer_orders.customer_id,
	(CASE
	WHEN customer_orders.not_include_items IS NULL OR 
	customer_orders.not_include_items = ('') THEN '0' ELSE customer_orders.not_include_items
	END) AS not_include_items,
	(CASE
	WHEN customer_orders.extra_items_included IS NULL OR 
	customer_orders.extra_items_included=('') OR customer_orders.extra_items_included=(' ')
	THEN '0' ELSE customer_orders.extra_items_included
	END) AS extra_items_included, 
	driver_order.order_id, 
	driver_order.distance as distance
FROM customer_orders
LEFT JOIN driver_order
ON driver_order.order_id = customer_orders.order_id
GROUP BY customer_orders.customer_id, customer_orders.not_include_items, 
	customer_orders.extra_items_included, driver_order.order_id, 
	driver_order.distance)

SELECT customer_id, SUM(
CASE WHEN not_include_items= '0' and extra_items_included='0' THEN 1
ELSE 0
END) AS no_change, SUM(
CASE WHEN not_include_items<> '0' or extra_items_included<>'0' THEN 1
ELSE 0
END) AS change
FROM temp_customer_orders
WHERE distance IS NOT NULL
GROUP BY customer_id
ORDER BY customer_id

--8. How many rolls were delivered that had both exclusions and extras?
WITH temp_customer_orders AS
	(SELECT customer_orders.customer_id,
	(CASE
	WHEN customer_orders.not_include_items IS NULL OR 
	customer_orders.not_include_items = ('') THEN '0' ELSE customer_orders.not_include_items
	END) AS not_include_items,
	(CASE
	WHEN customer_orders.extra_items_included IS NULL OR 
	customer_orders.extra_items_included=('') OR customer_orders.extra_items_included=(' ')
	THEN '0' ELSE customer_orders.extra_items_included
	END) AS extra_items_included, 
	driver_order.order_id, 
	driver_order.distance as distance
FROM customer_orders
LEFT JOIN driver_order
ON driver_order.order_id = customer_orders.order_id
GROUP BY customer_orders.customer_id, customer_orders.not_include_items, 
	customer_orders.extra_items_included, driver_order.order_id, 
	driver_order.distance)

SELECT SUM(
CASE WHEN not_include_items<> '0' and extra_items_included<>'0' THEN 1
ELSE 0
END) AS rolls_delivered
FROM temp_customer_orders
WHERE distance IS NOT NULL

--9. What was the total number of rolls ordered for each hour of the day?
SELECT 
	(EXTRACT(HOUR FROM order_date) || ' - ' ||
	(EXTRACT(HOUR FROM order_date)+1)) as Hour_day,
	COUNT(roll_id)
FROM customer_orders
GROUP BY  Hour_day
ORDER BY Hour_day

--10. What was the number of orders for each day of week?
SELECT 
	TO_CHAR(order_date, 'Day') as week,
	COUNT(roll_id)
FROM customer_orders
GROUP BY  week
ORDER BY week


-----DRIVER AND CUSTOMER EXPERIENCE-----

--1. What was average time in minutes it took for each driver to arrive at 
--the fasoos HQ to pickup the order?

SELECT driver_order.driver_id,(AVG(EXTRACT(MINUTE FROM (driver_order.Pickup_time)-
(customer_orders.order_date)))
FROM driver_order
LEFT JOIN customer_orders
ON driver_order.order_id = customer_orders.order_id
WHERE driver_order.Pickup_time IS NOT NULL
GROUP BY driver_order.driver_id

--2. Is there any relationship between number of rolls and how long order takes to prepare?
SELECT customer_orders.order_id, COUNT(customer_orders.roll_id) as no_rolls,
(AVG(EXTRACT(MINUTE FROM (driver_order.Pickup_time)-
(customer_orders.order_date)))) as time
FROM driver_order
LEFT JOIN customer_orders
ON driver_order.order_id = customer_orders.order_id
WHERE driver_order.Pickup_time IS NOT NULL
GROUP BY customer_orders.order_id
ORDER BY no_rolls desc, time


--3. What is the average distance travelled for each of customer?
SELECT customer_orders.customer_id, 
ROUND(AVG((replace(driver_order.distance, 'km',''))::text::NUMERIC),2)
FROM customer_orders
LEFT JOIN driver_order
ON driver_order.order_id = customer_orders.order_id
WHERE driver_order.Pickup_time IS NOT NULL
GROUP BY customer_orders.customer_id
ORDER BY customer_orders.customer_id

--4. What was the difference between shortest and longest delivery times of all orders?
SELECT (MAX(SUBSTRING(duration FROM 1 FOR 2)::text::numeric)-
(MIN(SUBSTRING(duration FROM 1 FOR 2)::text::numeric)))
FROM driver_order
WHERE duration IS NOT NULL

--5. What was the average speed for each driver for each delivery?
SELECT driver_id,order_id,  ROUND(AVG((replace(driver_order.distance, 'km','')::text::numeric)/
(SUBSTRING(duration FROM 1 FOR 2)::text::numeric)),2) as speed
FROM driver_order
WHERE duration IS NOT NULL
GROUP BY driver_id, order_id
ORDER BY driver_id, order_id

--6. What is the successful percentage delivery for each driver?
with co as
(SELECT driver_id, (CASE WHEN distance IS NOT NULL THEN 1
ELSE 0
END) As distance
FROM driver_order)
SELECT driver_id, ROUND(((SUM(distance)*1.0)/COUNT(driver_id))*100)
FROM co
GROUP BY driver_id
ORDER BY driver_id
SELECT * FROM driver_order