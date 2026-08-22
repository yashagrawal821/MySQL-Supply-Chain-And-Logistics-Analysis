
-- Query 117: Sales overview KPIs
SELECT 
	COUNT( DISTINCT o.OrderID) as total_orders,
    SUM(oi.Quantity) as total_units_sold,
    SUM(oi.Quantity * oi.UnitPrice) as total_revenue,
    ROUND(SUM(oi.Quantity * oi.UnitPrice) / COUNT( DISTINCT o.OrderID),2) as avg_order_value,
    ROUND(SUM(oi.Quantity) / COUNT( DISTINCT o.OrderID),2) as avg_units_per_order
FROM orders o
JOIN order_items oi
ON o.OrderId = oi.OrderID;


-- Query 118: 
WITH order_value AS(
SELECT 
	o.OrderID,
	SUM(oi.Quantity * oi.UnitPrice) as order_value,
    ROW_NUMBER() OVER( ORDER BY SUM(oi.Quantity * oi.UnitPrice) ) as rn,
    COUNT(*) OVER() as total_rows
    
FROM orders o
JOIN order_items oi
ON o.OrderId = oi.OrderID
GROUP BY o.OrderId)

SELECT 
    ROUND(AVG(order_value),2) as avg_order_value,
    MIN(order_value) as min_order_value,
    MAX(order_value) as max_order_value,
    ROUND(AVG(median_order_value),2) as median_order_value,
    MAX(25_percentile) as q1_25_percentile,
    MAX(75_percentile) as q3_75_percentile,
    MAX(75_percentile) - MAX(25_percentile) as IQR
FROM(
	SELECT 
		OrderID,
        order_value,
		CASE 
            WHEN (total_rows % 2 != 0) AND (rn = (total_rows +1) /2) THEN order_value
            WHEN (total_rows % 2 = 0) AND (rn = total_rows / 2 OR rn = total_rows / 2 + 1) THEN order_value
		END as median_order_value,
        CASE 
            WHEN (rn = ceiling(total_rows * 0.25) ) THEN order_value 
        END as 25_percentile,
        CASE
            WHEN (rn = ceiling(total_rows * 0.75) ) THEN order_value 
        END as 75_percentile
	FROM order_value
) as DT;


-- Query 119: Monthly Sales perfromance
WITH monthly_sales_analysis AS (
SELECT
	YEAR(OrderDate) as year, MONTH(OrderDate) as month,
	COUNT(DISTINCT o.OrderID) as orders,
    SUM(oi.Quantity) as units,
    SUM(oi.Quantity * oi.unitPrice) as revenue,
    ROUND(( SUM(oi.Quantity * oi.unitPrice) / COUNT(DISTINCT o.OrderID) ),2) as AOV
    
FROM orders o 
JOIN order_items oi
ON o.OrderID = oi.OrderID 
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)

SELECT *
FROM monthly_sales_analysis;


-- Query 120: Sales growth analysis
WITH sales_growth_analysis AS(
SELECT
	DATE_FORMAT(o.OrderDate, '%Y-%m') as month_year,
    SUM(oi.Quantity * oi.UnitPrice) as Revenue
FROM orders o
JOIN order_items oi
ON o.OrderId = oi.OrderId 
GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
)

SELECT
	month_year,
    Revenue,
    previous_revenue,
    ROUND(((Revenue - previous_revenue) / previous_revenue * 100),2) as MoM_growth
FROM (
	SELECT *, 
		LAG(Revenue) OVER( ORDER BY month_year) as previous_revenue
	FROM sales_growth_analysis
) as DT; 


-- Query 121: Customer Segment Sales Performance
WITH segment_performance_analysis AS(
SELECT
	CustomerSegment,
	revenue,
    orders,
    ROUND((revenue/orders),2) as AOV,
    SUM(revenue) OVER() as total_revenue
FROM(
	SELECT
		c.CustomerSegment,
		SUM(oi.Quantity * oi.UnitPrice) as revenue,
		COUNT( DISTINCT o.OrderID) as orders
	FROM customers c
	LEFT JOIN orders o
		ON c.CustomerId = o.CustomerID
	LEFT JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY c.CustomerSegment
) AS DT
)

