set statistics time on --, io on

declare @ID_object int = 82263218

drop table if exists #KART_QUEUE
create table #KART_QUEUE (
  ID_LS int not null, bdate date, edate date
);

INSERT INTO #KART_QUEUE (ID_LS, bdate, edate)
select				 k.ID1, bdateLS, isnull(edateLS, '20500101')
from        dbo.kart as k 
where       ID_object = @ID_object
and bdateLS <= isnull(edatels, '20500101') and isnull(edateLS, '20500101') >= getdate()

create nonclustered index inx_id_ls on #KART_QUEUE (ID_LS) 

drop table if exists #dedEconom_id;
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.rn1
	   ,e.dataid
into    #dedEconom_id
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
		 --where pmonth between bdate and edate
		 ) e
where   e.rn = 1 

create nonclustered index dedec_ix on #dedEconom_id (parentid, id_serv, ID_CONTRAG, PMONTH, tariff)
--create nonclustered index id_ix on #dedEconom_id (id)

drop table if exists #dedEconom_res;
--если последня id с initial_id_serv подтягиваем все остальные услуги
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.dataid
into    #dedEconom_res
from    #dedEconom_id i
join #dedEconom_id e
             on      e.parentid = i.parentid
                        and e.pmonth = i.pmonth
                        and e.tariff = i.tariff
                        and e.id_contrag = i.id_contrag
                        and e.id_serv = i.id_serv
                        --and e.id <> i.id
                        and e.initial_id_serv is not null
                        and e.initial_id_serv <> i.initial_id_serv
where   i.initial_id_serv is not null and  i.rn1 = 1
union
select  e.parentid
       ,e.id_serv
       ,e.id_contrag
       ,e.pmonth
       ,e.initial_id_serv
       ,e.tariff
	   ,e.id
	   ,e.dataid
from    #dedEconom_id e 
where e.rn1 = 1

--------------------------------

--соберем предварительно всю экономию, которая нам будет нужна
drop table if exists #dedEconom_tmp;
;with excludeContrag as
  (select 7527843 as id_contrag)
     ,excludeServ as
  (select 6095988 as id_serv
   union
   select 8109725
   union
   select 8109727)
     ,excludeServContrag as
(select 44294 as id_serv, 350 as id_contrag)
select  d.id
       ,d.parentid
       ,d.ded
	   ,d.tariff
	   ,d.volume
       ,d.id_serv
       ,d.id_contrag
       ,d.pmonth
       ,d.ddate
       ,d.uchid
       ,d.dataid
	   ,d.dednp
	   ,d.initial_id_serv
	   ,q.BDATE as bdate_act
	   ,q.EDATE as edate_act
	   ,d.previous_ded_econom 
into    #dedEconom_tmp
from    test.dedEconom_part_ls d
join    #KART_QUEUE q on d.parentid = q.ID_LS
join		#dedEconom_res as dei on dei.id = d.id 
left join excludeContrag as ec on ec.id_contrag = d.id_contrag
left join excludeServ as es on es.id_serv = d.id_serv
left join excludeServContrag as esc on esc.id_contrag = d.id_contrag
                                       and  esc.id_serv = d.id_serv
where   ec.id_contrag is null
        and es.id_serv is null
        and esc.id_serv is null

drop table if exists #dedEconom;
select  d.id
       ,d.parentid
       ,d.ded
       ,d.tariff
       ,d.volume
       ,d.id_serv
       ,d.id_contrag
       ,d.pmonth
       ,d.ddate
       ,d.uchid
       ,d.dataid
       ,d.dednp
       ,d.initial_id_serv
	   ,d.previous_ded_econom 
into    #dedEconom
from    #dedEconom_tmp as d
where   d.pmonth between d.bdate_act and d.edate_act;


--плюс добавим экономию по воде для ВО (при наличии услуги инициатора), если она еще не поднята
INSERT INTO #dedEconom (id
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
select    det.id
         ,det.parentid
         ,det.ded
         ,det.tariff
		 ,det.volume
		 ,det.id_serv
		 ,det.id_contrag
         ,det.pmonth
         ,det.ddate
         ,det.uchid
         ,det.dataid
		 ,det.dednp
         ,det.initial_id_serv
		 ,det.previous_ded_econom 
from      #dedEconom_tmp as initial_serv
join      #dedEconom_tmp as det on det.parentid = initial_serv.parentid
                                   and det.id_contrag = initial_serv.id_contrag
                                   and det.pmonth = initial_serv.pmonth
                                   and det.id_serv = initial_serv.initial_id_serv
left join #dedEconom as de on de.parentid = det.parentid
                              and de.id_contrag = det.id_contrag
                              and de.id_serv = det.id_serv
                              and de.pmonth = initial_serv.pmonth
where     initial_serv.initial_id_serv is not null
          and de.id is null; 

return
select  d.id
       ,d.parentid
       ,d.ded
       ,d.id_serv
       ,d.id_contrag
	   ,d.tariff
	   ,d.volume
       ,d.pmonth
       ,d.ddate
       ,d.uchid
       ,d.dataid
	   ,d.dednp
	   ,d.initial_id_serv
	   ,D.previous_ded_econom
from    #dedEconom d