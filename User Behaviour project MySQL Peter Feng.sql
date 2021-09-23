USE self;

-- data is between 2017/09/11 to 2017/12/03


-- first look at all the data
SELECT * FROM userbehavior;

-- DATA CLEANING AND PREPARATION

-- check and deal with duplicate values
SELECT user_id, product_id, timestamp
FROM userbehavior
GROUP BY user_id, product_id, timestamp
HAVING COUNT(user_id)>1;
-- result shows no duplicate values

-- check and deal with missing
SELECT COUNT(user_id), COUNT(product_id), 
COUNT(category_id), COUNT(behaviour_type), COUNT(timestamp)
FROM userbehavior;
-- result shows no missing values

-- add ID column to the table as row no
ALTER TABLE userbehavior
ADD ID int unsigned primary key auto_increment;

-- add more time columns to the table
-- because timestamp makes no sense so set date and time to make more sense
ALTER TABLE userbehavior
ADD (date_time varchar(260), date varchar(260), time varchar(260));

UPDATE userbehavior
SET date_time = FROM_UNIXTIME(timestamp, '%Y-%m-%d %k:%i:%s'),
date=FROM_UNIXTIME(timestamp,'%Y-%m-%d'),
time=FROM_UNIXTIME(timestamp,'%k:%i:%s')
WHERE ID BETWEEN 1 AND 55891;

-- add hour to the table
ALTER TABLE userbehavior ADD hour INT(10);
UPDATE userbehavior SET hour = HOUR(time)
WHERE ID BETWEEN 1 AND 55891;

-- checking different purchase behaviour first
SELECT DISTINCT(behaviour_type) FROM userbehavior;

-- DATA ANALYSIS
							     
-- data info
SELECT 
COUNT(DISTINCT(user_id)) AS customers,
COUNT(DISTINCT(product_id)) AS products,
COUNT(DISTINCT(category_id)) AS categories,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'page visit',
SUM(CASE WHEN behaviour_type = 'fav' THEN 1 ELSE 0 END) AS collection,
SUM(CASE WHEN behaviour_type = 'cart' THEN 1 ELSE 0 END) AS 'add to cart',
SUM(CASE WHEN behaviour_type = 'buy' THEN 1 ELSE 0 END) AS purchased
FROM userbehavior;

-- page visit analysis
SELECT 
COUNT(DISTINCT(user_id)) AS customers,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS page_visit,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per customer'
FROM userbehavior;
-- result shows average page visited 97 times between 2017/11/25 to 2017/12/03

-- CUSTOMER ANALYSIS
-- customer volume analysis per day
SELECT date,
COUNT(DISTINCT(user_id)) AS 'total visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'total page visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per customer'
FROM userbehavior
GROUP BY date
ORDER BY SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) desc;

-- customer volume analysis per hour
SELECT hour,
COUNT(DISTINCT(user_id)) AS 'total visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'total page visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per user'
FROM userbehavior
GROUP BY hour
ORDER BY hour;

-- TIME ANALYSIS
-- purchased based on date
select date, sum(case when behaviour_type ='buy' then 1 else 0 end) as 'purchased'
from userbehavior
group by date
order by date;
-- more purchase at the end of November

-- purchased based on hour
SELECT hour, SUM(CASE WHEN behaviour_type = 'buy' THEN 1 ELSE 0 END) AS 'purchased'
FROM userbehavior
GROUP BY hour
ORDER BY hour;
-- more purchase during night, peak at 19pm

-- active user based on date
SELECT date, COUNT(DISTINCT(user_id)) AS 'active customer'
FROM userbehavior
GROUP BY date 
ORDER BY date; 

-- active user based on hour
SELECT hour, COUNT(DISTINCT(user_id)) AS 'active customer'
FROM userbehavior
GROUP BY hour 
ORDER BY hour; 

