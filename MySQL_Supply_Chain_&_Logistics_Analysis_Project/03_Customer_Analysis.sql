
-- Query 72: Total customers
SELECT COUNT(*) as customer_count
FROM customers;


-- Query 73: Customers by industry
SELECT Industry, COUNT(*) as customer_count
FROM customers
GROUP BY Industry
ORDER BY customer_count DESC;


-- Query 74: Customers by region
SELECT Region, COUNT(*) as customer_count
FROM customers
GROUP BY Region
ORDER BY customer_count DESC;


-- Query 75: Customers by customer segment
SELECT CustomerSegment, COUNT(*) as customer_count
FROM customers
GROUP BY CustomerSegment
ORDER BY customer_count DESC;


-- Query 76: Customer acquisition by year
SELECT YEAR(signupDate) as Year, COUNT(*) as customer_count
FROM customers
GROUP BY Year
ORDER BY Year;


-- Query 77: Orders per customer
SELECT c.CustomerID, c.CustomerName, COUNT(*) as order_count
FROM customers c JOIN orders o
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID, c.CustomerName
ORDER BY order_count DESC;


-- Query 78: Average orders per customer
SELECT AVG(order_count) as Avg_order_count
FROM (
SELECT c.CustomerID, COUNT(*) as order_count
FROM customers c JOIN orders o
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID) as t1;


-- Query 79: Customers with no orders
SELECT c.CustomerID, c.CustomerName
FROM customers c LEFT JOIN orders o
ON c.CustomerID = o.CustomerID
WHERE o.OrderID IS NULL;


-- Query 80: Top customers by order count
SELECT c.CustomerID, c.CustomerName, COUNT(*) AS order_count
FROM customers c JOIN orders o 
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerID
ORDER BY order_count DESC
LIMIT 10;


-- Query 81: Order frequency distribution
SELECT order_range, COUNT(*) AS customer_count
FROM(
	SELECT
		CASE
        WHEN COUNT(o.orderID) = 0 THEN '0'
        WHEN COUNT(o.orderID) BETWEEN 1 AND 100 THEN '1-100'
        WHEN COUNT(o.orderID) BETWEEN 101 AND 250 THEN '101-250'
        WHEN COUNT(o.orderID) BETWEEN 251 AND 500 THEN '251-500'
        WHEN COUNT(o.orderID) BETWEEN 501 AND 1000 THEN '501-1000'
        WHEN COUNT(o.orderID) BETWEEN 1001 AND 2000 THEN '1001-2000'
        ELSE '2000+'
        END as order_range
    FROM customers c LEFT JOIN orders o
    ON c.CustomerID = o.CustomerID
    GROUP BY c.CustomerID
) AS tt
GROUP BY order_range
ORDER BY customer_count DESC;


-- Query 82: Total spending per customer
SELECT CustomerID, SUM(order_amount) as total_customer_spending
FROM(SELECT o.CustomerID ,oi.OrderID, SUM(Quantity*UnitPrice) as order_amount
	FROM order_items oi JOIN orders o
    ON oi.OrderId = o.OrderId
	GROUP BY o.CustomerID, oi.OrderID) as tt
GROUP BY CustomerID
ORDER BY total_customer_spending DESC;


-- Query 83: Average order value per customer
SELECT CustomerID, ROUND(AVG(order_amount),2) as Avg_order_spending
FROM(SELECT o.CustomerID ,oi.OrderID, SUM(Quantity*UnitPrice) as order_amount
	FROM order_items oi JOIN orders o
    ON oi.OrderId = o.OrderId
	GROUP BY o.CustomerID, oi.OrderID) as tt
GROUP BY CustomerID
ORDER BY Avg_order_spending DESC;


