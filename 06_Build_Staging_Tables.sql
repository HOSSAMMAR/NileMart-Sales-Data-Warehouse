use NileMartDW


CREATE TABLE dbo.Stg_DimCategory
(
    CategoryID INT,
    CategoryName NVARCHAR(100),
    ParentCategoryID INT
);

select
COUNT (*) as TotalRows,
COUNT(Distinct CategoryID) as UniqueCategories,
SUM ( case
when ParentCategoryID IS Null Then 1
Else 0 
End ) as RootCategories
From dbo.Stg_DimCategory


SELECT *
FROM dbo.DimCategory;

---------------------------------------------------------


CREATE TABLE dbo.Stg_DimProduct
(
    ProductID INT NOT NULL,
    ProductName NVARCHAR(200) NOT NULL,
    CategoryID INT NULL,
    SupplierID INT NULL,
    SupplierName NVARCHAR(200) NULL,
    UnitPrice DECIMAL(10,2) NULL,
    UnitCost DECIMAL(10,2) NULL,
    LaunchDate DATE NULL,
    IsDiscontinued BIT NULL
);

SELECT COUNT(*) AS TotalProducts
FROM dbo.DimProduct;

------------------------------------------------------

CREATE TABLE dbo.Stg_DimCustomer
(
    CustomerID INT NOT NULL,
    FirstName NVARCHAR(100) NULL,
    LastName NVARCHAR(100) NULL,
    Email NVARCHAR(255) NULL
);

Select 
COUNT(*) As TotalStagingCustomers,
COUNT (Distinct CustomerID) AS UniqueCustomers
FROM dbo.DimCustomer;

------------------------------------------------------------------

select 
column_Name,
DAta_type,
Character_maximum_length,
Numeric_precision,
Numeric_scale,
IS_NullAble
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME = 'DimStore'
Order by ORDINAL_POSITION;

Create table dbo.stg_Dimstore(
StoreID INT NOT NULL,
StoreName NVARCHAR(200) NULL,
StoreType VARCHAR(100) NULL ,
CityID INT NULL ,
OpenDate DATE NULL ,
IsOnline BIT NULL
);

--------------------------------------------
 select
 COLUMN_NAME,
 CHARACTER_MAXIMUM_LENGTH,
 DATA_TYPE,
 IS_NULLABLE
 FROM INFORMATION_SCHEMA.COLUMNS
 WHERE TABLE_NAME ='DimpaymentMethod'
 order by ORDINAL_POSITION;

 Create table dbo.stg_DimPaymentMethod(
 paymentMethodeID int not null,
 MethodeName nvarchar(100) Null
 );
----------------------------------------------------
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimEmployee'
ORDER BY ORDINAL_POSITION;

select 
Column_Name,
Data_type,
Numeric_precision,
Numeric_Scale
from INFORMATION_SCHEMA.COLUMNS
Where TABLE_NAME='Employees' And column_name ='Salary';

Create table dbo.stg_DimEmployee(
EmployeeID Int Null,
FirstName nvarchar(100) Null,
LastName nvarchar(100) Null,
JobTitle nvarchar(100) Null,
ManagerID int NULL,
StoreID int NUll,
HireDate date NULL,
Salary decimal(10,2) NULL
);

SELECT
    COUNT(*) AS TotalDimEmployees,
    COUNT(DISTINCT EmployeeID) AS UniqueEmployees
FROM dbo.DimEmployee;

--------------------------------------------------------
SELECT
    COUNT(*) AS TotalDates,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM dbo.DimDate;

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT FullDate) AS UniqueDates,
    DATEDIFF(DAY, MIN(FullDate), MAX(FullDate)) + 1 AS ExpectedDates
FROM dbo.DimDate;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DimDate'
ORDER BY ORDINAL_POSITION;

SELECT
    MIN(CAST(OrderDate AS DATE)) AS StartDate,
    MAX(CAST(OrderDate AS DATE)) AS EndDate
FROM dbo.Orders;

CREATE TABLE dbo.Stg_DimDate
(
    DateKey INT NOT NULL,
    FullDate DATE NOT NULL,
    [Year] INT NOT NULL,
    [Month] INT NOT NULL,
    MonthName NVARCHAR(20) NOT NULL,
    [Quarter] INT NOT NULL
);

SELECT
    COUNT(*) AS TotalRows,
    COUNT(DISTINCT DateKey) AS UniqueDateKeys,
    COUNT(DISTINCT FullDate) AS UniqueDates,
    MIN(FullDate) AS FirstDate,
    MAX(FullDate) AS LastDate
FROM dbo.DimDate;

