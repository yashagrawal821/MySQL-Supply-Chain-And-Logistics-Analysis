-- =============================================================================
-- Meridian Commerce Group — Supply Chain & Logistics Analytics
-- MySQL 8.0+ schema
-- Load order (respects foreign keys):
--   1. customers, products, suppliers, warehouses
--   2. supplier_products, warehouse_products
--   3. orders
--   4. order_items, shipments
--   5. inventory_transactions
-- =============================================================================

CREATE DATABASE IF NOT EXISTS supply_chain_analytics
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE supply_chain_analytics;

-- ---------------------------------------------------------------------------
-- CUSTOMERS
-- ---------------------------------------------------------------------------
CREATE TABLE customers (
    CustomerID       VARCHAR(10)     NOT NULL,
    CustomerName     VARCHAR(120)    NOT NULL,
    CustomerType     VARCHAR(5)      NOT NULL,          -- B2B / B2C
    Industry         VARCHAR(40)     NOT NULL,
    Country          VARCHAR(60)     NOT NULL,
    Region           VARCHAR(30)     NOT NULL,
    City             VARCHAR(60)     NOT NULL,
    StateProvince    VARCHAR(5)          NULL,
    PostalCode       VARCHAR(10)         NULL,
    SignupDate       DATE            NOT NULL,
    CustomerSegment  VARCHAR(20)     NOT NULL,
    PRIMARY KEY (CustomerID),
    INDEX idx_customers_region (Region),
    INDEX idx_customers_segment (CustomerSegment)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- PRODUCTS
-- ---------------------------------------------------------------------------
CREATE TABLE products (
    ProductID             VARCHAR(6)   NOT NULL,
    ProductName           VARCHAR(120) NOT NULL,
    Category              VARCHAR(40)  NOT NULL,
    SubCategory            VARCHAR(40)  NOT NULL,
    Brand                 VARCHAR(40)  NOT NULL,
    UnitCost              DECIMAL(10,2) NOT NULL,
    UnitPrice             DECIMAL(10,2) NOT NULL,
    WeightKg              DECIMAL(6,2)     NULL,
    SupplierLeadTimeDays  INT          NOT NULL,
    ReorderLevel          INT          NOT NULL,
    DiscontinuedFlag      BOOLEAN      NOT NULL DEFAULT FALSE,
    PRIMARY KEY (ProductID),
    INDEX idx_products_category (Category),
    INDEX idx_products_subcategory (SubCategory)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- SUPPLIERS
-- ---------------------------------------------------------------------------
CREATE TABLE suppliers (
    SupplierID        VARCHAR(5)   NOT NULL,
    SupplierName      VARCHAR(80)  NOT NULL,
    Country           VARCHAR(60)  NOT NULL,
    Region            VARCHAR(30)  NOT NULL,
    City              VARCHAR(60)  NOT NULL,
    SupplierType      VARCHAR(30)  NOT NULL,
    ReliabilityScore  DECIMAL(4,1) NOT NULL,
    QualityScore      DECIMAL(4,1)     NULL,
    PaymentTermsDays  INT          NOT NULL,
    ActiveFlag        BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (SupplierID),
    INDEX idx_suppliers_region (Region)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- WAREHOUSES
-- ---------------------------------------------------------------------------
CREATE TABLE warehouses (
    WarehouseID            VARCHAR(5)    NOT NULL,
    WarehouseName          VARCHAR(80)   NOT NULL,
    Country                VARCHAR(60)   NOT NULL,
    Region                 VARCHAR(30)   NOT NULL,
    City                   VARCHAR(60)   NOT NULL,
    WarehouseType          VARCHAR(30)   NOT NULL,
    CapacityUnits          INT           NOT NULL,
    OperatingCostPerMonth  DECIMAL(12,2) NOT NULL,
    OpeningDate            DATE          NOT NULL,
    ActiveFlag             BOOLEAN       NOT NULL DEFAULT TRUE,
    PRIMARY KEY (WarehouseID),
    INDEX idx_warehouses_region (Region)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- SUPPLIER_PRODUCTS (many-to-many: suppliers <-> products)
-- ---------------------------------------------------------------------------
CREATE TABLE supplier_products (
    SupplierID             VARCHAR(5)    NOT NULL,
    ProductID              VARCHAR(6)    NOT NULL,
    SupplierUnitCost       DECIMAL(10,2) NOT NULL,
    LeadTimeDays           INT           NOT NULL,
    MinimumOrderQuantity   INT           NOT NULL,
    PreferredSupplierFlag  BOOLEAN       NOT NULL DEFAULT FALSE,
    PRIMARY KEY (SupplierID, ProductID),
    CONSTRAINT fk_sp_supplier FOREIGN KEY (SupplierID) REFERENCES suppliers(SupplierID),
    CONSTRAINT fk_sp_product  FOREIGN KEY (ProductID)  REFERENCES products(ProductID),
    INDEX idx_sp_product (ProductID)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- WAREHOUSE_PRODUCTS (many-to-many: warehouses <-> products)
-- ---------------------------------------------------------------------------
CREATE TABLE warehouse_products (
    WarehouseID          VARCHAR(5)    NOT NULL,
    ProductID            VARCHAR(6)    NOT NULL,
    InitialStock         INT           NOT NULL,
    SafetyStock          INT           NOT NULL,
    ReorderPoint         INT           NOT NULL,
    StorageCostPerUnit   DECIMAL(6,3)  NOT NULL,
    PRIMARY KEY (WarehouseID, ProductID),
    CONSTRAINT fk_wp_warehouse FOREIGN KEY (WarehouseID) REFERENCES warehouses(WarehouseID),
    CONSTRAINT fk_wp_product   FOREIGN KEY (ProductID)   REFERENCES products(ProductID),
    INDEX idx_wp_product (ProductID)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- ORDERS
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
    OrderID               VARCHAR(7)   NOT NULL,
    CustomerID            VARCHAR(10)  NOT NULL,
    OrderDate             DATE         NOT NULL,
    RequiredDeliveryDate  DATE         NOT NULL,
    OrderStatus           VARCHAR(20)  NOT NULL,
    SalesChannel          VARCHAR(20)  NOT NULL,
    WarehouseID           VARCHAR(5)   NOT NULL,
    ShippingMethod        VARCHAR(15)  NOT NULL,
    Priority              VARCHAR(10)  NOT NULL,
    PRIMARY KEY (OrderID),
    CONSTRAINT fk_orders_customer  FOREIGN KEY (CustomerID)  REFERENCES customers(CustomerID),
    CONSTRAINT fk_orders_warehouse FOREIGN KEY (WarehouseID) REFERENCES warehouses(WarehouseID),
    INDEX idx_orders_date (OrderDate),
    INDEX idx_orders_customer (CustomerID),
    INDEX idx_orders_warehouse (WarehouseID),
    INDEX idx_orders_status (OrderStatus)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- ORDER_ITEMS
-- ---------------------------------------------------------------------------
CREATE TABLE order_items (
    OrderItemID      VARCHAR(9)    NOT NULL,
    OrderID          VARCHAR(7)    NOT NULL,
    ProductID        VARCHAR(6)    NOT NULL,
    Quantity         INT           NOT NULL,
    UnitPrice        DECIMAL(10,2) NOT NULL,
    DiscountPercent  DECIMAL(4,1)  NOT NULL DEFAULT 0,
    PRIMARY KEY (OrderItemID),
    CONSTRAINT fk_oi_order   FOREIGN KEY (OrderID)   REFERENCES orders(OrderID),
    CONSTRAINT fk_oi_product FOREIGN KEY (ProductID) REFERENCES products(ProductID),
    INDEX idx_oi_order (OrderID),
    INDEX idx_oi_product (ProductID)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- SHIPMENTS
-- ---------------------------------------------------------------------------
CREATE TABLE shipments (
    ShipmentID            VARCHAR(8)    NOT NULL,
    OrderID               VARCHAR(7)    NOT NULL,
    ShipmentDate          DATE          NOT NULL,
    ExpectedDeliveryDate  DATE          NOT NULL,
    ActualDeliveryDate    DATE              NULL,
    ShipmentStatus        VARCHAR(15)   NOT NULL,
    Carrier               VARCHAR(40)   NOT NULL,
    ShippingCost          DECIMAL(10,2)     NULL,
    DistanceKm            DECIMAL(8,1)  NOT NULL,
    DeliveryDelayDays     INT               NULL,
    PRIMARY KEY (ShipmentID),
    CONSTRAINT fk_ship_order FOREIGN KEY (OrderID) REFERENCES orders(OrderID),
    INDEX idx_ship_order (OrderID),
    INDEX idx_ship_status (ShipmentStatus),
    INDEX idx_ship_carrier (Carrier)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------------
-- INVENTORY_TRANSACTIONS
-- ---------------------------------------------------------------------------
CREATE TABLE inventory_transactions (
    InventoryTransactionID  VARCHAR(9)   NOT NULL,
    WarehouseID              VARCHAR(5)   NOT NULL,
    ProductID                VARCHAR(6)   NOT NULL,
    TransactionDate          DATE         NOT NULL,
    TransactionType          VARCHAR(20)  NOT NULL,
    Quantity                 INT          NOT NULL,   -- signed: +in / -out (see README §5)
    ReferenceID               VARCHAR(20)      NULL,
    PRIMARY KEY (InventoryTransactionID),
    CONSTRAINT fk_it_warehouse FOREIGN KEY (WarehouseID) REFERENCES warehouses(WarehouseID),
    CONSTRAINT fk_it_product   FOREIGN KEY (ProductID)   REFERENCES products(ProductID),
    INDEX idx_it_warehouse_product (WarehouseID, ProductID),
    INDEX idx_it_date (TransactionDate),
    INDEX idx_it_type (TransactionType)
) ENGINE=InnoDB;

-- =============================================================================
-- Example load statements (adjust local_infile path/permissions as needed)
-- =============================================================================
-- LOAD DATA LOCAL INFILE 'customers.csv' INTO TABLE customers
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- (repeat per table, in the load order documented above)