-- Query 84: Minimum and maximum order value per customer
SELECT CustomerID, MIN(order_amount) as Min_order_amount, MAX(order_amount) as Max_order_amount
FROM(SELECT o.CustomerID ,oi.OrderID, SUM(Quantity*UnitPrice) as order_amount
	FROM order_items oi JOIN orders o
    ON oi.OrderId = o.OrderId
	GROUP BY o.CustomerID, oi.OrderID) as tt
GROUP BY CustomerID


-- Query 85: Top Cutomers by total spending
SELECT CustomerID, SUM(order_amount) as total_customer_spending
FROM(SELECT o.CustomerID ,oi.OrderID, SUM(Quantity*UnitPrice) as order_amount
	FROM order_items oi JOIN orders o
    ON oi.OrderId = o.OrderId
	GROUP BY o.CustomerID, oi.OrderID) as tt
GROUP BY CustomerID
ORDER BY total_customer_spending DESC
LIMIT 10;


-- Query 86:  Customer spending distribution
SELECT spending_range, COUNT(*) as customer_count
FROM(SELECT CASE
			WHEN SUM(Quantity * UnitPrice) BETWEEN 1 AND 10000 THEN '1-10k'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 10001 AND 100000 THEN '10k-100k'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 100001 AND 1000000 THEN '100k-1M'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 1000001 AND 5000000 THEN '1M-5M'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 5000001 AND 10000000 THEN '5M-10M'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 10000001 AND 25000000 THEN '10M-25M'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 25000001 AND 50000000 THEN '25M-50M'
			WHEN SUM(Quantity * UnitPrice) BETWEEN 50000001 AND 70000000 THEN '50M-70M'
			ELSE '70M+'
			END AS spending_range
	FROM order_items oi JOIN orders o
    ON oi.OrderId = o.OrderId
	GROUP BY o.CustomerID) as tt
GROUP BY spending_range;


-- Query 87: Total units purchased per customer
SELECT o.CustomerID, SUM(quantity) as total_units_purchased
FROM order_items oi JOIN orders o
on oi.OrderID = o.OrderID
GROUP BY o.CustomerID
ORDER BY total_units_purchased DESC;


-- Query 88: Unique products purchased per customer
SELECT o.CustomerID, COUNT(DISTINCT ProductID) as Unique_products_purchased
FROM order_items oi JOIN orders o
on oi.OrderID = o.OrderID
GROUP BY o.CustomerID
ORDER BY Unique_products_purchased DESC;


-- Query 89: Most purchased products by customer
SELECT CustomerID, ProductID, quantity_count
FROM(
	SELECT o.CustomerID, oi.ProductID, SUM(Quantity) as quantity_count, RANK() OVER( PARTITION BY o.CustomerID ORDER BY SUM(Quantity) DESC) AS product_rank
	FROM order_items oi JOIN orders o
	ON oi.OrderID = o.OrderID
	GROUP BY o.CustomerID, oi.ProductID) as customer_products
WHERE product_rank = 1;


-- Query 90: Customer purchase quantity distribution
SELECT
	purchased_quantity_range, COUNT(*) as customer_count
FROM(
	SELECT
		CASE
			WHEN SUM(Quantity) = 0 THEN '0'
			WHEN SUM(Quantity) BETWEEN 1 AND 100 THEN '1-100'
			WHEN SUM(Quantity) BETWEEN 101 AND 500 THEN '101-500'
			WHEN SUM(Quantity) BETWEEN 501 AND 1000 THEN '501-1000'
			WHEN SUM(Quantity) BETWEEN 1001 AND 2500 THEN '1001-2500'
			WHEN SUM(Quantity) BETWEEN 2501 AND 5000 THEN '2501-5000'
			WHEN SUM(Quantity) BETWEEN 5001 AND 10000 THEN '5001-10000'
			WHEN SUM(Quantity) BETWEEN 10001 AND 25000 THEN '10001-25000'
			WHEN SUM(Quantity) BETWEEN 25001 AND 50000 THEN '25001-50000'
			WHEN SUM(Quantity) BETWEEN 50001 AND 100000 THEN '50001-100000'
			ELSE '100001+'
		END purchased_quantity_range
	FROM order_items oi JOIN orders o
	ON oi.OrderID = o.OrderID
	GROUP BY o.CustomerID
) as DT
    
