SELECT *
FROM PortfolioProject..NashvilleHousing

--
-- Standardize date format

SELECT SaleDate, CONVERT(date, SaleDate) AS SaleDateConverted
FROM PortfolioProject..NashvilleHousing

UPDATE PortfolioProject..NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD SaleDateConverted Date

UPDATE PortfolioProject..NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)

--
-- Populate property address data

SELECT UniqueId, ParcelID, LandUse, PropertyAddress, SaleDateConverted, LegalReference
FROM PortfolioProject..NashvilleHousing
ORDER BY 2,4

-- See which parcelID's property address is null and if there is another same parcelID that have an address
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON	a.ParcelID = b.ParcelID
	AND	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- update the table of null property address with an address
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON	a.ParcelID = b.ParcelID
	AND	a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL


--
-- Breaking the addresses into individual columns (address, city, state)


-- separate property address with substring

SELECT SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) AS PropertyAddressStreet,
	SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS PropertyAddressCity
FROM PortfolioProject..NashvilleHousing

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertyAddressStreet nvarchar(255)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD PropertyAddressCity nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET PropertyAddressStreet = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)

UPDATE PortfolioProject..NashvilleHousing
SET PropertyAddressCity = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))


-- Separate owner address with parsename

SELECT TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)),
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)),
	TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))
FROM PortfolioProject..NashvilleHousing

-- add new column and update the table
ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerAddressStreet nvarchar(255)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerAddressCity nvarchar(255)

ALTER TABLE PortfolioProject..NashvilleHousing
ADD OwnerAddressState nvarchar(255)

UPDATE PortfolioProject..NashvilleHousing
SET OwnerAddressStreet = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3))

UPDATE PortfolioProject..NashvilleHousing
SET OwnerAddressCity = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2))

UPDATE PortfolioProject..NashvilleHousing
SET OwnerAddressState = TRIM(PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1))


---
-- Change Y and N to Yes and No on the SoldAsVacant column

-- Count the number of Y, N, Yes, and No
SELECT SoldAsVacant, COUNT(SoldAsVacant) AS TheCount
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 1

-- Test to change the value of Y and N to Yes and No
SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
FROM PortfolioProject..NashvilleHousing
ORDER BY 1

-- Update the table, change Y and N with Yes and No
UPDATE PortfolioProject..NashvilleHousing
SEt SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END


---
-- Remove Duplicates

-- Use CTE to look at the duplicate data
WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueId) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num >1
ORDER BY PropertyAddress

-- Use the CTE to remove the duplicate data
WITH RowNumCTE AS (
SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference ORDER BY UniqueId) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1