<div align="center">

# 🚚 MySQL Supply Chain & Logistics Analysis

### An End-to-End SQL Analytics Project — From Raw Data to Business Intelligence

[![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![SQL Queries](https://img.shields.io/badge/SQL_Queries-178-orange?style=for-the-badge)](#-repository-structure)
[![Tables](https://img.shields.io/badge/Tables-10-blue?style=for-the-badge)](#-database-schema)
[![Chapters](https://img.shields.io/badge/Analysis_Chapters-9-success?style=for-the-badge)](#-analysis-chapters)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

*A production-style relational dataset analyzed through 178 progressively complex SQL queries — covering data validation, profiling, customer, product, sales, inventory, supplier, warehouse, and logistics performance analysis.*

</div>

---

## 📌 About This Project

This project simulates a **real-world enterprise supply chain and logistics operation** — customers placing orders, products flowing from suppliers into warehouses, inventory being tracked, and shipments being delivered by carriers — and analyzes it end-to-end using pure **MySQL**.

Rather than a handful of disconnected queries, this is structured as **9 sequential analytical chapters**, each one building on the last: starting with validating the data can be trusted, profiling what it actually contains, and then progressively answering real supply chain business questions around customers, products, sales, inventory, suppliers, warehouses, and shipping logistics.

**Every query is written, commented, and organized like a real analyst would deliver it to a business stakeholder** — not just "get the answer," but structure it, rank it, segment it, and classify it into something decision-ready.

---

## ✨ Highlights

| | |
|---|---|
| 🧮 **178 SQL Queries** | Organized into 9 progressively advanced analytical chapters |
| 🗃️ **10 Relational Tables** | A fully normalized, real-world-style supply chain schema |
| 📊 **9 Analysis Chapters** | From data validation → profiling → customer/product/sales → inventory/supplier/warehouse → logistics |
| 🧠 **Advanced SQL Techniques** | CTEs, Window Functions, Subqueries, Pareto Analysis, RFM-style Segmentation, Rankings |
| 📈 **Large-Scale Dataset** | Enterprise-grade volume across orders, shipments, and inventory transactions |
| 📝 **Fully Documented** | Every chapter ends with a structured business summary of objectives, coverage, and outcomes |

---

## 🗂️ Repository Structure

```
MySQL-Supply-Chain-And-Logistics-Analysis/
│
├── MySQL_Supply_Chain_&_Logistics_Analysis_Project/
│   ├── 01_Data_Validation.sql              # 25 queries — data integrity & sanity checks
│   ├── 02_Data_Profiling.sql               # 46 queries — dataset structure & distributions
│   ├── 03_Customer_Analysis.sql            # 33 queries — customer behavior & value
│   ├── 04_Product_Analysis.sql             # 12 queries — product performance & profitability
│   ├── 05_Sales_Order_Analysis.sql         # 14 queries — sales trends & order economics
│   ├── 06_Inventory_Analysis.sql           # 11 queries — stock health & turnover
│   ├── 07_Supplier_Analysis.sql            # 11 queries — supplier dependency & performance
│   ├── 08_Warehouse_Analysis.sql           # 13 queries — network capacity & efficiency
│   └── 09_Shipment_Logistics_Analysis.sql  # 13 queries — carrier performance & SLA analysis
│
├── Supply_chain_database/                  # Database schema & table creation scripts
├── supply_chain_dataset/                   # Raw source data
├── LICENSE                                 # MIT License
└── README.md
```

---

## 🗃️ Database Schema

The database (`supply_chain_analytics`) consists of **10 interconnected tables**, split across master data, relationship/bridge tables, and transactional data:

| Table | Type | Description |
|---|---|---|
| `customers` | Master | Customer master data — industry, region, segment, signup date |
| `products` | Master | Product catalog — category, brand, cost, price, weight, reorder level |
| `suppliers` | Master | Supplier master data — region, supplier type |
| `warehouses` | Master | Warehouse network — location, type, capacity, operating cost |
| `supplier_products` | Bridge | Supplier ↔ Product relationships, unit cost, lead time |
| `warehouse_products` | Bridge | Warehouse ↔ Product relationships, initial stock, storage cost |
| `orders` | Transactional | Customer orders — status, date, fulfilling warehouse |
| `order_items` | Transactional | Line-item level order detail — quantity, unit price |
| `shipments` | Transactional | Shipment records — carrier, cost, distance, delivery dates |
| `inventory_transactions` | Transactional | Inbound/outbound stock movement history |

<details>
<summary><b>📐 View simplified relationship overview</b></summary>

```
customers ──< orders ──< order_items >── products
                │                           │
                ∨                           ∨
            shipments              supplier_products >── suppliers
                                           │
                                           ∨
warehouses ──< warehouse_products ────────┘
    │
    └──< inventory_transactions >── products
```

</details>

---

## 📊 Analysis Chapters

Each chapter is a self-contained `.sql` file with numbered, commented queries and a closing business summary block.

### Chapter 1 — Data Validation `25 queries`
Confirms the dataset is trustworthy before any analysis begins: table/row-count checks, primary key uniqueness, NULL checks on required fields, referential integrity across all 10 tables, invalid numeric values (negative costs/prices), and chronological sanity checks (shipments can't precede orders, deliveries can't precede shipments).

### Chapter 2 — Data Profiling `46 queries`
Builds a full statistical and structural picture of the dataset — product category/brand distributions, pricing statistics, customer segmentation by industry/region, supplier and warehouse coverage, order-value distributions, inventory movement patterns, and shipment/carrier distributions.

### Chapter 3 — Customer Analysis `33 queries`
Deep dive into customer behavior: order frequency, spending patterns, product purchase behavior, segment-level performance, revenue concentration (deciles + cumulative contribution), and a **customer value classification** (High/Low Value × High/Low Frequency) using median-based segmentation.

### Chapter 4 — Product Analysis `12 queries`
Revenue ranking, gross margin & profitability, Pareto-style revenue concentration, demand consistency, pricing/markup analysis, product lifecycle status, and a composite **product performance classification** (High Performer / High Revenue-Low Margin / High Margin-Low Demand / Low Performer).

### Chapter 5 — Sales & Order Analysis `14 queries`
Sales KPIs, order-value statistics (median, quartiles, IQR), month-over-month growth via `LAG()`, order-size segmentation (Small/Medium/Large), high-value order concentration (Top 1/5/10/25%), repeat vs. one-time customer economics, and a **period-level sales performance classification** (Excellent/Strong/Average/Weak).

### Chapter 6 — Inventory Analysis `11 queries`
Stock position, inventory value & storage cost, stock utilization %, low-stock/reorder risk tiers (Out of Stock → Adequate), warehouse inventory concentration, inventory turnover ratio, and a final **inventory health classification** (High Demand / Slow Moving / Healthy).

### Chapter 7 — Supplier Analysis `11 queries`
Supplier product coverage, procurement value & contribution, warehouse reach, single- vs. multi-supplier dependency risk, cost-vs-demand efficiency, and full **supplier portfolio performance** combining inventory exposure, units sold, and revenue.

### Chapter 8 — Warehouse Analysis `13 queries`
Network-wide KPIs across geography, warehouse type, capacity tiers, operating cost tiers, cost efficiency (capacity-per-dollar), facility age, order workload, fulfillment completion rate, and a composite **warehouse performance classification** (Strong/Average/Weak) blending revenue, cost-efficiency, and capacity utilization.

### Chapter 9 — Shipment & Logistics Analysis `13 queries`
Shipment KPIs, delivery-time analysis, on-time delivery rate, delay-severity tiers (Minor/Moderate/Severe), carrier performance & reliability ranking, cost-per-km efficiency, distance-vs-cost tiering, monthly shipment trend, and a final **carrier performance classification** (Excellent/Strong/Average/Weak) built on SLA %, delay days, and freight cost efficiency.

---

## 🧠 SQL Techniques Demonstrated

- **Common Table Expressions (CTEs)** — including multi-layered, chained CTEs for readable, modular logic
- **Window Functions** — `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `NTILE()`, `LAG()`, cumulative `SUM() OVER()`
- **Pareto / Revenue Concentration Analysis** — cumulative contribution across products, customers, and segments
- **RFM-style Customer & Product Segmentation** — median-based value/frequency classification
- **Conditional Aggregation** — `CASE WHEN` inside `SUM()`/`COUNT()` for pivot-style summaries
- **Multi-table JOINs** across up to 4–5 tables per query
- **Subqueries & Derived Tables** for layered, step-by-step calculations
- **Referential Integrity Auditing** via `LEFT JOIN ... WHERE NULL` orphan-record checks
- **Business Rule Classification Logic** — turning raw metrics into decision-ready tiers (e.g., Fast/Slow Moving, Excellent/Weak performance)

---

## 🔍 Example Query

**Chapter 4, Query 111 — Product Revenue Concentration (Pareto Analysis)**

```sql
WITH total_revenue AS (
    SELECT SUM(Quantity * UnitPrice) AS total_revenue
    FROM order_items
),
contribution AS (
    SELECT
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
        ProductID, ProductName, revenue, revenue_contribution,
        SUM(revenue_contribution) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_contribution
    FROM (
        SELECT
            p.ProductID, p.ProductName,
            SUM(oi.Quantity * oi.UnitPrice) AS revenue,
            ROUND(SUM(oi.Quantity * oi.UnitPrice)
                / (SELECT total_revenue FROM total_revenue) * 100, 2) AS revenue_contribution
        FROM order_items oi
        JOIN products p ON oi.ProductID = p.ProductID
        GROUP BY p.ProductID, p.ProductName
    ) AS DT
)
SELECT * FROM contribution;
```
> Identifies which products drive the bulk of revenue — the SQL equivalent of an 80/20 Pareto chart, built entirely with window functions.

---

## 🛠️ Tech Stack

- **Database:** MySQL 8.x
- **Tooling:** MySQL Workbench
- **Concepts:** Data Validation • Data Profiling • Business Analytics • SQL Window Functions • Data Segmentation

---

## 🚀 How to Use

1. Clone the repository
   ```bash
   git clone https://github.com/yashagrawal821/MySQL-Supply-Chain-And-Logistics-Analysis.git
   ```
2. Create the database and load the schema/data from `Supply_chain_database/` and `supply_chain_dataset/`
3. Run the chapters **in order (01 → 09)** inside `MySQL_Supply_Chain_&_Logistics_Analysis_Project/` — later chapters assume earlier validation/profiling context
4. Explore each `.sql` file — every query is numbered and commented, with a business summary at the end of each chapter

---

## 👤 Author

**Yash Agrawal**
📍 Moradabad, Uttar Pradesh
📧 yashsinghal821866@gmail.com
🔗 [LinkedIn](https://www.linkedin.com/in/yashsite) • [GitHub](https://github.com/yashagrawal821)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

<div align="center">

⭐ **If you found this project useful, consider giving it a star!** ⭐

</div>
