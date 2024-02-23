-- Dropping tables we dont need
alter table content
drop column `URL`;

select *
from content
where `Content ID` ='' or `Content ID` = NULL;

select *
from content
where `User ID` ='' or `User ID` = NULL;

select *
from content
where `Type` ='' or `Type` = NULL;

select Category
from content;

update content
set Category = replace(Category, '"', '');

-- Changing name of column from type to content type
alter table content
change Type `Content Type` varchar(255);

alter table reactions
change Type `Reaction Type` varchar(255);

alter table reactiontypes
change Type `Reaction Type` varchar(255);

select *
from content;

-- removing null values from reaction table
select * from reactions;

delete from reactions
where `User ID`= "" OR `User ID` = NULL;

-- for our analysis, user id is not necessary

alter table content 
drop column `User ID`;

alter table reactions
drop column `User ID`;

-- 
delete from reactions
where `Reaction Type`= "" OR `Reaction Type` = NULL;

-- Creating final data by merging tables together

SELECT r.`Content ID`, r.`Reaction Type`, r.Datetime, c.`Content Type`, c.Category, rt.Sentiment, rt.Score
FROM reactions r
JOIN content c 
ON r.`Content ID` = c.`Content ID`
JOIN reactiontypes rt 
ON r.`Reaction Type` = rt.`Reaction Type`;

SELECT distinct(c.Category), avg(rt.Score) 
FROM reactions r
JOIN content c 
ON r.`Content ID` = c.`Content ID`
JOIN reactiontypes rt 
ON r.`Reaction Type` = rt.`Reaction Type`
group by c.Category
order by avg(rt.Score) desc
limit 5;





