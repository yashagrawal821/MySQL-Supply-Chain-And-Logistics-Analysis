
--Query 166: Shipment Overview KPIs
WITH shipment_overview_kpis AS(
SELECT
	COUNT(ShipmentID) as total_shipments,
    COUNT(DISTINCT OrderID) as total_orders_shipped,
    SUM(ShippingCost) as total_shipping_cost,
    ROUND(AVG(ShippingCost),2) as avg_shipping_cost,
    ROUND(AVG(DistanceKm),2) as avg_distance_km,
    ROUND(AVG(DeliveryDelayDays),2) as avg_delivery_delay_days
FROM shipments
)

SELECT *
FROM shipment_overview_kpis;


--Query 167: Shipment Status Analysis
WITH total_shipments AS(
SELECT COUNT(ShipmentID) as total_shipments
FROM shipments
),

shipment_status_analysis AS(
SELECT
	ShipmentStatus,
    COUNT(ShipmentID) as shipment_count,
    ROUND(( COUNT(ShipmentID) / (SELECT total_shipments FROM total_shipments) *100),2) as pct_of_total_shipments,
    SUM(ShippingCost) as total_shipping_cost
FROM shipments
GROUP BY ShipmentStatus

)

SELECT *
FROM shipment_status_analysis;


--Query 168: Delivery Time Analysis
WITH delivery_time_analysis AS(
SELECT
	COUNT(ShipmentID) as total_shipments,
    ROUND(AVG(DATEDIFF(ActualDeliveryDate, ShipmentDate)),2) as avg_delivery_days,
    MIN(DATEDIFF(ActualDeliveryDate, ShipmentDate)) as min_delivery_days,
    MAX(DATEDIFF(ActualDeliveryDate, ShipmentDate)) as max_delivery_days
FROM shipments
WHERE ActualDeliveryDate IS NOT NULL
)

SELECT *
FROM delivery_time_analysis;


--Query 169: On-time delivery performnace
WITH total_delivery AS(
SELECT COUNT(ShipmentID) as total_delivery
FROM shipments
WHERE ActualDeliveryDate IS NOT NULL
),

ontime_delivery_performance AS(
SELECT
	delivery_performance,
    COUNT(ShipmentID) as shipment_count,
    ROUND((COUNT(ShipmentID) / (SELECT total_delivery FROM total_delivery) *100),2) as pct_of_total_delivery
    
FROM(
	SELECT
		*,
		CASE
			WHEN ActualDeliveryDate <= ExpectedDeliveryDate THEN 'On-Time'
			ELSE 'Late'
		END as delivery_performance
	FROM shipments
    WHERE ActualDeliveryDate IS NOT NULL
) AS DT
GROUP BY delivery_performance
)

SELECT *
FROM ontime_delivery_performance;


--Query 170: Delivery Delay Analysis
WITH delivery_delay_analysis AS(
SELECT
	COUNT(ShipmentID) as delayed_shipment_count,
    ROUND(AVG(DeliveryDelayDays),2) as avg_delay_days,
    MIN(DeliveryDelayDays) as min_delay_days,
    MAX(DeliveryDelayDays) as max_delay_days
FROM shipments
WHERE DeliveryDelayDays > 0
)

SELECT *
FROM delivery_delay_analysis;


--Query 171: Delay Severity Classification
WITH total_shipment AS(
SELECT COUNT(ShipmentID) as total_shipment
FROM shipments
),

delivery_severity_classification AS(
SELECT
	delay_tier,
    COUNT(ShipmentID) as shipment_count,
    ROUND(( COUNT(ShipmentID) / (SELECT total_shipment FROM total_shipment) * 100),2) as pct_of_total_shipments,
    ROUND(AVG(DeliveryDelayDays),2) as avg_delay_days
    
FROM(
	SELECT
		*,
		CASE
			WHEN DeliveryDelayDays <=0 THEN 'OnTime /Early'
			WHEN DeliveryDelayDays IN (1,2) THEN 'Minor delay'
			WHEN DeliveryDelayDays IN (3,4,5) THEN 'Moderate delay'
			ELSE 'Severe delay'
		END as delay_tier
	FROM shipments
) AS DT
GROUP BY delay_tier
)

SELECT *
FROM delivery_severity_classification;


--Query 172: Carrier performnace analysis
WITH carrier_performance_analysis AS(
SELECT
	Carrier,
    COUNT(ShipmentID) as total_shipments,
    SUM(ShippingCost) as total_shipment_cost,
    ROUND(AVG(DATEDIFF(ActualDeliveryDate, ShipmentDate)),2) as avg_delivery_days,
    ROUND(AVG(DeliveryDelayDays),2) as avg_delay_days,
    DENSE_RANK() OVER(ORDER BY COUNT(ShipmentID) DESC) as carrier_rank
FROM shipments
GROUP BY Carrier
)

SELECT *
FROM carrier_performance_analysis;


