/********************************************************/
/*создаем копии таблиц для тестирования изменений
dedEconom - исходная таблица без неактульных записей
dedEconom_index - таблица с перестроенными индексами без неактульных записей
dedEconom_part_ls - секционированная таблица  без неактульных записей
*/

/*чистим таблицу от "лишних" данных. Полностью оставляем данные за последние 6 месяцев, по остальным
оставляем последнюю запись в разрезе parentid(id ЛС)/id_serv/id_contrag/pmonth/tariff/dataid/initial_id_serv*/
--миграция данных
declare @ddate date = dateadd(m, -6, dbo.bomonth('20250401'));

drop table if exists #id;
with wEconom as (select d.id
                       ,row_number() over (partition by d.parentid
                                                       ,d.id_serv
                                                       ,d.id_contrag
                                                       ,d.pmonth
                                                       ,d.tariff
                                                       ,iif(d.id_serv = 80017394, d.dataid, null)
                                                       ,d.initial_id_serv
                                           order by id desc) rn
                 from   dbo.dedEconom as d
                 where  @ddate > d.ddate)
select  id into #id from wEconom where rn = 1;
create nonclustered index id_ix on #id (id);

select  i.id
       ,parentid
       ,ded
       ,tariff
       ,volume
       ,id_serv
       ,id_contrag
       ,pmonth
       ,ddate
       ,uchid
       ,dataid
       ,dednp
       ,initial_id_serv
       ,previous_ded_econom
into    test.dedEconom_tmp
from    #id i
join    dbo.dedEconom d on d.id = i.id;


insert into test.dedEconom_tmp (id
                           ,parentid
                           ,ded
                           ,tariff
                           ,volume
                           ,id_serv
                           ,id_contrag
                           ,pmonth
                           ,ddate
                           ,uchid
                           ,dataid
                           ,dednp
                           ,initial_id_serv
                           ,previous_ded_econom)
select  id
       ,parentid
       ,ded
       ,tariff
       ,volume
       ,id_serv
       ,id_contrag
       ,pmonth
       ,ddate
       ,uchid
       ,dataid
       ,dednp
       ,initial_id_serv
       ,previous_ded_econom
from    dbo.dedEconom d
where   @ddate <= d.ddate;


create clustered index [ddate_cix] on test.dedEconom_tmp ([ddate]) with (fillfactor = 90, pad_index = on) on [PRIMARY]; 
create nonclustered index [parentid_ix] on test.dedEconom_tmp ([parentid]) with (fillfactor = 90, pad_index = on) on [PRIMARY]; 
--create nonclustered index [lastMonth_ix] on test.dedEconom ([lastMonth]) with (fillfactor=90, pad_index=on) on [PRIMARY]
create nonclustered index [dedEconom_ix] on test.dedEconom_tmp ([parentid], [id_serv], [id_contrag], [pmonth], [initial_id_serv], [tariff]) on [PRIMARY]; 

--truncate table test.dedEconom;
--drop table test.dedEconom;
/********************************************************/

--создаем таблицу для архива данных
select  top 1 id
             ,parentid
             ,ded
             ,tariff
             ,volume
             ,id_serv
             ,id_contrag
             ,pmonth
             ,ddate
             ,uchid
             ,dataid
             ,dednp
             ,initial_id_serv
             ,previous_ded_econom
into    GKUBK.dbo.dedEconom_testarch
from    dbo.dedEconom;

truncate table GKUBK.dbo.dedEconom_testarch;

/********************************************************/
exec move_old_dedEconom_in_archiveBK @date = '20250408';
/********************************************************/
/****************************************************************************************************************/

select  id
       ,parentid
       ,ded
       ,tariff
       ,volume
       ,id_serv
       ,id_contrag
       ,pmonth
       ,ddate
       ,uchid
       ,dataid
       ,dednp
       ,initial_id_serv
       ,previous_ded_econom
into    test.dedEconom_index
from    test.dedEconom d 

create clustered index  parentid_ix on test.dedEconom_index (parentid)
CREATE NONCLUSTERED INDEX [dedEconom_ix] ON test.dedEconom_index (parentid, [id_serv], [id_contrag], pmonth, [tariff],[initial_id_serv]) include ( dataid, id ) ON [PRIMARY]

--drop table test.dedEconom_index;
/****************************************************************************************************************/

select  id
       ,parentid
       ,ded
       ,tariff
       ,volume
       ,id_serv
       ,id_contrag
       ,pmonth
       ,ddate
       ,uchid
       ,dataid
       ,dednp
       ,initial_id_serv
       ,previous_ded_econom
into    test.dedEconom_part_ls
from    test.dedEconom_tmp d 

--create clustered index  parentid_ix on test.dedEconom_part_ls (parentid)
--CREATE NONCLUSTERED INDEX [dedEconom_ix] ON test.dedEconom_part_ls (parentid, [id_serv], [id_contrag], pmonth, [tariff],[initial_id_serv]) include( dataid, id ) 

--drop table test.dedEconom_part_ls
/****************************************************************************************************************/

select  count(*) from dbo.dedEconom;
select  count(*) from test.dedEconom;
select  count(*) from test.dedEconom_index
select  count(*) from test.dedEconom_part_ls


update statistics test.dedEconom_tmp
update statistics test.dedEconom_index
update statistics test.dedEconom_part_ls