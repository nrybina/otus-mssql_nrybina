/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

use WideWorldImporters;

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

--1 вариант
select      PersonID
           ,FullName
from        Application.People p
outer apply ( select  InvoiceID
              from    Sales.Invoices i
              where   p.PersonID = i.SalespersonPersonID
                      and InvoiceDate = '20150704') a
where       IsSalesPerson = 1
            and InvoiceID is null;

--2 вариант
;
with wInvoices as (select InvoiceID
                         ,SalespersonPersonID
                   from   Sales.Invoices i
                   where  InvoiceDate = '20150704')
select  PersonID
       ,FullName
from    Application.People p
where   IsSalesPerson = 1
        and not exists (select  * from wInvoices i where p.PersonID = i.SalespersonPersonID);


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select  s.StockItemID
       ,s.StockItemName
       ,s.UnitPrice
from    Warehouse.StockItems s
where   s.UnitPrice = (select min(UnitPrice)from Warehouse.StockItems si);

select  s.StockItemID
       ,s.StockItemName
       ,s.UnitPrice
from    (select top 1 UnitPrice from Warehouse.StockItems si order by UnitPrice) m
join    Warehouse.StockItems s on s.UnitPrice = m.UnitPrice;

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

--1 вариант если один клиент дважды попал в топ 5 платежей, но должен вывестись один раз
select    distinct a.CustomerID
                  ,a.CustomerName
                  ,a.TransactionAmount
from      ( select    top 5 c.CustomerID
                           ,CustomerName
                           ,TransactionAmount
            from      Sales.CustomerTransactions ct
            join      Sales.Customers c on ct.CustomerID = c.CustomerID
            order by  TransactionAmount desc) a
order by  3 desc

--1.1 вариант с with
;
with topTransactionAmount as (select    top 5 ct.CustomerID
                                             ,TransactionAmount
                              from      Sales.CustomerTransactions ct
                              order by  TransactionAmount desc)
select    distinct c.CustomerID
                  ,CustomerName
                  ,TransactionAmount
from      topTransactionAmount t
join      Sales.Customers c on t.CustomerID = c.CustomerID
order by  3 desc;

--2 вариант если нужно вывести топ 5 платежей без учета повторного попадания в топ 5
select    top 5 c.CustomerID
               ,c.CustomerName
               ,TransactionAmount
from      ( select    CustomerID
                     ,max(TransactionAmount) TransactionAmount
            from      Sales.CustomerTransactions
            group by  CustomerID) ct
join      Sales.Customers c on ct.CustomerID = c.CustomerID
order by  TransactionAmount desc;

--2.1 вариант с with
;
with topTransactionAmount as (select    CustomerID
                                       ,max(TransactionAmount) TransactionAmount
                              from      Sales.CustomerTransactions
                              group by  CustomerID)
select    top 5 c.CustomerID
               ,CustomerName
               ,TransactionAmount
from      topTransactionAmount t
join      Sales.Customers c on t.CustomerID = c.CustomerID
order by  TransactionAmount desc;

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

--исправленный вариант
select    distinct CityID
                  ,CityName
                  ,FullName
--select *
from      (select top 3 UnitPrice from Warehouse.StockItems order by UnitPrice desc) si
join		Warehouse.StockItems ws on ws.UnitPrice = si.UnitPrice  --не уверена что OrderLines стоит соединять по UnitPrice, поэтому вызов таблицы еще раз
join      sales.OrderLines ol on ws.StockItemID = ol.StockItemID
join      Sales.Invoices i on ol.OrderID = i.OrderID
join      sales.Customers ct on ct.CustomerID = i.CustomerID
join      Application.People p on PackedByPersonID = p.PersonID
join      Application.Cities c on c.CityID = ct.DeliveryCityID
order by  1
         ,3;

--2 вариант
with topStockItemID as (select  top 3 UnitPrice from Warehouse.StockItems order by UnitPrice desc)
    ,cities as (select  distinct DeliveryCityID
                                ,PackedByPersonID
                from    topStockItemID t
				join	Warehouse.StockItems ws on t.UnitPrice = ws.UnitPrice
                join    sales.OrderLines ol on ws.StockItemID = ol.StockItemID
                join    Sales.Invoices i on ol.OrderID = i.OrderID
                join    sales.Customers ct on ct.CustomerID = i.CustomerID)
select    CityID
         ,CityName
         ,FullName
