alter database gku add filegroup dedEconomLs
alter database gku add file (name = 'dedEconomLs', filename = 'G:\MSSQL\DB\GKU\dedEconomLs.ndf') to filegroup dedEconomLs

create PARTITION FUNCTION pf_int_parentid (int)
AS RANGE RIGHT FOR VALUES (500000, 1000000, 1100000, 1200000, 1300000, 1400000, 1500000, 1600000, 1700000, 1800000, 1900000, 2000000);

CREATE PARTITION SCHEME ps_int_parentid
AS PARTITION pf_int_parentid
ALL TO (dedEconomLs);

--dedEconom_part_ls уже существует, поэтому просто создадим индексы по схеме

/*create table dedEconom_part_ls ([id] [int] not null identity(1, 1)
                               ,[parentid] [int] not null
                               ,[ded] [money] not null constraint [DF__dedEconom__ded__10DE80A5] default ((0))
                               ,[tariff] [decimal](15, 5) null constraint [DF__dedEconom__tarif__11D2A4DE] default ((0))
                               ,[volume] [float] null constraint [DF__dedEconom__volum__12C6C917] default ((0))
                               ,[id_serv] [int] not null
                               ,[id_contrag] [int] not null
                               ,[pmonth] [date] not null
                               ,[ddate] [date] not null
                               ,[uchid] [int] null
                               ,[dataid] [int] null
                               ,[dednp] [money] not null constraint [DF__dedEconom__dednp__25D99D8B] default ((0))
                               ,[initial_id_serv] [int] null
                               ,[previous_ded_econom] [int] null);
*/

create clustered index pk_parentid on test.dedEconom_part_ls (parentid) on ps_int_parentid(PARENTID)
create nonclustered index [dedEconom_ix] on test.dedEconom_part_ls (PARENTID, [ID_SERV], [ID_CONTRAG], PMONTH, [TARIFF], [initial_id_serv]) include ( DATAID, ID) on ps_int_parentid(PARENTID);


/*
select $partition.pf_int_parentid(parentid) as section, min(parentid) as [min], max(parentid) as [max],
    count(*) as qty, fg.name as fg
from test.dedEconom_part_ls
join sys.partitions p on $partition.pf_int_parentid(parentid) = p.partition_number
join sys.destination_data_spaces dds on p.partition_number = dds.destination_id
join sys.filegroups fg on dds.data_space_id = fg.data_space_id
where p.object_id = object_id('test.dedEconom_part_ls') -- указываем имя таблицы
and fg.name = 'dedEconomLs'
group by $partition.pf_int_parentid(parentid), fg.name
order by section
*/