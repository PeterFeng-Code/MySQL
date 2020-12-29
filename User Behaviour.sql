USE self;

-- data is between 2017/09/11 to 2017/12/03

-- first look at all the data
SELECT * FROM userbehavior;



-- Data Cleaning and Preparation
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

-- add ID column to the table as row count
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



-- descriptive statistics
SELECT 
COUNT(DISTINCT(user_id)) AS users,
COUNT(DISTINCT(product_id)) AS product,
COUNT(DISTINCT(category_id)) AS category,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'page visit',
SUM(CASE WHEN behaviour_type = 'fav' THEN 1 ELSE 0 END) AS collection,
SUM(CASE WHEN behaviour_type = 'cart' THEN 1 ELSE 0 END) AS 'add to cart',
SUM(CASE WHEN behaviour_type = 'buy' THEN 1 ELSE 0 END) AS purchased
FROM userbehavior;

-- user volume analysis
SELECT 
COUNT(DISTINCT(user_id)) AS users,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS page_visit,
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per user'
FROM userbehavior;
-- result shows each user visited 97 times between 2017/11/25 to 2017/12/03

-- user volume analysis per day
SELECT date,
COUNT(DISTINCT(user_id)) AS 'total visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'total page visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per user'
FROM userbehavior
GROUP BY date
ORDER BY SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) desc;

-- user volume analysis per hour
SELECT hour,
COUNT(DISTINCT(user_id)) AS 'total visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) AS 'total page visits',
SUM(CASE WHEN behaviour_type = 'pv' THEN 1 ELSE 0 END) / COUNT(DISTINCT(user_id)) AS 'average page visit per user'
FROM userbehavior
GROUP BY hour
ORDER BY hour;

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
SELECT date, COUNT(DISTINCT(user_id)) AS 'active user'
FROM userbehavior
GROUP BY date 
ORDER BY date; 

-- active user based on hour
SELECT hour, COUNT(DISTINCT(user_id)) AS 'active user'
FROM userbehavior
GROUP BY hour 
ORDER BY hour; 

-- average frequency for customer payment by date
SELECT date, behaviour_type, COUNT(DISTINCT(user_id)) AS 'user',
SUM(CASE WHEN behaviour_type='buy' THEN 1 ELSE 0 END)/COUNT(DISTINCT(user_id)) AS 'average user payment frequency'
FROM userbehavior
WHERE behaviour_type='buy'
GROUP BY date
ORDER BY date ASC;


-- average frequency for customer payment by hour
SELECT hour, COUNT(DISTINCT user_id) as user
FROM userbehavior
WHERE behaviour_type='buy'
GROUP BY hour;

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

-- calculate number of customer retained by the company in the first 7 days

select count(distinct user_id) as first_day_customer_num from userbehavior
where date = '2017-11-25';-- 359
select count(distinct user_id) as second_day_customer_num from userbehavior
where date = '2017-11-26' and user_id in (SELECT user_id FROM userbehavior
WHERE date = '2017-11-25');-- 295
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
seventh_day_customer_num int)

INSERT INTO customer_retention VALUES(359,295,289,283);

select * from customer_retention;

SELECT CONCAT(ROUND(100*second_day_customer_num/first_day_customer_num,2),'%')AS two_days_retention,
CONCAT(ROUND(100*third_day_customer_num/first_day_customer_num,2),'%')AS three_days_retention,
CONCAT(ROUND(100*seventh_day_customer_num/first_day_customer_num,2),'%')AS seven_days_retention
from customer_retention;