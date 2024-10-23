select * 
from credit_card_transactions;

select min(transaction_date) as first_transaction_date
from credit_card_transactions;                                               -- 2013-10-04

select max(transaction_date) as latest_transaction_date
from credit_card_transactions;                                               -- 2015-05-26

select distinct card_type
from credit_card_transactions;                                               -- silver, signature, gold, platinum

select distinct exp_type
from credit_card_transactions;                                               -- entertainment, food, bills, fuel, travel, grocery

select distinct city
from credit_card_transactions;                                               -- all most all the cities in india with 986 rows

-- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte as
(select city, sum(amount) as total_spent
from credit_card_transactions
group by city),
cte2 as 
(select sum(cast(amount as bigint)) as total_sales
from credit_card_transactions)

select top 5 cte.*, (total_spent/total_sales)*100 as percentage_contribution
from cte,cte2
order by cte.total_spent desc

--  write a query to print highest spend month and amount spent in that month for each card type

with cte as
(select card_type, datepart(year,transaction_date) as transaction_year, datename(MONTH,transaction_date) as transaction_month, 
sum(amount) as amount_spent
from credit_card_transactions
group by card_type,datepart(year,transaction_date), datename(MONTH,transaction_date))

select * 
from (select *,rank() over(partition by card_type order by amount_spent desc) as rn from cte) a
where rn = 1;

-- write a query to print the transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends

with cte as
(select *, sum(amount) over (partition by card_type order by transaction_date,transaction_id) as total_spent
from credit_card_transactions)

select * 
from (select *, rank() over (partition by card_type order by total_spent) as rn from cte where total_spent >=1000000) a
where rn = 1;

-- write a query to find city which had lowest percentage spend for gold card type

with cte as
(select city,card_type, sum(amount) as total_spent,
sum(case when card_type = 'Gold' then amount end) as gold_amount
from credit_card_transactions
group by city,card_type)

select top 1 city,
round(sum(gold_amount)*1.0 / sum(total_spent)*100,5)  as gold_percentage
from cte
group by city
having sum(gold_amount) is not null
order by gold_percentage;

-- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel) --

with cte as
(select city, exp_type, sum(amount) as total_amount
from credit_card_transactions
group by city, exp_type)

select city, max( case when rn_asc =1 then exp_type end) as lowest_expense_type,
min(case when rn_desc = 1 then exp_type end) as highest_expense_type
from
(select *,
rank() over(partition by city order by total_amount desc) rn_desc,
rank() over(partition by city order by total_amount asc) rn_asc
from cte)A
group by city;

-- write a query to find percentage contribution of spends by females for each expense type

select exp_type,
round(sum(case when gender = 'F' then amount else 0 end)*1.0 / sum(amount)* 100,3) as female_percentage_contributuion
from credit_card_transactions
group by exp_type
order by female_percentage_contributuion desc;

-- which card and expense type combination saw highest month over month growth in Jan-2014

with cte as
(select card_type, exp_type,
DATEPART(year,transaction_date) as transaction_year,
datepart(month, transaction_date) as transaction_month,
sum(amount) as total_spent
from credit_card_transactions
group by card_type,exp_type,DATEPART(year,transaction_date),datepart(month, transaction_date) 
)
select top 1 *, (total_spent-previous_month_spend) as mom_growth
from
(select *, 
lag(total_spent) over (partition by card_type, exp_type order by transaction_year,transaction_month) as previous_month_spend
from cte) A
where previous_month_spend is not null and transaction_year = '2014' and transaction_month = '1'
order by mom_growth desc;

-- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city,sum(amount) *1.0 / count(1) as ratio
from credit_card_transactions
where DATEPART(WEEKDAY,transaction_date) in (1,7)
group by city
order by ratio desc;

-- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as
(select *,
row_number() over (partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select top 1 city, datediff(day,min(transaction_date),max(transaction_date)) as difference_in_days
from cte
where rn = 1 or rn = 500
group by city
having count(*) = 2
order by difference_in_days ;







