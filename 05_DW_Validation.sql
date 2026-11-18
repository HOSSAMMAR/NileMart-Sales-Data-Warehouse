/*==============================================================================
  NileMart project - File 05 : DW Validation
  Database : NileMartDW

  What is this file?
    After building the warehouse (file 04), these SELECT queries check that
    the data was copied correctly and that the relationships are right.
    They only READ data.

  Sections
    1. Dimension checks
    2. FactSales checks (rows and totals)
    3. Employee checks
    4. Foreign key checks
==============================================================================*/

USE NileMartDW;
GO

/*------------------------------------------------------------------------------
  1. DIMENSION CHECKS
------------------------------------------------------------------------------*/

-- DimDate: number of days and the first and last date.

SELECT
    COUNT(*) AS TotalDates,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM dbo.DimDate;

-- DimProduct: look at the first 5 rows (before the data was loaded this table was empty).

SELECT TOP 5 *
FROM dbo.DimProduct;

-- DimProduct: first 5 rows after loading, with the supplier name.

 SELECT TOP 5
    ProductID,
    ProductName,
    SupplierName,
    UnitPrice,
    IsDiscontinued
FROM NileMartDW.dbo.DimProduct;

-- DimCustomer: count the rows. It should match the number of customers in the source.

---To make sure the prosses of transfere is success
    select COUNT(*) As TotalCustomers
    from  NileMartDW.dbo.DimCustomer;

-- DimStore: look at the stores with the IsOnline value.

SELECT
    StoreID,
    StoreName,
    StoreType,
    IsOnline
FROM dbo.DimStore;

-- DimStore: total number of stores.

SELECT COUNT(*) AS TotalStores
FROM dbo.DimStore;

-- DimStore: number of stores for each store type.

SELECT
    StoreType,
    COUNT(*) AS TotalStores
FROM dbo.DimStore
GROUP BY StoreType;

-- DimPaymentMethod: read all the rows.

select *
from NileMartDW.dbo.DimPaymentMethod;

/*------------------------------------------------------------------------------
  2. FactSales CHECKS
------------------------------------------------------------------------------*/

-- Show the details of the DimEmployee table and the FactSales table (columns, keys).

EXEC sp_help 'dbo.DimEmployee';
EXEC sp_help 'dbo.FactSales';

-- Number of rows in FactSales.

SELECT COUNT(*) AS TotalRows
FROM NileMartDW.dbo.FactSales;

SELECT COUNT(*) AS TotalSalesRows
FROM NileMartDW.dbo.FactSales;

-- Rows, total quantity and total sales in the warehouse.

SELECT
    COUNT(*) AS TotalSalesRows,
    SUM(Quantity) AS TotalQuantitySold,
    SUM(LineTotal) AS TotalSales
FROM NileMartDW.dbo.FactSales;

-- Total sales of Completed orders in the source database.
-- This number should be equal to TotalSales of the previous query.

SELECT
    SUM(oi.LineTotal) AS SourceSales
FROM NileMartTraining.dbo.OrderItems AS oi
JOIN NileMartTraining.dbo.Orders AS o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed';

-- Do any values of LineTotal have NULL?
-- RowsWithoutLineTotal should be 0.

SELECT
    COUNT(*) AS TotalRows,
    COUNT(LineTotal) AS RowsWithLineTotal,
    COUNT(*) - COUNT(LineTotal) AS RowsWithoutLineTotal,
    SUM(LineTotal) AS TotalSales
FROM dbo.FactSales;

/*------------------------------------------------------------------------------
  3. EMPLOYEE CHECKS
------------------------------------------------------------------------------*/

-- Sales rows that have an employee and sales rows that have no employee.

SELECT
    COUNT(*) AS TotalSalesRows,
    COUNT(o.EmployeeID) AS SalesRowsWithEmployee,
    COUNT(*) - COUNT(o.EmployeeID) AS SalesRowsWithoutEmployee
FROM dbo.FactSales AS fs
INNER JOIN NileMartTraining.dbo.Orders AS o
    ON fs.OrderID = o.OrderID;

-- The same check for each store type, to see where the missing employees come from.

    SELECT
    s.StoreType,
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END AS EmployeeStatus,
    COUNT(*) AS TotalSalesRows
