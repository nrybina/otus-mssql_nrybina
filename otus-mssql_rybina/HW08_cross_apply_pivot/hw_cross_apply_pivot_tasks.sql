/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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

use WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/
;
with wCustomers as (select    substring(c.CustomerName, charindex('(', c.CustomerName) + 1, len(c.CustomerName) - charindex('(', c.CustomerName) - 1) CustomerName
                             ,dateadd(day, -day(InvoiceDate) + 1, InvoiceDate) InvoiceDate
                             ,count(InvoiceID) countInvoice
                    from      Sales.Invoices i
                    join      sales.Customers c on i.CustomerID = c.CustomerID
                    where     c.CustomerID between 2 and 6
                    group by  c.CustomerName
                             ,dateadd(day, -day(InvoiceDate) + 1, InvoiceDate))
select  InvoiceDate
       ,[Peeples Valley, AZ]
       ,[Medicine Lodge, KS]
       ,[Gasport, NY]
       ,[Sylvanite, MT]
       ,[Jessie, ND]
from    (select CustomerName, InvoiceDate, countInvoice from wCustomers) c
pivot ( sum(countInvoice)
        for CustomerName in ([Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND])) as t;

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/
select  c.CustomerName
       ,PostalAddressLine1 AddressLine
from    sales.Customers c
where   CustomerName like '%Tailspin Toys%'
union
select  c.CustomerName
       ,PostalAddressLine2
from    sales.Customers c
where   CustomerName like '%Tailspin Toys%'
union
select  c.CustomerName
       ,DeliveryAddressLine1
from    sales.Customers c
where   CustomerName like '%Tailspin Toys%'
union
select  c.CustomerName
       ,DeliveryAddressLine2
from    sales.Customers c
where   CustomerName like '%Tailspin Toys%'
order by  1;

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select  CountryID, CountryName, IsoAlpha3Code from Application.Countries
union all
select  CountryID
       ,CountryName
       ,cast(IsoNumericCode as nvarchar(100))
from    Application.Countries
order by  1
         ,2;

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select      c.CustomerID
           ,c.CustomerName
           ,si.StockItemID
           ,si.UnitPrice
           ,si.InvoiceDate
from        Sales.Customers c
cross apply ( select    top 2 StockItemID
                             ,UnitPrice
                             ,InvoiceDate
              from      Sales.Invoices i
              join      sales.InvoiceLines l on i.InvoiceID = l.InvoiceID
              where     c.CustomerID = i.CustomerID
              order by  UnitPrice desc) si
order by    1
           ,3
           ,4 desc;

