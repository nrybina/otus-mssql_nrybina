set statistics time, io on

declare @ID_object int = 82263218

drop table if exists #KART_QUEUE
create table #KART_QUEUE (
  ID_LS int not null, bdate date, edate date
);

INSERT INTO #KART_QUEUE (ID_LS, bdate, edate)
select 		 k.ID1, bdateLS, isnull(edateLS, '20500101')
from        dbo.kart as k 
where       ID_object = @ID_object
and bdateLS <= isnull(edatels, '20500101') and isnull(edateLS, '20500101') >= getdate()

create nonclustered index inx_id_ls on #KART_QUEUE (ID_LS) 

/*******************************************/

drop table if exists #dedEconom_idt;
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.rn1
	   ,iif(e.id_serv=80017394, e.dataid, null) as dataid
into    #dedEconom_idt
from    (select d.parentid
               ,d.id_serv
               ,d.id_contrag
               ,d.pmonth
               ,d.initial_id_serv
               ,d.tariff
			   ,d.id
			   ,iif(d.id_serv=80017394, d.dataid, null) as dataid
               ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null), d.initial_id_serv order by id desc) rn
			   ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null) order by id desc) rn1
         from   test.dedEconom_tmp as d
         join   #KART_QUEUE as q on d.parentid = q.id_ls  ) e
where   e.rn = 1 

/*******************************************/

drop table if exists #dedEconom_idi;
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.rn1
	   ,e.dataid
into    #dedEconom_idi
from    (select d.parentid
               ,d.id_serv
               ,d.id_contrag
               ,d.pmonth
               ,d.initial_id_serv
               ,d.tariff
			   ,d.id
			   ,iif(d.id_serv=80017394, d.dataid, null) as dataid
               ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null), d.initial_id_serv order by id desc) rn
			   ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null) order by id desc) rn1
         from   test.dedEconom_index as d
         join   #KART_QUEUE as q on d.parentid = q.id_ls  
		 --where pmonth between bdate and edate
		 ) e
where   e.rn = 1 

/*******************************************/

drop table if exists #dedEconom_idp;
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.rn1
	   ,e.dataid
into    #dedEconom_idp
from    (select d.parentid
               ,d.id_serv
               ,d.id_contrag
               ,d.pmonth
               ,d.initial_id_serv
               ,d.tariff
			   ,d.id
			   ,iif(d.id_serv=80017394, d.dataid, null) as dataid
               ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null), d.initial_id_serv order by id desc) rn
			   ,row_number() over (partition by d.parentid, d.id_serv, d.id_contrag, d.pmonth, d.tariff, iif(d.id_serv=80017394, d.dataid, null) order by id desc) rn1
         from   test.dedEconom_part_ls as d
         join   #KART_QUEUE as q on d.parentid = q.id_ls  
		 ) e
where   e.rn = 1 
