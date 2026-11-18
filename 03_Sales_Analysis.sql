/*==============================================================================
  NileMart project - File 03 : Sales Analysis
  Database : NileMartTraining

  What is this file?
    It answers business questions about sales.
    Here ONLY Completed orders are counted (cancelled and processing are ignored).

  Sections
    1. Sales by store
    2. Sales by year
    3. A saved report (VIEW) of product sales
==============================================================================*/

USE NileMartTraining;
GO

/*------------------------------------------------------------------------------
  1. SALES BY STORE
------------------------------------------------------------------------------*/

-- Number of orders and total sales for each store, highest sales first.
-- COUNT(DISTINCT OrderID) is used because one order can have many lines.

SELECT
    s.StoreName,
    COUNT(DISTINCT o.OrderID) AS NumberOfOrders,
    SUM(oi.LineTotal) AS TotalSales
FROM dbo.Orders o
JOIN dbo.OrderItems oi
    ON o.OrderID = oi.OrderID
JOIN dbo.Stores s
    ON o.StoreID = s.StoreID
WHERE o.OrderStatus = 'Completed'
GROUP BY s.StoreName
ORDER BY TotalSales DESC;
/*sales by stores High is NileMartOnline*/

/*------------------------------------------------------------------------------
  2. SALES BY YEAR
------------------------------------------------------------------------------*/

-- Total sales for each year, newest year first.
-- YEAR(date) takes the year from the order date.

Select 
Year(o.OrderDate) As SalesYear,
Sum(oi.LineTotal) As TotalSales
From dbo.Orders o
join dbo.OrderItems oi
on o.OrderID = oi.OrderID
Where o.OrderStatus ='Completed'
Group by Year(o.OrderDate)
Order by  SalesYear Desc;
/*Sales by year high in 2025*/

/*------------------------------------------------------------------------------
  3. PRODUCT SALES REPORT (VIEW)
------------------------------------------------------------------------------*/

-- A VIEW is a saved query. After creating it you can read it like a table:
-- SELECT * FROM dbo.vw_ProductSalesReport;
-- It shows for each product: category, units sold, total sales and average selling price.
-- GO is needed before CREATE VIEW because CREATE VIEW must be the first statement of its batch.

GO

CREATE VIEW dbo.vw_ProductSalesReport
AS
SELECT
    p.ProductID,
    p.ProductName,
    c.CategoryName,
    SUM(oi.Quantity) AS UnitsSold,
    SUM(oi.LineTotal) AS TotalSales,
    AVG(oi.UnitPrice) AS AverageSellingPrice
FROM dbo.OrderItems oi
JOIN dbo.Products p
    ON oi.ProductID = p.ProductID
JOIN dbo.Categories c
    ON p.CategoryID = c.CategoryID
JOIN dbo.Orders o
    ON oi.OrderID = o.OrderID
WHERE o.OrderStatus = 'Completed'
GROUP BY
    p.ProductID,
    p.ProductName,
    c.CategoryName;
