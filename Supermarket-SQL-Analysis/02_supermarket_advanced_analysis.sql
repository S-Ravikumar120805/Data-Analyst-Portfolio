-- ============================================================
-- SUPERMARKET DATA ANALYSIS - ADVANCED PORTFOLIO PROJECT
-- Database: MySQL 8.0+
-- Independent schema; safe to run separately from the basic file.
-- ============================================================

CREATE DATABASE IF NOT EXISTS SUPERMARKET_ANALYTICS_ADVANCED;
USE SUPERMARKET_ANALYTICS_ADVANCED;

-- Reset in dependency order if you want to rebuild:
-- DROP TABLE IF EXISTS Sales;
-- DROP TABLE IF EXISTS Customers;
-- DROP TABLE IF EXISTS Products;

CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50) NOT NULL,
    Brand VARCHAR(50),
    UnitPrice DECIMAL(10,2) NOT NULL,
    ReorderLevel INT NOT NULL DEFAULT 10
);

CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    City VARCHAR(60) NOT NULL,
    CustomerSegment VARCHAR(30) NOT NULL
);

CREATE TABLE Sales (
    SaleID INT PRIMARY KEY,
    ProductID INT NOT NULL,
    CustomerID INT NOT NULL,
    QuantitySold INT NOT NULL,
    DiscountPercent DECIMAL(5,2) NOT NULL DEFAULT 0,
    SaleDate DATE NOT NULL,
    PaymentMethod VARCHAR(30) NOT NULL,
    CONSTRAINT fk_adv_sales_product
        FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT fk_adv_sales_customer
        FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    CONSTRAINT chk_quantity CHECK (QuantitySold > 0),
    CONSTRAINT chk_discount CHECK (DiscountPercent BETWEEN 0 AND 100)
);

CREATE INDEX idx_sales_date ON Sales(SaleDate);
CREATE INDEX idx_sales_product ON Sales(ProductID);
CREATE INDEX idx_sales_customer ON Sales(CustomerID);

INSERT INTO Products VALUES
(101, 'Milk', 'Dairy', 'Amul', 30.00, 20),
(102, 'Bread', 'Bakery', 'Britannia', 40.00, 15),
(103, 'Biscuits', 'Snacks', 'Parle', 25.00, 25),
(104, 'Shampoo', 'Personal Care', 'Dove', 180.00, 8),
(105, 'Rice', 'Grocery', 'India Gate', 750.00, 10),
(106, 'Soap', 'Personal Care', 'Lux', 35.00, 20),
(107, 'Juice', 'Beverages', 'Real', 120.00, 12),
(108, 'Chocolate', 'Confectionery', 'Cadbury', 50.00, 18);

INSERT INTO Customers VALUES
(1, 'Customer 1', 'Chennai', 'Regular'),
(2, 'Customer 2', 'Coimbatore', 'Premium'),
(3, 'Customer 3', 'Madurai', 'Regular'),
(4, 'Customer 4', 'Chennai', 'New'),
(5, 'Customer 5', 'Salem', 'Premium'),
(6, 'Customer 6', 'Trichy', 'Regular');

INSERT INTO Sales VALUES
(1, 101, 1, 20, 0,  '2026-03-05', 'UPI'),
(2, 102, 2, 15, 5,  '2026-03-06', 'Card'),
(3, 103, 3, 30, 0,  '2026-03-06', 'Cash'),
(4, 104, 1, 8,  10, '2026-03-07', 'UPI'),
(5, 105, 4, 12, 5,  '2026-03-08', 'Card'),
(6, 106, 5, 25, 0,  '2026-03-08', 'Cash'),
(7, 107, 6, 10, 0,  '2026-03-09', 'UPI'),
(8, 108, 2, 18, 5,  '2026-03-09', 'Card'),
(9, 101, 4, 22, 0,  '2026-03-10', 'UPI'),
(10, 103, 1, 35, 10, '2026-03-10', 'Cash'),
(11, 105, 5, 3,  0,  '2026-03-11', 'Card'),
(12, 104, 3, 5,  5,  '2026-03-12', 'UPI'),
(13, 107, 2, 14, 0,  '2026-03-13', 'Cash'),
(14, 102, 6, 9,  0,  '2026-03-14', 'UPI'),
(15, 108, 4, 25, 10, '2026-03-15', 'Card');

-- BUSINESS QUESTION 1: What is the net sales value for each transaction?
-- Net sales = quantity * unit price after discount.
SELECT s.SaleID, p.ProductName, s.QuantitySold, p.UnitPrice,
       s.DiscountPercent,
       ROUND(s.QuantitySold * p.UnitPrice *
             (1 - s.DiscountPercent / 100), 2) AS NetSales
FROM Sales s
JOIN Products p ON p.ProductID = s.ProductID
ORDER BY NetSales DESC;

-- BUSINESS QUESTION 2: Which categories generate the highest net sales?
SELECT p.Category,
       ROUND(SUM(s.QuantitySold * p.UnitPrice *
                 (1 - s.DiscountPercent / 100)), 2) AS NetSales
FROM Sales s
JOIN Products p ON p.ProductID = s.ProductID
GROUP BY p.Category
ORDER BY NetSales DESC;

-- BUSINESS QUESTION 3: Which customers spend the most?
SELECT c.CustomerID, c.CustomerName, c.City,
       ROUND(SUM(s.QuantitySold * p.UnitPrice *
                 (1 - s.DiscountPercent / 100)), 2) AS CustomerSpend
