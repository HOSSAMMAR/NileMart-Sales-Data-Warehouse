/*==============================================================================
  NileMart project - File 01 : Data Exploration
  Database : NileMartTraining (the original data)

  What is this file?
    Before changing or building anything, we LOOK at the data first:
    which tables exist, how many rows, what values, and what problems.

  Important: every query here only READS data (SELECT). Nothing is changed.

  Sections
    1. Structure of the database
    2. Customers
    3. Orders
    4. Products and Categories
    5. Sales overview (all orders, any status)
    6. Data-quality checks (suppliers, payment methods, employees)
    7. Relationships between tables

  Order of the project files
    01 Exploration -> 02 Cleaning -> 03 Sales Analysis -> 04 DW Build -> 05 DW Validation
==============================================================================*/

USE NileMartTraining;
GO

/*------------------------------------------------------------------------------
  1. STRUCTURE OF THE DATABASE
------------------------------------------------------------------------------*/

-- sp_help shows the full details of a table (columns, data types, keys).
-- Here it is used for the Customers and Promotions tables.

use NileMartTraining
EXEC sp_help 'dbo.Customers';
EXEC sp_help 'dbo.promotions';

-- List of all the tables in the database.

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;

-- Columns of the Orders table: name, data type, and whether NULL is allowed.

SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Orders'
ORDER BY ORDINAL_POSITION;

-- Columns and data types of the Products table.

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
  AND TABLE_NAME = 'Products'
ORDER BY ORDINAL_POSITION;

-- Columns and data types of the Categories table.

select 
    COLUMN_NAME,
    DATA_TYPE
    From INFORMATION_SCHEMA.COLUMNS
    Where TABLE_SCHEMA='dbo'
    AND TABLE_NAME ='Categories'
    ORDER By ORDINAL_POSITION;

/*------------------------------------------------------------------------------
  2. CUSTOMERS
------------------------------------------------------------------------------*/

-- Look at all the customer rows.
-- Finding (written by the author below): some customers have NULL in phone, email and birthdate.
-- These NULLs are handled later in file 02.

/* Explore the data  */
select *
from dbo.Customers;
/*conculsion = There some null in phone,Email and Birthdate*/

-- How many customers are there?

select count(*) AS TotalCustomers
from dbo.Customers;
/*Result =There are 2525 customers*/

/*------------------------------------------------------------------------------
  3. ORDERS
------------------------------------------------------------------------------*/

-- The 10 newest orders (ORDER BY ... DESC puts the newest date first).
-- This shows how far the data goes in time.

/* Explore Orders */

select Top 10 *
from dbo.Orders
Order By OrderDate Desc;
/* Result = the last 10 order at 31-12-2025 */

-- Number of orders for each status.
-- WITH ROLLUP adds one extra row at the end with the total of all statuses
-- (ISNULL replaces the NULL of that extra row with the word 'Total').

select ISNULL(OrderStatus,'Total'),count(*) As NumberEachStatus
from dbo.Orders
Group By OrderStatus with ROLLUP;
/*Result = cancelled =819 ,completed =10959,processing=222*/

-- The first and the last order date.
-- These two dates are used later to decide the date range of DimDate (file 04).

USE NileMartTraining;
GO

SELECT
    MIN(OrderDate) AS FirstOrderDate,
    MAX(OrderDate) AS LastOrderDate
FROM dbo.Orders;

/*------------------------------------------------------------------------------
  4. PRODUCTS AND CATEGORIES
------------------------------------------------------------------------------*/

-- A quick look at the first 10 products and their main columns.

/* Explore products */
=========================================
SELECT TOP 10
    ProductID,ProductName,CategoryID,SupplierID,UnitPrice,UnitCost,LaunchDate, IsDiscontinued
FROM dbo.Products;

-- How many products are there?

SELECT COUNT(*) AS TotalProducts
FROM dbo.Products;
/* Result = 300 */

-- Cheapest, most expensive and average price of the products.

Select 
min(UnitPrice)As CheapestProduct,
max(Unitprice)As MostExpensiveprice,
Avg(Unitprice) As Avrageprice
From dbo.products;
/*Min=6.99,Max=2948.99,Avg=421.8533*/

-- Look at the Categories table.
-- ParentCategoryID shows that some categories sit inside other categories.

SELECT
    CategoryID,
    CategoryName,
    ParentCategoryID
FROM NileMartTraining.dbo.Categories
ORDER BY CategoryID;

/*------------------------------------------------------------------------------
  5. SALES OVERVIEW (all orders, any status)
------------------------------------------------------------------------------*/

-- Total value of all order lines.
-- Note: there is no status filter here, so cancelled and processing orders are included.
-- The queries in file 03 use only Completed orders.

SELECT
    SUM(LineTotal) AS TotalSales
FROM dbo.OrderItems;
/*Total sales = 23818579.90*/

-- Quantity sold and sales value for each product, highest sales first.
-- JOIN connects each order line to its product by ProductID.

select
p.ProductName ,
sum(oi.Quantity)AS TotalQuantitySold,
sum(oi.LineTotal) As TotalSales
From dbo.OrderItems oi
join dbo.products p
On oi.ProductID =p.ProductID
Group By p.productName
Order By TotalSales Desc;
/*Sales by product the HighproductSales is  smart Gaming laptop*/

-- Quantity sold and sales value for each category, highest sales first.
-- Path: OrderItems -> Products -> Categories.