SELECT
	*,
    ROUND((revenue/total_revenue *100),2) as revenue_contribution
FROM segment_performance_analysis;


-- Query 122: Order size analysis
WITH total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items 
),

total_orders AS(
SELECT COUNT(DISTINCT OrderID) as total_orders
FROM orders
),

order_value_size AS(
SELECT
	OrderID,
    order_value,
    CASE
		WHEN (rn < CEILING(total_orders * 0.25) ) THEN 'Small'
		WHEN (rn BETWEEN CEILING(total_orders * 0.25) AND CEILING(total_orders * 0.75) ) THEN 'Medium'
		WHEN (rn > CEILING(total_orders * 0.75) ) THEN 'Large'
	END as order_size
    
FROM(
	SELECT
		o.OrderID,
		SUM(oi.Quantity * oi.UnitPrice) as order_value,
		ROW_NUMBER() OVER( ORDER BY SUM(oi.Quantity * oi.UnitPrice)) as rn,
		(SELECT total_orders FROM total_orders) as total_orders
	FROM orders o 
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY o.OrderID
) as DT
),

order_categorisation as (
SELECT
	order_size,
    orders,
    revenue,
    ROUND((revenue / (SELECT total_revenue FROM total_revenue) * 100),2) as '% of revenue',
    ROUND((orders / (SELECT total_orders FROM total_orders) * 100),2) as '% of orders'
    
FROM(
	SELECT
		order_size,
		COUNT(OrderID) as orders,
		SUM(order_value) as revenue
	FROM order_value_size
	GROUP BY order_size
) as DT
)

SELECT *
FROM order_categorisation;


-- Query 123: High Value Order concentration (non-cumulative)
WITH order_value_rank AS(
SELECT
	OrderID,
    order_value,
    ROW_NUMBER() OVER( ORDER BY order_value DESC) as rn
FROM(
	SELECT  
		o.OrderID,
		SUM(oi.Quantity * oi.UnitPrice) as order_value
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY o.OrderID
    ) AS DT
),

total_orders AS(
SELECT COUNT(DISTINCT OrderID) total_orders
FROM orders
),

total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items
),

order_concentration AS(
SELECT
	categorisation,
    COUNT(OrderID) as orders,
    SUM(order_value) as revenue
    
FROM(
	SELECT
		OrderID,
		order_value,
		rn,
		CASE 
			WHEN (rn <= CEILING((SELECT total_orders FROM total_orders) * 0.01) ) THEN 'Top 1 %'
			WHEN (rn <= CEILING((SELECT total_orders FROM total_orders) * 0.05) ) THEN 'Top 5 %'
			WHEN (rn <= CEILING((SELECT total_orders FROM total_orders) * 0.1) ) THEN 'Top 10 %'
			WHEN (rn <= CEILING((SELECT total_orders FROM total_orders) * 0.25) ) THEN 'Top 25 %'
			ELSE 'Bottom 75%'
		END as categorisation
	FROM order_value_rank
) AS DT
GROUP BY categorisation
)

SELECT *, ROUND((revenue / (SELECT total_revenue FROM total_revenue) * 100),2) as revenue_contribution
FROM order_concentration;


-- Query 124: Order Status Performance
WITH order_value_status AS(
SELECT
	o.OrderID,
    SUM(oi.Quantity * oi.UnitPrice) as order_value,
    SUM(oi.Quantity) as units,
    o.OrderStatus
FROM orders o
JOIN order_items oi
	ON o.OrderID = oi.OrderID
GROUP BY o.OrderID
)

SELECT 
	OrderStatus,
    COUNT(OrderID) as orders,
    SUM(units) as units,
    SUM(order_value) as revenue,
    ROUND(SUM(order_value) / COUNT(OrderID),2) as AOV
FROM order_value_status
GROUP BY OrderStatus;


-- Query 125: Customer ordering behavior
WITH customer_orders AS(
SELECT
	c.CustomerID,
	COUNT(DISTINCT o.OrderID) as orders,
    SUM(oi.Quantity * oi.UnitPrice) as revenue
FROM customers c
LEFT JOIN orders o
	ON c.CustomerID = o.CustomerID
LEFT JOIN order_items oi
	ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID
)

