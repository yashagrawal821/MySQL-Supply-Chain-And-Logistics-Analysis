
-- Query 105: Products Performance Overview
SELECT 
	COUNT(DISTINCT ProductID) AS total_products, 
    SUM(CASE WHEN DiscontinuedFlag = 0 THEN 1 ELSE 0 END) as active_products,
    SUM(CASE WHEN DiscontinuedFlag = 1 THEN 1 ELSE 0 END) as discontinued_products,
    COUNT(DISTINCT Category) AS categories,
    COUNT(DISTINCT SubCategory) AS subcategories,
    COUNT(DISTINCT Brand) AS brands
    
FROM products;


-- Query 106: Product revennue ranking
WITH product_revenue_rank AS (
SELECT
    ProductID, ProductName, revenue, RANK() OVER( ORDER BY revenue DESC) as revenue_rank
FROM(
    SELECT p.ProductID, p.ProductName, SUM(oi.Quantity * oi.UnitPrice) as revenue
    FROM order_items oi JOIN products p
    ON oi.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName
    ) as DT
)

SELECT *
FROM product_revenue_rank;


-- Query 107: Product Sales Volume vs Revenue
WITH product_revenue_units AS (
SELECT p.ProductID, p.ProductName, SUM(oi.Quantity) as units_sold, SUM(oi.Quantity * oi.UnitPrice) as revenue
FROM order_items oi JOIN products p
ON oi.ProductID = p.ProductID
GROUP BY p.ProductID
)

SELECT *
FROM product_revenue_units
ORDER BY revenue DESC;


-- Query 108: Profitability analysis
WITH profitability AS (
SELECT 
	p.ProductID, 
	p.ProductName, 
	SUM(oi.Quantity) as units_sold, 
	SUM(oi.Quantity * oi.UnitPrice) as revenue,
	SUM(oi.Quantity * p.UnitCost) as cost,
	( SUM(oi.Quantity * oi.UnitPrice) - SUM(oi.Quantity * p.UnitCost) ) as gross_profit,
	ROUND(( ( SUM(oi.Quantity * oi.UnitPrice) - SUM(oi.Quantity * p.UnitCost) ) / SUM(oi.Quantity * oi.UnitPrice) * 100 ),2) as gross_margin
FROM order_items oi JOIN products p
ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
)

SELECT *
FROM profitability
ORDER BY revenue DESC;


-- Query 109: Category performance analysis
WITH profitability AS (
SELECT 
	Category, 
	SUM(oi.Quantity) as units_sold, 
	SUM(oi.Quantity * oi.UnitPrice) as revenue,
	SUM(oi.Quantity * p.UnitCost) as cost,
	( SUM(oi.Quantity * oi.UnitPrice) - SUM(oi.Quantity * p.UnitCost) ) as gross_profit,
	ROUND(( ( SUM(oi.Quantity * oi.UnitPrice) - SUM(oi.Quantity * p.UnitCost) ) / SUM(oi.Quantity * oi.UnitPrice) * 100 ),2) as gross_margin
FROM order_items oi JOIN products p
ON oi.ProductID = p.ProductID
GROUP BY category
)

SELECT *
FROM profitability
ORDER BY revenue DESC;


-- Query 110: Product contribution to total revenue
WITH total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items
),

contribution AS (
SELECT 
	p.ProductID, 
    p.ProductName,
	SUM(oi.Quantity * oi.UnitPrice) as revenue,
    ROUND(( SUM(oi.Quantity * oi.UnitPrice) / (SELECT total_revenue from total_revenue) *100),2) as revenue_contribution
FROM order_items oi JOIN products p
ON oi.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
)

SELECT *
FROM contribution
ORDER BY revenue DESC;


-- Query 111: Product Revenue Concentration / Pareto Analysis
WITH total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items
),

contribution AS (
SELECT 
	RANK() OVER(ORDER BY revenue DESC) as revenue_rank, 
    ProductID, 
    ProductName, 
    revenue, 
    revenue_contribution, 
    SUM(revenue_contribution) OVER( ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW ) as cumulative_contribution
FROM(
	SELECT 
		p.ProductID, 
		p.ProductName,
		SUM(oi.Quantity * oi.UnitPrice) as revenue,
		ROUND(( SUM(oi.Quantity * oi.UnitPrice) / (SELECT total_revenue from total_revenue) *100),2) as revenue_contribution
	FROM order_items oi JOIN products p
	ON oi.ProductID = p.ProductID
	GROUP BY p.ProductID, p.ProductName ) AS DT
)

SELECT *
FROM contribution;


-- Query 112: Product Demand Consistency
SELECT
	p.ProductID,
    p.ProductName,
    COUNT(DISTINCT oi.OrderID) as order_count,
    SUM(oi.Quantity) as units_sold,
    ROUND(( SUM(oi.Quantity) / COUNT(DISTINCT oi.OrderID) ),2) as Avg_units_per_order,
    MAX(oi.Quantity) as Max_units_in_a_single_order    
FROM products p 
JOIN order_items oi
	ON p.ProductID = oi.ProductID
GROUP BY p.ProductID, p.ProductName;


-- Query 113: Product pricing and markup analysis
SELECT 
	ProductID,
    ProductName,
    UnitCost,
    UnitPrice,
    (UnitPrice - UnitCost) as markup,
    ROUND(((UnitPrice - UnitCost) / UnitCost *100),2) as markup_percentage
FROM products;


