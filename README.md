# NileMart Sales Data Warehouse (SQL Server)

A SQL Server practice project on a retail training database called **NileMart**.
I explored and cleaned the data, analyzed sales with SQL, and built a **star-schema data warehouse** with dimension and fact tables. Then I checked the warehouse against the source data.

> This is a practice project built on a training database.

## Skills used

SQL Server · T-SQL · JOINs · CTEs · Window functions · Views · Data cleaning · Data modeling (star schema)

## Project files

Run the files in this order:

| # | File | What it does |
|---|------|--------------|
| 1 | `01_Data_Exploration.sql` | Looks at the tables, columns, row counts and data-quality problems (NULL values, orders without an employee). Read-only. |
| 2 | `02_Data_Cleaning.sql` | Replaces NULL values, fixes product and supplier names, and finds duplicate customers. |
| 3 | `03_Sales_Analysis.sql` | Sales by store and by year (Completed orders only) and a reusable view for product sales. |
| 4 | `04_DW_Build.sql` | Builds the warehouse `NileMartDW`: 6 dimension tables, 1 fact table, primary keys and foreign keys. |
| 5 | `05_DW_Validation.sql` | Checks that the warehouse is complete, that its sales total matches the source, and that the relationships are correct. |

## Data warehouse design (star schema)

**Fact table**

- `FactSales`: one row for each order line of a Completed order. It stores `Quantity` and `LineTotal`.

**Dimension tables**

- `DimDate`
- `DimProduct`
- `DimCustomer`
- `DimStore`
- `DimPaymentMethod`
- `DimEmployee`

`FactSales` points to every dimension through foreign keys.

## What I did in each step

- **Exploration:** checked the table structure, counted rows, looked at order statuses, price range, and found missing values.
- **Cleaning:** used `COALESCE` for NULL values, `CHARINDEX` / `LEFT` / `RTRIM` to clean names, and `COUNT(*) OVER (PARTITION BY ...)` to find duplicates.
- **Analysis:** used JOINs, `GROUP BY`, `COUNT(DISTINCT ...)` and a `VIEW`.
- **Warehouse:** created the tables, generated the date dimension with a recursive CTE, and loaded the data from the source database.
- **Validation:** compared the total sales in the warehouse with the total sales in the source database.

## How to run

1. Open SQL Server Management Studio (SSMS).
2. Make sure the source database `NileMartTraining` exists.
3. Run the files in order, from `01` to `05`.

Note: `04_DW_Build.sql` is written step by step, and some steps were changed later (the comments explain which). Run it step by step and read the comments.

## Next step

- Build an ETL process with SSIS (in progress).

## Author

Hossam Abdelaziz Ammar
[LinkedIn](https://linkedin.com/in/hossam-abdelaziz-ammar)
