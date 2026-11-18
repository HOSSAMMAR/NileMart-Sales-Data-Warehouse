/*==============================================================================
  NileMart project - File 04 : Data Warehouse (DW) Build
  Databases : NileMartDW (new, the warehouse)  <-  data comes from NileMartTraining

  What is this file?
    It builds a small data warehouse for reports, using a "star schema":
      - Dimension tables (Dim...) describe things: dates, products, customers,
        stores, payment methods, employees.
      - The Fact table (FactSales) stores the sales numbers and points to the dimensions.

  Simple terms
    Primary Key (PK)  : a column that identifies each row, with no repeated values.
    Foreign Key (FK)  : a column that points to the PK of another table.
    Surrogate key     : a new number made for the warehouse (here EmployeeKey).
    IDENTITY          : a column that numbers the rows automatically (1, 2, 3 ...).

  Notes
    - The queries are kept in the order they were written, step by step.
      Some steps were tried more than once or changed later; comments say which.
    - The SELECT checks of this part are in file 05_DW_Validation.sql.

  Sections
    0. Create the database
    1. DimDate          2. DimProduct       3. DimCustomer
    4. DimStore         5. DimPaymentMethod 6. DimEmployee
    7. FactSales        8. EmployeeKey in DimEmployee (surrogate key)
    9. EmployeeKey in FactSales             10. Later change: NULL instead of 'Not Applicable'
    11. Foreign keys from FactSales to the other dimensions
==============================================================================*/

/*------------------------------------------------------------------------------
  0. CREATE THE DATABASE
------------------------------------------------------------------------------*/

-- Create the new warehouse database and switch to it.

CREATE DATABASE NileMartDW;
GO
USE NileMartDW;
GO

/*------------------------------------------------------------------------------
  1. DimDate (one row for each day)
------------------------------------------------------------------------------*/

-- First try: create the date table.
-- DateKey is a number like 20250131 (year, month, day).

/*DimDate*/
CREATE TABLE dbo.DimDate (
    DateKey INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    [Quarter] INT NOT NULL
);
GO

-- Second try: the same table, but IF OBJECT_ID(...) IS NULL creates it only when it does not exist yet.
-- This version is safe to run again.

USE NileMartDW;
GO

IF OBJECT_ID('dbo.DimDate', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DimDate (
        DateKey INT PRIMARY KEY,
        FullDate DATE NOT NULL,
        [Year] INT NOT NULL,
        [Month] INT NOT NULL,
        MonthName NVARCHAR(20) NOT NULL,
        [Quarter] INT NOT NULL
    );
END;
GO

-- Fill DimDate with every day from the first order date to the last order date
-- (the two dates come from the MIN/MAX query in file 01).
-- The WITH part is a recursive CTE: it starts at @StartDate and adds one day each time until @EndDate.
-- CONVERT(..., 112) turns a date into the text YYYYMMDD, and then into a number for DateKey.
-- MAXRECURSION 0 removes the default limit of 100 repeats.

DECLARE @StartDate DATE = '2022-01-16';
DECLARE @EndDate   DATE = '2025-12-31';

;WITH DateSeries AS
(
    SELECT @StartDate AS FullDate

    UNION ALL

    SELECT DATEADD(DAY, 1, FullDate)
    FROM DateSeries
    WHERE FullDate < @EndDate
)
INSERT INTO dbo.DimDate
(
    DateKey,
    FullDate,
    [Year],
    [Month],
    MonthName,
    [Quarter]
)
SELECT
    CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),
    FullDate,
    YEAR(FullDate),
    MONTH(FullDate),
    DATENAME(MONTH, FullDate),
    DATEPART(QUARTER, FullDate)
FROM DateSeries
OPTION (MAXRECURSION 0);
GO

/*------------------------------------------------------------------------------
  2. DimProduct
------------------------------------------------------------------------------*/

-- Create the product dimension (it also has the supplier name).

-----Dimproduct-------------------------------------------
CREATE TABLE dbo.DimProduct
(
    ProductID INT PRIMARY KEY,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT,
    SupplierID INT,
    SupplierName NVARCHAR(200),
    UnitPrice DECIMAL(10,2),
    UnitCost DECIMAL(10,2),
    LaunchDate DATE,
    IsDiscontinued BIT
);
GO

