SET QUOTED_IDENTIFIER ON
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		n.rybina
-- Create date: '20250414'
-- Description:	Процедура переноса устаревших данных (экономии) в архивную таблицу
-- =============================================

create procedure move_old_dedEconom_in_archiveBK @date date
as
  begin
    set nocount on;

    declare @ddate date = dateadd(m, -6, dbo.bomonth(@date));
	declare @error_msg nvarchar(2000)

    drop table if exists #id;
    with wEconom as (select d.id
                           ,d.parentid
                           ,row_number() over (partition by d.parentid
                                                           ,d.id_serv
                                                           ,d.id_contrag
                                                           ,d.pmonth
                                                           ,d.tariff
                                                           ,iif(d.id_serv = 80017394, d.dataid, null)
                                                           ,d.initial_id_serv
                                               order by id desc) rn
                     from   test.dedEconom_part_ls as d
                     where  @ddate > d.ddate)
    select id, parentid into #id from wEconom where rn != 1;

    create clustered index parentid_ix on #id (parentid);

    begin try
      begin transaction;

	  --переносим в архив
      set identity_insert GKUBK.dbo.dedEconom_testarch on;
      insert into GKUBK.dbo.dedEconom_testarch (id
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
      select  i.id
             ,i.parentid
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
      from    #id i
      join    test.dedEconom_part_ls d on d.id = i.id
                                          and d.parentid = i.parentid;
      set identity_insert GKUBK.dbo.dedEconom_testarch off;

      --select count(*) from GKUBK.dbo.dedEconom_testarch
      --select count(*) from test.dedEconom_part_ls


      --удалим перенесенные данные из dedEconom_part_ls
      merge into test.dedEconom_part_ls as target
      using #id as source
      on source.parentid = target.parentid
         and target.id = source.id
      when matched then delete;


      /**********************************************************************/

      --переменная, которая соберет скрипт для исполнения по индексам
      declare @maintenance_index_script nvarchar(max);

      --найдем индексы dedEconom_part_ls, который нужно обслужить после всех переносов
      with index_fragmentation_data as (select      IndStat.object_id
                                                   ,quotename(s.name) + '.' + quotename(o.name) as object_name
                                                   ,IndStat.index_id
                                                   ,quotename(i.name) as index_name
                                                   ,IndStat.avg_fragmentation_in_percent
                                                   ,IndStat.partition_number
                                                   ,iif(i.type in (5, 6), 1, 0) as isColumnstore
                                        --select *
                                        from        sys.dm_db_index_physical_stats(db_id('gku'), object_id('gku.test.dedEconom_part_ls'), null, null, 'LIMITED') as IndStat
                                        inner join  sys.objects as o on (IndStat.object_id = o.object_id)
                                        inner join  sys.schemas as s on s.schema_id = o.schema_id
                                        inner join  sys.indexes as i on ( i.object_id = IndStat.object_id
                                                                          and i.index_id = IndStat.index_id)
                                        where       IndStat.avg_fragmentation_in_percent >= 15)
          ,index_create_scripts as (select  i.object_id
                                           ,i.index_id
                                           ,i.partition_number
                                           ,'alter index ' + i.index_name + ' on ' + i.object_name
                                            + iif(i.isColumnstore = 1 or i.avg_fragmentation_in_percent < 30, ' reorganize ', ' rebuild ') + 'partition = '
                                            + cast(i.partition_number as varchar(5)) + ';' + char(10) as script
                                    from    index_fragmentation_data as i
                                    where   i.isColumnstore = 0
                                            or ( i.isColumnstore = 1
                                                 and i.avg_fragmentation_in_percent >= 20))
      select  @maintenance_index_script = ( select    index_create_scripts.script + ''
                                            from      index_create_scripts
                                            order by  index_create_scripts.object_id
                                                     ,index_create_scripts.index_id
                                                     ,index_create_scripts.partition_number
                                            for xml path(''));

      select  @maintenance_index_script;
      --выполним обслуживание индексов (только в нужных секциях)
      exec (@maintenance_index_script);


      --обновим статистику
      update statistics test.dedEconom_part_ls;

      --rollback
      commit;
    end try
    begin catch
      set @error_msg = N'Ошибка переноса dedEconom' + char(13) + error_message();
      raiserror(@error_msg, 16, 1);
      rollback;
      return;
    end catch;

  end;