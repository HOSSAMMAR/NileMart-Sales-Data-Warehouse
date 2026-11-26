# NileMart Sales Data Warehouse (SQL Server + SSIS)

A SQL Server practice project on a retail training database called **NileMart**.
I explored and cleaned the data, analyzed sales with SQL, built a **star-schema data warehouse**, and then built an **SSIS ETL package** that loads the warehouse through staging tables. I checked the result against the source data.

> This is a practice project built on a training database.

## Skills used

SQL Server · T-SQL · SSIS (ETL) · Visual Studio · JOINs · CTEs · Window functions · Views · Transactions · Data cleaning · Data modeling (star schema) · Data validation

## Project flow

```
NileMartTraining (source)  ->  SSIS package  ->  Stg_ tables (staging)  ->  Dim / Fact tables (NileMartDW)
```

## Repository structure

```
sql/
  01_Data_Exploration.sql
  02_Data_Cleaning.sql
  03_Sales_Analysis.sql
  04_DW_Build.sql
  05_DW_Validation.sql
  06_Build_Staging_Tables.sql
  07_Load_DimCategory.sql
ssis/
  NileMartETL.sln
  Integration Services Project1/     (Package.dtsx, project file, parameters)
docs/
  08_SSIS_ETL_Guide.md
  NileMart_SSIS_ETL_Field_Guide.pdf
README.md
```

## Project files

Run the SQL files in this order:

| # | File | What it does |
|---|------|--------------|
| 1 | `01_Data_Exploration.sql` | Looks at the tables, columns, row counts and data-quality problems (NULL values, orders without an employee). Read-only. |
| 2 | `02_Data_Cleaning.sql` | Replaces NULL values, fixes product and supplier names, and finds duplicate customers. |
| 3 | `03_Sales_Analysis.sql` | Sales by store and by year (Completed orders only) and a reusable view for product sales. |
| 4 | `04_DW_Build.sql` | Builds the warehouse `NileMartDW`: dimension tables, the fact table, primary keys and foreign keys. |
| 5 | `05_DW_Validation.sql` | Checks that the warehouse is complete, that its sales total matches the source, and that the relationships are correct. |
| 6 | `06_Build_Staging_Tables.sql` | Creates the `Stg_` staging tables for the ETL, and has the checks used to compare structures, counts and totals. |
| 7 | `07_Load_DimCategory.sql` | Moves categories from `Stg_DimCategory` into `DimCategory`, inserting only new rows. |

## ETL with SSIS

The package `Package.dtsx` has **8 chains**: Category, Product, Customer, Store, PaymentMethod, Employee, Date and FactSales. Every chain follows the same three steps:

| Step | Task | What it does |
|------|------|--------------|
| 1 | `SQL_Clear_Stg_...` (Execute SQL Task) | Empties the staging table with `TRUNCATE TABLE` |
| 2 | `DFT_Load_...` (Data Flow Task) | Copies rows from `NileMartTraining` into the staging table (OLE DB Source -> OLE DB Destination) |
| 3 | `SQL_Load_...` (Execute SQL Task) | Loads the final warehouse table from staging |

How the loads work:

- **Dimensions** use `WHERE NOT EXISTS`, so a row is inserted only when it is not already in the dimension. Running the package again does not create duplicates.
- **FactSales** is a full refresh: `TRUNCATE` and `INSERT` inside one transaction (`TRY/CATCH`, `XACT_ABORT ON`). If an error happens, it rolls back.
- **Business rules:** only `Completed` orders are loaded, and one fact row is one order line. The `DateKey` and `EmployeeKey` are found with joins to `DimDate` and `DimEmployee`. An order without an employee keeps `NULL` in `EmployeeKey`.

Task-by-task explanation, with every SQL statement of the package: [`docs/08_SSIS_ETL_Guide.md`](docs/08_SSIS_ETL_Guide.md).
A longer learning reference (business rules, troubleshooting log, validation queries): [`docs/NileMart_SSIS_ETL_Field_Guide.pdf`](docs/NileMart_SSIS_ETL_Field_Guide.pdf).

## Data warehouse design (star schema)

**Fact table**

- `FactSales`: one row for each order line of a Completed order. It stores `Quantity` and `LineTotal`.

**Dimension tables**

- `DimDate`
- `DimProduct`
- `DimCategory` (reached through `DimProduct`, with a parent/child hierarchy)
- `DimCustomer`
- `DimStore`
- `DimPaymentMethod`
- `DimEmployee`

`FactSales` points to the dimensions through foreign keys.

## Validated results

From the validation queries (see the field guide):

| Check | Result |
|-------|--------|
| Completed order lines loaded | 27,635 |
| Total quantity sold | 52,018 |
| Total sales | 21,819,798.89 |
| Unique `OrderItemID` in `FactSales` | 27,635 |
| Orders without an employee (`EmployeeKey` is NULL) | 12,281 |
| Rows in `DimDate` | 1,446 (2022-01-16 to 2025-12-31) |
| Orphan keys for the required dimensions | 0 |

## How to run

1. Open SQL Server Management Studio (SSMS).
2. Make sure the source database `NileMartTraining` exists.
3. Run files `01` to `05` in order. (`04_DW_Build.sql` is written step by step and some steps were changed later; read the comments and run it step by step.)
4. Run `06_Build_Staging_Tables.sql` to create the staging tables.
5. Open `ssis/NileMartETL.sln` in Visual Studio (with SQL Server Integration Services installed), set the two connections to your server, and run the package.
6. Run the checks from `05` and `06` to confirm the data.

## Known limits and next steps

- **Dimensions are insert-only.** Changed rows in the source are not updated in the warehouse.
- **Incremental loading is not built yet.** The package reloads everything.
- **Load order.** The 8 chains run in parallel. `FactSales` needs `DimDate` and `DimEmployee` loaded first, so a precedence constraint should be added.
- **Returns** are not subtracted from sales, and there is no `FactReturns` table yet.
- **Power BI report** on top of the warehouse is the next step.

## Author

Hossam Abdelaziz Ammar
[LinkedIn](https://linkedin.com/in/hossam-abdelazizammar)
