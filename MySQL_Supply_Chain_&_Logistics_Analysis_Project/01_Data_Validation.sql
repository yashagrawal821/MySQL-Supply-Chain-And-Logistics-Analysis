-- Query 1: Confirm Database
USE supply_chain_analytics;
SELECT DATABASE();


-- Query 2: Verify expected tables
SHOW TABLES;


-- Query 3: Validate row counts
SELECT 'customers' AS table_name, COUNT(*) AS row_count FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL
SELECT 'warehouses', COUNT(*) FROM warehouses
UNION ALL
SELECT 'supplier_products', COUNT(*) FROM supplier_products
UNION ALL
SELECT 'warehouse_products', COUNT(*) FROM warehouse_products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'shipments', COUNT(*) FROM shipments
UNION ALL
SELECT 'inventory_transactions', COUNT(*) FROM inventory_transactions;


-- Query 4: Check duplicate primary keys
SELECT 'customers' AS table_name, CustomerID AS primary_key, COUNT(*) AS occurrences
FROM customers
GROUP BY CustomerID
HAVING COUNT(*) > 1

UNION ALL

SELECT 'products', ProductID, COUNT(*)
FROM products
GROUP BY ProductID
HAVING COUNT(*) > 1

UNION ALL

SELECT 'suppliers', SupplierID, COUNT(*)
FROM suppliers
GROUP BY SupplierID
HAVING COUNT(*) > 1

UNION ALL

SELECT 'warehouses', WarehouseID, COUNT(*)
FROM warehouses
GROUP BY WarehouseID
HAVING COUNT(*) > 1;


-- Query 5: Check NULLs in required fields
SELECT 'customers' AS table_name,
    SUM(CustomerID IS NULL) AS null_customer_id,
    SUM(CustomerName IS NULL) AS null_customer_name
FROM customers

UNION ALL

SELECT 'products',
    SUM(ProductID IS NULL),
    SUM(ProductName IS NULL)
FROM products

UNION ALL

SELECT 'suppliers',
    SUM(SupplierID IS NULL),
    SUM(SupplierName IS NULL)
FROM suppliers

UNION ALL

SELECT 'warehouses',
    SUM(WarehouseID IS NULL),
    SUM(WarehouseName IS NULL)
FROM warehouses;


-- Query 6: Check for order_items without a matching order
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN orders o
    ON oi.OrderID = o.OrderID
WHERE o.OrderID IS NULL;


-- Query 7: Check for order_items without a matching product
SELECT COUNT(*) AS orphan_order_items
FROM order_items oi
LEFT JOIN products p
    ON oi.ProductID = p.ProductID
WHERE p.ProductID IS NULL;


-- Query 8: Check for shipments without a matching order
SELECT COUNT(*) AS orphan_shipments
FROM shipments s
LEFT JOIN orders o
    ON s.OrderID = o.OrderID
WHERE o.OrderID IS NULL;


-- Query 9: Check for inventory transactions without a matching product
SELECT COUNT(*) AS orphan_inventory_transactions
FROM inventory_transactions it
LEFT JOIN products p
    ON it.ProductID = p.ProductID
WHERE p.ProductID IS NULL;


-- Query 10: Check for inventory transactions without a matching warehouse
SELECT COUNT(*) AS orphan_inventory_transactions
FROM inventory_transactions it
LEFT JOIN warehouses w
    ON it.WarehouseID = w.WarehouseID
WHERE w.WarehouseID IS NULL;


-- Query 11: Check for supplier_products without a matching supplier
SELECT COUNT(*) AS orphan_supplier_products
FROM supplier_products sp
LEFT JOIN suppliers s
    ON sp.SupplierID = s.SupplierID
WHERE s.SupplierID IS NULL;


-- Query 12: Check for supplier_products without a matching product
SELECT COUNT(*) AS orphan_supplier_products
FROM supplier_products sp
LEFT JOIN products p
    ON sp.ProductID = p.ProductID
WHERE p.ProductID IS NULL;


-- Query 13: Check for warehouse_products without a matching warehouse
SELECT COUNT(*) AS orphan_warehouse_products
FROM warehouse_products wp
LEFT JOIN warehouses w
    ON wp.WarehouseID = w.WarehouseID
WHERE w.WarehouseID IS NULL;


-- Query 14: Check for warehouse_products without a matching product
SELECT COUNT(*) AS orphan_warehouse_products
FROM warehouse_products wp
LEFT JOIN products p
    ON wp.ProductID = p.ProductID
WHERE p.ProductID IS NULL;


