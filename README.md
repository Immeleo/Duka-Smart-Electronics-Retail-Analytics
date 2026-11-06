# Duka Smart Electronics — Retail Analytics with SQL

## 1. Project Story & Overview

**Duka Smart Electronics** is a growing Kenyan retailer selling mobile phones, computing devices, accessories, TVs, and home appliances across ten major towns—including Nairobi, Mombasa, Nakuru, Meru, and Machakos. 

Trading since January 2025, the business has accumulated substantial sales and customer data. This SQL database serves as a comprehensive SQL analysis tool to answer key executive questions:
* *Who are our best customers?*
* *Which product categories actually drive profit?*
* *How is revenue growing month-over-month?*
* *Which customers are at risk of churning?*

The dataset consists of **150 customers** and **800 order transactions** evaluated using **PostgreSQL** across 46 distinct SQL analytical queries.

---

## 2. Business Rules & Logic

To maintain analytical consistency, all queries strictly adhere to the following business rules:

| Metric / Rule | Definition / Formula |
| :--- | :--- |
| **Revenue** | `quantity * unit_price * (1 - discount / 100)` |
| **Cost** | `quantity * cost_price` |
| **Profit** | `revenue - cost` |
| **Profit Margin %** | `(profit / NULLIF(revenue, 0)) * 100` |
| **Monetary Questions** | Evaluates **`order_status = 'Completed'`** only (excludes Pending/Cancelled orders). |
| **Order Volumes** | Counts all orders regardless of status (`Completed`, `Pending`, `Cancelled`). |
| **Customer Counts** | Always uses `COUNT(DISTINCT customer_id)`. |
| **Reference "Today"** | Evaluated dynamically against `SELECT MAX(order_date) FROM orders`. |
| **Monthly Grouping** | Evaluated by distinct year and month using `DATE_TRUNC('month', order_date)` or `TO_CHAR(order_date, 'YYYY-MM')`. |
| **Currency Rounding** | Rounded to 2 decimal places (`ROUND(..., 2)`). |

---

## 3. Database Setup Instructions

### Prerequisites
* **PostgreSQL** (v12 or higher)
* A database client such as **pgAdmin 4**, **DBeaver**, or the **psql CLI**

### Setup Steps

1. **Create Database:**
   Connect to your local PostgreSQL server and create the target database:
   ```sql
   CREATE DATABASE retail_analytics;
   ```

2. **Connect to Database:**
   Switch your workspace or CLI connection to `retail_analytics`.

3. **Initialize Schema & Data:**
   Run `schema.sql` (or your initial database script) to set up:
   * **`customers` table** (150 rows with demographics, cities, and segments)
   * **`orders` table** (800 transaction records)
   * Performance indexes (`idx_orders_customer`, `idx_orders_date`)

---

## 4. Running the Queries

The project queries are organized into 6 progressive sections in `queries.sql`:

* **Section A — SQL Fundamentals (Q1–Q10):** Basic data extraction using `SELECT`, `WHERE`, `DISTINCT`, `ORDER BY`, `LIKE`, and `BETWEEN`.
* **Section B — Aggregations & Grouping (Q11–Q20):** Summary metrics using `COUNT`, `SUM`, `AVG`, `MIN`, `MAX`, `GROUP BY`, and `HAVING`.
* **Section C — Joins & Customer Analytics (Q21–Q28):** Multi-table queries with `INNER JOIN` and `LEFT JOIN` analyzing customer spending and preferences.
* **Section D — Subqueries & CTEs (Q29–Q34):** Complex multi-stage analysis using Common Table Expressions (`WITH`), including 90-day churn detection.
* **Section E — Window Functions (Q35–Q42):** Advanced ranking and time-series analysis using `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `LAG()`, and `NTILE()`.
* **Section F — Advanced Business Intelligence (Q43–Q46):** Enterprise tools including database views (`monthly_sales_summary`), custom PL/pgSQL functions (`get_customer_revenue`), customer RFM value segmentation, and executive summary reports.

### Executing Queries via CLI
**Execution Options**
1. Via Command Line (psql CLI)
Run the script directly from your terminal:
```
psql -d retail_analytics -U your_username -f queries.sql

```
2. Via GUI Clients (Windows)
**pgAdmin 4:**
Open queries.sql in the Query Tool window.
- Highlight/select the specific query block you want to execute.
- Click the Execute/Run button (or press F5).

**DBeaver:**
Open queries.sql in the SQL Editor.
- Highlight the query block and click the Execute SQL Statement button, OR
- Place your cursor anywhere inside or at the end of the query and press CTRL + Enter (on Windows).