--Query 173: Carrier on-time reliability
WITH carrier_ontime_reliability AS(
SELECT
	*,
    DENSE_RANK() OVER(ORDER BY ontime_delivery_pct DESC) as reliability_rank
FROM(
	SELECT
		Carrier,
		COUNT(ShipmentID) as total_delivered,
		SUM(CASE WHEN ActualDeliveryDate <= ExpectedDeliveryDate THEN 1 END) as ontime_deliveries,
		SUM(CASE WHEN DeliveryDelayDays > 0 THEN 1 END) as late_deliveries,
		ROUND(( SUM(CASE WHEN ActualDeliveryDate <= ExpectedDeliveryDate THEN 1 END) / COUNT(ShipmentID) * 100 ),2) as ontime_delivery_pct
	FROM shipments
	WHERE shipmentStatus = 'Delivered'
	GROUP BY Carrier
) AS DT
)

SELECT *
FROM carrier_ontime_reliability;


--Query 174: Shipping Cost Analysis
WITH shipping_cost_analysis AS(
SELECT
	SUM(ShippingCost) as total_shipment_cost,
    ROUND(AVG(ShippingCost),2) as avg_shipping_cost,
    MIN(ShippingCost) as min_shipping_cost,
    MAX(ShippingCost) as max_shipping_cost,
    SUM(DistanceKm) as total_distance
FROM shipments
)

SELECT *
FROM shipping_cost_analysis;


--Query 175: Shipping Cost Efficiency
WITH shipping_cost_efficiency AS(
SELECT
	*,
    DENSE_RANK() OVER(ORDER BY cost_per_km) as efficiency_rank
FROM(
	SELECT
		Carrier,
        COUNT(ShipmentID) as total_shipments,
		SUM(ShippingCost) as total_shipping_cost,
		SUM(DistanceKm) as total_distance_km,
		ROUND((SUM(ShippingCost) / SUM(DistanceKm)),2) as cost_per_km
	FROM shipments
	GROUP By Carrier
) as DT
)

SELECT *
FROM shipping_cost_efficiency;


--Query 176: Distance vs Shipping Cost Analysis
WITH distance_vs_shipping_cost_analysis AS (
    SELECT
        distance_tier,
        COUNT(ShipmentID) AS shipment_count,
        ROUND(AVG(DistanceKm), 2) AS avg_distance_km,
        ROUND(AVG(ShippingCost), 2) AS avg_shipping_cost,
        ROUND((SUM(ShippingCost) / SUM(DistanceKm)), 2) AS cost_per_km
    FROM (
        SELECT
            *,
            CASE
                WHEN DistanceKm < 200 THEN 'Local / Short (< 200 km)'
                WHEN DistanceKm BETWEEN 200 AND 500 THEN 'Medium Distance (200 - 500 km)'
                WHEN DistanceKm BETWEEN 501 AND 1000 THEN 'Long Distance (501 - 1000 km)'
                ELSE 'Cross-Country / Ultra Long (> 1000 km)'
            END AS distance_tier
        FROM shipments
    ) AS DT
    GROUP BY distance_tier
)

SELECT *
FROM distance_vs_shipping_cost_analysis;


--Query 177: Shipment Volume by Period
WITH monthly_shipment_performance AS (
    SELECT
        DATE_FORMAT(ShipmentDate, '%Y-%m') AS shipment_month,
        COUNT(ShipmentID) AS total_shipments,
        SUM(ShippingCost) AS total_shipping_cost,
        ROUND(AVG(DeliveryDelayDays), 2) AS avg_delay_days,
        ROUND(
            (SUM(CASE WHEN ActualDeliveryDate <= ExpectedDeliveryDate THEN 1 ELSE 0 END) 
             / NULLIF(COUNT(CASE WHEN ActualDeliveryDate IS NOT NULL THEN 1 END), 0)) * 100, 
            2
        ) AS ontime_delivery_rate_pct
    FROM shipments
    GROUP BY DATE_FORMAT(ShipmentDate, '%Y-%m')
)

SELECT *
FROM monthly_shipment_performance
ORDER BY shipment_month ASC;


--Query 178: Logistics Performance Classification
WITH carrier_metrics AS (
    SELECT
        Carrier,
        COUNT(ShipmentID) AS total_shipments,
        SUM(ShippingCost) AS total_shipping_cost,
        SUM(DistanceKm) AS total_distance_km,
        ROUND(
            (SUM(CASE WHEN ActualDeliveryDate <= ExpectedDeliveryDate THEN 1 ELSE 0 END) 
             / NULLIF(COUNT(CASE WHEN ActualDeliveryDate IS NOT NULL THEN 1 END), 0)) * 100, 
            2
        ) AS ontime_delivery_rate_pct,
        ROUND(AVG(DeliveryDelayDays), 2) AS avg_delay_days,
        ROUND(SUM(ShippingCost) / NULLIF(SUM(DistanceKm), 0), 2) AS cost_per_km
    FROM shipments
    GROUP BY Carrier
),

