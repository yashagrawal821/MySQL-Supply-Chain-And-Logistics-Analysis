
--Query 153: Warehouse Network Overview KPIs
WITH warehouse_kpis AS(
SELECT
	COUNT(DISTINCT WarehouseID) as total_warehouses,
    SUM(CASE WHEN ActiveFlag = 1 THEN 1 ELSE 0 END) as active_warehouses,
    COUNT(DISTINCT Country) as countries,
    COUNT(DISTINCT Region) as regions,
    COUNT(DISTINCT City) as cities,
    COUNT(DISTINCT WarehouseType) as warehouse_types,
    SUM(CapacityUnits) as total_capacity_units,
    SUM(OperatingCostPerMonth) as total_monthly_operational_cost
FROM warehouses
)

SELECT * 
FROM warehouse_kpis;


--Query 154: Warehouse Operational Status
WITH total_warehouses AS(
SELECT COUNT(DISTINCT WarehouseID) as total_warehouses
FROM warehouses
),

Warehouse_operational_status AS(
SELECT
	operational_status,
    COUNT(WarehouseID) as warehouse_count,
    ROUND(( COUNT(WarehouseID) / (SELECT total_warehouses FROM total_warehouses) * 100),2) as pct_of_total_warehouses,
    SUM(CapacityUnits) as total_capacity
FROM(
	SELECT
		*,
        CASE 
			WHEN ActiveFlag = 1 THEN 'Active' 
            ELSE 'Inactive' 
		END as operational_status
    FROM warehouses 
) as DT
GROUP BY operational_status
)

SELECT * 
FROM Warehouse_operational_status;


--Query 155: Warehouse Geographic Distribution
WITH total_warehouses AS(
SELECT COUNT(DISTINCT WarehouseID) as total_warehouses
FROM warehouses
),

warehouse_geographic_distribution AS(
SELECT
	Country,
    Region,
    City,
    COUNT(DISTINCT WarehouseID) as warehouse_count,
    SUM(CASE WHEN ActiveFlag = 1 THEN 1 ELSE 0 END) AS active_warehouses,
    SUM(CapacityUnits) AS total_capacity_units,
    SUM(OperatingCostPerMonth) AS total_monthly_operating_cost,
    ROUND((COUNT(WarehouseID) / (SELECT total_warehouses FROM total_warehouses)) * 100, 2) AS pct_of_total_warehouses
FROM warehouses
GROUP BY Country,Region,City
)

SELECT *
FROM warehouse_geographic_distribution;


--Query 156: Warehouse Type Analysis
WITH total_capacity AS(
SELECT SUM(CapacityUnits) as total_capacity
FROM warehouses
),

warehouse_type_analysis AS(
SELECT
	WarehouseType,
    COUNT(Distinct WarehouseID) as warehouse_count,
    SUM(CASE WHEN ActiveFlag = 1 THEN 1 END) as active_warehouses,
    SUM(CapacityUnits) as total_capacity_units,
    ROUND(AVG(CapacityUnits),2) as avg_capacity_units,
    SUM(OperatingCostPerMonth) as total_monthly_operating_cost,
    ROUND(AVG(OperatingCostPerMonth),2) as avg_monthly_opearting_cost,
    (SUM(CapacityUnits) / (SELECT total_capacity FROM total_capacity) *100) as pct_of_total_capacity
FROM warehouses
GROUP BY WarehouseType
)

SELECT *
FROM warehouse_type_analysis;


--Query 157: Warehouse capacity analysis
WITH avg_capacity AS(
SELECT AVG(CapacityUnits) as avg_capacity
FROM warehouses
),

warhouse_capacity_analysis AS(
SELECT
	*,
    CASE 
		WHEN CapacityUnits >= 200000 THEN 'Very High'
		WHEN CapacityUnits >= 100000 THEN 'High'
		WHEN CapacityUnits >= 50000  THEN 'Medium'
		ELSE 'Low'
	END AS capacity_tier,
    DENSE_RANK() OVER(ORDER BY CapacityUnits DESC) as capacity_rank
FROM(
	SELECT
		WarehouseID,
		WarehouseName,
		WarehouseType,
		CapacityUnits,
		ROUND((CapacityUnits - (SELECT avg_capacity FROM avg_capacity) ),0) as diff_from_avg_capacity
	FROM warehouses
) AS DT
)

