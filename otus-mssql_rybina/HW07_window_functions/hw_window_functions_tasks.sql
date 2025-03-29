/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
-- ---------------------------------------------------------------------------

use WideWorldImporters;
/*
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

drop table if exists #summ_tmp;
select    i.InvoiceID
         ,i.CustomerID
         ,i.InvoiceDate
         ,sum(l.UnitPrice * l.Quantity) summ
into      #summ_tmp
from      Sales.Invoices i
join      sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
group by  i.InvoiceID
         ,i.CustomerID
         ,i.InvoiceDate
order by  2
         ,3;

select    t.InvoiceID
         ,c.CustomerName
         ,t.InvoiceDate
         ,summ
         ,( select  sum(summ)
            from    #summ_tmp s
            where   s.CustomerID = t.CustomerID
                    and s.InvoiceDate <= eomonth(t.InvoiceDate)) summAll
from      #summ_tmp t
join      Sales.Customers c on t.CustomerID = c.CustomerID
order by  2
         ,3


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
;
with wInvoices as (select   i.InvoiceID
                           ,i.CustomerID
                           ,i.InvoiceDate
                           ,sum(l.UnitPrice * l.Quantity) summ
                           ,eomonth(InvoiceDate) emInvoiceDate
                   from     Sales.Invoices i
                   join     sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
                   group by i.InvoiceID
                           ,i.CustomerID
                           ,i.InvoiceDate
                           ,i.CustomerID)
    ,summMonth as (select w.InvoiceID
                         ,w.CustomerID
                         ,w.InvoiceDate
                         ,emInvoiceDate
                         ,summ
                         ,dense_rank() over (partition by w.CustomerID order by w.CustomerID, emInvoiceDate) num
                   from   wInvoices w)
--select * from summMonth
select    w.InvoiceID
         ,c.CustomerName
         ,w.InvoiceDate
         ,summ
         ,sum(summ) over (partition by w.CustomerID order by num)
from      summMonth w
join      Sales.Customers c on w.CustomerID = c.CustomerID
order by  2
         ,3

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/
;
with wStockItem as (select    StockItemID
                             ,month(InvoiceDate) monthInvoiceDate
                             ,sum(Quantity) TotalQuantity
                    from      sales.Invoices i
                    join      Sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
                    where     year(i.InvoiceDate) = 2016
                    group by  StockItemID
                             ,month(InvoiceDate))
    ,wStockItemQuantity as (select  StockItemID
                                   ,monthInvoiceDate
                                   ,TotalQuantity
                                   ,row_number() over (partition by monthInvoiceDate order by TotalQuantity desc) num
                            from    wStockItem)
select    monthInvoiceDate
         ,w.StockItemName
         ,TotalQuantity
from      wStockItemQuantity s
join      Warehouse.StockItems w on s.StockItemID = w.StockItemID
where     num <= 2
order by  1
         ,3 desc;

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select    s.StockItemID
         ,s.StockItemName
         ,s.Brand
         ,s.UnitPrice
         ,s.TypicalWeightPerUnit
         ,row_number() over (partition by substring(StockItemName, 1, 1)order by StockItemName) numStockItemName
         ,count(*) over () countTotalStockItem
         ,count(*) over (partition by substring(StockItemName, 1, 1)) countStockItemName
         ,lead(StockItemID, 1) over (order by StockItemName) lastStockItemId
         ,lag(StockItemID, 1) over (order by StockItemName) prevStockItemId
         ,isnull(last_value(StockItemName) over (order by StockItemName rows between 2 preceding and 2 preceding), 'No items') lastStockItemName
         ,ntile(30) over (order by s.TypicalWeightPerUnit) groupTypicalWeightPerUnit
--select *, substring(StockItemName,1, 1)
from      Warehouse.StockItems s
order by  StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/
;
with wInvoices_tmp as (select   i.SalespersonPersonID
                               ,i.CustomerID
                               ,InvoiceDate
                               ,sum(l.Quantity * l.UnitPrice) summInvoices
                       from     Sales.Invoices i
                       join     sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
                       group by i.SalespersonPersonID
                               ,i.CustomerID
                               ,InvoiceDate)
    ,wInvoices as (select SalespersonPersonID
                         ,CustomerID
                         ,InvoiceDate
                         ,summInvoices
                         ,row_number() over (partition by SalespersonPersonID order by InvoiceDate desc) num
                   from   wInvoices_tmp w)
select    w.SalespersonPersonID
         ,p.FullName
         ,w.CustomerID
         ,c.CustomerName
         ,w.InvoiceDate
         ,w.summInvoices
from      wInvoices w
join      sales.Customers c on w.CustomerID = c.CustomerID
join      Application.People p on w.SalespersonPersonID = p.PersonID
where     num = 1
order by  1
         ,3
         ,5

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/
;
with wInvoices as (select i.CustomerID
                         ,l.StockItemID
                         ,l.UnitPrice
                         ,i.InvoiceDate
                         ,row_number() over (partition by CustomerID order by UnitPrice desc) num
                   from   Sales.Invoices i
                   join   sales.InvoiceLines l on i.InvoiceID = l.InvoiceID)
select    w.CustomerID
         ,c.CustomerName
         ,w.StockItemID
         ,w.UnitPrice
         ,w.InvoiceDate
from      wInvoices w
join      Sales.Customers c on w.CustomerID = c.CustomerID
where     num <= 2
order by  1
         ,3
         ,4 desc;