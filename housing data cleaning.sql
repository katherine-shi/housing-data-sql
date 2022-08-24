#property address data
select *
from housing.housing
where propertyaddress is null
order by ParcelID;

#replace property address with same parcelid addres
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress,b.PropertyAddress)
from housing.housing a
join housing.housing b
on a.ParcelID = b.ParcelID and a.uniqueid <> b.uniqueid
where a.PropertyAddress is null;

update housing.housing a
join housing.housing b
on a.ParcelID = b.ParcelID
and a.UniqueID <> b.UniqueID 
set a.PropertyAddress = b.PropertyAddress
where a.PropertyAddress is null;

#Breaking out Address into Individual Columns (Address, City, State)
SELECT
    substring(PropertyAddress,1,locate(",",PropertyAddress)-1) as address,
    SUBSTRING(PropertyAddress, locate(',', PropertyAddress) + 1 , length(PropertyAddress)) as Address
FROM housing.housing;

ALTER TABLE housing
Add PropertySplitAddress varchar(255);

update housing
set PropertySplitAddress=substring(PropertyAddress,1,locate(",",PropertyAddress)-1);

ALTER TABLE housing
Add PropertySplitcity varchar(255);

update housing
set PropertySplitcity=SUBSTRING(PropertyAddress, locate(',', PropertyAddress) + 1 , length(PropertyAddress));

#Change Y and N to Yes and No in "Sold as Vacant" field
select distinct(soldasvacant), count(soldasvacant)
from housing
group by SoldAsVacant
order by 2;

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From housing;

update housing
set SoldAsVacant=CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END;

#remove duplicate
with cte1 as(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
from housing)

select *
from cte1
where row_num > 1
Order by PropertyAddress;

delete from housing 
where UniqueID in (select UniqueID 
                from (
                Select *, ROW_NUMBER() OVER (PARTITION BY ParcelID,PropertyAddress,SalePrice,SaleDate,LegalReference ORDER BY UniqueID) row_num
                from housing
                ) t1
                where row_num != 1);
 
ALTER TABLE housing.housing
DROP COLUMN OwnerAddress, 
DROP COLUMN TaxDistrict, 
DROP COLUMN PropertyAddress, 
DROP COLUMN SaleDate