-- Fill DimProduct from the source tables.
-- LEFT JOIN to Suppliers so a product without a supplier is still copied.

INSERT INTO NileMartDW.dbo.DimProduct
(
    ProductID,
    ProductName,
    CategoryID,
    SupplierID,
    SupplierName,
    UnitPrice,
    UnitCost,
    LaunchDate,
    IsDiscontinued
)
SELECT
    p.ProductID,
    p.ProductName,
    p.CategoryID,
    p.SupplierID,
    s.SupplierName,
    p.UnitPrice,
    p.UnitCost,
    p.LaunchDate,
    p.IsDiscontinued
FROM NileMartTraining.dbo.Products AS p
LEFT JOIN NileMartTraining.dbo.Suppliers AS s
    ON p.SupplierID = s.SupplierID;

/*------------------------------------------------------------------------------
  3. DimCustomer
------------------------------------------------------------------------------*/

-- Create DimCustomer (only the basic columns) and fill it from the Customers table.

-----------------DimCustomer----------------------
use NileMartDW
CREATE TABLE dbo.DimCustomer
(
    CustomerID INT PRIMARY KEY,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    Email NVARCHAR(255)
);

Insert into NileMartDW.dbo.Dimcustomer(
    CustomerID,
    FirstName,
    LastName,
    Email
)
Select 
    CustomerID,
    FirstName,
    LastName,
    Email
    from NileMartTraining.dbo.Customers ;

/*------------------------------------------------------------------------------
  4. DimStore
------------------------------------------------------------------------------*/

    /*  DimStore  */

-- Create the store dimension.

USE NileMartDW;
GO

CREATE TABLE dbo.DimStore
(
    StoreID INT PRIMARY KEY,
    StoreName NVARCHAR(200),
    StoreType VARCHAR(100),
    CityID INT,
    OpenDate DATE
);

-- Add a new column IsOnline (1 = online store, 0 = physical store).

Alter Table DimStore
ADD IsOnline Bit ;

-- Fill IsOnline from StoreType using CASE.
-- Note: an UPDATE changes only the rows that exist when it runs.
-- If the table is still empty at this point, run this UPDATE again after the INSERT below.

update dbo.DimStore
set IsOnline =
case
when StoreType = 'Online' then 1
when StoreType = 'Physical' then 0
End;

-- Copy the stores from the source database into DimStore.

INSERT INTO NileMartDW.dbo.DimStore
(
    StoreID,
    StoreName,
    StoreType,
    CityID,
    OpenDate
)
SELECT
    StoreID,
    StoreName,
    StoreType,
    CityID,
    OpenDate
FROM NileMartTraining.dbo.Stores;

/*------------------------------------------------------------------------------
  5. DimPaymentMethod
------------------------------------------------------------------------------*/

-- Create the payment method dimension.

/* Creat DimPaymentMethod in NileMartDW */

Create table dbo.DimPaymentMethod
(
paymentMethodeID int primary key ,
MethodeName Nvarchar(100)
);

-- Fill it from the source PaymentMethods table.

Insert into NileMartDW.dbo.DimPaymentMethod
(
paymentMethodeID,
MethodeName
)
select 
paymentMethodID,
MethodName 
from NileMartTraining.dbo.PaymentMethods;

/*------------------------------------------------------------------------------
  6. DimEmployee
------------------------------------------------------------------------------*/

/* Creat a DimEmployee*/

-- Create the employee dimension.
-- Here EmployeeID (from the source) is the primary key. This is changed later (section 8).

Create table Dbo.DimEmployee
(
EmployeeID int primary key ,
FirstName NVarchar(100),
LastName Nvarchar(100),
JobTitle Nvarchar(100),
ManagerID Int Null,
StoreID Int Null,
HireDate Date,
Salary Decimal(12,2)
);

-- Copy the employees from the source database.

