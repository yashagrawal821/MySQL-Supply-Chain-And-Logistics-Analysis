-- Query 26: Overall dataset scale
 SELECT
    (SELECT COUNT(*) FROM customers) AS customers,
    (SELECT COUNT(*) FROM products) AS products,
    (SELECT COUNT(*) FROM suppliers) AS suppliers,
    (SELECT COUNT(*) FROM warehouses) AS warehouses,
    (SELECT COUNT(*) FROM orders) AS orders,
    (SELECT COUNT(*) FROM order_items) AS order_items,
    (SELECT COUNT(*) FROM shipments) AS shipments,
    (SELECT COUNT(*) FROM inventory_transactions) AS inventory_transactions;


-- Query 27: Products by category
SELECT Category, COUNT(*) as product_count
FROM products
GROUP BY Category
ORDER BY product_count DESC;


-- Query 28: Products by SubCategory
SELECT SubCategory, COUNT(*) AS product_count
FROM products
GROUP BY SubCategory
ORDER BY product_count DESC;


-- Query 29: Products by brand
SELECT Brand, COUNT(*) as product_count
FROM products
GROUP BY Brand
ORDER BY product_count DESC;


-- Query 30: Average/min/max UnitCost
SELECT ROUND(AVG(UnitCost),2) as AvgUnitCost, ROUND(MIN(UnitCost),2) as MinUnitCost, ROUND(MAX(UnitCost),2) as MaxUnitCost
FROM products;


-- Query 31: Average/min/max UnitPrice
SELECT ROUND(AVG(UnitPrice),2) as AvgUnitPrice, ROUND(MIN(UnitPrice),2) as MinUnitPrice, ROUND(MAX(UnitPrice),2) as MaxUnitPrice
FROM products;


-- Query 32: Average/min/max WeightKg
SELECT ROUND(AVG(WeightKg),2) as AvgWeight, ROUND(MIN(WeightKg),2) as MinWeight, ROUND(MAX(WeightKg),2) as MaxWeight
FROM products;


-- Query 33: Selling price as percentage of unit cost
SELECT ProductName, ROUND(UnitPrice / UnitCost * 100, 2) AS Price_As_Percent_Of_Cost
FROM products
ORDER BY Price_As_Percent_Of_Cost DESC;


-- Query 34: Discontinued and active products
SELECT DiscontinuedFlag , COUNT(*) as product_count
FROM products
GROUP BY DiscontinuedFlag
ORDER BY DiscontinuedFlag;


-- Query 35: Customer Distribution by Industry
SELECT Industry, COUNT(*) as Customer_count
FROM customers
GROUP BY Industry
ORDER BY Customer_count DESC;


-- Query 36: Customers by region
SELECT Region, COUNT(*) as Customer_count
FROM customers
GROUP BY Region
ORDER BY Customer_count DESC;


-- Query 37: Customers by segment
SELECT CustomerSegment, COUNT(*) as Customer_count
FROM customers
GROUP BY CustomerSegment
ORDER BY Customer_count DESC;


-- Query 38: Customer signup date range
SELECT MIN(SignupDate) as Earliest_signup, MAX(SignupDate) as Latest_signup
FROM customers;


-- Query 39: Customers acquired by year
SELECT YEAR(SignupDate) as Year, COUNT(*) as customer_count
FROM customers
GROUP BY YEAR(SignupDate) 
ORDER BY Year;


-- Query 40: Customer segments by signup year
SELECT YEAR(SignupDate) as Year, CustomerSegment as Segment, COUNT(*) as customer_count
FROM customers
GROUP BY YEAR(SignupDate), CustomerSegment
ORDER BY Year, customer_count DESC;


-- Query 41: Suppliers by region
SELECT Region, COUNT(*) as suppliers_count
FROM suppliers
GROUP BY Region
ORDER BY suppliers_count DESC;


-- Query 42: Suppliers by SupplierType
SELECT SupplierType, COUNT(*) as supplier_count
FROM suppliers
GROUP BY SupplierType
ORDER BY supplier_count DESC;


-- Query 43: Supplier product coverage
SELECT SupplierName, COUNT(*) as product_count
FROM supplier_products sp JOIN suppliers s
ON sp.SupplierID = s.SupplierID
GROUP BY SupplierName
ORDER BY product_count DESC;


-- Query 44: Average supplier lead time
SELECT SupplierName, ROUND(AVG(LeadTimeDays),0) as AvgLeadTimeDays
FROM supplier_products sp JOIN suppliers s
ON sp.SupplierID = s.SupplierID
GROUP BY SupplierName
ORDER BY AvgLeadTimeDays DESC;


-- Query 45: suppliers per products
SELECT ProductName, count(*) as supplier_count
FROM supplier_products sp JOIN products p
ON sp.productID = p.productID
GROUP BY ProductName
ORDER BY supplier_count DESC;


