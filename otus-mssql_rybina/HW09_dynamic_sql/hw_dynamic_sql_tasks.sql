/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

USE WideWorldImporters

/*

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

declare @column as nvarchar(max)
       ,@query  as nvarchar(max);

select  @column = isnull(@column + ',', '') + quotename(CustomerName)
from    ( select  distinct c.[CustomerName]
          from    Sales.Invoices inv
          join    Sales.Customers c on inv.CustomerID = c.CustomerID) t;
--select @column

set @query
  = N'SELECT 
    FORMAT(InvoiceDate,''dd.MM.yyyy'') AS InvoiceMonth,' + @column
    + N'
FROM (
    SELECT 
        dateadd(dd, 1- day(i.InvoiceDate) , InvoiceDate) InvoiceDate,
        c.CustomerName,
        COUNT(*) AS InvoiceCount
    FROM Sales.Invoices i
    JOIN Sales.Customers c ON i.CustomerID = c.CustomerID
    GROUP BY dateadd(dd, 1- day(i.InvoiceDate) , InvoiceDate), c.CustomerName
) cname
PIVOT(
    SUM(InvoiceCount)
    FOR CustomerName IN (' + @column + N')
) piv
ORDER BY InvoiceMonth;';
--select @query

execute sp_executesql @query;