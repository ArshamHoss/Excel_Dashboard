--Austin, TX and Los Angeles, CA Airbnb data from kaggle
--Queried using: Microsoft SQL Server

--Geting a feel for the data
SELECT*
FROM [dbo].[Austin]

SELECT*
FROM [dbo].[LosAngeles]

-- Look at reviews
SELECT avg(review_scores_rating), avg(review_scores_cleanliness),
avg(review_scores_location) ,avg(review_scores_value), avg(number_of_reviews)
FROM [dbo].[Austin]

SELECT avg(review_scores_rating), avg(review_scores_cleanliness),
avg(review_scores_location) ,avg(review_scores_value), avg(number_of_reviews)
FROM [dbo].[LosAngeles]


SELECT neighbourhood_city ,count (neighbourhood_city)
FROM [dbo].[LosAngeles]
GROUP BY neighbourhood_city

SELECT * from [dbo].[LosAngeles]






--Check how many hosts are out of state hosts
--Texas
WITH Out_Of_TX as(
SELECT COUNT(id) as Count_TX FROM [dbo].[Austin]
WHERE host_location not like '%TX%'
)

SELECT  Out_Of_TX.Count_TX as Out_Of_State ,COUNT(id) as Total, (Out_Of_TX.Count_TX*1.0/COUNT(id)*1.0)*100 as Percent_Out_Of_State
FROM [dbo].[Austin], Out_Of_TX
WHERE host_location is not null
GROUP BY Out_Of_TX.Count_TX

--add host out of state collumn
ALTER TABLE [dbo].[Austin]
ADD host_out_of_state nvarchar(10)

Begin Transaction
UPDATE [dbo].[Austin]
SET host_out_of_state = CASE WHEN host_location not like '%TX%' THEN 'Yes' ELSE 'No' END
WHERE host_location is not null
commit



--California

WITH Out_Of_CA as(
SELECT COUNT(id) as Count_CA FROM [dbo].[LosAngeles]
WHERE host_location not like '%CA%'
)

SELECT Out_Of_CA.Count_CA as Out_Of_State,COUNT(id) as Total, (Out_Of_CA.Count_CA*1.0/COUNT(id)*1.0)*100 as Percent_Out_Of_State
FROM [dbo].[LosAngeles], Out_Of_CA
WHERE host_location is not null
GROUP BY Out_Of_CA.Count_CA

--Add column for out of state hosts
ALTER TABLE [dbo].[LosAngeles]
ADD host_out_of_state nvarchar(10)

Begin Transaction
UPDATE [dbo].[LosAngeles]
SET host_out_of_state = CASE WHEN host_location not like '%CA%' THEN 'Yes' ELSE 'No' END
WHERE host_location is not null
commit



--Average Price of Airbnb
-- Texas
SELECT neighbourhood, AVG(price) as average_price
FROM [dbo].[Austin]
GROUP by neighbourhood
order by 2


--Data Cleansing

--Dates in data set contain time values which are unneccesary, we will standardize all dates
ALTER TABLE [dbo].[Austin] alter column last_scraped date
ALTER TABLE [dbo].[Austin] alter column host_since date
ALTER TABLE [dbo].[Austin] alter column calendar_last_scraped date
ALTER TABLE [dbo].[Austin] alter column first_review date
ALTER TABLE [dbo].[Austin] alter column last_review date

ALTER TABLE [dbo].[LosAngeles] alter column last_scraped date
ALTER TABLE [dbo].[LosAngeles] alter column host_since date
ALTER TABLE [dbo].[LosAngeles] alter column calendar_last_scraped date
ALTER TABLE [dbo].[LosAngeles] alter column first_review date
ALTER TABLE [dbo].[LosAngeles] alter column last_review date

-- Standardize locations so that same locations with different syntax are grouped together
--Austin
SELECT neighbourhood, COUNT( neighbourhood)
FROM [dbo].[Austin]
GROUP BY neighbourhood