carrier_performance_classification AS (
    SELECT
        Carrier,
        total_shipments,
        ontime_delivery_rate_pct,
        avg_delay_days,
        cost_per_km,
        CASE
            WHEN ontime_delivery_rate_pct >= 88 AND avg_delay_days <= 1.0 THEN 'Excellent'
            WHEN ontime_delivery_rate_pct >= 83 AND avg_delay_days <= 1.5 THEN 'Strong'
            WHEN ontime_delivery_rate_pct >= 78 THEN 'Average'
            ELSE 'Weak'
        END AS performance_tier,
        DENSE_RANK() OVER(ORDER BY ontime_delivery_rate_pct DESC, avg_delay_days ASC) AS overall_rank
    FROM carrier_metrics
)

SELECT *
FROM carrier_performance_classification
ORDER BY overall_rank ASC;




/* ============================================================
CHAPTER 9 SUMMARY — LOGISTICS & SHIPMENT ANALYSIS

OBJECTIVE:
Analyze network-wide fulfillment efficiency, carrier performance,
shipping unit economics, delivery speed, delay severity, transit
distances, cost-per-kilometer, temporal dispatch volume trends, and
overall 3PL carrier classification to evaluate third-party logistics,
service level agreement (SLA) execution, and freight spend productivity.

KEY ANALYSIS AREAS COVERED:

1. Shipment overview KPIs
* Total shipment volume and distinct orders shipped
* Aggregate network freight spend and average shipping cost per package
* Average transit distance in kilometers and average delivery delay days


2. Shipment status analysis
* Distribution of shipments across operational states (Delivered, In Transit, Delayed, Cancelled)
* Percentage contribution of each status tier to total network volume
* Total financial commitment and freight spend allocated per shipment status


3. Delivery time analysis
* Cycle time measurement using DATEDIFF(ActualDeliveryDate, ShipmentDate) for completed orders
* Average transit duration in days across delivered packages
* Shortest (minimum) and longest (maximum) fulfillment delivery windows


4. On-time delivery performance
* Network-wide SLA compliance evaluation for delivered shipments
* On-Time / Early vs. Late delivery classification via CASE logic
* On-time delivery rate percentage across total completed order volume


5. Delivery delay analysis
* Targeted evaluation of delayed shipments (WHERE DeliveryDelayDays > 0)
* Total delayed shipment volume and average delay duration in days
* Shortest and worst-case (maximum) delay durations across late packages


6. Delay severity classification
* Segmentation of delay duration into actionable severity tiers (On-Time/Early, Minor, Moderate, Severe)
* Distribution of shipment counts and network percentage share per delay tier
* Average delay days within each severity classification bucket


7. Carrier performance analysis
* Operational workload distribution across primary carriers (FedEx, UPS, DHL, USPS)
* Total freight spend, average delivery days, and average delay days by carrier
* Ranking carriers by total shipment volume handled via DENSE_RANK()


8. Carrier on-time reliability
* Carrier-level SLA contract execution for completed deliveries
* Count of on-time vs. late shipments per logistics partner using conditional aggregation
* On-time delivery rate percentage and carrier reliability ranking


9. Shipping cost analysis
* Network-wide freight spend evaluation
* Average, minimum, and maximum shipping cost per transaction
* Total cumulative transit distance in kilometers across all shipments


10. Shipping cost efficiency
* Unit economic efficiency calculated as cost per kilometer (SUM(ShippingCost) / SUM(DistanceKm))
* Comparison of freight spend relative to transit distance across carriers
* Ranking carriers by cost efficiency per kilometer


11. Distance vs shipping cost analysis
* Classification of shipping routes into distance tiers (Local/Short, Medium, Long, Cross-Country)
* Average transit distance, average shipping cost, and cost-per-km across distance buckets
* Freight cost scaling analysis relative to route length


12. Shipment volume by period
* Monthly time-series tracking via DATE_FORMAT(ShipmentDate, '%Y-%m')
* Monthly trends in shipment volume, total freight spend, and average delay days
* On-time delivery rate percentage evolution month-over-month using NULLIF() guard


13. Logistics performance classification
* Multi-metric integration of volume, SLA punctuality %, delay days, and unit cost-per-km
* Strategic carrier performance tiering (Excellent, Strong, Average, Weak)
* Overall composite carrier performance ranking across the logistics network



OUTCOME:
This chapter provides an end-to-end evaluation of the enterprise supply
chain and shipping operations by connecting fulfillment volume and transit
speed directly to carrier SLA execution, delay severity, and route unit economics.
It identifies top-performing logistics partners, pinpoints cost leakage across
long-haul distance buckets, highlights delay bottlenecks, and establishes an objective,
data-driven framework for carrier contract negotiations and strategic dispatch routing.

============================================================ */