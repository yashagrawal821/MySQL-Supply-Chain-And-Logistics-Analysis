
--Query 142: Suppliers overview KPIs
SELECT
	COUNT(DISTINCT SupplierID) as total_suppliers,
    COUNT(DISTINCT ProductID) as total_products_supplied,
    COUNT(*) as supplier_products_records,
    ROUND((COUNT(DISTINCT ProductID) / COUNT(DISTINCT SupplierID) ),2) as avg_products_per_supplier
FROM supplier_products;


-- Query 143: Supplier product coverage
SELECT
	SupplierID,
    COUNT(DISTINCT ProductID) supplied_products
FROM supplier_products
GROUP BY SupplierID
ORDER BY supplied_products DESC;


-- Query 144: Supplier Procurement Value
SELECT
	SupplierID,
    SUM(p.UnitCost) as total_precurement_value
FROM supplier_products sp
JOIN products p
	ON sp.ProductID = p.ProductID
GROUP BY sp.SupplierID
ORDER BY total_precurement_value DESC;


--Query 145: Supplier Cost Analysis
SELECT
	SupplierID,
    COUNT(DISTINCT ProductID) as products_supplied,
    ROUND(AVG(SupplierUnitCost),2) as avg_unit_cost,
    MAX(SupplierUnitCost) as max_unit_cost,
    MIN(SupplierUnitCost) as min_unit_cost
FROM supplier_products
GROUP BY SupplierID


--Query 146: Supplier procurement value contribution
WITH total_procurement AS(
SELECT SUM(SupplierUnitCost) as total_procurement
FROM supplier_products
)

SELECT
	*,
    ROUND((procurement_value / (SELECT total_procurement FROM total_procurement) * 100),2) as procurement_contribution_pct
FROM(
	SELECT
		SupplierID,
		SUM(SupplierUnitCost) as procurement_value
	FROM supplier_products
	GROUP BY SupplierID
) AS DT;


--Query 147: Suppliers warehosue reach
SELECT
	sp.SupplierID,
    COUNT(DISTINCT wp.WarehouseID) as warehouses_reached
FROM supplier_products sp
JOIN warehouse_products wp
	ON sp.ProductID = wp.ProductID
GROUP BY sp.SupplierID;


--Query 148 : Supplier dependency by product
SELECT
	*,
	CASE
		WHEN suppliers_count = 1 THEN 'High'
        WHEN suppliers_count = 2 THEN 'Moderate'
        WHEN suppliers_count >=3 THEN 'Low'
	END as dependency_status
FROM(
	SELECT
		ProductID,
		COUNT(DISTINCT SupplierID) as suppliers_count
	FROM supplier_products
	GROUP BY ProductID
) as DT;


--Query 149: Multi-supplier vs Single-supplier products
WITH total_products AS(
SELECT COUNT(DISTINCT ProductID) as total_products
FROM supplier_products
)

SELECT
	supplier_type,
    COUNT(*) as products,
    ROUND((COUNT(*) / (SELECT total_products FROM total_products) * 100),2) as product_share_pct
FROM(
	SELECT
		ProductID, 
		COUNT(DISTINCT SupplierID) as supplier_count,
        CASE
			WHEN COUNT(DISTINCT SupplierID) = 1 THEN 'Single_supplier'
            WHEN COUNT(DISTINCT SupplierID) > 1 THEN 'Multi_supplier'
		END as supplier_type
	FROM supplier_products
	GROUP BY ProductID
) as DT
GROUP BY supplier_type;


--Query 150: Supplier Product Demand Performance
WITH aggregated_oi AS(
SELECT 
	ProductID,
    SUM(Quantity) as units,
    SUM(Quantity*UnitPrice) as revenue
FROM order_items
GROUP BY ProductID
)

SELECT
	sp.SupplierID,
    COUNT(DISTINCT sp.ProductID) as products_supplied,
    SUM(oi.units) as units_sold,
    SUM(revenue) as revenue
FROM supplier_products sp
JOIN aggregated_oi oi
	ON sp.ProductID = oi.ProductID
GROUP BY sp.SupplierID


--Query 151: Supplier Cost vs Demand Efficiency
WITH aggregated_oi AS(
SELECT 
	ProductID,
    SUM(Quantity) as units,
    SUM(Quantity*UnitPrice) as revenue
FROM order_items
GROUP BY ProductID
)

SELECT
	sp.SupplierID,
    ROUND(AVG(sp.SupplierUnitCost),2) as avg_supplier_unit_cost,
    SUM(oi.units) as units_sold,
    SUM(revenue) as revenue