SELECT *
FROM warhouse_capacity_analysis;


--Query 158: Warehouse Operating Cost Analysis
WITH avg_cost AS(
SELECT AVG(OperatingCostPerMonth) as avg_cost
FROM warehouses
),

warhouse_opeartion_cost_analysis AS(
SELECT
	*,
    CASE 
		WHEN OperatingCostPerMonth >= 300000 THEN 'High Cost'
		WHEN OperatingCostPerMonth >= 100000 THEN 'Medium Cost'
		ELSE 'Low Cost'
	END AS cost_tier,
    DENSE_RANK() OVER(ORDER BY OperatingCostPerMonth DESC) as cost_rank
FROM(
	SELECT
		WarehouseID,
		WarehouseName,
		WarehouseType,
		OperatingCostPerMonth,
		ROUND((OperatingCostPerMonth - (SELECT avg_cost FROM avg_cost) ),0) as diff_from_avg_cost
	FROM warehouses
) AS DT
)

SELECT *
FROM warhouse_opeartion_cost_analysis;


--Query 159: Warehouse cost efficiency analysis
WITH warehouse_cost_efficiency_analysis AS(
SELECT
	*,
    CASE 
		WHEN capacity_per_dollar >= 1.0 THEN 'High Efficiency'
		WHEN capacity_per_dollar >= 0.8 THEN 'Medium Efficiency'
		ELSE 'Low Efficiency'
	END AS efficiency_tier,
    DENSE_RANK() OVER(ORDER BY capacity_per_dollar DESC) as efficiency_rank
FROM(
	SELECT
		WarehouseID,
		WarehouseName,
		OperatingCostPerMonth,
		CapacityUnits,
		ROUND(CapacityUnits / OperatingCostPerMonth,2) as capacity_per_dollar,
		ROUND(OperatingCostPerMonth / CapacityUnits,2) as cost_per_capacity_unit
	FROM warehouses
) AS DT
)

SELECT *
FROM warehouse_cost_efficiency_analysis;


--Query 160: Warehouse Age Analysis
WITH warehouse_age_analysis AS(
SELECT
	*,
    CASE
		WHEN warehouse_age >= 15 THEN 'Old'
        WHEN warehouse_age >= 10 THEN 'Established'
        WHEN warehouse_age >= 5 THEN 'Recent'
        ELSE 'Brand New'
	End as age_tier,
    DENSE_RANK() OVER(ORDER BY warehouse_age DESC) as age_rank
        
FROM(
	SELECT
		WarehouseID,
		OpeningDate,
		timestampdiff(YEAR, OpeningDate, CURDATE()) as warehouse_age
	FROM warehouses
) AS DT
)

SELECT *
FROM warehouse_age_analysis;


--Query 161: Warehouse order workload
WITH total_orders AS(
SELECT COUNT(DISTINCT OrderID) as total_orders
FROM orders
),

warehouse_order_workload_analysis AS(
SELECT
	*,
    CASE 
		WHEN orders_served >= 4000 THEN 'Heavy'
		WHEN orders_served >= 2000  THEN 'Moderate'
		ELSE 'Light'
	END AS workload_tier,
    DENSE_RANK() OVER(ORDER BY orders_served DESC) as workload_rank
FROM(
	SELECT
		WarehouseID,
		COUNT(DISTINCT OrderID) as orders_served,
		ROUND(( COUNT(DISTINCT OrderID) / (SELECT total_orders FROM total_orders) *100 ),2) as pct_of_total_orders
	FROM orders
	GROUP BY WarehouseID
) AS DT
)

SELECT *
FROM warehouse_order_workload_analysis;