FROM dbo.FactSales AS fs
INNER JOIN NileMartTraining.dbo.Orders AS o
    ON fs.OrderID = o.OrderID
LEFT JOIN NileMartTraining.dbo.Stores AS s
    ON o.StoreID = s.StoreID
GROUP BY
    s.StoreType,
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END
ORDER BY s.StoreType, EmployeeStatus;

-- DimEmployee: number of rows, number of different EmployeeID, smallest and biggest EmployeeID.
-- COUNT(DISTINCT ...) counts each value once.

SELECT
    COUNT(*) AS TotalEmployees,
    COUNT(DISTINCT EmployeeID) AS UniqueEmployees,
    MIN(EmployeeID) AS MinEmployeeID,
    MAX(EmployeeID) AS MaxEmployeeID
FROM dbo.DimEmployee;

-- DimEmployee: all employees ordered by the new EmployeeKey.

SELECT
    EmployeeKey,
    EmployeeID,
    FirstName,
    LastName
FROM dbo.DimEmployee
ORDER BY EmployeeKey;

-- The first 5 and the last 5 rows of DimEmployee.
-- UNION ALL puts the two results one under the other.

SELECT *
FROM
(
    SELECT TOP 5
        EmployeeKey, EmployeeID, FirstName, LastName
    FROM dbo.DimEmployee
    ORDER BY EmployeeKey ASC
) AS FirstRows

UNION ALL

SELECT *
FROM
(
    SELECT TOP 5
        EmployeeKey, EmployeeID, FirstName, LastName
    FROM dbo.DimEmployee
    ORDER BY EmployeeKey DESC
) AS LastRows;

-- The special row where EmployeeID is NULL (the 'Not Applicable' member).

SELECT
    EmployeeKey,
    EmployeeID,
    FirstName,
    LastName,
    JobTitle
FROM dbo.DimEmployee
WHERE EmployeeID IS NULL;

-- FactSales: how many rows have an EmployeeKey and how many do not.
-- (After the later change in file 04, rows without an employee have NULL.)

    SELECT
    COUNT(*) AS TotalRows,
    COUNT(EmployeeKey) AS RowsWithEmployeeKey,
    COUNT(*) - COUNT(EmployeeKey) AS RowsWithoutEmployeeKey
FROM dbo.FactSales;

-- Number of sales rows for each employee key.

SELECT
    de.EmployeeKey,
    de.EmployeeID,
    de.JobTitle,
    COUNT(*) AS TotalSalesRows
FROM dbo.FactSales AS fs
INNER JOIN dbo.DimEmployee AS de
    ON fs.EmployeeKey = de.EmployeeKey
GROUP BY
    de.EmployeeKey,
    de.EmployeeID,
    de.JobTitle
ORDER BY de.EmployeeKey;

/*------------------------------------------------------------------------------
  4. FOREIGN KEY CHECKS
------------------------------------------------------------------------------*/

-- Which foreign keys point to DimEmployee, and from which table.

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS ReferencingTable
FROM sys.foreign_keys AS fk
WHERE fk.referenced_object_id = OBJECT_ID('dbo.DimEmployee');

-- Is EmployeeKey in FactSales allowed to be NULL? (IS_NULLABLE = YES or NO)

select 
COLUMN_NAME,
Is_NULLABLE
From INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME='FactSales'And COLUMN_NAME='EmployeeKey';

-- Is the foreign key enabled and trusted?
-- is_disabled = 0 and is_not_trusted = 0 means it works normally.

Select
name ,
is_disabled,
is_not_trusted
from sys.foreign_keys
where name ='FK_FactSales_DimEmployee';

-- Find sales rows that point to an EmployeeKey which does not exist in DimEmployee.
-- It should return no rows.

SELECT
    fs.EmployeeKey,
    COUNT(*) AS TotalRows
FROM dbo.FactSales AS fs
LEFT JOIN dbo.DimEmployee AS de
    ON fs.EmployeeKey = de.EmployeeKey
WHERE fs.EmployeeKey IS NOT NULL
  AND de.EmployeeKey IS NULL
GROUP BY fs.EmployeeKey;