GROUP BY purchased_quantity_range;


-- Query 91: Average number of unique products purchased
SELECT AVG(distinct_product_purchased) Avg_unique_products_purchase
FROM(
    SELECT o.CustomerID, COUNT( DISTINCT oi.ProductID) as distinct_product_purchased
	FROM order_items oi JOIN orders o
	ON oi.OrderID = o.OrderID
	GROUP BY o.CustomerID
) AS DT;


-- Query 92: Customer count by segments
SELECT CustomerSegment as segment, COUNT(*) as customer_count
FROM customers
GROUP BY CustomerSegment
ORDER BY customer_count desc;


-- Query 93: Order by Customer Segment
SELECT c.CustomerSegment, COUNT(o.OrderID) as order_count
FROM Customers c JOIN orders o
ON c.CustomerID = o.CustomerID
GROUP BY c.CustomerSegment
ORDER BY order_count DESC;


-- Query 94: total spending by segment
SELECT c.CustomerSegment, SUM(oi.Quantity * oi.UnitPrice) as total_spending
FROM customers c
JOIN orders o
	ON c.CustomerID = o.CustomerID
JOIN order_items oi
	ON o.OrderID = oi.OrderID  
GROUP BY c.CustomerSegment
ORDER BY total_spending DESC;


-- Query 95: Average order value by customer segment
SELECT CustomerSegment, ROUND(AVG(order_value),2) as avg_order_value
FROM(
	SELECT
		c.CustomerSegment, o.OrderID, SUM(oi.Quantity * oi.UnitPrice) as order_value
	FROM customers c
	JOIN orders o
		ON c.CustomerID = o.CustomerID
	JOIN order_items oi
		ON o.OrderID = oi.OrderID
		
	GROUP BY c.CustomerSegment, o.OrderID ) as DT
GROUP BY CustomerSegment;


-- Query 96: Average orders per customer by segment
SELECT CustomerSegment, ROUND(order_count/customer_count,2) as avg_order_per_customer
FROM(
	SELECT c.CustomerSegment, COUNT(DISTINCT c.CustomerID) as customer_count, COUNT(o.OrderID) as order_count
	FROM customers c LEFT JOIN orders o
	ON c.CustomerID = o.CustomerID
	GROUP BY c.CustomerSegment) AS DT
ORDER BY avg_order_per_customer DESC;


-- Query 97: Customer spending as % of total revenue
WITH total_revenue AS(
	SELECT SUM(Quantity*UnitPrice)
    FROM order_items
)

SELECT CustomerID, CustomerName, CONCAT( ROUND(customer_revenue/( SELECT * FROM total_revenue ) * 100 ,2), " %")   AS customer_revenue_contribution
FROM(
	SELECT c.CustomerID, c.CustomerName, SUM(oi.quantity * oi.UnitPrice) as customer_revenue
    FROM customers c
    LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID 
    LEFT JOIN order_items oi
		ON o.OrderID = oi.OrderID 
	GROUP BY c.CustomerID) AS DT
ORDER BY customer_revenue_contribution DESC;


-- Query 98: top 10 contribution % in total revenue
WITH total_revenue AS(
	SELECT SUM(Quantity*UnitPrice) AS total_revenue
    FROM order_items
),

top_10_revenue AS(
	SELECT SUM(customer_revenue) AS top_10_revenue
	FROM(
		SELECT c.CustomerID, SUM(oi.Quantity * oi.UnitPrice) AS customer_revenue
		FROM 
			customers c 
			LEFT JOIN orders o 
				ON c.CustomerID = o.CustomerID
			LEFT JOIN order_items oi 
				ON o.OrderID = oi.OrderID
				
		GROUP BY c.CustomerID
        ORDER BY customer_revenue DESC
        LIMIT 10
	) AS DT
)