INSERT INTO NileMartDW.dbo.DimEmployee
(
    EmployeeID,
    FirstName,
    LastName,
    JobTitle,
    ManagerID,
    StoreID,
    HireDate,
    Salary
)
SELECT
    EmployeeID,
    FirstName,
    LastName,
    JobTitle,
    ManagerID,
    StoreID,
    HireDate,
    Salary
FROM NileMartTraining.dbo.Employees;

/*------------------------------------------------------------------------------
  7. FactSales (one row for each order line of a Completed order)
------------------------------------------------------------------------------*/

    /*Creat a factsales */

-- Switch to the warehouse database.

USE NileMartDW;
GO

-- Create the sales fact table.
-- Each row has the keys that point to the dimensions (date, product, customer, store, payment)
-- and the numbers to analyze (Quantity and LineTotal).

CREATE TABLE dbo.FactSales
(
    OrderItemID INT NOT NULL PRIMARY KEY,
    OrderID INT NOT NULL,
    DateKey INT NOT NULL,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    StoreID INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    Quantity INT NOT NULL,
    LineTotal DECIMAL(12,2) NOT NULL
);
GO

-- Fill FactSales from the source.
-- Only Completed orders are copied (WHERE o.OrderStatus = 'Completed').
-- DateKey is made from OrderDate in the same YYYYMMDD style used in DimDate.

INSERT INTO NileMartDW.dbo.FactSales
(
    OrderItemID,
    OrderID,
    DateKey,
    ProductID,
    CustomerID,
    StoreID,
    PaymentMethodID,
    Quantity,
    LineTotal
)
SELECT
    oi.OrderItemID,
    o.OrderID,
    CONVERT(INT, CONVERT(CHAR(8), o.OrderDate, 112)),
    oi.ProductID,
    o.CustomerID,
    o.StoreID,
    o.PaymentMethodID,
    oi.Quantity,
    oi.LineTotal
FROM NileMartTraining.dbo.OrderItems AS oi
JOIN NileMartTraining.dbo.Orders AS o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed';

/*------------------------------------------------------------------------------
  8. EmployeeKey IN DimEmployee (surrogate key)
------------------------------------------------------------------------------*/

-- Problem: some orders have no employee (EmployeeID is NULL), but a key column cannot be NULL
-- if we want a relationship to DimEmployee.
-- Idea: give DimEmployee its own key (EmployeeKey) and add a special row 'Not Applicable'.
--
-- Step A - add the EmployeeKey column. IDENTITY(1,1) numbers the rows automatically.

ALTER TABLE dbo.DimEmployee
ADD EmployeeKey INT IDENTITY(1,1) NOT NULL;

-- Step B - find the name of the current primary key, then drop it.
-- The name [PK__DimEmplo__...] was generated by SQL Server, so it can be different on another computer.

SELECT name
FROM sys.key_constraints
WHERE parent_object_id = OBJECT_ID('dbo.DimEmployee')
  AND type = 'PK';

  ALTER TABLE dbo.DimEmployee
DROP CONSTRAINT [PK__DimEmplo__7AD04FF1B5A1F96A];

-- Step C - make EmployeeKey the new primary key.

ALTER TABLE dbo.DimEmployee
ADD CONSTRAINT PK_DimEmployee
PRIMARY KEY CLUSTERED (EmployeeKey);

-- Step D - add the special row 'Not Applicable' with key 0.
-- IDENTITY_INSERT ON lets us write our own value in an IDENTITY column. It must be OFF again after.
-- EmployeeID must accept NULL for this row (see Step E).

SET IDENTITY_INSERT dbo.DimEmployee ON;

INSERT INTO dbo.DimEmployee
(
    EmployeeKey,
    EmployeeID,
    FirstName,
    LastName,
    JobTitle,
    ManagerID,
    StoreID,
    HireDate,
    Salary
)
VALUES
(
    0,
    NULL,
    'Not',
    'Applicable',
    'Not Applicable',
    NULL,
    NULL,
    NULL,
    NULL
);

SET IDENTITY_INSERT dbo.DimEmployee OFF;

-- Step E - make sure IDENTITY_INSERT is OFF, then allow NULL in EmployeeID
-- (the 'Not Applicable' row has no source employee id).

-- التأكد من إيقاف IDENTITY_INSERT
SET IDENTITY_INSERT dbo.DimEmployee OFF;

