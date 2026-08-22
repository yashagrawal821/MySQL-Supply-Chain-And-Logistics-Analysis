
--Query 131: Inventory Overview KPIs
WITH inventory_kpis AS(
SELECT 
	COUNT(DISTINCT ProductID) as total_products,
    COUNT(DISTINCT WarehouseID) as total_warehouses,
    COUNT(*) as inventory_records,
    SUM(InitialStock) as total_initial_stock,
    ROUND(AVG(InitialStock),2) as avg_initial_stock
    
FROM warehouse_products
)

SELECT *
FROM inventory_kpis;


--Query 132: Current Stock Position
SELECT 
	ProductID,
    SUM(InitialStock) as total_initial_stock,
    COUNT(DISTINCT WarehouseID) as warehouse_count,
    ROUND(AVG(InitialStock),2) as avg_initial_stock_across_warehouses
FROM warehouse_products
GROUP BY ProductID;


--Query 133: Inventory Value & Storage Cost Analysis
SELECT
	p.ProductID,
	SUM(wp.InitialStock) as total_initial_stock,
    p.UnitCost as unit_cost,
    (SUM(wp.InitialStock) * p.UnitCost) as inventory_value,
    ROUND(AVG(StorageCostPerUnit),2) as avg_storage_cost_per_unit,
    ROUND(SUM(wp.InitialStock * wp.StorageCostPerUnit),2) as total_storage_cost
FROM warehouse_products wp
JOIN products p
	ON wp.ProductID = p.ProductID
GROUP BY p.ProductID


--Query 134: stock utilization analysis
WITH updated_wp AS(
SELECT ProductID, SUM(InitialStock) as InitialStock
FROM warehouse_products
GROUP BY ProductID
),

updated_oi AS(
SELECT ProductID, SUM(Quantity) as Quantity
FROM order_items
GROUP BY ProductID
)

SELECT
	*,
    ROUND((units_sold / total_initial_stock * 100),2) as stock_utilization_pct
FROM(
	SELECT
		wp.ProductID,
		SUM(wp.InitialStock) as total_initial_stock,
		COALESCE(SUM(oi.Quantity),0) as units_sold
	FROM updated_wp wp
	LEFT JOIN updated_oi oi
		ON wp.ProductID = oi.ProductID
	GROUP BY wp.ProductID
) as DT;


--Query 135: Low Stock / Reorder Risk Analysis
WITH updated_wp AS(
SELECT ProductID, SUM(InitialStock) as InitialStock
FROM warehouse_products
GROUP BY ProductID
),

updated_oi AS(
SELECT ProductID, SUM(Quantity) as Quantity
FROM order_items
GROUP BY ProductID
),

remaining_stock AS(
SELECT
	*,
    ROUND((remaining_stock / InitialStock * 100),2) as stock_remaining_pct
FROM(
	SELECT
		wp.ProductID,
		wp.InitialStock,
		oi.Quantity as units_sold,
        (wp.Initialstock - oi.Quantity) as remaining_stock
	FROM updated_wp wp
	LEFT JOIN updated_oi oi
		ON wp.ProductID = oi.ProductID
) AS DT
)

SELECT 
	*,
    CASE
    WHEN stock_remaining_pct <= 0 THEN 'Out of stock'
    WHEN stock_remaining_pct BETWEEN 1 AND 10 THEN 'Urgent-refill'
    WHEN stock_remaining_pct BETWEEN 11 AND 25 THEN 'Critical'
    WHEN stock_remaining_pct BETWEEN 26 AND 75 THEN 'In-stock'
    WHEN stock_remaining_pct > 75 THEN 'Adequate'
    END as Stock_status
FROM remaining_stock;


-- Query 136: Inventory Distribution across warehouses
WITH total_inventory AS(
SELECT SUM(InitialStock) as total_inventory
FROM warehouse_products
)