-- Query 15: Check for invalid product numeric values
SELECT COUNT(*) AS invalid_products
FROM products
WHERE UnitCost < 0
   OR UnitPrice < 0
   OR WeightKg < 0
   OR SupplierLeadTimeDays < 0
   OR ReorderLevel < 0;


-- Query 16: Products with UnitPrice below UnitCost
SELECT COUNT(*) AS products_below_cost
FROM products
WHERE UnitPrice < UnitCost;


-- Query 17: Check for invalid supplier lead times
SELECT COUNT(*) AS invalid_lead_times
FROM products
WHERE SupplierLeadTimeDays <= 0;


-- Query 18: Check for invalid reorder levels
SELECT COUNT(*) AS invalid_reorder_levels
FROM products
WHERE ReorderLevel < 0;


-- Query 19: Products with zero gross margin
SELECT COUNT(*) AS zero_margin_products
FROM products
WHERE UnitPrice = UnitCost;


-- Query 20: Check inventory movement directions
SELECT
    SUM(CASE WHEN Quantity > 0 THEN 1 ELSE 0 END) AS inbound_transactions,
    SUM(CASE WHEN Quantity < 0 THEN 1 ELSE 0 END) AS outbound_transactions,
    SUM(CASE WHEN Quantity = 0 THEN 1 ELSE 0 END) AS zero_quantity_transactions
FROM inventory_transactions;


-- Query 21: Check for invalid/future dates
SELECT
    'orders' AS table_name,
    COUNT(*) AS invalid_dates
FROM orders
WHERE OrderDate IS NULL
   OR OrderDate > CURDATE()

UNION ALL

SELECT
    'shipments' AS table_name,
    COUNT(*) AS invalid_dates
FROM shipments
WHERE ShipmentDate IS NULL
   OR ShipmentDate > CURDATE();


-- Query 22: Check for shipments occurring before the order date
SELECT COUNT(*) AS invalid_shipment_dates
FROM orders o
JOIN shipments s
    ON o.OrderID = s.OrderID
WHERE s.ShipmentDate < o.OrderDate;


-- Query 23: Check for deliveries occurring before shipment
SELECT COUNT(*) AS invalid_delivery_dates
FROM shipments
WHERE ActualDeliveryDate IS NOT NULL
  AND ActualDeliveryDate < ShipmentDate;


-- Query 24: Actual delivery cannot exist without a shipment date
SELECT COUNT(*) AS invalid_shipment_records
FROM shipments
WHERE ActualDeliveryDate IS NOT NULL
  AND ShipmentDate IS NULL;


-- Query 25: Orders without order items
SELECT COUNT(*) AS orders_without_items
FROM orders o
LEFT JOIN order_items oi
    ON o.OrderID = oi.OrderID
WHERE oi.OrderID IS NULL;


/*
=========================================================
CHAPTER 1 SUMMARY — DATA VALIDATION
=========================================================

Objective:
Validate the structure, integrity, consistency, and
basic business sanity of the supply chain dataset before
performing profiling and analysis.

Key Validation Areas Covered:

1. Database & Schema Validation
   - Confirmed the active database
   - Verified the expected tables are present
   - Validated row counts across all major tables

2. Primary Key Validation
   - Checked for duplicate primary keys in core master
     tables
   - Confirmed uniqueness of CustomerID, ProductID,
     SupplierID, and WarehouseID

3. Required Field Validation
   - Checked NULL values in critical identifier and
     name fields
   - Confirmed required fields are populated

4. Referential Integrity Validation
   - Checked for orphan order items
   - Checked for orphan shipments
   - Checked for orphan inventory transactions
   - Checked supplier-product relationships
   - Checked warehouse-product relationships
   - Verified referenced products, suppliers, warehouses,
     and orders exist

5. Product Data Validation
   - Checked for negative UnitCost, UnitPrice, and WeightKg
   - Checked supplier lead time validity
   - Checked reorder level validity
   - Identified products priced below cost
   - Identified products with zero gross margin

6. Inventory Transaction Validation
   - Classified inventory movements as inbound,
     outbound, or zero-quantity transactions
   - Verified the direction of inventory movement based
     on Quantity sign

7. Date & Timeline Validation
   - Checked for NULL and future order dates
   - Checked for NULL and future shipment dates
   - Verified shipments do not occur before their
     associated orders
   - Verified deliveries do not occur before shipments
   - Verified actual delivery dates cannot exist without
     a shipment date

8. Order Completeness Validation
   - Checked for orders without associated order items
   - Verified that orders have corresponding transactional
     detail

Outcome:
The dataset passed the core structural, referential,
date, and business sanity checks required for further
analysis.

No major data integrity issues were identified in the
validated areas, allowing the project to proceed to
Chapter 2 — Data Profiling.

=========================================================
*/