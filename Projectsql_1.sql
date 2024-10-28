create database coffeeshop_salesdb;
use coffeeshop_salesdb;

select * from coffeeshop_sales;


describe coffeeshop_sales;


# DATA CLEANING 

update coffeeshop_sales
set transaction_date = str_to_date(transaction_date, '%d-%m-%Y');

# now I will change the data type of transaction_date into DATE format 

alter table coffeeshop_sales
modify column transaction_date date;

describe coffeeshop_sales;

# Data cleaning for transaction_time 
# LPAD stands for "Left PAD", which adds a character to the left side of the string until it reaches the specified length.
# Here, we are ensuring that transaction_time has a length of 8 characters, padding with '0' on the left if necessary.
# this will help to convert the format of transaction time column into HH:MM:SS

UPDATE coffeeshop_sales
SET transaction_time = LPAD(transaction_time, 8, '0');

alter table  coffeeshop_sales
modify column transaction_time time;

describe coffeeshop_sales;

select * from coffeeshop_sales;

# Changing COLUMN NAME `ï»¿transaction_id` to transaction_id
Alter table coffeeshop_sales
Change column `ï»¿transaction_id` transaction_id INT;

describe coffeeshop_sales;

# Now after the data cleaning it is ready to solve the business problem 

### Problem 1 - Total sales analysis 
# 1.1- Calculate the Total sales for each respective month .
select round(sum(unit_price*transaction_qty))as Total_sales 
from coffeeshop_sales
where 
month(transaction_date)= 5 -- say may month (you can change the month by just changing the month )

#1.2 Difference in sales between the selected month and the previous month 

select
    month(transaction_date) as month,                                                      # number of month 
    round(sum(unit_price * transaction_qty)) as Total_sales,                               # Total_sales
    (sum(unit_price * transaction_qty) - lag(sum(unit_price * transaction_qty), 1)         # month sales difference say (ex - april - may )
    over (order by month(transaction_date))) / lag(sum(unit_price * transaction_qty), 1)   # dividing by previous month sales 
    over (order by month(transaction_date)) * 100 as mon_inc_percentage                    # percentage because we all know how mon on mon sales or yr on yr sales difference is calculated 
from 
    coffeeshop_sales
where 
    month(transaction_date) in (4, 5) -- for months of April and May where april is (previous month)and may is (current month) 
group by 
    month(transaction_date)
order by 
    month(transaction_date);   # by default it will be in ascending order 
    
#1.3 Determine the month on month increase or decrease in sales 
-- (here we have to take the difference of the current month and previous month 156728-118941 =37787) 
-- which is positive and also have represented it in dashboard

## Problem 2 Total order analysis 
# 2.1 Calculate the total number of orders month by month 

select count(transaction_id) as Total_orders
from coffeeshop_sales
where month(transaction_date) = 5   #(may month we can take any month number )


 
# 2.2 Calculate the difference in the no of orders between the selected month and previous month 
select 
    month(transaction_date) as month,
    round(count(transaction_id)) as Total_orders,
    (count(transaction_id) - lag(count(transaction_id), 1) 
    over (order by month(transaction_date))) / lag(count(transaction_id), 1) 
    over (order by month(transaction_date)) * 100 as mon_increase_percentage
from 
    coffeeshop_sales
where 
    month(transaction_date) in (4, 5) -- for April and May
group by 
    month(transaction_date)
order by 
    month(transaction_date);
    
# 2.3 Determine the month on month increase or decrease in the number of orders 
-- To find out Current month and Last month increase or decrease in order we will subtract Cureent month orders by Last month order so here 
-- I have taken for the month of ( April and May  ) => 33527 - 25335 = 8237. 
-- Note : similarly we can calculate for other months as well by simply selecting Current month and Previous month


    
# Problem 3 Total quantity sold analysis 

#3.1 Calculate the total quantity sold for each respective month.

select sum(transaction_qty) as Total_quantity_sold
from coffeeshop_sales
where month(transaction_date)= 5 -- example for month may we can see the result for any other month like that 

#3.2 Calculate the difference in the total quantity sold between the selected month and the previous month.
#3.3 Determine the month-on-month increase or decrease in the total quantity sold.

select 
    month(transaction_date) as month,
    round(sum(transaction_qty)) as Total_quantity_sold,
    (sum(transaction_qty) - lag(sum(transaction_qty), 1) 
    over (order by month(transaction_date))) / lag(sum(transaction_qty), 1) 
    over (order by month(transaction_date)) * 100 as mon_increase_percentage
from 
    coffeeshop_sales
where 
    month(transaction_date) in (4, 5)   -- for April and May
group by 
    month(transaction_date)
order by 
    month(transaction_date);

---------------------------------------------------------------------------------------------------------------------------------------------------
select * from coffeeshop_sales;

# Chart Requirement query 
# 4. will be used in Calendar heat map 
# Tooltips to display detailed metrics (Sales, Orders, Quantity) when hovering over a specific day.This is how we deal with calendar heat map 

select 
concat(round(sum(unit_price*transaction_qty)/1000,1),'K') as Total_Sales,
concat(round(sum(transaction_qty)/1000,1),'K')as Total_quantity_sold,
concat(round(count(transaction_id)/1000,1),'K')as Total_Orders
from coffeeshop_sales
where (transaction_date) ='2023-05-18';  # for any date we can change the date from here 

#5. Sales analysis by weekdays and weekends 
-- weekends - sat sun 
-- weekdays - monday to friday 
-- sun is day 1 and so on sat is day 7 
 
select 
  case when dayofweek(transaction_date) in (1,7) then 'weekends'  
  else 'weekdays'
  end as day_type,
  concat(round(sum(unit_price*transaction_qty)/1000,1),'K') as Total_sales
from coffeeshop_sales
where month(transaction_date)= 5 -- say may 
group by 
  case when dayofweek(transaction_date) in (1,7) then 'weekends'  
  else 'weekdays'
  end

#6.  Sales analysis by store location 
select * from coffeeshop_sales;

select 
  store_location,
  concat(round(sum(unit_price*transaction_qty)/1000,1),'K') as Total_Sales
from coffeeshop_sales
where month(transaction_date) = 5 -- say may again 
group by store_location
order by sum(unit_price*transaction_qty) desc;

# 7. Analyze sales by product category 
select 
     product_category,
     sum(unit_price*transaction_qty) as Total_sales 
from coffeeshop_sales
where month(transaction_date) = 5 -- may month 
group by product_category
order by sum(unit_price*transaction_qty) desc;
      
#8.  Top 10 products by sales 
select 
     product_type,
     sum(unit_price*transaction_qty) as Total_sales 
from coffeeshop_sales
where month(transaction_date) = 5 and product_category='Coffee'
group by product_type
order by sum(unit_price*transaction_qty) desc
limit 10;

#9. Sales analysis by days and hours 
select 
     sum(unit_price*transaction_qty) as Total_sales,
     sum(transaction_qty) as Total_quantity_sold,
     count(*) as Total_orders
from coffeeshop_sales
where month(transaction_date) = 5
and dayofweek(transaction_date)=1  -- sunday
and hour(transaction_time)= 14 ;-- hour no - 14 

# sales in peak hours 

select
    hour(transaction_time),
    sum(unit_price*transaction_qty) as Total_sales
from coffeeshop_sales
where month(transaction_date) = 5
group by hour(transaction_time)
order by hour(transaction_time)





     

 
