CREATE DATABASE Order_processing1;
USE Order_processing1;

-- Create Customer table
CREATE TABLE Customer (
    Cust INT PRIMARY KEY,
    cname VARCHAR(100),
    city VARCHAR(100)
);

-- Insert some data into Customer table
INSERT INTO Customer (Cust, cname, city) VALUES
(1, 'John Doe', 'New York'),
(2, 'Jane Smith', 'Los Angeles'),
(3, 'Kumar', 'Chicago'),
(4, 'Alice Johnson', 'San Francisco'),
(5, 'Bob Brown', 'Seattle');

-- Create Order table
CREATE TABLE Orders (
    orders INT PRIMARY KEY,
    odate DATE,
    cust INT,
    order_amt INT,
    FOREIGN KEY (cust) REFERENCES Customer(Cust) ON DELETE CASCADE
);

-- Insert some data into Order table
INSERT INTO Orders (orders, odate, cust, order_amt) VALUES
(101, '2023-01-15', 1, 500),
(102, '2023-02-20', 3, 700),
(103, '2023-03-25', 2, 300),
(104, '2023-04-10', 4, 900),
(105, '2023-05-05', 3, 600);

-- Create Item table
CREATE TABLE Item (
    Item INT PRIMARY KEY,
    unitprice INT
);

-- Insert some data into Item table
INSERT INTO Item (Item, unitprice) VALUES
(1, 50),
(2, 30),
(3, 100),
(4, 80),
(5, 120);

-- Create Order-item table
CREATE TABLE Order_item (
    orders INT,
    Item INT,
    qty INT,
    FOREIGN KEY (orders) REFERENCES Orders(orders) ON DELETE CASCADE,
    FOREIGN KEY (Item) REFERENCES Item(Item) ON DELETE CASCADE
);

-- Insert some data into Order_item table
INSERT INTO Order_item (orders, Item, qty) VALUES
(101, 1, 2),
(101, 2, 3),
(102, 3, 1),
(103, 2, 2),
(104, 1, 4);

-- Create Warehouse table
CREATE TABLE Warehouse (
    warehouse INT PRIMARY KEY,
    city VARCHAR(100)
);

-- Insert some data into Warehouse table
INSERT INTO Warehouse (warehouse, city) VALUES
(1, 'New York'),
(2, 'Los Angeles'),
(3, 'Chicago'),
(4, 'San Francisco'),
(5, 'Seattle');

-- Create Shipment table
CREATE TABLE Shipment (
    orders INT,
    warehouse INT,
    ship_date DATE,
    FOREIGN KEY (orders) REFERENCES Orders(orders) ON DELETE CASCADE,
    FOREIGN KEY (warehouse) REFERENCES Warehouse(warehouse) ON DELETE CASCADE
);

-- Insert some data into Shipment table
INSERT INTO Shipment (orders, warehouse, ship_date) VALUES
(101, 1, '2023-01-20'),
(102, 2, '2023-02-25'),
(103, 3, '2023-03-30'),
(104, 1, '2023-04-15'),
(105, 2, '2023-05-10');

-- List the Orders and Ship_date for all orders shipped from Warehouse "W2".
SELECT o.orders, s.ship_date FROM Orders o join Shipment s ON o.orders=s.orders WHERE s.warehouse = 2;

-- List the Warehouse information from which the Customer named "Kumar" was supplied his orders. Produce a listing of Orders, Warehouse.
SELECT o.orders, s.warehouse
FROM Orders o
JOIN Shipment s ON o.orders = s.orders
JOIN Customer c ON o.cust = c.cust
WHERE c.cname = 'Kumar';

-- Produce a listing: Cname, #ofOrders, Avg_Order_Amt, where the middle column is the total number of orders by the customer and the last column is the average order amount for that customer. (Use aggregate functions)
SELECT c.cname, COUNT(o.orders), AVG(o.order_amt)
FROM Customer c JOIN Orders o ON c.cust = o.cust
GROUP BY c.cname;

-- delete all orders for customer named kumar
DELETE FROM Orders
WHERE cust = (SELECT cust FROM Customer WHERE cname = 'Kumar');

-- Find the item with the maximum unit price.
SELECT *
FROM Item
WHERE unitprice = (SELECT MAX(unitprice) FROM Item);

-- A trigger that updates order_amout based on quantity and unitprice of order_item
DELIMITER //
CREATE TRIGGER update_order_amt
AFTER INSERT ON Order_item
FOR EACH ROW
BEGIN
    UPDATE Orders
    SET order_amt = NEW.qty * (SELECT unitprice FROM Item WHERE Item = NEW.Item)
    WHERE orders = NEW.orders;
END;
//
DELIMITER ;

-- check
-- Insert a new item
INSERT INTO Item (item, unitprice) VALUES (1006, 600);

-- Insert a new order with the new item
INSERT INTO Orders (orders, odate, cust, order_amt) VALUES (206, '2023-04-16', 2, 0);

-- Insert the new item into the order
INSERT INTO Order_Item (orders, item, qty) VALUES (206, 1006, 5);

-- Check the updated order_amount using the trigger
SELECT * FROM Orders;


-- Create a view to display orderID and shipment date of all orders shipped from a warehouse 5
CREATE OR REPLACE VIEW Order_Shipment_View AS
SELECT o.orders, s.ship_date
FROM Orders o
JOIN Shipment s ON o.orders = s.orders
WHERE s.warehouse = 5;

select * from Order_Shipment_View;
