use NileMartDW
Go

INSERT INTO dbo.DimCategory
(
    CategoryID,
    CategoryName,
    ParentCategoryID
)
SELECT
    s.CategoryID,
    s.CategoryName,
    s.ParentCategoryID
FROM dbo.Stg_DimCategory AS s
WHERE NOT EXISTS
(
    SELECT *
    FROM dbo.DimCategory AS d
    WHERE d.CategoryID = s.CategoryID
);

SELECT COUNT(*) AS TotalCategories
FROM dbo.DimCategory;