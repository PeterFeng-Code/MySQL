USE self;

-- data is between 2017/11/25 to 2017/12/03

-- first look at all the data
SELECT * FROM userbehavior;

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
select distinct(behaviour_type) from userbehavior;

-- descriptive statistics
select 
count(distinct(user_id)) as users,
count(distinct(product_id)) as product,
count(distinct(category_id)) as category,
sum(case when behaviour_type = 'pv' then 1 else 0 end) as 'page visit',
sum(case when behaviour_type = 'fav' then 1 else 0 end) as collection,
sum(case when behaviour_type = 'cart' then 1 else 0 end) as 'add to cart',
sum(case when behaviour_type = 'buy' then 1 else 0 end) as purchased
from userbehavior;

-- user volume analysis
select 
count(distinct(user_id)) as users,
sum(case when behaviour_type = 'pv' then 1 else 0 end) as page_visit,
sum(case when behaviour_type = 'pv' then 1 else 0 end) / count(distinct(user_id)) as 'average page visit per user'
from userbehavior;
-- result shows each user visited 97 times between 2017/11/25 to 2017/12/03

-- user volume analysis based on date
select date,
count(distinct(user_id)) as 'total visits',
sum(case when behaviour_type = 'pv' then 1 else 0 end) as 'total page visits',
sum(case when behaviour_type = 'pv' then 1 else 0 end) / count(distinct(user_id)) as 'average page visit per user'
from userbehavior
group by date
order by sum(case when behaviour_type = 'pv' then 1 else 0 end) / count(distinct(user_id)) desc;

-- user volume analysis based on hour
select hour,
count(distinct(user_id)) as 'total visits',
sum(case when behaviour_type = 'pv' then 1 else 0 end) as 'total page visits',
sum(case when behaviour_type = 'pv' then 1 else 0 end) / count(distinct(user_id)) as 'average page visit per user'
from userbehavior
group by hour
order by hour;