from      cities ct
join      Application.People p on PackedByPersonID = p.PersonID
join      Application.cities c on c.CityID = ct.DeliveryCityID
order by  1
         ,3;

/*
--исходный вариант
select    distinct CityID
                  ,CityName
                  ,FullName
--select *
from      (select top 3 StockItemID from Warehouse.StockItems order by UnitPrice desc) si
join      sales.OrderLines ol on si.StockItemID = ol.StockItemID
join      Sales.Invoices i on ol.OrderID = i.OrderID
join      sales.Customers ct on ct.CustomerID = i.CustomerID
join      Application.People p on PackedByPersonID = p.PersonID
join      Application.Cities c on c.CityID = ct.DeliveryCityID
order by  1
         ,3;

--2 вариант
with topStockItemID as (select  top 3 StockItemID from Warehouse.StockItems order by UnitPrice desc)
    ,cities as (select  distinct DeliveryCityID
                                ,PackedByPersonID
                from    topStockItemID t
                join    sales.OrderLines ol on t.StockItemID = ol.StockItemID
                join    Sales.Invoices i on ol.OrderID = i.OrderID
                join    sales.Customers ct on ct.CustomerID = i.CustomerID)
select    CityID
         ,CityName
         ,FullName
from      cities ct
join      Application.People p on PackedByPersonID = p.PersonID
join      Application.cities c on c.CityID = ct.DeliveryCityID
order by  1
         ,3;
*/

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
set statistics io, time on;
select    Invoices.InvoiceID
         ,Invoices.InvoiceDate
         ,( select  People.FullName
            from    Application.People
            where   People.PersonID = Invoices.SalespersonPersonID) as SalesPersonName
         ,SalesTotals.TotalSumm as TotalSummByInvoice
         ,( select  sum(OrderLines.PickedQuantity * OrderLines.UnitPrice)
            from    Sales.OrderLines
            where   OrderLines.OrderId = ( select Orders.OrderId
                                           from   Sales.Orders
                                           where  Orders.PickingCompletedWhen is not null
                                                  and Orders.OrderId = Invoices.OrderId)) as TotalSummForPickedItems
from      Sales.Invoices
join      ( select    InvoiceId
                     ,sum(Quantity * UnitPrice) as TotalSumm
            from      Sales.InvoiceLines
            group by  InvoiceId
            having    sum(Quantity * UnitPrice) > 27000) as SalesTotals on Invoices.InvoiceID = SalesTotals.InvoiceID
order by  TotalSumm desc;

-- --

--TODO: напишите здесь свое решение
/*Собирает данные по скомплектованным заказам с счет-фактурами, сумма которых больше 27000 */
/*Время ЦП в два раза меньше (было 296мс, стало 140 мс), затраченное время -  в 1,5 раза меньше (было 583 мс, стало 463 мс). 
Так же меньше сконирований индексов по таблицам и логических операций чтения
Например OrderLines сканирований было 22, стало 2; Orders было 12, стало 1*/
;with winvoices as (select    InvoiceId
                             ,sum(Quantity * UnitPrice) as TotalSumm
                    from      Sales.InvoiceLines
                    group by  InvoiceId
                    having    sum(Quantity * UnitPrice) > 27000)
     ,wOrder as (select o.OrderID
                       ,i.InvoiceID
                       ,i.InvoiceDate
                       ,wi.TotalSumm
                       ,i.SalespersonPersonID
                 from   winvoices wi
                 join   Sales.Invoices i on wi.InvoiceID = i.InvoiceID
                 join   Sales.Orders o on i.OrderID = o.OrderID
                 where  o.PickingCompletedWhen is not null)
select    i.InvoiceID
         ,i.InvoiceDate
         ,p.FullName SalesPersonName
         ,i.TotalSumm TotalSummByInvoice
         ,sum(ol.PickedQuantity * ol.UnitPrice) TotalSummForPickedItems
from      wOrder i
join      Sales.OrderLines ol on i.OrderID = ol.OrderID
join      Application.People p on i.SalespersonPersonID = p.PersonID
group by  i.InvoiceID
         ,i.InvoiceDate
         ,p.FullName
         ,i.TotalSumm
order by  TotalSumm desc;