FROM supplier_products sp
JOIN aggregated_oi oi
	ON sp.ProductID = oi.ProductID
GROUP BY sp.SupplierID


--Query 152: Supplier portfolio performance
WITH aggregated_wp AS(
SELECT
	wp.ProductID,
    SUM(wp.InitialStock) as total_stock,
    COUNT(DISTINCT wp.WarehouseID) as warehouse_reached,
    (SUM(wp.InitialStock) * p.UnitCost) as inventory_value
FROM warehouse_products wp
JOIN products p
	ON wp.ProductID = p.ProductID
GROUP BY ProductID
),

warehouse_reached_by_suppliers AS(
SELECT
	sp.SupplierID,
    COUNT(DISTINCT wp.WarehouseID) as warehouse_reached
FROM supplier_products sp
JOIN warehouse_products wp
	ON sp.ProductID = wp.ProductID
GROUP BY sp.SupplierID
),

aggregated_oi AS(
SELECT
	ProductID,
    SUM(Quantity) as units_sold,
    SUM(Quantity * UnitPrice) as revenue
FROM order_items oi
GROUP BY ProductID
),

supplier_portfolio_performance AS(
SELECT
	sp.SupplierID,
    COUNT(DISTINCT sp.ProductID) as products_supplied,
    wr.warehouse_reached as warehouse_reached,
    SUM(wp.inventory_value) as inventory_value,
    SUM(oi.units_sold) as units_sold,
    SUM(oi.revenue) as revenue
FROM supplier_products sp
JOIN aggregated_wp wp
	ON sp.ProductID = wp.ProductID
JOIN warehouse_reached_by_suppliers wr
	ON sp.SupplierID = wr.SupplierID
JOIN Aggregated_oi oi
	ON sp.ProductID = oi.ProductID
GROUP BY sp.SupplierID
)

SELECT * 
FROM supplier_portfolio_performance;




/* ============================================================
   CHAPTER 7 SUMMARY — SUPPLIER ANALYSIS
   ============================================================

   OBJECTIVE:
   Analyze the supplier base, product coverage, procurement
   costs, supplier dependency, warehouse reach, demand
   performance, cost efficiency, and overall supplier
   portfolio performance to understand supplier importance,
   concentration, dependency, and business contribution.

   KEY ANALYSIS AREAS COVERED:
   1. Supplier overview and supplier-base structure
      - Total number of suppliers
      - Total number of products supplied
      - Supplier-product relationship records
      - Average number of products supplied per supplier

   2. Supplier product coverage
      - Number of distinct products supplied by each supplier
      - Ranking suppliers based on product portfolio breadth

   3. Supplier procurement value
      - Total product-cost value associated with each supplier
      - Ranking suppliers by overall procurement value

   4. Supplier cost analysis
      - Number of products supplied by each supplier
      - Average, minimum, and maximum supplier unit costs
      - Comparison of supplier-level cost structures

   5. Supplier procurement value contribution
      - Total procurement value generated by each supplier
      - Percentage contribution of each supplier to overall
        procurement cost

   6. Supplier warehouse reach
      - Number of distinct warehouses reached by each supplier's
        supplied products
      - Identification of suppliers with broader warehouse
        distribution

   7. Supplier dependency by product
      - Number of suppliers available for each product
      - Classification of products into High, Moderate, and
        Low supplier dependency based on supplier availability

   8. Multi-supplier versus single-supplier products
      - Classification of products based on the number of
        available suppliers
      - Comparison of single-supplier and multi-supplier
        product counts
      - Percentage share of products in each supplier category

   9. Supplier product demand performance
      - Products supplied by each supplier
      - Total units sold associated with supplier portfolios
      - Revenue generated by products supplied by each supplier

   10. Supplier cost versus demand efficiency
       - Average supplier unit cost
       - Units sold generated by supplier portfolios
       - Revenue generated alongside supplier cost levels
       - Comparison of supplier cost structure against demand
         and revenue performance

   11. Supplier portfolio performance
       - Product portfolio breadth
       - Warehouse reach
       - Inventory value associated with supplier portfolios
       - Units sold and revenue generated
       - Integrated comparison of supplier portfolio scale,
         inventory exposure, and demand performance

   OUTCOME:
   This chapter provides a comprehensive view of supplier
   performance and supplier-related business exposure by
   connecting supplier coverage, procurement costs, warehouse
   distribution, product dependency, demand, revenue, and
   inventory value. It helps identify broad and strategically
   important suppliers, products with higher supplier
   dependency, procurement cost concentration, supplier
   distribution reach, and suppliers whose product portfolios
   generate significant demand and revenue.

   ============================================================ */