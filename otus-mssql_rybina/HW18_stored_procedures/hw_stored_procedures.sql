/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

create function dbo.maxOrder ()
returns nvarchar(100)
  begin
    declare @max nvarchar(100);
    set @max = ( select   top 1 c.CustomerName
                 from     Sales.Invoices i
                 join     Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
                 join     Sales.Customers c on c.CustomerID = i.CustomerID
                 group by c.CustomerName
                 order by sum(il.Quantity * il.UnitPrice) desc);
    return @max;
  end;

select dbo.maxOrder()


/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

create procedure dbo.sumInv (@CustomerID int)
as
  begin
    select  sum(il.Quantity * il.UnitPrice)
    from    Sales.Invoices i
    join    Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
    join    Sales.Customers c on c.CustomerID = i.CustomerID
    where   c.CustomerID = @CustomerID;
  end;

exec dbo.sumInv 143
exec dbo.sumInv @CustomerID = 143

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/
create procedure dbo.procGetSum (@CustomerID int)
as
  begin
    select  sum(il.Quantity * il.UnitPrice)
    from    Sales.Invoices i
    join    Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
    join    Sales.Customers c on c.CustomerID = i.CustomerID
    where   c.CustomerID = @CustomerID;
  end;

create function dbo.funGetSum (@CustomerID int)
returns decimal(18, 2)
  begin
    declare @sum decimal(18, 2);
    set @sum = ( select sum(il.Quantity * il.UnitPrice)
                 from   Sales.Invoices i
                 join   Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
                 join   Sales.Customers c on c.CustomerID = i.CustomerID
                 where  c.CustomerID = @CustomerID);
    return @sum;
  end;

SET STATISTICS TIME ON
select dbo.funGetSum(143)
exec dbo.procGetSum 143

/*время работы процедуры в разы быстрее, т.к. меньшее количество операций при выполнении. Так же ХП кэшируют план выполнения, за счет чего выполняются быстрее*/

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

create function dbo.fGetOrder (@CustomerID int)
returns table
as
return select i.OrderID
             ,il.Quantity * il.UnitPrice sumOrder
       from   Sales.Invoices i
       join   Sales.InvoiceLines il on i.InvoiceID = il.InvoiceID
       where  i.CustomerID = @CustomerID;

select      c.CustomerName
           ,f.OrderID
           ,f.sumOrder
from        Sales.Customers c
cross apply dbo.fGetOrder(CustomerID) f;

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