Select 
c.CategoryName,
Sum(oi.Quantity)As unitsold,
Sum(oi.LineTotal) As TotalSales
From dbo.OrderItems oi
join dbo.Products p
on oi.productID = p.productID
join dbo.Categories c 
On p.CategoryID=c.CategoryID
Group By c.CategoryName
Order By TotalSales Desc;
/*Sales by Categories the high is GamingLaptops*/

/*------------------------------------------------------------------------------
  6. DATA-QUALITY CHECKS
------------------------------------------------------------------------------*/

-- Products with their supplier name.
-- LEFT JOIN keeps every product, even when it has no supplier.

USE NileMartTraining;
GO
---------------------------------------------------------
SELECT TOP 10
    p.ProductID,
    p.ProductName,
    p.SupplierID,
    s.SupplierName
FROM dbo.Products p
LEFT JOIN dbo.Suppliers s
    ON p.SupplierID = s.SupplierID;

-- How many products have no supplier?
-- CASE puts 1 for a product without a supplier and 0 otherwise, and SUM adds them up.

    SELECT
    COUNT(*) AS TotalProducts,
    SUM(CASE
        WHEN s.SupplierID IS NULL THEN 1
        ELSE 0
    END) AS ProductsWithoutSupplier
FROM dbo.Products p
LEFT JOIN dbo.Suppliers s
    ON p.SupplierID = s.SupplierID;

-- Look at the payment methods table (it is small, so we read all of it).

select *
from NileMartTraining.dbo.PaymentMethods;

-- Employees: how many rows have a value in each column?
-- COUNT(*) counts all rows, but COUNT(column) skips NULLs.
-- If the two numbers are different, the column has missing values.

SELECT
    COUNT(*) AS TotalEmployees,
    COUNT(EmployeeID) AS EmployeesWithID,
    COUNT(FirstName) AS EmployeesWithFirstName,
    COUNT(LastName) AS EmployeesWithLastName,
    COUNT(JobTitle) AS EmployeesWithJobTitle
FROM NileMartTraining.dbo.Employees;

-- Employees: how many have a store and how many have a manager.

SELECT
    COUNT(*) AS TotalEmployees,
    COUNT(StoreID) AS EmployeesWithStore,
    COUNT(ManagerID) AS EmployeesWithManager
FROM NileMartTraining.dbo.Employees;

-- Link between order lines and employees (the employee is saved on the order).
-- INNER JOIN returns only the order lines that have a matching order.

/* to see employee between three order ,prouct and orederitems*/
SELECT
    oi.OrderItemID,
    oi.OrderID,
    oi.ProductID,
    o.EmployeeID
FROM NileMartTraining.dbo.OrderItems AS oi
INNER JOIN NileMartTraining.dbo.Orders AS o
    ON oi.OrderID = o.OrderID;

-- Problem check: some orders have NULL in EmployeeID.
-- Total orders, orders with an employee, and orders without one.

    /* To See that Null in employee appear a problem in the data */

    SELECT
    COUNT(*) AS TotalOrders,
    COUNT(EmployeeID) AS OrdersWithEmployee,
    COUNT(*) - COUNT(EmployeeID) AS OrdersWithoutEmployee
FROM NileMartTraining.dbo.Orders;

-- Which store types have orders without an employee?
-- CASE gives each order a label ('No Employee' or 'Has Employee')
-- and then the orders are counted for each label and store type.

SELECT
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END AS EmployeeStatus,

    s.StoreType,
    COUNT(*) AS TotalOrders

FROM NileMartTraining.dbo.Orders AS o

LEFT JOIN NileMartTraining.dbo.Stores AS s
    ON o.StoreID = s.StoreID

GROUP BY
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END,
    s.StoreType

ORDER BY EmployeeStatus, s.StoreType;

-- The same check as above (it was written in the first sales file too).
-- LEFT JOIN keeps all the orders even if the store is missing.

SELECT
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END AS EmployeeStatus,

    s.StoreType,
    COUNT(*) AS TotalOrders

FROM NileMartTraining.dbo.Orders AS o

LEFT JOIN NileMartTraining.dbo.Stores AS s
    ON o.StoreID = s.StoreID

GROUP BY
    CASE
        WHEN o.EmployeeID IS NULL THEN 'No Employee'
        ELSE 'Has Employee'
    END,
    s.StoreType

ORDER BY EmployeeStatus, s.StoreType;

/*------------------------------------------------------------------------------
  7. RELATIONSHIPS BETWEEN TABLES
------------------------------------------------------------------------------*/

-- Order lines with the customer and the date of their order.
-- This shows what one row of the future FactSales table will contain.

SELECT
    oi.OrderItemID,
    oi.ProductID,
    o.CustomerID,
    o.OrderDate
FROM dbo.OrderItems AS oi
JOIN dbo.Orders AS o
    ON oi.OrderID = o.OrderID;

-- The full path of a customer: Customer -> Orders -> Order items -> Returns.
-- LEFT JOIN is used so that customers without orders, and order lines without returns, still appear.

USE NileMartTraining;
GO

SELECT
    c.CustomerID,
    o.OrderID,
    o.OrderDate,
    o.OrderStatus,
    oi.OrderItemID,
    oi.ProductID,
    oi.Quantity,
    r.ReturnID,
    r.ReturnDate
FROM dbo.Customers AS c
LEFT JOIN dbo.Orders AS o
    ON c.CustomerID = o.CustomerID
LEFT JOIN dbo.OrderItems AS oi
    ON o.OrderID = oi.OrderID
LEFT JOIN dbo.Returns AS r
    ON oi.OrderItemID = r.OrderItemID
ORDER BY
    c.CustomerID,
    o.OrderID,
    oi.OrderItemID,
    r.ReturnDate;