Begin transaction 
UPDATE [dbo].[Austin]
SET neighbourhood = 'Austin, Texas, United States'
WHERE neighbourhood like '%Austin%'
--rollback
commit

--la

SELECT neighbourhood, COUNT( neighbourhood)
FROM [dbo].[LosAngeles]
GROUP BY neighbourhood
order by 1

Begin transaction 
UPDATE [dbo].[LosAngeles]
SET neighbourhood = 'Los Angeles, California, United States'
WHERE neighbourhood like '%los angeles%' or neighbourhood like 'LA, %'
--rollback
commit

--Remove empty collumns with no values and irrelevant columns
ALTER TABLE [dbo].[Austin]
DROP COLUMN neighbourhood_group_cleansed,  bathrooms ,calendar_updated, license 

ALTER TABLE [dbo].[LosAngeles]
DROP COLUMN neighbourhood_group_cleansed,  bathrooms ,calendar_updated, license 

--Fill in null values using self join by matching zipcodes to cities 

SELECT DISTINCT a.id ,a.neighbourhood_cleansed,a.neighbourhood, b.neighbourhood, b.neighbourhood_cleansed
,ISNULL(a.neighbourhood, b.neighbourhood )
FROM [dbo].[Austin] a
Inner JOIN [dbo].[Austin] b on a.neighbourhood_cleansed = b.neighbourhood_cleansed
and a.id <> b.id
WHERE a.neighbourhood is null and b.neighbourhood is not null
order by 1,2

--Update missing values
Begin transaction 
UPDATE a
SET neighbourhood=ISNULL(a.neighbourhood, b.neighbourhood )
FROM [dbo].[Austin] a
Inner JOIN [dbo].[Austin] b on a.neighbourhood_cleansed = b.neighbourhood_cleansed
and a.id <> b.id
WHERE a.neighbourhood is null and b.neighbourhood is not null
--rollback
commit


-- LA
SELECT DISTINCT a.id ,a.neighbourhood_cleansed,a.neighbourhood, b.neighbourhood, b.neighbourhood_cleansed
,ISNULL(a.neighbourhood, b.neighbourhood )
FROM  [dbo].[LosAngeles] a
Inner JOIN [dbo].[LosAngeles] b on a.neighbourhood_cleansed = b.neighbourhood_cleansed
and a.id <> b.id
WHERE a.neighbourhood is null and b.neighbourhood is not null
order by 1,2


Begin transaction 
UPDATE a
SET neighbourhood=ISNULL(a.neighbourhood, b.neighbourhood )
FROM [dbo].[LosAngeles] a
Inner JOIN [dbo].[LosAngeles] b on a.neighbourhood_cleansed = b.neighbourhood_cleansed
and a.id <> b.id
WHERE a.neighbourhood is null and b.neighbourhood is not null
--rollback
commit

--Seperate states and cities for host location for easier analysis
SELECT PARSENAME(REPLACE(host_location,',','.'),2) as host_city,
 PARSENAME(REPLACE(host_location,',','.'),1) as host_state
FROM [dbo].[Austin]

--add new state and city for host
ALTER TABLE [dbo].[Austin]
add host_city nvarchar(50),
host_state nvarchar(50)

UPDATE [dbo].[Austin]
SET host_city = PARSENAME(REPLACE(host_location,',','.'),2),
host_state= PARSENAME(REPLACE(host_location,',','.'),1)

--la

SELECT PARSENAME(REPLACE(host_location,',','.'),2) as host_city,
 PARSENAME(REPLACE(host_location,',','.'),1) as host_state
FROM [dbo].[LosAngeles]

ALTER TABLE [dbo].[LosAngeles]
add host_city nvarchar(50),
host_state nvarchar(50)

UPDATE [dbo].[LosAngeles]
SET host_city = PARSENAME(REPLACE(host_location,',','.'),2),
host_state= PARSENAME(REPLACE(host_location,',','.'),1)