--Query 162: Warehouse Order Status Performance
WITH warehouse_order_status_performance_analysis AS(
SELECT
	*,
    ROUND((completed_orders / total_orders *100),2) as completion_rate_pct
FROM(
	SELECT 
		WarehouseID,
		COUNT(DISTINCT OrderID) as total_orders,
		SUM(CASE WHEN OrderStatus = 'Completed' THEN 1 END) as completed_orders,
		SUM(CASE WHEN OrderStatus = 'Cancelled' THEN 1 END) as cancelled_orders,
		SUM(CASE WHEN OrderStatus = 'Pending' THEN 1 END) as pending_orders
	FROM orders
	GROUP BY WarehouseID
) AS DT
)

SELECT * 
FROM warehouse_order_status_performance_analysis;


--Query 163: Warehouse Sales Analysis
WITH total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items
),

warehouse_sales_analysis AS(
SELECT
	*,
    CASE 
		WHEN revenue >= 40000000 THEN 'High Revenue'   -- $40M+
		WHEN revenue >= 15000000 THEN 'Medium Revenue' -- $15M - $40M
		ELSE 'Low Revenue'                                   -- Under $15M
	END AS revenue_tier,
    DENSE_RANK() OVER(ORDER BY revenue DESC) as revenue_rank
FROM(
	SELECT
		o.WarehouseID,
		SUM(oi.Quantity) as units_sold,
		SUM(oi.Quantity * oi.UnitPrice) as revenue,
		ROUND(( SUM(oi.Quantity * oi.UnitPrice) / (SELECT total_revenue FROM total_revenue) *100 ),2) AS pct_to_total_revenue
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY o.WarehouseID
) AS DT
)

SELECT *
FROM warehouse_sales_analysis;


--Query 164: Warehouse Revenue & Operating Cost Efficiency
WITH Warehouse_revenue_and_cost_efficiency_analysis AS(
SELECT
	*,
    CASE 
		WHEN revenue_to_cost_ratio >= 400 THEN 'High Profitability'   -- 400x+ cost cover
		WHEN revenue_to_cost_ratio >= 200 THEN 'Medium Profitability' -- 200x - 400x
		ELSE 'Low Profitability'                                      -- Under 200x
	END AS profitability_tier,
    DENSE_RANK() OVER(ORDER BY revenue_to_cost_ratio DESC ) as profitability_rank
FROM(
	SELECT
		o.WarehouseID,
		w.OperatingCostPerMonth,
		SUM(oi.Quantity * oi.UnitPrice) as revenue,
		ROUND(( SUM(oi.Quantity * oi.UnitPrice) / w.OperatingCostPerMonth ),2) as revenue_to_cost_ratio
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	JOIN warehouses w
		ON o.WarehouseID = w.WarehouseID
	GROUP BY o.WarehouseID
) AS DT
)

SELECT *
FROM Warehouse_revenue_and_cost_efficiency_analysis;


--Query 165: Warehouse Performance Classification
WITH Warehouse_revenue_and_cost_efficiency_analysis AS(
SELECT
	*,
    CASE 
		WHEN (orders / CapacityUnits) >= 0.10 THEN 'High'
		WHEN (orders / CapacityUnits) >= 0.05 THEN 'Medium'
		ELSE 'Low'
	END AS capacity_utilization_score,
    CASE 
		WHEN revenue >= 40000000 AND revenue_to_cost_ratio >= 400 THEN 'Strong'
		WHEN revenue >= 15000000 AND revenue_to_cost_ratio >= 200 THEN 'Average'
		ELSE 'Weak'
	END AS performance_tier,
    DENSE_RANK() OVER(ORDER BY revenue DESC, revenue_to_cost_ratio DESC) as overall_rank
FROM(
	SELECT
		o.WarehouseID,
        COUNT(DISTINCT o.OrderID) as orders,
		w.OperatingCostPerMonth,
		SUM(oi.Quantity * oi.UnitPrice) as revenue,
		ROUND(( SUM(oi.Quantity * oi.UnitPrice) / w.OperatingCostPerMonth ),2) as revenue_to_cost_ratio,
        w.CapacityUnits
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	JOIN warehouses w
		ON o.WarehouseID = w.WarehouseID
	GROUP BY o.WarehouseID
) AS DT
)