-- السماح بأن يكون EmployeeID فارغًا
ALTER TABLE dbo.DimEmployee
ALTER COLUMN EmployeeID INT NULL;

-- Step F - add the 'Not Applicable' row only if it does not exist yet.
-- IF NOT EXISTS makes this block safe to run again.

-- إضافة Special Dimension Member
IF NOT EXISTS
(
    SELECT 1
    FROM dbo.DimEmployee
    WHERE EmployeeID IS NULL
      AND JobTitle = 'Not Applicable'
)
BEGIN
    INSERT INTO dbo.DimEmployee
    (
        EmployeeID,
        FirstName,
        LastName,
        JobTitle,
        ManagerID,
        StoreID,
        HireDate,
        Salary
    )
    VALUES
    (
        NULL,
        'Not',
        'Applicable',
        'Not Applicable',
        NULL,
        NULL,
        NULL,
        NULL
    );
END;

/*------------------------------------------------------------------------------
  9. EmployeeKey IN FactSales
------------------------------------------------------------------------------*/

-- First way: everything inside one TRANSACTION.
-- A transaction means "all steps succeed or none of them is saved":
-- TRY runs the steps, CATCH does ROLLBACK (undo) if there is an error.
-- Steps inside: find the key of 'Not Applicable', add EmployeeKey to FactSales,
-- fill it, make it NOT NULL, and create the foreign key to DimEmployee.
-- COALESCE gives the 'Not Applicable' key to sales that have no employee.

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @NotApplicableEmployeeKey INT;

    -- Get the Special Dimension Member key
    SELECT @NotApplicableEmployeeKey = EmployeeKey
    FROM dbo.DimEmployee
    WHERE EmployeeID IS NULL
      AND JobTitle = 'Not Applicable';

    IF @NotApplicableEmployeeKey IS NULL
        THROW 50001, 'Not Applicable member not found.', 1;

    -- Add EmployeeKey to FactSales
    IF COL_LENGTH('dbo.FactSales', 'EmployeeKey') IS NULL
    BEGIN
        ALTER TABLE dbo.FactSales
        ADD EmployeeKey INT NULL;
    END;

    -- Map sales rows to employees
    UPDATE fs
    SET EmployeeKey =
        COALESCE(de.EmployeeKey, @NotApplicableEmployeeKey)
    FROM dbo.FactSales AS fs
    INNER JOIN NileMartTraining.dbo.Orders AS o
        ON fs.OrderID = o.OrderID
    LEFT JOIN dbo.DimEmployee AS de
        ON o.EmployeeID = de.EmployeeID;

    -- Make EmployeeKey mandatory
    ALTER TABLE dbo.FactSales
    ALTER COLUMN EmployeeKey INT NOT NULL;

    -- Add relationship
    ALTER TABLE dbo.FactSales
    ADD CONSTRAINT FK_FactSales_DimEmployee
    FOREIGN KEY (EmployeeKey)
    REFERENCES dbo.DimEmployee(EmployeeKey);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    THROW;
END CATCH;

-- Second way (step by step, outside a transaction).
-- First check whether the EmployeeKey column exists (COL_LENGTH returns NULL if it does not), then add it.

SELECT COL_LENGTH('dbo.FactSales', 'EmployeeKey')
    AS EmployeeKeyColumn;

    ALTER TABLE dbo.FactSales
ADD EmployeeKey INT NULL;


SELECT COL_LENGTH('dbo.FactSales', 'EmployeeKey')
    AS EmployeeKeyColumn;

-- Fill EmployeeKey: sales with no employee get the 'Not Applicable' key, the others get their employee key.
-- Note: the '0.' at the end of the last line is extra text, not a query.

    DECLARE @NotApplicableKey INT;

SELECT @NotApplicableKey = EmployeeKey
FROM dbo.DimEmployee
WHERE EmployeeID IS NULL
  AND JobTitle = 'Not Applicable';

IF @NotApplicableKey IS NULL
    THROW 50001, 'Not Applicable member not found.', 1;