SELECT  CONCAT( ROUND(( SELECT * FROM top_10_revenue )/( SELECT * FROM total_revenue ) * 100 ,2), " %")   AS top_10_customers_contribution;


-- Query 99: Top 10 Customers by revenue
SELECT c.CustomerID, c.CustomerName, SUM(oi.Quantity * oi.UnitPrice) AS total_spending
FROM 
	customers c 
	LEFT JOIN orders o 
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi 
		ON o.OrderID = oi.OrderID
		
GROUP BY c.CustomerID, c.CustomerName
ORDER BY total_spending DESC
LIMIT 10;


-- Query 100: Avg total spend by customers
WITH customer_spend AS (
SELECT SUM(oi.Quantity * oi.UnitPrice) as spend
FROM customers c
LEFT JOIN orders o
	ON c.CustomerID = o.CustomerID
LEFT JOIN order_items oi
	ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID, c.CustomerName
)

SELECT ROUND(AVG(spend),2) as avg_customer_spend
FROM customer_spend;


-- Query 101: Revenue Rank + Cumulative Revenue Contribution
WITH total_spend AS (
SELECT SUM(Quantity * UnitPrice) as total_spend
FROM order_items
),

customer_spend AS(
SELECT
	c.CustomerID, 
    SUM(oi.Quantity * oi.UnitPrice) as customer_spend

FROM customers c
LEFT JOIN orders o
	ON c.CustomerID = o.CustomerID
LEFT JOIN order_items oi
	ON o.OrderID = oi.OrderID
GROUP BY c.CustomerID
)

SELECT 
	CustomerID, 
    customer_spend, 
    RANK() OVER(ORDER BY customer_spend DESC) as spend_rank, 
    CONCAT(ROUND((SUM(customer_spend) OVER(
		ORDER BY customer_spend DESC
		ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
	)/(SELECT * FROM total_spend) * 100),2), ' %')  as cumulative_contribution
    
FROM customer_spend;


-- Query 102: Revenue contribution by customer decile
WITH total_spend AS (
SELECT SUM(Quantity * UnitPrice) as total_spend
FROM order_items
),

customer_spend_rank_decile AS(
SELECT 
	CustomerID, customer_spend, 
    RANK() OVER( ORDER BY customer_spend DESC) as spend_rank, 
    NTILE(10) OVER( ORDER BY customer_spend DESC) as decile
FROM(
	SELECT
		c.CustomerID, 
		SUM(oi.Quantity * oi.UnitPrice) as customer_spend
	FROM customers c
	LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY c.CustomerID ) AS DT
)

SELECT decile, COUNT(*) as customer_count, SUM(customer_spend) as total_spend, CONCAT(ROUND((SUM(customer_spend)/(SELECT * FROM total_spend) * 100),2),  ' %') as contribution
FROM customer_spend_rank_decile
GROUP BY decile
ORDER BY decile;


-- Query 103: Total-spend, total-orders, average-order-value by customer
WITH customer_spend_orders AS(
SELECT 
	CustomerID, customer_spend, order_count

FROM(
	SELECT
		c.CustomerID, 
		SUM(oi.Quantity * oi.UnitPrice) as customer_spend,
        COUNT(DISTINCT o.OrderID) as order_count
	FROM customers c
	LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY c.CustomerID ) AS DT
)

SELECT 
	CustomerID, 
    CONCAT('₹ ',customer_spend) as total_spend, 
    order_count, 
    CONCAT('₹ ',ROUND(AVG(customer_spend / NULLIF(order_count, 0)),2)) avg_order_value
FROM customer_spend_orders
GROUP BY CustomerID
ORDER BY total_spend DESC;