-- average payment frequency by date
SELECT date, behaviour_type, COUNT(DISTINCT(user_id)) AS 'customer',
SUM(CASE WHEN behaviour_type='buy' THEN 1 ELSE 0 END)/COUNT(DISTINCT(user_id)) AS 'average customer purchase frequency'
FROM userbehavior
WHERE behaviour_type='buy'
GROUP BY date
ORDER BY date ASC;
-- very stable rate of average 1.5 buy frequency per day

-- average payment frequency by hour
SELECT hour, COUNT(DISTINCT user_id) as customer
FROM userbehavior
WHERE behaviour_type='buy'
GROUP BY hour;
-- more customers are buying during 19pm-21pm

-- calculate payment rate based on date
-- payment rate: number of purchases / number of customers
SELECT 
    a.date, 
    a.number_of_customers,
    b.number_of_purchases,
    CONCAT(ROUND(b.number_of_purchases/a.number_of_customers*100,2),'%') as payment_rate 
FROM 
(SELECT date, COUNT(DISTINCT(user_id)) AS number_of_customers
FROM userbehavior 
GROUP BY date 
ORDER BY date ASC) as a
LEFT JOIN 
(SELECT date, COUNT(DISTINCT user_id) as number_of_purchases
FROM userbehavior
WHERE behaviour_type='buy'
GROUP BY date) as b 
ON a.date =b.date;
-- payment rate is around 16% - 22%

-- CUSTOMER RETENTION
-- calculate number of customers retained by the company in the first 7 days
select count(distinct user_id) as first_day_customer_num from userbehavior
where date = '2017-11-25';-- 359 
select count(distinct user_id) as third_day_customer_num from userbehavior
where date = '2017-11-27' and user_id in (SELECT user_id FROM userbehavior
WHERE date = '2017-11-25');-- 289
select count(distinct user_id) as seventh_day_customer_num from userbehavior
where date = '2017-12-01' and user_id in (SELECT user_id FROM userbehavior
WHERE date = '2017-11-25');-- 283

CREATE TABLE customer_retention
(first_day_customer_num int,
second_day_customer_num int,
third_day_customer_num int,
seventh_day_customer_num int);

INSERT INTO customer_retention VALUES(359,295,289,283);
select * from customer_retention;

-- number of customer retained in second, thrid and seventh day
SELECT CONCAT(ROUND(100*second_day_customer_num/first_day_customer_num,2),'%')AS two_days_retention,
	CONCAT(ROUND(100*third_day_customer_num/first_day_customer_num,2),'%')AS three_days_retention,
	CONCAT(ROUND(100*seventh_day_customer_num/first_day_customer_num,2),'%')AS seven_days_retention
FROM customer_retention;
-- retention rate for two days, three days and seven days are 82%, 80%, 78% respectively

-- PRODUCT ANALYSIS
-- num of products website sells
SELECT COUNT(DISTINCT product_id) AS products
FROM userbehavior;
-- 37766 products are selling

-- products sold
SELECT COUNT(DISTINCT product_id)
FROM userbehavior
WHERE behaviour_type = 'buy';
-- total of 1121 products are sold

-- purchase rate based on products
SELECT a.purchase_num,
		COUNT(a.product_id) AS products
FROM
	(SELECT product_id, COUNT(DISTINCT user_id) AS purchase_num
FROM userbehavior
WHERE behaviour_type = 'buy') a
GROUP BY purchase_num
ORDER BY purchase_num DESC;
-- data shows all products are purchased once only

-- product search rank
SELECT product_id,
		SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS product_click
FROM userbehavior
GROUP BY product_id
ORDER BY product_click DESC;
-- shows product_id 3006793 have the highest click

-- product buying rank
SELECT product_id,
		SUM(CASE WHEN behaviour_type = 'buy' THEN 1 ELSE 0 END) AS product_purchase
FROM userbehavior
GROUP BY product_id
ORDER BY product_purchase DESC;
-- product_id 667682 have the most purchase

-- product_id 3006793 have the highest click but not the most purchase, this shows coversion rate is low.