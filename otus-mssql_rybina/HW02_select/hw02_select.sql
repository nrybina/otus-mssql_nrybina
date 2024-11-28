/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

use WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select  StockItemID
       ,StockItemName
from    Warehouse.StockItems
where   StockItemName like '%urgent%'
        or StockItemName like 'Animal%';

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select    s.SupplierID
         ,s.SupplierName
from      Purchasing.Suppliers s
left join Purchasing.PurchaseOrders o on s.SupplierID = o.SupplierID
where     o.SupplierID is null;

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/
declare @pagesize bigint = 100  -- Размер страницы
       ,@pagenum  bigint = 11;

select    o.OrderID
         ,convert(nvarchar, OrderDate, 104) OrderDate
         ,datename(month, OrderDate) MonthDate
         ,datepart(quarter, OrderDate) QuarterDate
         ,case
            when datepart(month, OrderDate) between 1 and 4 then 1
            when datepart(month, OrderDate) between 5 and 8 then 2
            when datepart(month, OrderDate) between 9 and 12 then 3
          end PartYearDate
         ,c.CustomerName
from      Sales.Orders o
--join    Sales.OrderLines ol on o.OrderID = ol.OrderID
join      Sales.Customers c on o.CustomerID = c.CustomerID
join      ( select  distinct OrderID
            from    Sales.OrderLines
            where   UnitPrice > 100
                    or Quantity > 20
                       and PickingCompletedWhen is not null) ol on o.OrderID = ol.OrderID
order by  4
         ,5
         ,2 offset (@pagenum - 1) * @pagesize rows fetch next @pagesize rows only;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select  dm.DeliveryMethodName
       ,po.ExpectedDeliveryDate
       ,s.SupplierName
       ,p.PreferredName ContactPerson
from    Purchasing.Suppliers s
join    Purchasing.PurchaseOrders po on s.SupplierID = po.SupplierID
join    Application.DeliveryMethods dm on po.DeliveryMethodID = dm.DeliveryMethodID
join    Application.People p on p.PersonID = po.ContactPersonID
where   po.ExpectedDeliveryDate between '20130101' and '20130131'
        and dm.DeliveryMethodName in ('Air Freight', 'Refrigerated Air Freight')
        and po.IsOrderFinalized = 1;

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select    top 10 c.CustomerName
                ,pc.FullName SalespersonPersonName
from      Sales.Orders o
join      Application.People pc on pc.PersonID = o.SalespersonPersonID
join      Sales.Customers c on o.CustomerID = c.CustomerID
order by  o.OrderDate desc;

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select  distinct c.CustomerID
                ,c.CustomerName
                ,c.PhoneNumber
                ,c.FaxNumber
from    Warehouse.StockItems si
join    Sales.OrderLines ol on si.StockItemID = ol.StockItemID
join    Sales.Orders o on ol.OrderID = o.OrderID
join    Sales.Customers c on o.CustomerID = c.CustomerID
where   si.StockItemName = 'Chocolate frogs 250g';