SELECT
	WarehouseID,
    COUNT(DISTINCT ProductID) as products,
    SUM(InitialStock) as total_initial_stock,
    ROUND(AVG(InitialStock),2) as avg_stock_per_product,
    ROUND((SUM(InitialStock) / (SELECT total_inventory FROM total_inventory) *100),2) as inventory_share_pct
FROM warehouse_products
GROUP BY WarehouseID


-- Query 137: Warehouse Inventory concentration
SELECT
	WarehouseID,
    COUNT(DISTINCT ProductID) as products,
    SUM(InitialStock) as total_stock,
    MAX(InitialStock) as highest_product_stock,
    ROUND(AVG(InitialStock),2) as avg_stock_per_product,
    ROUND(( MAX(InitialStock) / SUM(InitialStock) *100),2) as concentration_ratio_pct
FROM warehouse_products
GROUP BY WarehouseID;


-- Query 138: Inventory Turnover Analysis
WITH aggregated_wp AS(
SELECT  
	ProductID,
    SUM(InitialStock) as InitialStock
FROM warehouse_products
GROUP BY ProductID
),

aggregated_oi AS(
SELECT
	ProductID,
    SUM(Quantity) as UnitsSold
FROM order_items
GROUP BY ProductID
),

Inventory_turnover_analysis AS(
SELECT
	*,
    ROUND((UnitsSold/InitialStock),2) as inventory_turnover_ratio
FROM(
	SELECT
		wp.ProductID,
		wp.InitialStock,
		oi.UnitsSold
	FROM aggregated_wp wp
	JOIN aggregated_oi oi
		ON wp.ProductID = oi.ProductID
) as DT
)

SELECT
	*,
    CASE
		WHEN inventory_turnover_ratio >= 1.5 THEN 'Fast Moving'
		WHEN inventory_turnover_ratio < 0.75 THEN 'Slow Moving'
		ELSE 'Normal'
	END AS movement_status
FROM Inventory_turnover_analysis;


--Query 139: Inventory value concentration by product
WITH aggregated_wp AS(
SELECT
    ProductID,
    SUM(InitialStock) as InitialStock
FROM warehouse_products
GROUP BY ProductID
),

total_inventory_value AS(
SELECT
    SUM(InitialStock * UnitCost) as total_inventory_value
FROM aggregated_wp wp
JOIN products p
    ON wp.ProductID = p.productID

),

Inventory_value_concentration AS(
SELECT
    *,
    SUM(inventory_value_pct) 
        OVER(
            ORDER BY inventory_value_pct DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) as cumulative_inventory_value_pct
FROM(
    SELECT
        wp.ProductID,
        p.ProductName,
        (wp.InitialStock * UnitCost) as inventory_value,
        ROUND(( (wp.InitialStock * UnitCost) / (SELECT total_inventory_value from total_inventory_value) * 100 ),2)  as inventory_value_pct
    FROM aggregated_wp wp
    JOIN products p
        ON wp.ProductID = p.productID
) as DT
)

SELECT *
FROM Inventory_value_concentration;


-- Query 140: Inventory Efficiency by Warehouse
WITH aggregated_wp AS(
SELECT
	WarehouseID,
    SUM(InitialStock) as total_stock
FROM warehouse_products
GROUP BY WarehouseID
),

aggregated_ooi AS(
SELECT
	WarehouseID,
    SUM(Units) as Units_sold
FROM(
	SELECT
		o.OrderID,
		o.WarehouseID,
		SUM(oi.Quantity) as Units
	FROM Orders o 
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY o.OrderID
) as DT
GROUP BY WarehouseID
),

Inventory_efficiency_analysis AS(
SELECT
	*,
    ROUND((Units_sold / total_stock * 100),2) as stock_utilization_pct,
    ROUND(Units_sold / total_stock,2) as inventory_turnover_ratio
FROM(
	SELECT
		wp.WarehouseID,
		wp.total_stock,
		ooi.Units_sold
	FROM aggregated_wp wp
	JOIN aggregated_ooi ooi
		ON wp.WarehouseID = ooi.WarehouseID
) AS DT
)

