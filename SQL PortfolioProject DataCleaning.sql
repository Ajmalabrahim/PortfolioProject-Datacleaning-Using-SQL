
/*
CLEANING Data in SQL Queries. 
Using NashvilleHousing Dataset we will go through the dataset, get familiar with it and start prepping the data for cleaning.
*/

SELECT *
FROM PortfolioProject..NashvilleHousing
ORDER BY 1 ASC

/*
First lets look at the SaleDate column.
We want to convert the SaleDate format from datetime to just date. 
*/

ALTER TABLE NashvilleHousing
ALTER COLUMN SaleDate date

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Next, lets fix the Property Address. 
For the null values we can use the ParcelID as a reference point for Property address.
If the same ParcelID has an address for one property but not for another we can copy that address over.
We will have to do a self join to see if the ParcelID and PropertyAddress match before we can start converting Nulls over
*/

SELECT A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, a.[UniqueID ], b.[UniqueID ], ISNULL(a.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]!= B.[UniqueID ]
WHERE a.PropertyAddress IS NULL

/*
Now lets update the table and replace the null values with the new column we created. 
The new column is the Property address that matches the ParcelID but was blank for 35 rows for other uniqueID's.
*/

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, B.PropertyAddress)
FROM NashvilleHousing a
JOIN NashvilleHousing b
ON a.ParcelID = b.ParcelID
AND a.[UniqueID ]!= B.[UniqueID ]
WHERE a.PropertyAddress IS NULL
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking apart the Address column into Two separate columns (Address, City)

SELECT PropertyAddress
FROM NashvilleHousing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress)) AS City  
FROM NashvilleHousing

-- Now we need to update our table to insert the two new columns

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
Lets look at the OwnerAddress column.
We want to split this column into three new columns, Address, City, State.
This method requires less coding and will use the ParseName function.
*/

SELECT OwnerAddress
FROM NashvilleHousing

SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
We can see from the table that most of the rows use the Yes, No instead of the N, Y if property is SoldAsVacant. 
Lets change the values to just Yes, and No. 
*/

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant) AS count
FROM NashvilleHousing
GROUP BY SoldAsVacant 
ORDER BY 2 DESC


SELECT SoldAsVacant,
	   CASE WHEN SoldAsVacant LIKE 'N' THEN 'No'
	   WHEN SoldAsVacant LIKE 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END AS SoldAsVacantClean 	   	
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant LIKE 'N' THEN 'No'
	   WHEN SoldAsVacant LIKE 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
lets remove duplicates.
To find what rows are duplicates we can use the row_number clause combined with the Partition By clause to find duplicate rows.
We know that these Duplicate rows should be deleted because the columns we listed below
all match which means deleting the duplicate rows will not hurt the data but instead improve the dataset. 
*/

WITH RowNumCTE AS(
SELECT *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY UniqueID
				) row_num
			 

FROM NashvilleHousing
--ORDER BY ParcelID 
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress


------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Lets delete unused columns

SELECT *
FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict, SaleDate

/*
The PropertyAddress and OwnerAddress columns were dropped because it is much more beneficial to have the address, city and state split up into separate columns rather
then having them all in one column. 
*/