-- Query 114: Product Lifecycle Analysis
SELECT 
	p.ProductID,
    p.ProductName,
    CASE
		WHEN DiscontinuedFlag = 1 THEN 'Discontinued'
        WHEN DiscontinuedFlag = 0 THEN 'Active'
        END as status,
    SUM(oi.Quantity) as units_sold,
    sum(oi.Quantity * oi.UnitPrice) as revenue,
    ( sum(oi.Quantity * oi.UnitPrice) - sum(oi.Quantity * p.UnitCost) )as gross_profit
FROM products p 
LEFT JOIN order_items oi
	ON p.ProductId = oi.ProductID
GROUP BY p.ProductID, p.ProductName;


-- Query 115: Product inventory performance
WITH product_stock AS (
    SELECT
        ProductID,
        SUM(InitialStock) AS initial_stock
    FROM warehouse_products
    GROUP BY ProductID
),

product_demand AS (
    SELECT
        p.ProductID,
        p.ProductName,
        ps.initial_stock,
        COALESCE(SUM(oi.Quantity), 0) AS units_sold
    FROM products p
    LEFT JOIN product_stock ps
        ON p.ProductID = ps.ProductID
    LEFT JOIN order_items oi
        ON p.ProductID = oi.ProductID
    GROUP BY
        p.ProductID,
        p.ProductName,
        ps.initial_stock
)

SELECT
    ProductID,
    ProductName,
    initial_stock,
    units_sold,
    ROUND(
        units_sold / NULLIF(initial_stock, 0),
        2
    ) AS demand_ratio,
    CASE
        WHEN units_sold / NULLIF(initial_stock, 0) >= 3
            THEN 'High Demand / Low Stock'
        WHEN units_sold / NULLIF(initial_stock, 0) >= 1
            THEN 'High Demand / Adequate Stock'
        WHEN units_sold / NULLIF(initial_stock, 0) < 0.25
            THEN 'Low Demand / Overstocked'
        ELSE 'Normal Demand / Stock'
    END AS inventory_status
FROM product_demand;


-- Query 116 : Product performance classification
WITH product_stock AS (
    SELECT
        ProductID,
        SUM(InitialStock) AS initial_stock
    FROM warehouse_products
    GROUP BY ProductID
),

median_revenue AS (
    SELECT 100000 AS median_revenue
),

product_sales AS (
    SELECT
        p.ProductID,
        p.ProductName,
        SUM(oi.Quantity * oi.UnitPrice) AS revenue,
        SUM(oi.Quantity * p.UnitCost) AS cost,
        SUM(oi.Quantity) AS units_sold
    FROM products p
    LEFT JOIN order_items oi
        ON p.ProductID = oi.ProductID
    GROUP BY p.ProductID, p.ProductName
),

product_analysis AS (
    SELECT
        ps.ProductID,
        ps.ProductName,
        ps.revenue,
        ps.units_sold,
        ROUND(
            (ps.revenue - ps.cost) / NULLIF(ps.revenue, 0) * 100,
            2
        ) AS gross_margin,
        ROUND(
            ps.units_sold / NULLIF(st.initial_stock, 0),
            2
        ) AS demand_ratio
    FROM product_sales ps
    LEFT JOIN product_stock st
        ON ps.ProductID = st.ProductID
)

SELECT
    *,
    CASE
        WHEN gross_margin >= 40
             AND revenue >= (SELECT median_revenue FROM median_revenue)
             AND demand_ratio >= 1
            THEN 'High Performer'

        WHEN revenue >= (SELECT median_revenue FROM median_revenue)
             AND gross_margin < 40
            THEN 'High Revenue / Low Margin'

        WHEN gross_margin >= 40
             AND demand_ratio < 1
            THEN 'High Margin / Low Demand'

        ELSE 'Low Performer'
    END AS product_classification
FROM product_analysis;




/* ============================================================
   CHAPTER 4 SUMMARY — PRODUCT ANALYSIS
   ============================================================

   OBJECTIVE:
   Analyze product-level sales, revenue, profitability, pricing,
   demand, inventory utilization, lifecycle status, and overall
   product performance to identify high-value products, demand
   patterns, revenue concentration, and potential inventory or
   profitability concerns.

   KEY ANALYSIS AREAS COVERED:
   1. Product portfolio overview
      - Total, active, and discontinued products
      - Categories, subcategories, and brands

   2. Product sales performance
      - Product revenue ranking
      - Units sold versus revenue
      - Product and category-level sales performance

   3. Product profitability
      - Revenue, cost, gross profit, and gross margin
      - Category-level profitability comparison

   4. Revenue contribution and concentration
      - Individual product contribution to total revenue
      - Pareto-style cumulative revenue concentration

   5. Product demand analysis
      - Order frequency and units sold
      - Average units per order
      - Maximum quantity sold in a single order

   6. Product pricing and markup
      - Unit cost versus selling price
      - Absolute markup and markup percentage

   7. Product lifecycle analysis
      - Active versus discontinued products
      - Sales, revenue, and gross profit by lifecycle status

   8. Product inventory performance
      - Initial stock versus units sold
      - Demand ratio
      - Identification of high-demand/low-stock and
        low-demand/overstocked products

   9. Product performance classification
      - Combined revenue, gross margin, and demand analysis
      - Classification into High Performer, High Revenue /
        Low Margin, High Margin / Low Demand, and Low Performer

   OUTCOME:
   This chapter establishes a comprehensive view of product
   performance by connecting sales, profitability, pricing,
   demand, and inventory indicators. It helps identify the
   products and categories driving revenue and profit, products
   with concentrated demand, pricing opportunities, inventory
   risks, and products requiring further business attention.

   ============================================================ */