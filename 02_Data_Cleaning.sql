/*==============================================================================
  NileMart project - File 02 : Data Cleaning
  Database : NileMartTraining

  What is this file?
    It fixes the problems found in file 01 (NULL values, extra text in names)
    and then checks for duplicate customers.

  WARNING: the UPDATE queries CHANGE the data.
    Run each UPDATE only ONE time.
    Especially the Suppliers update: every run cuts 3 more characters from the names.

  Sections
    1. Replace NULL values in Customers
    2. Clean product names
    3. Clean supplier names
    4. Find duplicate customers (SELECT only)
==============================================================================*/

USE NileMartTraining;
GO

/*------------------------------------------------------------------------------
  1. REPLACE NULL VALUES IN CUSTOMERS
------------------------------------------------------------------------------*/

-- Replace the missing values.
-- COALESCE(x, y) returns x if it has a value, otherwise it returns y.
--  - email and Phone: NULL becomes the text 'NoData'
--  - SignupDate: NULL becomes the date 1900-01-01
-- The WHERE part makes the update touch only the rows that have a NULL.

----- Remove NULL
UPDATE dbo.Customers
SET 
    email = COALESCE(email, 'NoData'),
    Phone = COALESCE(Phone, 'NoData'),
    SignupDate = COALESCE(SignupDate, '1900-01-01')
WHERE email IS NULL 
   OR Phone IS NULL 
   OR SignupDate IS NULL;

-- Change the placeholder date 1900-01-01 into the text 'NoData'.
-- This works only if the SignupDate column accepts text. A DATE column does not accept 'NoData'.

 UPDATE dbo.Customers
 SEt SignupDate = Coalesce(signupDAte,'NoData')
 where SignupDate ='1900-01-01'

/*------------------------------------------------------------------------------
  2. CLEAN PRODUCT NAMES
------------------------------------------------------------------------------*/

-- Some product names have a '#' and extra text after it.
-- CHARINDEX finds the position of '#', LEFT keeps the text before it,
-- and RTRIM removes the spaces at the end. Only names that contain '#' are updated.

 UPDATE dbo.Products
SET ProductName = RTRIM(LEFT(ProductName, CHARINDEX('#', ProductName) - 1))
WHERE CHARINDEX('#', ProductName) > 0;

/*------------------------------------------------------------------------------
  3. CLEAN SUPPLIER NAMES
------------------------------------------------------------------------------*/

-- Remove the last 3 characters of every supplier name.
-- There is no WHERE, so ALL the rows are updated. Do not run it twice.

UPDATE dbo.Suppliers
SET SupplierName = RTRIM(LEFT(SupplierName, LEN(SupplierName) - 3));

/*------------------------------------------------------------------------------
  4. FIND DUPLICATE CUSTOMERS (SELECT only)
------------------------------------------------------------------------------*/

-- Customers who have the same first name, last name and email.
-- HAVING COUNT(*) > 1 keeps only the groups that appear more than once.
-- UNION ALL adds one last row 'TOTAL DUPLICATES' with the sum of all counts.

WITH DuplicateGroups AS (
    SELECT 
        CONCAT(FirstName, ' ', LastName) AS FullName, 
        COALESCE(Email, 'NoData') AS Email, 
        COUNT(*) AS DuplicateCount          -- Removed trailing comma here
    FROM dbo.Customers
    GROUP BY FirstName, LastName, Email
    HAVING COUNT(*) > 1
)
SELECT FullName, Email, DuplicateCount
FROM DuplicateGroups
UNION ALL
SELECT 'TOTAL DUPLICATES' AS FullName, '', SUM(DuplicateCount)
FROM DuplicateGroups;

-- Customers that still have a NULL email.
-- After section 1 this should return no rows.

SELECT FirstName, LastName, Email, SignupDate, IsActive
FROM Customers
WHERE Email IS NULL
GROUP BY FirstName, LastName, Email, SignupDate, IsActive;

-- The duplicate customers row by row.
-- COUNT(*) OVER (PARTITION BY ...) counts the rows of each group without collapsing them.
-- ExtraDuplicateCount is the number of extra copies (total rows - 1).

WITH RankedCustomers AS (
    SELECT 
        CONCAT(FirstName, ' ', LastName) AS FullName, 
        email,
        Phone,
        IsActive,
        SignupDate,
        COUNT(*) OVER (
            PARTITION BY FirstName, LastName, email
        ) AS TotalRows,
        -- Subtract 1 so it only counts the extra copies
        COUNT(*) OVER (
            PARTITION BY FirstName, LastName, email
        ) - 1 AS ExtraDuplicateCount
    FROM dbo.Customers
)
SELECT 
    FullName, 
    email, 
    Phone, 
    IsActive, 
    SignupDate, 
    ExtraDuplicateCount
FROM RankedCustomers
-- Filter for groups that have more than 1 total row
WHERE TotalRows > 1
ORDER BY FullName, email;