FROM Customers c
JOIN Sales s ON s.CustomerID = c.CustomerID
JOIN Products p ON p.ProductID = s.ProductID
GROUP BY c.CustomerID, c.CustomerName, c.City
ORDER BY CustomerSpend DESC;

-- BUSINESS QUESTION 4: Monthly sales trend.
SELECT DATE_FORMAT(s.SaleDate, '%Y-%m') AS SalesMonth,
       ROUND(SUM(s.QuantitySold * p.UnitPrice *
                 (1 - s.DiscountPercent / 100)), 2) AS MonthlyNetSales
FROM Sales s
JOIN Products p ON p.ProductID = s.ProductID
GROUP BY DATE_FORMAT(s.SaleDate, '%Y-%m')
ORDER BY SalesMonth;

-- BUSINESS QUESTION 5: Top 3 products by net sales.
SELECT p.ProductID, p.ProductName,
       ROUND(SUM(s.QuantitySold * p.UnitPrice *
                 (1 - s.DiscountPercent / 100)), 2) AS NetSales
FROM Products p
JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY NetSales DESC
LIMIT 3;

-- BUSINESS QUESTION 6: Include products that have no sales (LEFT JOIN).
SELECT p.ProductID, p.ProductName,
       COALESCE(SUM(s.QuantitySold), 0) AS UnitsSold
FROM Products p
LEFT JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY UnitsSold DESC;

-- BUSINESS QUESTION 7: Compare each product's price with its category average.
SELECT ProductName, Category, UnitPrice,
       (SELECT ROUND(AVG(p2.UnitPrice), 2)
        FROM Products p2
        WHERE p2.Category = p.Category) AS CategoryAveragePrice
FROM Products p
ORDER BY Category, UnitPrice DESC;

-- BUSINESS QUESTION 8: Rank products by net sales within each category.
WITH ProductSales AS (
    SELECT p.ProductID, p.ProductName, p.Category,
           SUM(s.QuantitySold * p.UnitPrice *
               (1 - s.DiscountPercent / 100)) AS NetSales
    FROM Products p
    JOIN Sales s ON s.ProductID = p.ProductID
    GROUP BY p.ProductID, p.ProductName, p.Category
)
SELECT ProductName, Category, ROUND(NetSales, 2) AS NetSales,
       RANK() OVER (PARTITION BY Category ORDER BY NetSales DESC) AS SalesRank,
       DENSE_RANK() OVER (PARTITION BY Category ORDER BY NetSales DESC) AS DenseSalesRank
FROM ProductSales
ORDER BY Category, SalesRank;

-- BUSINESS QUESTION 9: Classify transactions by value using CASE.
SELECT s.SaleID,
       ROUND(s.QuantitySold * p.UnitPrice *
             (1 - s.DiscountPercent / 100), 2) AS NetSales,
       CASE
           WHEN s.QuantitySold * p.UnitPrice *
                (1 - s.DiscountPercent / 100) >= 1000 THEN 'High Value'
           WHEN s.QuantitySold * p.UnitPrice *
                (1 - s.DiscountPercent / 100) >= 300 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS TransactionCategory
FROM Sales s
JOIN Products p ON p.ProductID = s.ProductID
ORDER BY NetSales DESC;

-- BUSINESS QUESTION 10: Find customers whose spend is above average customer spend.
WITH CustomerSpend AS (
    SELECT c.CustomerID, c.CustomerName,
           SUM(s.QuantitySold * p.UnitPrice *
               (1 - s.DiscountPercent / 100)) AS Spend
    FROM Customers c
    JOIN Sales s ON s.CustomerID = c.CustomerID
    JOIN Products p ON p.ProductID = s.ProductID
    GROUP BY c.CustomerID, c.CustomerName
)
SELECT CustomerID, CustomerName, ROUND(Spend, 2) AS Spend
FROM CustomerSpend
WHERE Spend > (SELECT AVG(Spend) FROM CustomerSpend)
ORDER BY Spend DESC;

-- BUSINESS QUESTION 11: Payment method usage.
SELECT PaymentMethod, COUNT(*) AS TransactionCount,
       ROUND(SUM(s.QuantitySold * p.UnitPrice *
                 (1 - s.DiscountPercent / 100)), 2) AS NetSales
FROM Sales s
JOIN Products p ON p.ProductID = s.ProductID
GROUP BY PaymentMethod
ORDER BY NetSales DESC;

-- BUSINESS QUESTION 12: Products that need replenishment based on units sold.
SELECT p.ProductID, p.ProductName, p.ReorderLevel,
       COALESCE(SUM(s.QuantitySold), 0) AS UnitsSold,
       CASE
           WHEN COALESCE(SUM(s.QuantitySold), 0) < p.ReorderLevel
               THEN 'Review Stock'
           ELSE 'Sales Above Reorder Threshold'
       END AS StockReview
FROM Products p
LEFT JOIN Sales s ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName, p.ReorderLevel
ORDER BY UnitsSold ASC;

-- EXTRA: CTE for a reusable sales summary.
WITH DailySales AS (
    SELECT s.SaleDate,
           SUM(s.QuantitySold * p.UnitPrice *
               (1 - s.DiscountPercent / 100)) AS DailyNetSales
    FROM Sales s
    JOIN Products p ON p.ProductID = s.ProductID
    GROUP BY s.SaleDate
)
SELECT SaleDate, ROUND(DailyNetSales, 2) AS DailyNetSales,
       ROUND(AVG(DailyNetSales) OVER (
           ORDER BY SaleDate ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ), 2) AS ThreeDayMovingAverage
FROM DailySales
ORDER BY SaleDate;