SELECT *, ROUND((revenue / NULLIF(orders, 0)),2) as AOV
FROM customer_orders;


-- Query 126: Repeating vs one-time customers
WITH customer_type AS(
SELECT
	*,
    CASE
		WHEN orders = 0 THEN 'zero-order'
		WHEN orders = 1 THEN 'one-time'
		WHEN orders > 1 THEN 'repeating'
	END as customer_type
FROM(
	SELECT
		c.CustomerID,
		COUNT(DISTINCT o.OrderID) as orders,
		SUM(oi.Quantity * oi.unitPrice) as revenue
	FROM Customers c 
	LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi
		ON o.orderID = oi.OrderID
	GROUP BY c.CustomerID
    ) AS DT
)

SELECT 
	customer_type,
    COUNT(CustomerID) as customers,
    SUM(orders) as orders,
    COALESCE(SUM(revenue),0) as revenue,
    COALESCE(ROUND( (SUM(revenue) /  COUNT(CustomerID) ),2),0) as revenue_per_customer

FROM customer_type
GROUP BY customer_type;


-- Query 127: Order Frequency vs Customer Value
WITH order_frequency AS(
SELECT
	*,
    CASE
    WHEN orders = 0 THEN 0
    WHEN orders BETWEEN 1 AND 5 THEN'1-5'
    WHEN orders BETWEEN 6 AND 20 THEN '6-20'
    WHEN orders BETWEEN 21 AND 50 THEN '21-50'
    ELSE '50+'
    END AS order_frequency
    
FROM(
	SELECT
		c.CustomerID,
		COUNT(DISTINCT o.OrderID) as orders,
		SUM(oi.Quantity * oi.unitPrice) as revenue
	FROM Customers c 
	LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi
		ON o.orderID = oi.OrderID
	GROUP BY c.CustomerID
) as DT
)

SELECT
	order_frequency,
    COUNT(CustomerID) as customers,
    SUM(orders) as total_orders,
    COALESCE(SUM(revenue),0) as revenue,
    COALESCE(ROUND(SUM(revenue) / COUNT(CustomerID),2),0) as revenue_per_customer,
    COALESCE(ROUND(SUM(revenue) / SUM(orders),2),0)  as AOV
    
FROM order_frequency
GROUP BY order_frequency


-- Query 128: Revenue Concentration by Customer Segment
WITH total_revenue AS(
SELECT SUM(Quantity * UnitPrice) as total_revenue
FROM order_items
),

segment_concentration AS(
SELECT
	CustomerSegment,
    revenue,
    ROUND((revenue/ (SELECT total_revenue FROM total_revenue) * 100),2) as revenue_pct
FROM(
	SELECT 
		c.CustomerSegment,
		SUM(oi.Quantity * oi.UnitPrice) as revenue
	FROM Customers c
	JOIN orders o
		ON c.CustomerID = o.CustomerID
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY c.CustomerSegment
) as DT
)

