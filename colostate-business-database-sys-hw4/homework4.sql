-- What is the email address for the person with the last name of “Looney”?
SELECT LastName, EmailAddress
FROM Person.Contact
WHERE LastName = 'Looney'

-- How many customers are there?
SELECT DISTINCT COUNT (CustomerID) AS CustomerCount
FROM Sales.Customer

-- Which order was the largest?
SELECT TOP 1 SalesOrderID, OrderQty
FROM Sales.SalesOrderDetail
ORDER BY OrderQty DESC

-- Which customer(s) have placed the most orders (not $ amount)? Must include their name.
SELECT TOP 10 Person.Contact.FirstName, Person.Contact.LastName, COUNT (Sales.SalesOrderHeader.CustomerID) AS OrdersPlaced
FROM Sales.SalesOrderHeader
LEFT JOIN Person.Contact ON Person.Contact.ContactID = Sales.SalesOrderHeader.ContactID
GROUP BY Person.Contact.FirstName, Person.Contact.LastName
HAVING COUNT (Sales.SalesOrderHeader.CustomerID) > 1
ORDER BY OrdersPlaced DESC

-- Who manages the employee “Dan Wilson”? The result set should the manager’s EmployeeID, name (first & last combined into a single column), job title, and when they were hired (MM-DD-YYYY).
SELECT DISTINCT m.EmployeeID, CONCAT(mc.FirstName, ' ', mc.LastName) AS Name, m.Title, m.HireDate
FROM HumanResources.Employee e
INNER JOIN HumanResources.Employee m ON e.ManagerID = m.EmployeeID
INNER JOIN Person.Contact ec ON ec.ContactID = e.ContactID
INNER JOIN Person.Contact mc ON mc.ContactID = m.ContactID
WHERE ec.LastName = 'Wilson'

-- List each sales person’s name (first & last), Job Title and total number of customers that each sales person has sold to. Sort by the most number of customers first. Bonus – who has the least customers each territory? (This should be a single query that sorts by territory.) DOUBLE Bonus – which Sales Manager has the fewest sales?
SELECT DISTINCT TOP 10 c.FirstName, c.LastName, e.Title, COUNT (s.SalesPersonID) AS Sales
FROM Sales.SalesOrderHeader s
INNER JOIN HumanResources.Employee e ON s.SalesPersonID = e.EmployeeID
INNER JOIN Person.Contact c ON s.SalesPersonID = c.ContactID
GROUP BY c.FirstName, c.LastName, e.Title
ORDER BY Sales DESC
-- Bonus
SELECT DISTINCT c.FirstName, c.LastName, COUNT(s.CustomerID) AS Customers, s.TerritoryID
FROM Sales.SalesOrderHeader s
JOIN HumanResources.Employee e ON s.SalesPersonID = e.EmployeeID
JOIN Person.Contact c ON s.SalesPersonID = c.ContactID
GROUP BY s.TerritoryID, c.FirstName, c.LastName
ORDER BY s.TerritoryID, Customers ASC
-- Double Bonus
SELECT DISTINCT TOP 10 c.FirstName, c.LastName, e.Title, COUNT (s.SalesPersonID) AS Sales
FROM Sales.SalesOrderHeader s
INNER JOIN HumanResources.Employee e ON s.SalesPersonID = e.EmployeeID
INNER JOIN Person.Contact c ON s.SalesPersonID = c.ContactID
WHERE e.Title LIKE '%Manager'
GROUP BY c.FirstName, c.LastName, e.Title
ORDER BY Sales ASC

-- List, for each product (ProductID and Product Name), the % of profit made when selling it (10 least profitable products).
SELECT TOP 40 p.ProductID, p.Name, p.StandardCost, s.UnitPrice, FORMAT(((s.UnitPrice - p.StandardCost) / p.StandardCost),'P') AS [Profit]
FROM Production.Product p
JOIN Sales.SalesOrderDetail s ON p.ProductID = s.ProductID
GROUP BY p.Name, p.ProductID, p.StandardCost, s.UnitPrice
ORDER BY ((s.UnitPrice - p.StandardCost) / p.StandardCost) ASC

-- Which 1972 car (make and model) sold for the most money (include details)?
SELECT TOP 10 s.AuctionID, s.WinBid, s.TotalBids, o.Description
FROM Summary s
INNER JOIN Objects o ON s.ObjectID = o.ObjectID
WHERE o.Description LIKE '%1972%' AND s.Category LIKE '%PassengerVehicles%'
ORDER BY s.WinBid DESC

-- Which 1972 car (make and model) sold for the least amount of money (include details)?
SELECT TOP 10 s.AuctionID, s.WinBid, s.TotalBids, o.Description
FROM Summary s
INNER JOIN Objects o ON s.ObjectID = o.ObjectID
WHERE o.Description LIKE '%1972%' AND s.Category LIKE '%PassengerVehicles%'
AND s.WinBid IS NOT NULL
ORDER BY s.WinBid ASC

-- Certain cars (make and model) have listed in a higher number of auctions than what actually sells. What is the make and model of the car that has highest ratio of number of auctions:actual sale? This may take more than one query.
SELECT TOP 10 s.ObjectID, o.Description, SUM(Case When WinBid > 0 Then 1 Else 0 End) AS Sold, SUM(Case When WinBid > 0 Then 1 Else 0 End + Case When WinBid IS NULL Then 1 Else 0 End ) AS Total, CAST(SUM(Case When WinBid > 0 Then 1 Else 0 End) AS DECIMAL) / SUM(Case When WinBid > 0 Then 1 Else 0 End + Case When WinBid IS NULL Then 1 Else 0 End ) AS SellRatio
FROM Summary s
INNER JOIN Objects o ON s.ObjectID = o.ObjectID
GROUP BY s.ObjectID, o.Description
HAVING CAST(SUM(Case When WinBid > 0 Then 1 Else 0 End) AS DECIMAL) / SUM(Case When WinBid > 0 Then 1 Else 0 End + Case When WinBid IS NULL Then 1 Else 0 End ) = 1.00
ORDER BY Total DESC

-- Many vehicles are a depreciating asset, but there are some vehicles in this database whose value appears to decline quite a bit. Compare such a poorly depreciating car (which you need to find - this may take several attempts at queries to find the final prices for your vehicle of interest), to the 1967 Ford Mustang (Year, Make, Model).
SELECT s.AuctionID, s.WinBid, Convert(date, s.EndDate) AS SoldDate, o.Description
FROM Summary s
INNER JOIN Objects o ON s.ObjectID = o.ObjectID
WHERE o.Description LIKE '%1967%' AND o.Description LIKE '%Ford%' AND o.Description LIKE '%Mustang%' AND s.Category LIKE '%PassengerVehicles%' AND s.WinBid IS NOT NULL
ORDER BY s.EndDate ASC