SELECT *
FROM Inventory_efficiency_analysis;


-- Query 141: Inventory Health classification
WITH aggregated_wp AS(
SELECT 
	ProductID,
    SUM(InitialStock) as total_stock
FROM warehouse_products
GROUP BY ProductID
),

aggregated_oi AS(
SELECT
	ProductID,
    SUM(Quantity) as units
FROM order_items 
GROUP BY ProductID
),

Inventory_health_classification AS (
SELECT
	*,
    ROUND((units_sold / total_stock),2) as Inventory_turnover_ratio,
    ROUND((units_sold / total_stock * 100),2) as stock_utilization_pct
FROM(
	SELECT
		wp.ProductID,
		wp.total_stock,
		oi.units as units_sold
	FROM aggregated_wp wp
	JOIN aggregated_oi oi
		ON wp.ProductID = oi.ProductID
) AS DT
)

SELECT 
	*,
    CASE
    WHEN inventory_turnover_ratio >= 1.5 THEN 'High Demand'
    WHEN inventory_turnover_ratio < 0.75 THEN 'Slow Moving'
    ELSE 'Healthy'
END AS inventory_health
FROM Inventory_health_classification;




/* ============================================================
   CHAPTER 6 SUMMARY — INVENTORY ANALYSIS
   ============================================================

   OBJECTIVE:
   Analyze inventory levels, stock utilization, inventory value,
   storage costs, warehouse distribution, inventory movement,
   and inventory health to understand how efficiently inventory
   is being held and consumed across products and warehouses.

   KEY ANALYSIS AREAS COVERED:
   1. Inventory overview and stock position
      - Total products, warehouses, inventory records, total
        initial stock, and average initial stock
      - Product-level stock levels and the number of warehouses
        holding each product
      - Average stock held per product across warehouses

   2. Inventory value and storage cost analysis
      - Product-level inventory value based on unit cost
      - Average storage cost per unit
      - Total storage cost associated with inventory held

   3. Stock utilization analysis
      - Comparison of total initial stock with units sold
      - Stock utilization percentage to measure the proportion
        of inventory consumed through sales

   4. Low stock and reorder risk analysis
      - Calculation of remaining stock after units sold
      - Remaining stock percentage
      - Classification of products into Out of Stock,
        Urgent-Refill, Critical, In-Stock, and Adequate status

   5. Inventory distribution across warehouses
      - Number of products and total inventory held by each
        warehouse
      - Average stock per product
      - Percentage share of total inventory held by each
        warehouse

   6. Warehouse inventory concentration
      - Total stock and product count by warehouse
      - Highest product-level stock within each warehouse
      - Concentration ratio showing how much of warehouse
        inventory is represented by its highest-stock product

   7. Inventory turnover and movement analysis
      - Product-level inventory turnover ratio based on units
        sold relative to initial stock
      - Classification of products into Fast Moving,
        Normal, and Slow Moving categories

   8. Inventory value concentration by product
      - Product-level inventory value and percentage
        contribution to total inventory value
      - Cumulative inventory value contribution using a
        Pareto-style concentration analysis

   9. Inventory efficiency by warehouse
      - Warehouse-level units sold compared with total stock
      - Stock utilization percentage
      - Inventory turnover ratio to compare inventory movement
        across warehouses

   10. Inventory health classification
       - Product-level evaluation using inventory turnover and
         stock utilization
       - Classification of inventory into High Demand,
         Slow Moving, and Healthy categories

   OUTCOME:
   This chapter provides a comprehensive view of inventory
   performance by connecting stock levels, inventory value,
   storage costs, demand, warehouse distribution, turnover,
   and inventory health. It helps identify products with low
   or adequate stock, fast- and slow-moving inventory, products
   with high inventory-value concentration, and warehouses
   with different levels of inventory utilization and movement.

   ============================================================ */