SELECT
	*,
    ROUND(
        (
            (SUM(revenue) OVER(ORDER BY revenue DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) 
            / (SELECT total_revenue FROM total_revenue) 
            *100
        )
    ,2) as cumulative_revenue_pct
FROM segment_concentration;


-- Query 129: Best-Performing Periods
WITH period_analysis AS(
SELECT
	period,
    orders,
    units,
    revenue,
    RANK() OVER(ORDER BY revenue DESC) as revenue_rank
FROM(
	SELECT 
		DATE_FORMAT(o.OrderDate, '%Y-%m') as period,
		COUNT(DISTINCT o.OrderID) as orders,
		SUM(oi.Quantity) as units,
		SUM(oi.Quantity * oi.UnitPrice) as revenue
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
) as DT
)

SELECT *
FROM period_analysis
LIMIT 10;


-- Query 130: Sales Performance Classification
WITH period_analysis AS(
SELECT
	period,
    orders,
    revenue,
    ROUND((revenue/orders),2) as AOV,
    COALESCE(ROUND(((revenue - LAG(revenue) OVER(ORDER BY period)) / LAG(revenue) OVER(ORDER BY period) * 100),2),0) as mom_growth
FROM(
	SELECT 
		DATE_FORMAT(o.OrderDate, '%Y-%m') as period,
		COUNT(DISTINCT o.OrderID) as orders,
		SUM(oi.Quantity * oi.UnitPrice) as revenue
	FROM orders o
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY DATE_FORMAT(o.OrderDate, '%Y-%m')
) as DT
),

avg_revenue AS(
SELECT AVG(revenue) as avg_revenue
FROM period_analysis
),

avg_orders AS (
SELECT AVG(orders) as avg_orders
FROM period_analysis
),

avg_AOV AS(
SELECT AVG(AOV) as avg_AOV
FROM period_analysis
)

SELECT 
	*,
	CASE
		WHEN revenue > (SELECT avg_revenue FROM avg_revenue)
		 AND mom_growth > 0
		 AND orders > (SELECT avg_orders FROM avg_orders)
		 AND AOV > (SELECT avg_AOV from avg_AOV)
			THEN 'Excellent'

		WHEN revenue > (SELECT avg_revenue FROM avg_revenue)
		 AND mom_growth > 0
		 AND (orders > (SELECT avg_orders FROM avg_orders) OR AOV > (SELECT avg_AOV from avg_AOV))
			THEN 'Strong'

		WHEN revenue > (SELECT avg_revenue FROM avg_revenue)
		 OR mom_growth > 0
		 OR orders > (SELECT avg_orders FROM avg_orders)
		 OR AOV > (SELECT avg_AOV from avg_AOV)
			THEN 'Average'

		ELSE 'Weak'
	END AS performance_category
    
FROM period_analysis




/* ============================================================
   CHAPTER 5 SUMMARY — SALES & ORDER ANALYSIS
   ============================================================

   OBJECTIVE:
   Analyze overall sales performance, order-value behavior,
   sales trends, customer ordering patterns, revenue
   concentration, order status, and period-level performance
   to identify key sales drivers and performance patterns.

   KEY ANALYSIS AREAS COVERED:
   1. Sales overview and order-value distribution
      - Total orders, units sold, revenue, AOV, and average
        units per order
      - Minimum, maximum, average, median, Q1, Q3, and IQR
        of order values

   2. Monthly sales and growth analysis
      - Monthly orders, units, revenue, and AOV
      - Month-over-month revenue growth using LAG()

   3. Customer segment performance
      - Revenue, orders, AOV, and revenue contribution
        across customer segments

   4. Order size analysis
      - Classification of orders into Small, Medium, and Large
        based on their ranked order-value positions
      - Comparison of order volume and revenue contribution

   5. High-value order concentration
      - Revenue generated by the Top 1%, 5%, 10%, and 25%
        of orders
      - Comparison with the remaining Bottom 75%

   6. Order status performance
      - Orders, units, revenue, and AOV across different
        order statuses

   7. Customer ordering behavior
      - Orders and total spending by customer
      - Customer-level AOV

   8. Repeat versus one-time customers
      - Classification into zero-order, one-time, and
        repeating customers
      - Comparison of customer count, orders, revenue, and
        revenue per customer

   9. Order frequency versus customer value
      - Customer grouping by order-frequency ranges
      - Comparison of customer count, total orders, revenue,
        revenue per customer, and AOV

   10. Revenue concentration by customer segment
       - Segment-level revenue contribution
       - Cumulative revenue contribution using a
         Pareto-style analysis

   11. Best-performing sales periods
       - Monthly order volume, units, and revenue
       - Ranking of periods by revenue

   12. Sales performance classification
       - Combined revenue, MoM growth, order volume, and AOV
         analysis
       - Classification of periods into Excellent, Strong,
         Average, and Weak performance categories

   OUTCOME:
   This chapter provides a comprehensive view of sales and
   order performance by connecting order economics, sales
   trends, customer behavior, revenue concentration, and
   performance indicators. It helps identify high-value
   orders, important customer groups, strong sales periods,
   revenue concentration patterns, and periods requiring
   further performance attention.

   ============================================================ */
