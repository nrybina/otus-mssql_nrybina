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

/*����������
(��������� �����: 3619)
������� "StockItemTransactions". ������������ 1, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 66, ���������� �������� ������ LOB 1, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 130, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "StockItemTransactions". ������� ��������� 1, ��������� 0.
������� "OrderLines". ������������ 4, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 518, ���������� �������� ������ LOB 5, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 795, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "OrderLines". ������� ��������� 2, ��������� 0.
������� "Worktable". ������������ 0, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "CustomerTransactions". ������������ 5, ���������� �������� ������ 261, ���������� �������� ������ 4, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 253, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "Orders". ������������ 2, ���������� �������� ������ 883, ���������� �������� ������ 4, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 849, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "Invoices". ������������ 1, ���������� �������� ������ 67133, ���������� �������� ������ 2, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 11630, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "StockItems". ������������ 1, ���������� �������� ������ 2, ���������� �������� ������ 1, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.

(��������� ���� ������)

 ����� ������ SQL Server:
   ����� �� = 1031 ��, ����������� ����� = 1901 ��.

(��������� �����: 3619)
������� "OrderLines". ������������ 4, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 331, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "OrderLines". ������� ��������� 2, ��������� 0.
������� "Worktable". ������������ 0, ���������� �������� ������ 0, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "Invoices". ������������ 11767, ���������� �������� ������ 61156, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 2, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "Orders". ������������ 2, ���������� �������� ������ 883, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.
������� "StockItems". ������������ 1, ���������� �������� ������ 2, ���������� �������� ������ 0, �������� ������ ����������� ������� 0, �������� ������, ����������� � ����������� 0, �������� ������ ����������� �������, ����������� � ����������� 0, ���������� �������� ������ LOB 0, ���������� �������� ������ LOB 0, �������� ������ LOB ����������� ������� 0, �������� ������ LOB, ����������� � ����������� 0, �������� ������ LOB ����������� �������, ����������� � ����������� 0.

(��������� ���� ������)

 ����� ������ SQL Server:
   ����� �� = 375 ��, ����������� ����� = 1061 ��.

*/

/*�����: ����� ������ ������� ����������� � 2,5 ����
1.������ �� ������ StockItemTransactions � CustomerTransactions �� ��������� � �� ��������� � ��������,
�� ������� �� ����� ���������.
2.��� ������� Invoices ����������� ���������� ������������, �� ����������� ���������� �������� ������
3.���������� � ������� �������� � cte ��� ��������������� ���������� ������ 
*/


/***************************************************************************/
/* --��������� ��������
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
