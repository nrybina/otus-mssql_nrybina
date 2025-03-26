/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select    year(InvoiceDate) year
         ,month(InvoiceDate) month
         ,avg(UnitPrice) avgPrice
         ,sum(Quantity * UnitPrice) sumPrice
from      Sales.Invoices i
join      Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by  year(InvoiceDate)
         ,month(InvoiceDate)
order by  1
         ,2;

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select    year(InvoiceDate) year
         ,month(InvoiceDate) month
         ,sum(Quantity * UnitPrice) sumPrice
from      Sales.Invoices i
join      Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
group by  year(InvoiceDate)
         ,month(InvoiceDate)
having    sum(Quantity * UnitPrice) > 4600000
order by  1
         ,2;

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/
select    year(InvoiceDate) year
         ,month(InvoiceDate) month
         ,si.StockItemName
         ,sum(il.UnitPrice * il.Quantity) sumPrice
         ,min(InvoiceDate) firstDate
         ,sum(Quantity) count_q
from      Sales.Invoices i
join      Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
join      Warehouse.StockItems si on si.StockItemID = il.StockItemID
group by  year(InvoiceDate)
         ,month(InvoiceDate)
         ,si.StockItemName
having    sum(Quantity) < 50
order by  1
         ,2
         ,3;

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
declare @date date = '20130101';
--берем только 4 года
drop table if exists #fullMonth;
select  year(dateadd(mm, n.num - 1, @date)) y_month
       ,month(dateadd(mm, n.num - 1, @date)) m_month
into    #fullMonth
from    (select top 48 row_number() over (order by object_id) num from sys.all_objects) n;

--2 запрос
select    y_month
         ,m_month
         ,isnull(sumPrice, 0) sumPrice
from      ( select    year(InvoiceDate) year_date
                     ,month(InvoiceDate) month_date
                     ,sum(Quantity * UnitPrice) sumPrice
            from      Sales.Invoices i
            left join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
            group by  year(InvoiceDate)
                     ,month(InvoiceDate)
            having    sum(Quantity * UnitPrice) > 4600000) a
full join #fullMonth f on a.year_date = y_month
                          and month_date = m_month
order by  1
         ,2;

--3 запрос
select    y_month
         ,m_month
         ,isnull(StockItemName, '') StockItemName
         ,isnull(sumPrice, 0) sumPrice
         ,firstDate
         ,isnull(count_q, 0) count_q
from      ( select    year(InvoiceDate) year_date
                     ,month(InvoiceDate) month_date
                     ,si.StockItemName
                     ,sum(il.UnitPrice * il.Quantity) sumPrice
                     ,min(InvoiceDate) firstDate
                     ,sum(Quantity) count_q
            from      Sales.Invoices i
            join      Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
            join      Warehouse.StockItems si on si.StockItemID = il.StockItemID
            group by  year(InvoiceDate)
                     ,month(InvoiceDate)
                     ,si.StockItemName
            having    sum(Quantity) < 50) a
full join #fullMonth f on a.year_date = y_month
                          and month_date = m_month
order by  1
         ,2
         ,3;