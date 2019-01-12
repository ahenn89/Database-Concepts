--#1 Part 1
Create table ProductCategory(
CategoryID int identity(1,1), 
CategoryName varchar(50)
)

Insert into ProductCategory(CategoryName)
Select distinct Category
from Product

Alter table product
add CategoryID int

update Product
set CategoryID = c.CategoryID
from Product p
join ProductCategory c
on p.Category = c.CategoryName

Alter table Product 
drop column Category

--#2 Part 1
Create table CustomerAddresses(
AddressID int identity(1,1),
CustomerID int, 
AddressType varchar(10),
Address varchar(50),
City varchar(30),
State char(2),
ZipCode varchar(10)
)

Insert into CustomerAddresses(CustomerID, AddressType, Address, City, State, ZipCode)
Select CustomerID, 'Home', Address, City, State, ZipCode
from Customer

Insert into CustomerAddresses(CustomerID, AddressType, Address, City, State, ZipCode)
Select CustomerID, 'Ship', ShipAddress, ShipCity, ShipState, ShipZipCode
from OrderHeader

alter table Customer
Add AddressID int

alter table OrderHeader
add AddressID int

update Customer
set AddressID = a.AddressID
from Customer c
join CustomerAddresses a 
on c.CustomerID = a.CustomerID
where a.AddressType = 'Home'

update OrderHeader
set AddressID = a.AddressID
from OrderHeader o 
join CustomerAddresses a 
on o.CustomerID = a.CustomerID
where a.AddressType = 'Shipping'

alter table Customer
drop column Address

alter table Customer
drop column City

alter table Customer
drop column State

alter table Customer
drop column ZipCode

alter table OrderHeader
drop column ShipAddress

alter table OrderHeader
drop column ShipCity

alter table OrderHeader
drop column ShipState

alter table OrderHeader
drop column ShipZipCode

--#3 Part 1
alter table CustomerAddresses
add constraint pk_CustomerAddresses_AddressID Primary Key (AddressID)

alter table Customer
add constraint fk_Customer_AddressID Foreign Key (AddressID)
references CustomerAddresses(AddressID)

alter table OrderHeader
add constraint fk_OrderHeader_CustomerID Foreign Key (CustomerID)
references Customer(CustomerID),
constraint fk_OrderHeader_AddressID foreign key (AddressID)
references CustomerAddresses(AddressID)

alter table CustomerAddresses
add constraint fk_CustomerAddresses_CustomerID Foreign Key (CustomerID)
references Customer(CustomerID)

alter table ProductCategory
add constraint pk_ProductCategory_CategoryID primary key (CategoryID)

alter table Product
add constraint fk_Product_VendorID Foreign Key (VendorID)
references Vendor(VendorID),
constraint fk_Product_CategoryID foreign key (CategoryID)
references ProductCategory(CategoryID)

alter table OrderDetail
alter column SalesPromotionID smallint

alter table OrderDetail
add constraint fk_OrderDetail_OrderID foreign key (OrderID) 
references OrderHeader(OrderID),
constraint fk_OrderDetail_ProductID foreign key (ProductID)
references  Product(ProductID),
constraint fk_OrderDetail_SalesPromotionID foreign key (SalesPromotionID)
references SalesPromotion(SalesPromotionID)

--#1 Part 2
Create View ProductInformationByCategory_VW as
Select p.ProductID, p.Name as ProductName, p.Model, p.ProductNumber, p.Color, p.ListPrice, p.Cost, (p.ListPrice - p.Cost) as Profit, v.VendorID, v.Name as VendorName, pc.CategoryID, pc.CategoryName
from Product p
left join ProductCategory pc
on p.CategoryID = pc.CategoryID
left join Vendor v
on p.VendorID = v.VendorID

Select *
from ProductInformationByCategory_VW

--#2 Part 2
create view SalesReportByVendor_VW as
Select v.VendorID, v.Name as VendorName, cast(sum(p.ListPrice * (1 - sp.DiscountPercent) * od.OrderQuantity) as decimal(15,2))TotalSales, sum(od.OrderQuantity) as TotalQuantity, cast(sum(p.ListPrice * sp.DiscountPercent * od.OrderQuantity)as decimal(8,2)) as TotalDiscount, cast(sum((p.ListPrice * (1-sp.DiscountPercent)) - p.Cost)as decimal(15,2)) as TotalProfit 
from OrderHeader oh join OrderDetail od
on oh.OrderID = od.OrderID 
join SalesPromotion sp on od.SalesPromotionID = sp.SalesPromotionID
join Product p on od.ProductID = p.ProductID
join Vendor v on p.VendorID = v.VendorID

where oh.OrderDate between '1/1/2014' and '07/31/2014'

group by v.VendorID, v.Name 

Select *
from SalesReportByVendor_VW

--#3 Part 3
Select 
	o.OrderDate, 
	o.SalesOrderNumber, 
	c.FirstName + ' ' + c.LastName as CustomerName,
	Isnull(ca1.Address, '') + ' ' + Isnull(ca1.City, '') + ' '  + Isnull(ca1.State, '') + ' '  + Isnull(ca1.ZipCode, '') As HomeAddress,
	Isnull(ca2.Address, '') + ' ' + Isnull(ca2.City, '') + ' '  + Isnull(ca2.State, '') + ' '  + Isnull(ca2.ZipCode, '') As ShippingAddress,
	p.Name as ProductName, 
	p.ListPrice as RetailPrice,
	Cast((p.ListPrice * sp.DiscountPercent) as Decimal(8,2)) as DiscountAmount,
	od.OrderQuantity,
	Cast(p.ListPrice * (1-sp.DiscountPercent) * od.OrderQuantity as Decimal(10,2)) as LineTotal,
	isnull(st.TaxRate,0) as TaxRate,
	Cast((p.ListPrice * (1-sp.DiscountPercent) * od.OrderQuantity) * (isnull(st.TaxRate,0)/100) as Decimal(8,2)) as SalesTax
From 
	OrderHeader o
	Join Customer c on o.CustomerID = c.CustomerID
	Join CustomerAddresses ca1 on c.AddressID = ca1.AddressID And ca1.AddressType = 'Home'
	Join CustomerAddresses ca2 on o.AddressID = ca2.AddressID And ca2.AddressType = 'Shipping'
	Join OrderDetail od on o.OrderID = od.OrderID
	join Product p on od.ProductID = p.ProductID
	Left Join SalesPromotion sp on od.SalesPromotionID = sp.SalesPromotionID
	Left Join SalesTax st on st.State = ca1.State