-- Query 46: warehouse by region
SELECT Region, COUNT(*) as warehouse_count
FROM warehouses
GROUP BY Region
ORDER BY warehouse_count DESC;


-- Query 47: Product Coverage per warehouse
SELECT WarehouseName, COUNT(*) as product_count
FROM warehouse_products wp JOIN warehouses w
On wp.WarehouseID = w.WarehouseID
GROUP BY WarehouseName
ORDER BY product_count DESC;


-- Query 48: Initial stock per warehouse
SELECT WarehouseName, SUM(InitialStock) as net_inventory_stock
FROM warehouse_products wp JOIN warehouses w
ON wp.WarehouseID = w.WarehouseID
GROUP BY WarehouseName
ORDER BY net_inventory_stock DESC;


-- Query 49: Average initial stock per warehouse-product
SELECT WarehouseName, COUNT(*) as product_count, ROUND(AVG(InitialStock),2) as avg_initial_stock
FROM warehouse_products wp JOIN warehouses w
ON wp.WarehouseID = w.WarehouseID
GROUP BY WarehouseName
ORDER BY avg_initial_stock DESC;


-- Query 50: Orders by status
SELECT OrderStatus, COUNT(*) as order_count
FROM orders
GROUP BY OrderStatus
ORDER BY order_count DESC;


-- Query 51: Orders by year
SELECT YEAR(OrderDate) as Year, COUNT(*) as order_count
FROM orders
GROUP BY YEAR(OrderDate)
ORDER BY Year;


-- Query 52: Average items per order
SELECT
	ROUND(AVG(items_count),2) as AvgItemsCount,
    MIN(items_count) as MinItemsCount,
    MAX(items_count) as MaxItemsCount
FROM (
	SELECT OrderID, COUNT(*) AS items_count
    FROM order_items
    GROUP BY OrderID
    ORDER BY items_count DESC
    ) AS order_summary


-- Query 53: Average, minimum, and maximum order value
SELECT 
    ROUND(AVG(Total_amount), 2) AS AvgTotalAmount,
    MIN(Total_amount) AS MinTotalAmount,
    MAX(Total_amount) AS MaxTotalAmount
FROM (
    SELECT
        OrderID,
        SUM(Quantity * UnitPrice) AS Total_amount
    FROM order_items
    GROUP BY OrderID
) AS order_summary;


-- Query 54: Order size distribution
SELECT items_count, COUNT(*) as order_count
FROM (
	SELECT OrderID, COUNT(*) as items_count
    FROM order_items
    GROUP BY OrderID
    ) as order_summary
GROUP BY items_count
ORDER BY items_count;


-- Query 55: Orders by customer segment
SELECT c.CustomerSegment, COUNT(*) as order_count
FROM orders o JOIN customers c
ON o.CustomerID = c.CustomerID 
GROUP BY c.CustomerSegment
ORDER BY order_count DESC;


-- Query 56: Transactions by Type
SELECT TransactionType, COUNT(*) as transaction_count
FROM inventory_transactions
GROUP BY TransactionType
ORDER BY transaction_count DESC;


-- Query 57: Inbound vs Outbound Transactions
SELECT 
	SUM(CASE WHEN Quantity > 0 THEN 1 ELSE 0 END) AS InboundTrans,
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS OutboundTrans
FROM inventory_transactions;


-- Query 58: Total inbound vs outbound units
SELECT 
	SUM(CASE WHEN Quantity > 0 THEN Quantity ELSE 0 END) AS Total_inbound_units,
    ABS(SUM(CASE WHEN Quantity < 0 THEN Quantity ELSE 0 END)) AS Total_outbound_units
FROM inventory_transactions;


-- Query 59: Transactions by year
SELECT YEAR(TransactionDate) as Year, COUNT(*) as transaction_count
FROM inventory_transactions
GROUP BY YEAR(TransactionDate)
ORDER BY Year;


-- Query 60: Transactions by warehouse
SELECT WarehouseName, COUNT(*) AS transaction_count
FROM inventory_transactions it JOIN warehouses w
ON it.WarehouseID = w.WarehouseID
GROUP BY WarehouseName
ORDER BY transaction_count DESC;


-- Query 61: Transactions by product
SELECT ProductName, COUNT(*) AS transaction_count
FROM inventory_transactions it JOIN products p
ON it.ProductID = p.ProductID
GROUP BY ProductName
ORDER BY transaction_count DESC;


-- Query 62: Average Movement quantity
SELECT
    ROUND(AVG(ABS(Quantity)), 2) AS AvgMovingQuantity
FROM inventory_transactions;


-- Query 63: Inventory movement quantity distribution - by value
SELECT
    ABS(Quantity) AS movement_quantity,
    COUNT(*) AS transactions_count
FROM inventory_transactions
GROUP BY ABS(Quantity)
ORDER BY movement_quantity;