-- Query 104: Customer value classification
WITH customer_spend_orders AS(
SELECT 
	CustomerID, customer_spend, order_count

FROM(
	SELECT
		c.CustomerID, 
		SUM(oi.Quantity * oi.UnitPrice) as customer_spend,
        COUNT(DISTINCT o.OrderID) as order_count
	FROM customers c
	LEFT JOIN orders o
		ON c.CustomerID = o.CustomerID
	LEFT JOIN order_items oi
		ON o.OrderID = oi.OrderID
	GROUP BY c.CustomerID ) AS DT
),

median_spend AS (
SELECT 92074.99 as median_spend
),

median_order_count AS (
SELECT 8 as median_order_count
)

SELECT *,
	CASE
		WHEN customer_spend >= (SELECT median_spend FROM median_spend)
			 AND order_count >= (SELECT median_order_count FROM median_order_count)
			THEN 'High Value / High Frequency'

		WHEN customer_spend >= (SELECT median_spend FROM median_spend)
			 AND order_count < (SELECT median_order_count FROM median_order_count)
			THEN 'High Value / Low Frequency'

		WHEN customer_spend < (SELECT median_spend FROM median_spend)
			 AND order_count >= (SELECT median_order_count FROM median_order_count)
			THEN 'Low Value / High Frequency'

		ELSE 'Low Value / Low Frequency'
	END AS customer_classification
    
FROM(
	SELECT 
		CustomerID, 
		customer_spend, 
		order_count, 
		ROUND(AVG(customer_spend / NULLIF(order_count, 0)),2) AS avg_order_value
	FROM customer_spend_orders
	GROUP BY CustomerID
	ORDER BY customer_spend DESC
) AS DT2;





     /*
=========================================================
CHAPTER 3 SUMMARY — CUSTOMER ANALYSIS
=========================================================

Objective:
Analyze customer purchasing behavior, spending patterns,
order frequency, revenue contribution, and customer value
to understand customer importance and segmentation.

Key Customer Analysis Areas Covered:

1. Customer Overview
   - Total customer count
   - Customer distribution by Segment
   - Customer distribution by Industry
   - Customer distribution by Region
   - Customer acquisition trends over time

2. Customer Order Behavior
   - Orders per customer
   - Average orders per customer
   - Customers with no orders
   - Top customers by order count
   - Order frequency distribution

3. Customer Spending Behavior
   - Total spending per customer
   - Average order value per customer
   - Minimum order value per customer
   - Maximum order value per customer
   - Top customers by total spending
   - Customer spending distribution

4. Customer Purchase Behavior
   - Total units purchased per customer
   - Unique products purchased per customer
   - Most purchased product for each customer
   - Customer purchase quantity distribution
   - Average number of unique products purchased

5. Customer Segment Performance
   - Customer count by segment
   - Orders by customer segment
   - Total spending by customer segment
   - Average order value by customer segment
   - Average orders per customer by segment

6. Customer Revenue Contribution
   - Individual customer spending as a percentage of total revenue
   - Top 10 customers' contribution to total revenue
   - Top customers ranked by revenue
   - Average total customer spending

7. Customer Value Segmentation
   - Customer revenue ranking
   - Cumulative revenue contribution by customer
   - Revenue contribution by customer decile
   - Customer spending and order-frequency metrics
   - High Value / High Frequency customers
   - High Value / Low Frequency customers
   - Low Value / High Frequency customers
   - Low Value / Low Frequency customers

8. Advanced SQL Concepts Applied
   - Multi-table joins across Customers, Orders, and Order_Items
   - Customer-level aggregation
   - Nested subqueries
   - Common Table Expressions (CTEs)
   - CASE-based classification
   - Window functions
   - RANK()
   - NTILE()
   - Cumulative SUM() using window frames
   - DISTINCT counting
   - Median-based customer classification

Outcome:
A complete understanding of customer purchasing behavior,
spending concentration, order frequency, product purchasing
patterns, segment-level performance, and customer value,
providing the foundation for deeper customer and business
analysis in subsequent chapters.

=========================================================
*/