UPDATE fs
SET EmployeeKey =
    CASE
        WHEN o.EmployeeID IS NULL
            THEN @NotApplicableKey
        ELSE de.EmployeeKey
    END
FROM dbo.FactSales AS fs
INNER JOIN NileMartTraining.dbo.Orders AS o
    ON fs.OrderID = o.OrderID
LEFT JOIN dbo.DimEmployee AS de
    ON o.EmployeeID = de.EmployeeID;0.

-- Make EmployeeKey NOT NULL, then create the foreign key to DimEmployee.

ALTER TABLE dbo.FactSales
ALTER COLUMN EmployeeKey INT NOT NULL;

ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimEmployee
FOREIGN KEY (EmployeeKey)
REFERENCES dbo.DimEmployee(EmployeeKey);

/*------------------------------------------------------------------------------
  10. LATER CHANGE: NULL INSTEAD OF 'NOT APPLICABLE'
------------------------------------------------------------------------------*/

-- New decision: sales without an employee will keep NULL in EmployeeKey,
-- and the 'Not Applicable' row (EmployeeKey = 61) will be deleted.
-- First attempt: drop the foreign key.

Alter Table dbo.Factsales
Drop constraint Fk_Factsales_DimEmployee;

-- Full version in 5 steps: (1) drop the foreign key, (2) allow NULL, (3) replace 61 with NULL,
-- (4) delete the 'Not Applicable' member, (5) create the foreign key again.
-- The foreign key must be dropped first, because it does not allow deleting a row that is still used.

USE NileMartDW;
GO

-- 1. Remove Foreign Key
ALTER TABLE dbo.FactSales
DROP CONSTRAINT FK_FactSales_DimEmployee;

-- 2. Allow NULL
ALTER TABLE dbo.FactSales
ALTER COLUMN EmployeeKey INT NULL;

-- 3. Replace 61 with NULL
UPDATE dbo.FactSales
SET EmployeeKey = NULL
WHERE EmployeeKey = 61;

-- 4. Delete Not Applicable member
DELETE FROM dbo.DimEmployee
WHERE EmployeeKey = 61;

-- 5. Recreate Foreign Key
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimEmployee
FOREIGN KEY (EmployeeKey)
REFERENCES dbo.DimEmployee(EmployeeKey);

-- Delete the 'Not Applicable' row (EmployeeKey = 61).

DELETE FROM dbo.DimEmployee
WHERE EmployeeKey = 61;

-- Second attempt (shorter): allow NULL and replace 61 with NULL in FactSales.
-- The check query for this part is in file 05.

USE NileMartDW;
GO

ALTER TABLE dbo.FactSales
ALTER COLUMN EmployeeKey INT NULL;

UPDATE dbo.FactSales
SET EmployeeKey = NULL
WHERE EmployeeKey = 61;

-- Create the foreign key again.

ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimEmployee
FOREIGN KEY (EmployeeKey)
REFERENCES dbo.DimEmployee(EmployeeKey);

/*------------------------------------------------------------------------------
  11. FOREIGN KEYS FROM FactSales TO THE OTHER DIMENSIONS
------------------------------------------------------------------------------*/

-- Each foreign key makes sure that a value in FactSales really exists in the dimension table.
-- Example: every DateKey in FactSales must exist in DimDate.

USE NileMartDW;
GO

-- 1. FactSales → DimDate
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimDate
FOREIGN KEY (DateKey)
REFERENCES dbo.DimDate(DateKey);

-- 2. FactSales → DimProduct
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimProduct
FOREIGN KEY (ProductID)
REFERENCES dbo.DimProduct(ProductID);

-- 3. FactSales → DimCustomer
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimCustomer
FOREIGN KEY (CustomerID)
REFERENCES dbo.DimCustomer(CustomerID);

-- 4. FactSales → DimStore
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimStore
FOREIGN KEY (StoreID)
REFERENCES dbo.DimStore(StoreID);

-- 5. FactSales → DimPaymentMethod
ALTER TABLE dbo.FactSales
ADD CONSTRAINT FK_FactSales_DimPaymentMethod
FOREIGN KEY (PaymentMethodID)
REFERENCES dbo.DimPaymentMethod(paymentMethodeID);