-- Query 64: Inventory movement quantity distribution - by Range
SELECT movement_quantity_range, COUNT(*) as transaction_count
FROM (
	SELECT
		CASE
        WHEN ABS(Quantity) BETWEEN 1 AND 10 THEN '1-10'
        WHEN ABS(Quantity) BETWEEN 11 AND 25 THEN '11-25'
        WHEN ABS(Quantity) BETWEEN 26 AND 50 THEN '26-50'
        WHEN ABS(Quantity) BETWEEN 51 AND 100 THEN '51-100'
        WHEN ABS(Quantity) BETWEEN 101 AND 250 THEN '101-250'
        WHEN ABS(Quantity) BETWEEN 251 AND 500 THEN '251-500'
        WHEN ABS(Quantity) BETWEEN 501 AND 1000 THEN '501-1000'
        ELSE '1000+' 
        END AS movement_quantity_range
	FROM inventory_transactions
) AS quantity_range
GROUP BY movement_quantity_range;


-- Query 65: Product with highest total inventory movement
SELECT
    ProductName,
    total_movement_quantity
FROM (
    SELECT
        ProductName,
        SUM(ABS(Quantity)) AS total_movement_quantity
    FROM inventory_transactions it
    JOIN products p
        ON it.ProductID = p.ProductID
    GROUP BY ProductName
) AS movement_summary
ORDER BY total_movement_quantity DESC
LIMIT 1;


-- Query 66: Inventory movement by transaction type and direction
SELECT
    TransactionType,
    CASE
        WHEN Quantity > 0 THEN 'Inbound'
        WHEN Quantity < 0 THEN 'Outbound'
        ELSE 'Zero'
    END AS movement_direction,
    COUNT(*) AS transaction_count,
    SUM(ABS(Quantity)) AS movement_units
FROM inventory_transactions
GROUP BY
    TransactionType,
    movement_direction
ORDER BY
    TransactionType,
    movement_direction;


-- Query 67: Shipment status distribution
SELECT ShipmentStatus, COUNT(*) AS shipment_count
FROM shipments
GROUP BY ShipmentStatus
ORDER BY shipment_count DESC;    


-- Query 68: Shipment Carrier distribution
SELECT Carrier, COUNT(*) AS shipment_count
FROM shipments
GROUP BY Carrier
ORDER BY shipment_count DESC;


-- Query 69: Average delivery time (days)
SELECT ROUND(AVG(DATEDIFF(ActualDeliveryDate, ShipmentDate)),2) AS AvgDeliveryDays
FROM shipments;


-- Query 70: Average Actual vs Expected delivery gap   //positive = late, negative = early, zero = on time
SELECT ROUND(AVG(DATEDIFF(ActualDeliveryDate, ExpectedDeliveryDate)),2) as Avg_Actual_vs_Expected_delivery_gap
FROM shipments;


-- Query 71: Shipments by year
SELECT YEAR(ShipmentDate) as Year, COUNT(*) AS shipment_count
FROM shipments
GROUP BY YEAR(ShipmentDate)
ORDER BY Year;




/*
=========================================================
CHAPTER 2 SUMMARY — DATA PROFILING
=========================================================

Objective:
Profile the structure, distribution, and characteristics
of the supply chain dataset before performing business
analysis.

Key Profiling Areas Covered:

1. Dataset Overview
   - Row counts for all major tables
   - Overall dataset scale and structure

2. Product Profile
   - Product distribution by Category
   - Product distribution by SubCategory
   - Product distribution by Brand
   - Unit Cost statistics
   - Unit Price statistics
   - Weight statistics
   - Price-to-Cost relationship
   - Active vs Discontinued products

3. Customer Profile
   - Customer distribution by Industry
   - Customer distribution by Region
   - Customer distribution by Segment
   - Customer creation trends over time

4. Supplier Profile
   - Supplier distribution by Region
   - Supplier distribution by Supplier Type
   - Supplier product coverage
   - Average supplier lead times
   - Supplier count per product

5. Warehouse Profile
   - Warehouse distribution by Region
   - Product coverage by warehouse
   - Initial stock distribution by warehouse
   - Average stock per warehouse-product

6. Order Profile
   - Order distribution by Status
   - Order distribution over time
   - Average items per order
   - Order value statistics
   - Order size distribution
   - Orders by customer segment

7. Inventory Profile
   - Transaction distribution by Type
   - Inbound vs Outbound transactions
   - Inbound vs Outbound unit volumes
   - Inventory transactions over time
   - Inventory activity by warehouse
   - Inventory activity by product
   - Average movement quantity
   - Movement quantity distribution
   - Highest moving products

8. Shipment Profile
   - Shipment status distribution
   - Carrier distribution
   - Average delivery time
   - Expected vs Actual delivery gap
   - Shipment trends over time

Outcome:
A complete understanding of the dataset's structure,
volume, distributions, and operational characteristics,
providing the foundation for supply chain performance
analysis in subsequent chapters.

=========================================================
*/