SELECT *
FROM Warehouse_revenue_and_cost_efficiency_analysis;




/* ============================================================
CHAPTER 8 SUMMARY — WAREHOUSE ANALYSIS

OBJECTIVE:
Analyze the warehouse network, operational status, geographic
distribution, facility types, capacity levels, monthly operating
costs, cost efficiency, facility age, order workloads, order status
fulfillment performance, sales volume, cost-to-revenue efficiency,
and overall performance classification to evaluate physical
infrastructure, operational load, financial efficiency, and total
facility contribution.

KEY ANALYSIS AREAS COVERED:

1. Warehouse network overview KPIs
* Total count of warehouses and active facilities
* Network reach across countries, regions, and cities
* Breakdown of warehouse types, total capacity, and total operating cost


2. Warehouse operational status
* Distribution of active vs. inactive facilities
* Percentage share of active facilities across the total network
* Total network capacity contributed by operational status


3. Warehouse geographic distribution
* Distribution of warehouses by country, region, and city
* Active warehouse count and total capacity by geographic location
* Geographic concentration and cost exposure per region


4. Warehouse type analysis
* Categorization of facilities by warehouse type
* Average and total storage capacity by facility type
* Average and total monthly operating cost by facility type
* Percentage contribution of each warehouse type to total capacity


5. Warehouse capacity analysis
* Facility-level capacity evaluation
* Variance from the average network capacity
* Classification into capacity tiers (Very High, High, Medium, Low)
* Ranking facilities by storage capacity


6. Warehouse operating cost analysis
* Monthly facility operating costs
* Variance from the network average operating cost
* Segmentation into cost tiers (High Cost, Medium Cost, Low Cost)
* Ranking facilities by operational expenditure


7. Warehouse cost efficiency analysis
* Unit capacity generated per operating dollar (capacity_per_dollar)
* Monthly cost incurred per unit of capacity (cost_per_capacity_unit)
* Classification into efficiency tiers (High, Medium, Low Efficiency)
* Ranking warehouses by structural cost efficiency


8. Warehouse age analysis
* Calculation of operational age based on opening date
* Classification into maturity tiers (Old, Established, Recent, Brand New)
* Ranking warehouses by operational longevity


9. Warehouse order workload
* Total distinct orders fulfilled per facility
* Percentage share of total network order volume handled
* Classification into workload tiers (Heavy, Moderate, Light Workload)
* Ranking warehouses by order activity


10. Warehouse order status performance
* Categorization of fulfilled orders into Completed, Cancelled, and Pending
* Completion rate percentage per facility
* Identification of fulfillment bottlenecks and cancellation rates


11. Warehouse sales performance
* Total units sold and gross revenue generated per facility
* Percentage contribution of each warehouse to overall network sales
* Categorization into revenue tiers (High, Medium, Low Revenue)
* Ranking facilities by top-line revenue output


12. Warehouse revenue & operating cost efficiency
* Revenue generated relative to monthly operating cost (revenue_to_cost_ratio)
* Categorization into profitability tiers (High, Medium, Low Profitability)
* Ranking warehouses by cost-coverage and financial productivity


13. Warehouse performance classification
* Integration of order volume, gross revenue, operating costs, and capacity
* Capacity utilization scoring (High, Medium, Low) based on order density
* Holistic performance classification (Strong, Average, Weak)
* Composite performance ranking across the entire warehouse network



OUTCOME:
This chapter provides an end-to-end evaluation of the enterprise
warehouse network by linking physical storage capacity and fixed
operating costs directly to fulfillment workload, order status
quality, sales volume, and financial efficiency. It highlights high-volume
powerhouse hubs, identifies underutilized or high-cost facilities,
pinpoint fulfillment bottlenecks, and establishes an objective,
data-driven model for strategic footprint optimization.

============================================================ */
