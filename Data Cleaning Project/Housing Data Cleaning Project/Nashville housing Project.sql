select * from data;

-- 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Standardize data format

SELECT SaleDate, STR_TO_DATE('April 9, 2013', '%M %e, %Y') AS OriginalDate
from data;

-- You can update the column within the table itself using update function

Update data
set SaleDate = STR_TO_DATE('April 9, 2013', '%M %e, %Y');

select * from data;

-- 888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Populate Property address data

-- There are entries where the property address is null

select *
from data
-- where PropertyAddress = '' or PropertyAddress = NULL
order by ParcelID;

-- When we look through the data, the parcel ID is unique for every address 
-- So, we can say that, if two entries have the same parcel ID, and one of them is populated and the other one is not
-- Then populate the other one with the address same as that of the first one. 
--  But even in this same parcel ID and same address entry, the unique id is unique for each row
-- For this, we need to join the table within itself since we are comparing values within itself

select *
from data a
join data b
on a.ParcelID = b.ParcelID 
and a.UniqueID <> b.UniqueID; 

-- So each entry has its own unique ID but can have same Parcel ID, 
-- and the entries which have same parcel ID, have the same Property address. 
-- So we can use this to pupulate the null addresses

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, 
if(a.PropertyAddress = '', b.PropertyAddress, a.PropertyAddress) as PropertyAddress 
from data a
join data b
on a.ParcelID = b.ParcelID 
and a.UniqueID <> b.UniqueID
where a.PropertyAddress = ''; 

-- Updating the results

UPDATE data a
JOIN data b 
ON a.ParcelID = b.ParcelID 
AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IF(a.PropertyAddress = '', b.PropertyAddress, a.PropertyAddress)
WHERE a.PropertyAddress = '';

select * from data
where PropertyAddress = '';

-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Breaking the adress into individual columns (Address, City, State)

-- The format of the address in the table contains the city, and state as well. So;

select PropertyAddress
from data;

-- According to the data format of property address we have on the table, 
-- the city is separatedd by a comma from the rest of the address 

SELECT SUBSTRING_INDEX(PropertyAddress, ',', 1) AS Address, 
SUBSTRING_INDEX(PropertyAddress, ',', -1) AS City
FROM data;

-- We cant separate two values from one column without creating two new columns

alter table data
add PropertySplitAddress nvarchar(255);

Update data
set PropertySplitAddress = SUBSTRING_INDEX(PropertyAddress, ',', 1);

alter table data
add PropertySplitCity nvarchar(255);

Update data
set PropertySplitCity = SUBSTRING_INDEX(PropertyAddress, ',', -1);

alter table data
drop column PropertyAddress;

select * from data;

-- -----------------------------------------------------------------------
-- Doing the same thing for the owner addrees, but: 
-- it has three units that need separation: Address, city and the state

select OwnerAddress
from data;

SELECT substring_index(OwnerAddress, ',', 1) as Address, 
substring_index(substring_index(OwnerAddress, ',', 2), ',', -1) as City,
substring_index(OwnerAddress, ',', -1) as State
from data;

-- Updating the table with new columns:

alter table data
add OwnerSplitAddress nvarchar(255);

Update data
set OwnerSplitAddress = SUBSTRING_INDEX(OwnerAddress, ',', 1);

alter table data
add OwnerSplitCity nvarchar(255);

Update data
set OwnerSplitCity = substring_index(substring_index(OwnerAddress, ',', 2), ',', -1);

alter table data
add OwnerSplitState nvarchar(255);

Update data
set OwnerSplitState = substring_index(OwnerAddress, ',', -1);

select * from data;

-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Change Y and N to Yes and No in "Sold as vacant" field wherever they appear

select distinct(SoldAsVacant), count(SoldAsVacant)
from data
group by SoldAsVacant
order by 2;

select SoldAsVacant,
case 
when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end
from data;

Update data
set SoldAsVacant = 
case 
when SoldAsVacant = 'Y' then 'Yes'
when SoldAsVacant = 'N' then 'No'
else SoldAsVacant
end;

-- 88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
-- Removing Duplicates (Not a common practice)

-- this query is numbering the rows which have common parcel id, property address, saleprice, and legal reference
-- if the row number of 

with RowNumCTE as (
select *,
row_number() over(
partition by ParcelID,
			PropertySplitAddress,
			SalePrice,
            LegalReference
            order by 
            UniqueID) row_num
from data
order by ParcelID)

delete
from RowNumCTE
where row_num > 1;

WITH RowNumCTE AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ParcelID,
                            PropertySplitAddress,
                            SalePrice,
                            LegalReference
               ORDER BY UniqueID
           ) AS row_num
    FROM data
)
DELETE data
FROM data
JOIN RowNumCTE ON data.UniqueID = RowNumCTE.UniqueID
WHERE row_num > 1;

select * 
from RowNumCTE
where row_num > 1;

-- 8888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

-- Delete unused columns

select *
from data;

alter table data
-- drop column OwnerAddress ,
-- drop column TaxDistrict,
drop column SaleDate;