-----------------------------------------------------------------

Select 
Column_Name,
DAta_Type,
Is_NULLABLE
from INFORMATION_SCHEMA.COLUMNS
Where TABLE_Name = 'FactSales'
Order by ORDINAL_POSITION;

Select 
Table_Name,
Column_Name,
Data_Type,
Is_Nullable
from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME IN ('Order','OrderItems')
Order by TABLE_NAME ,ORDINAL_POSITION;

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Orders'
ORDER BY ORDINAL_POSITION;

SELECT
    COUNT(*) AS TotalOrderItems,
    COUNT(o.OrderID) AS MatchedOrders,
    SUM(CASE WHEN oi.LineTotal IS NULL THEN 1 ELSE 0 END)
        AS NullLineTotals,
    COUNT(DISTINCT oi.OrderItemID) AS UniqueOrderItems
FROM dbo.OrderItems oi
LEFT JOIN dbo.Orders o
    ON oi.OrderID = o.OrderID;

    SELECT
    o.OrderStatus,
    COUNT(*) AS TotalOrderItems
FROM dbo.OrderItems oi
INNER JOIN dbo.Orders o
    ON oi.OrderID = o.OrderID
GROUP BY o.OrderStatus;

SELECT
    oi.OrderItemID,
    o.OrderID,
    o.OrderDate,
    oi.ProductID,
    o.CustomerID,
    o.StoreID,
    o.PaymentMethodID,
    o.EmployeeID,
    oi.Quantity,
    oi.LineTotal
FROM dbo.OrderItems AS oi
INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed';

CREATE TABLE dbo.Stg_FactSales
(
    OrderItemID INT NOT NULL,
    OrderID INT NOT NULL,
    OrderDate DATETIME2 NOT NULL,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    StoreID INT NOT NULL,
    PaymentMethodID INT NOT NULL,
    EmployeeID INT NULL,
    Quantity INT NOT NULL,
    LineTotal DECIMAL(10,2) NOT NULL
);

SELECT COUNT(*) AS StagingRows
FROM dbo.Stg_FactSales;

SELECT COUNT(*) AS FactSalesRows
FROM dbo.FactSales;

SELECT
    (SELECT COUNT(*) FROM dbo.FactSales) AS FactSalesRows,
    (SELECT COUNT(*) FROM dbo.Stg_FactSales) AS StagingRows;

    SELECT
    name AS ForeignKeyName,
    OBJECT_NAME(parent_object_id) AS ReferencingTable
FROM sys.foreign_keys
WHERE referenced_object_id = OBJECT_ID('dbo.FactSales');

SELECT
    f.OrderItemID,
    f.ProductID
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimProduct AS p
    ON f.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

SELECT
    f.OrderItemID,
    f.CustomerID
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimCustomer AS c
    ON f.CustomerID = c.CustomerID
WHERE c.CustomerID IS NULL;

SELECT
    f.OrderItemID,
    f.StoreID
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimStore AS s
    ON f.StoreID = s.StoreID
WHERE s.StoreID IS NULL;

SELECT
    f.OrderItemID,
    f.PaymentMethodID
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimPaymentMethod AS pm
    ON f.PaymentMethodID = pm.PaymentMethodeID
WHERE pm.PaymentMethodeID IS NULL;

SELECT
    f.OrderItemID,
    f.DateKey
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimDate AS d
    ON f.DateKey = d.DateKey
WHERE d.DateKey IS NULL;

SELECT
    f.OrderItemID,
    f.EmployeeKey
FROM dbo.FactSales AS f
LEFT JOIN dbo.DimEmployee AS e
    ON f.EmployeeKey = e.EmployeeKey
WHERE f.EmployeeKey IS NOT NULL
  AND e.EmployeeKey IS NULL;

  SELECT
    COUNT(*) AS TotalRows,
    SUM(oi.Quantity) AS TotalQuantitySold,
    SUM(oi.LineTotal) AS TotalSales
FROM dbo.OrderItems AS oi
INNER JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed';

SELECT TOP 10
    Quantity,
    UnitPrice,
    DiscountPct,
    LineTotal
FROM dbo.OrderItems
WHERE DiscountPct > 0
ORDER BY DiscountPct DESC;


SELECT
    COUNT(*) AS TotalRows,
    SUM(
        CASE
            WHEN LineTotal <>
                CAST(
                    ROUND(
                        Quantity * UnitPrice *
                        (1 - DiscountPct / 100.0),
                        2
                    ) AS DECIMAL(10,2)
                )
            THEN 1
            ELSE 0
        END
    ) AS MismatchedRows
FROM dbo.OrderItems;


