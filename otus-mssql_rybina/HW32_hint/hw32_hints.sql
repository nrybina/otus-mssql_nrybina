set statistics time, io on

Select ord.CustomerID, det.StockItemID, SUM(det.UnitPrice), SUM(det.Quantity), COUNT(ord.OrderID)    
FROM Sales.Orders AS ord
    JOIN Sales.OrderLines AS det
        ON det.OrderID = ord.OrderID
    JOIN Sales.Invoices AS Inv 
        ON Inv.OrderID = ord.OrderID
    JOIN Sales.CustomerTransactions AS Trans
        ON Trans.InvoiceID = Inv.InvoiceID
    JOIN Warehouse.StockItemTransactions AS ItemTrans
        ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
    AND (Select SupplierId
         FROM Warehouse.StockItems AS It
         Where It.StockItemID = det.StockItemID) = 12
    AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
        FROM Sales.OrderLines AS Total
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
        WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
    AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

;with wStockItems as (
Select StockItemID
         FROM Warehouse.StockItems AS It
         Where SupplierID = 12
)
,wCustomerID as (
select CustomerID, sum(UnitPrice*Quantity)  sum_
from Sales.OrderLines AS Total  
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
group by CustomerID
having sum(UnitPrice*Quantity) > 250000
)
select c.CustomerID, s.StockItemID, sum(ol.UnitPrice), sum(ol.Quantity), count(o.OrderID) 
from wCustomerID c
join Sales.Orders AS o
                On o.CustomerID = c.CustomerID
join Sales.OrderLines ol on o.OrderID = ol.OrderID
join wStockItems s on s.StockItemID = ol.StockItemID
join sales.Invoices i on o.OrderID = i.OrderID
where i.BillToCustomerID != c.CustomerID
and DATEDIFF(dd, i.InvoiceDate, o.OrderDate) = 0
group by c.CustomerID, s.StockItemID
order by c.CustomerID, s.StockItemID

/*Статистика
(затронуто строк: 3619)
Таблица "StockItemTransactions". Сканирований 1, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 66, физических операций чтения LOB 1, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 130, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItemTransactions". Считано сегментов 1, пропущено 0.
Таблица "OrderLines". Сканирований 4, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 518, физических операций чтения LOB 5, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 795, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 2, пропущено 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "CustomerTransactions". Сканирований 5, логических операций чтения 261, физических операций чтения 4, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 253, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Orders". Сканирований 2, логических операций чтения 883, физических операций чтения 4, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 849, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 1, логических операций чтения 67133, физических операций чтения 2, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 11630, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItems". Сканирований 1, логических операций чтения 2, физических операций чтения 1, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

(затронута одна строка)

 Время работы SQL Server:
   Время ЦП = 1031 мс, затраченное время = 1901 мс.

(затронуто строк: 3619)
Таблица "OrderLines". Сканирований 4, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 331, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "OrderLines". Считано сегментов 2, пропущено 0.
Таблица "Worktable". Сканирований 0, логических операций чтения 0, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Invoices". Сканирований 11767, логических операций чтения 61156, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 2, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "Orders". Сканирований 2, логических операций чтения 883, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.
Таблица "StockItems". Сканирований 1, логических операций чтения 2, физических операций чтения 0, операций чтения страничного сервера 0, операций чтения, выполненных с упреждением 0, операций чтения страничного сервера, выполненных с упреждением 0, логических операций чтения LOB 0, физических операций чтения LOB 0, операций чтения LOB страничного сервера 0, операций чтения LOB, выполненных с упреждением 0, операций чтения LOB страничного сервера, выполненных с упреждением 0.

(затронута одна строка)

 Время работы SQL Server:
   Время ЦП = 375 мс, затраченное время = 1061 мс.

*/

/*Вывод: Время работы запроса сократилось в 2,5 раза
1.Данные из таблиц StockItemTransactions и CustomerTransactions не выводятся и не участвуют в фильтрах,
из запроса их можно исключить.
2.Для таблицы Invoices увеличилось количество сканирований, но уменьшилось количество операций чтения
3.Подзапросы в условии вынесены в cte для предварительной фильтрации данных 
*/


/***************************************************************************/
/* --неудачные варианты
;With wCustomerID as (
select ordTotal.CustomerID, StockItemID , ordTotal.OrderID, ordTotal.OrderDate,   UnitPrice, Quantity,  sum(UnitPrice*Quantity) over (partition by ordTotal.CustomerID) sum_
from Sales.OrderLines AS Total  
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
--and DATEDIFF(dd, Inv.InvoiceDate, ordTotal.OrderDate) = 0
--order by 1,3
)
,wStockItems as (
Select c.CustomerID, c.StockItemID , c.OrderID, c.OrderDate,  c.UnitPrice, c.Quantity
         FROM wCustomerID c
		 join Warehouse.StockItems AS It on c.StockItemID = It.StockItemID
         Where SupplierID = 12 and sum_ >250000
)
select c.CustomerID, c.StockItemID, sum(UnitPrice), sum(Quantity), count(c.OrderID) 
from wStockItems c
join Sales.Invoices AS Inv 
        ON Inv.OrderID = c.OrderID
where Inv.BillToCustomerID != c.CustomerID 
and DATEDIFF(dd, inv.InvoiceDate, c.OrderDate) = 0
GROUP BY c.CustomerID, c.StockItemID
ORDER BY c.CustomerID, c.StockItemID


;with wStockItems as (
Select StockItemID
         FROM Warehouse.StockItems AS It
         Where SupplierID = 12
)
,wCustomerID as (
select ordTotal.CustomerID, ordTotal.OrderID, Inv.InvoiceDate, ordTotal.OrderDate, StockItemID,  UnitPrice, Quantity,  sum(UnitPrice*Quantity) over (partition by ordTotal.CustomerID) sum_
from Sales.OrderLines AS Total  
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
join Sales.Invoices AS Inv 
        ON Inv.OrderID = ordTotal.OrderID
where Inv.BillToCustomerID != ordTotal.CustomerID 
--and DATEDIFF(dd, Inv.InvoiceDate, ordTotal.OrderDate) = 0
--order by 1,3
)
select c.CustomerID, s.StockItemID, sum(UnitPrice), sum(Quantity), count(c.OrderID) 
from wCustomerID c
join wStockItems s on s.StockItemID = c.StockItemID
where 
sum_>250000 
and DATEDIFF(dd, c.InvoiceDate, c.OrderDate) = 0
GROUP BY c.CustomerID, s.StockItemID
ORDER BY c.CustomerID, s.StockItemID


;with wStockItems as (
Select StockItemID
         FROM Warehouse.StockItems AS It
         Where SupplierID = 12
)
,wCustomerID as (
select CustomerID, ordTotal.OrderID, StockItemID, orderDate, UnitPrice, Quantity,  sum(UnitPrice*Quantity) over (partition by CustomerID) sum_
from Sales.OrderLines AS Total  
            Join Sales.Orders AS ordTotal
                On ordTotal.OrderID = Total.OrderID
--order by 1,3
)
select c.CustomerID, s.StockItemID, sum(UnitPrice), sum(Quantity), count(c.OrderID) from wCustomerID c
join wStockItems s on s.StockItemID = c.StockItemID
JOIN Sales.Invoices AS Inv 
        ON Inv.OrderID = c.OrderID
where Inv.BillToCustomerID != c.CustomerID 
and sum_>250000 
and DATEDIFF(dd, Inv.InvoiceDate, c.OrderDate) = 0
GROUP BY c.CustomerID, s.StockItemID
ORDER BY c.CustomerID, s.StockItemID
*/