/*******************************************************************************/
/* неоптимальные варианты
--  из них 1 и 2 по времени ЦП примерно столько же, как и итоговый, но больше затраченного времени в полтора раза. 
	Так же меньше сконирований индексов по таблицам и логических операций чтения по сравнению с исходным запросом
--  3 и 4 вариант по ресурсам занимают столько же, сколько и исходный вариант

--1 вариант
;with winvoices as (select   InvoiceId
                           ,sum(Quantity * UnitPrice) as TotalSumm
                   from     Sales.InvoiceLines
                   group by InvoiceId
                   having   sum(Quantity * UnitPrice) > 27000)
    ,wOrder as (select    o.OrderID
                         ,sum(ol.PickedQuantity * ol.UnitPrice) TotalSummForPickedItems
                from      Sales.Orders o
                join      Sales.OrderLines ol on o.OrderID = ol.OrderID
                where     o.PickingCompletedWhen is not null
                group by  o.OrderID)
select    i.InvoiceID
         ,i.InvoiceDate
         ,p.FullName
         ,wi.TotalSumm
         ,TotalSummForPickedItems
from      winvoices wi
join      Sales.Invoices i on wi.InvoiceID = i.InvoiceID
join      wOrder wo on wo.OrderID = i.OrderID
join      Application.People p on i.SalespersonPersonID = p.PersonID
order by  TotalSumm desc;

--2 вариант
;with winvoices as (select   InvoiceId
                           ,sum(Quantity * UnitPrice) as TotalSumm
                   from     Sales.InvoiceLines
                   group by InvoiceId
                   having   sum(Quantity * UnitPrice) > 27000)
select    i.InvoiceID
         ,i.InvoiceDate
         ,p.FullName
         ,wi.TotalSumm
         ,sum(ol.PickedQuantity * ol.UnitPrice) TotalSummForPickedItems
from      winvoices wi
join      Sales.Invoices i on wi.InvoiceID = i.InvoiceID
join      sales.Orders o on o.OrderID = i.OrderID
join      sales.OrderLines ol on ol.OrderID = o.OrderID
join      Application.People p on i.SalespersonPersonID = p.PersonID
where     o.PickingCompletedWhen is not null
group by  i.InvoiceID
         ,i.InvoiceDate
         ,p.FullName
         ,wi.TotalSumm
order by  TotalSumm desc;

--3 вариант
;with wOrder as (select    o.OrderID
                         ,sum(ol.PickedQuantity * ol.UnitPrice) TotalSummForPickedItems
                from      Sales.Orders o
                join      Sales.OrderLines ol on o.OrderID = ol.OrderID
                where     o.PickingCompletedWhen is not null
                group by  o.OrderID)
    ,wInvoices as (select   i.InvoiceID
                           ,i.InvoiceDate
                           ,o.TotalSummForPickedItems
                           ,SalespersonPersonID
                           ,sum(il.Quantity * il.UnitPrice) TotalSumm
                   from     wOrder o
                   join     Sales.Invoices i on o.OrderID = i.OrderID
                   join     Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
                   group by i.InvoiceID
                           ,i.InvoiceDate
                           ,o.TotalSummForPickedItems
                           ,SalespersonPersonID
                   having   sum(Quantity * UnitPrice) > 27000)
select    InvoiceID
         ,InvoiceDate
         ,FullName
         ,TotalSumm
         ,TotalSummForPickedItems
from      wInvoices wi
join      Application.People p on wi.SalespersonPersonID = p.PersonID
order by  TotalSumm desc;


--4 вариант
;with wOrder as (select    o.OrderID
                         ,sum(ol.PickedQuantity * ol.UnitPrice) TotalSummForPickedItems
                from      Sales.Orders o
                join      Sales.OrderLines ol on o.OrderID = ol.OrderID
                where     o.PickingCompletedWhen is not null
                group by  o.OrderID)
    ,wInvoices as (select   i.InvoiceID
                           ,i.InvoiceDate
                           ,o.TotalSummForPickedItems
                           ,SalespersonPersonID
                           ,sum(il.Quantity * il.UnitPrice) TotalSumm
                   from     wOrder o
                   join     Sales.Invoices i on o.OrderID = i.OrderID
                   join     Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
                   group by i.InvoiceID
                           ,i.InvoiceDate
                           ,o.TotalSummForPickedItems
                           ,SalespersonPersonID
                   having   sum(Quantity * UnitPrice) > 27000)
select    InvoiceID
         ,InvoiceDate
         ,FullName
         ,TotalSumm
         ,TotalSummForPickedItems
from      wInvoices wi
join      Application.People p on wi.SalespersonPersonID = p.PersonID
where     TotalSumm > 27000
order by  TotalSumm desc;

*************************************************************************************/