-- Seperate airbnb address into state, city and country for easiler visualization
--AUSTIN
SELECT PARSENAME(REPLACE(neighbourhood,',','.'),3),
PARSENAME(REPLACE(neighbourhood,',','.'),2),
PARSENAME(REPLACE(neighbourhood,',','.'),1)
from [dbo].[Austin]

ALTER TABLE [dbo].[Austin] 
add neighbourhood_city nvarchar(50), 
neighbourhood_state nvarchar(50),
neighbourhood_country nvarchar(50)

UPDATE [dbo].[Austin]
SET neighbourhood_city =PARSENAME(REPLACE(neighbourhood,',','.'),3), 
neighbourhood_state =PARSENAME(REPLACE(neighbourhood,',','.'),2), 
neighbourhood_country =PARSENAME(REPLACE(neighbourhood,',','.'),1)


--LA
SELECT PARSENAME(REPLACE(neighbourhood,',','.'),3),
PARSENAME(REPLACE(neighbourhood,',','.'),2),
PARSENAME(REPLACE(neighbourhood,',','.'),1)
from [dbo].[LosAngeles]

ALTER TABLE [dbo].[LosAngeles]
add neighbourhood_city nvarchar(50), 
neighbourhood_state nvarchar(50),
neighbourhood_country nvarchar(50)

UPDATE [dbo].[LosAngeles]
SET neighbourhood_city =PARSENAME(REPLACE(neighbourhood,',','.'),3), 
neighbourhood_state =PARSENAME(REPLACE(neighbourhood,',','.'),2), 
neighbourhood_country =PARSENAME(REPLACE(neighbourhood,',','.'),1)

--Standardize Ca, california and other spelling variations
SELECT distinct neighbourhood_state
FROM [dbo].[LosAngeles]

UPDATE [dbo].[LosAngeles]
set neighbourhood_state = 'California'

--Union the two data sets so for easy visuals when comparing la and austiin

with La_Austin_Union as (
SELECT* FROM [dbo].[Austin]

UNION

SELECT* FROM [dbo].[LosAngeles])

SELECT* FROM La_Austin_Union

--Correct miss matching types in certain columns
ALTER TABLE [dbo].[LosAngeles] alter column review_scores_rating float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_accuracy] float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_cleanliness] float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_checkin] float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_communication] float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_location] float
ALTER TABLE [dbo].[LosAngeles] alter column [review_scores_value] float
ALTER TABLE [dbo].[LosAngeles] alter column number_of_reviews int
ALTER TABLE [dbo].[LosAngeles] alter column accommodates int

ALTER TABLE [dbo].[Austin] alter column number_of_reviews int
ALTER TABLE [dbo].[Austin] alter column accommodates int


--Create a amenities view to import into our visualization

Drop view if exists amenitiesTX
Create view amenitiesTX as


SELECT TOP 30 neighbourhood_state, TRIM('" 'FROM TRIM(']' FROM TRIM('[' FROM TRIM(' " ' FROM VALUE)))) as Amenities, COUNT(amenities) as count_
FROM [dbo].[Austin]
CROSS APPLY
string_split(amenities,',')
GROUP by Value, neighbourhood_state 
ORDER BY COUNT(amenities) desc






Drop view if exists amenitiesCA
Create view amenitiesCA as


SELECT TOP 30 neighbourhood_state, TRIM('" 'FROM TRIM(']' FROM TRIM('[' FROM TRIM(' " ' FROM VALUE)))) as Amenities, COUNT(amenities) as count_
FROM [dbo].[LosAngeles]
CROSS APPLY
string_split(amenities,',')
GROUP by Value, neighbourhood_state 
ORDER BY COUNT(amenities) desc




 
 --Union amenties from CA and TX for visualization

SELECT* FROM amenitiesTX

UNION

SELECT* FROM amenitiesCA











