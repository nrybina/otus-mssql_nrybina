/*
Описание таблиц рабочего проекта.
Сфера ЖКХ. Ежемесячно для Абонентов проводятся начисления за потребление коммунальных услуг. 
Список Лицевых счетов, для которых проходят расчеты лежит в таблице kart.
В таблицах ref_services, ref_contrag  - список услуг и контрагентов, по которым проходят начисления. 
В таблице ref_houses - справочник домов

Ежемесячно в рамках начисления по ЛС рассчитывается экономия. Экономия — отрицательная разница между общедомовым объёмом потребления и объёмом, 
начисленным по данной услуге по всем жилым и нежилым помещениям данного дома. Данные по рассчитанной экономии лежат в dedEconom. Сумма экономии, 
которая была начислена в Лицевой счет лежит в таблице dedTransfer. Общедомовой объем, по которому была рссчитана экономия в HousePUVolumes

Приложила диаграмму, но часть полей из нее убрала, чтобы не перегружать.
*/


create TABLE [dbo].[kart](
	[ID1] [int] NOT NULL,
	[LS] [varchar](10) NULL,
	[Cod] [varchar](10) NULL,
	[LSCod] [varchar](15) NULL,
	[Fio] [varchar](100) NULL,
	[Flat] [varchar](50) NULL,
	[AllMetr] [smallmoney] NULL,
	[LivMetr] [smallmoney] NULL,
	[DopMetr] [smallmoney] NULL,
	[BronMetr] [varchar](8) NULL,
	[LoggMetr] [smallmoney] NULL,
	[BalcMetr] [smallmoney] NULL,
	[kk] [varchar](5) NULL,
	[ID_object] [int] NOT NULL,
	[rooms] [tinyint] NULL,
	[codene] [char](10) NULL,
	[subpos] [bit] NULL,
	[floor] [nvarchar](5) NULL,
	[entrance] [nvarchar](5) NULL,
	[income] [int] NULL,
	[TMPKOD] [int] NULL,
	[SHORTLS] [varchar](10) NULL,
	[PRIM] [varchar](1000) NULL,
	[DDOG] [smalldatetime] NULL,
	[INDIC] [money] NULL,
	[TMP] [int] NULL,
	[kind] [bit] NULL,
	[BAKID] [int] NULL,
	[NEWID] [int] NULL,
	[TMP2] [int] NULL,
	[PLIT] [smallint] NULL,
	[bdateLS] [smalldatetime] NOT NULL,
	[edateLS] [smalldatetime] NULL,
	[CloseReasonID] [int] NULL,
	[id_house] [int] NOT NULL,
	[ref_houses_entrance_id] [int] NULL,
	[checkdate] [smalldatetime] NULL,
	[ref_houses_flats_id] [int] NULL,
	[Id_objectPart] [tinyint] NULL,
 CONSTRAINT [PK_kart] PRIMARY KEY CLUSTERED 
(
	[ID1] ASC
)WITH (PAD_INDEX = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_LS]  DEFAULT ((-1)) FOR [LS]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_Cod]  DEFAULT ((-1)) FOR [Cod]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_LSCod]  DEFAULT ((-1)) FOR [LSCod]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_subpos]  DEFAULT ((0)) FOR [subpos]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_floor]  DEFAULT ('') FOR [floor]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_entrance]  DEFAULT ('') FOR [entrance]
ALTER TABLE [dbo].[kart] ADD  CONSTRAINT [DF_kart_Id_objectPart]  DEFAULT ((1)) FOR [Id_objectPart]

/*****************************************************************************/
create table [dbo].[ref_services](
	[ID] [int] identity(1,1) not null,
	[ID1] [int] not null,
	[SpUch] [tinyint] null,
	[Kind] [tinyint] null,
	[IsSubs] [bit] null,
	[SpParam] [tinyint] null,
	[AbsenceDed] [bit] null,
	[Measure] [nvarchar](10) null,
	[TDATE] [smalldatetime] not null,
	[id_measure] [int] null,
	[PuNormKind] [int] null,
 constraint [PK_ref_services] primary key nonclustered 
(
	[ID] asc
)with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on, fillfactor = 90) on [PRIMARY]
) on [PRIMARY]

alter table [dbo].[ref_services] add  constraint [DF_ref_services_SpUch]  default ((0)) for [SpUch]
alter table [dbo].[ref_services] add  constraint [DF_ref_services_TDATE]  default ([dbo].[calcdate](getdate(),(0),(1))) for [TDATE]

/*****************************************************************************/

create table [dbo].[ref_contrag](
	[ID] [int] identity(1,1) not null,
	[id_contrag] [int] not null,
	[algPercERC] [int] null,
	[QuitCode] [varchar](4) null,
	[isNew] [int] null,
	[isOtherContrag] [bit] null,
	[isKRcontrag] [bit] null,
	[ROSpecShet] [bit] null,
	[isOfficeContrag] [bit] null,
	[description] [nvarchar](250) null,
	[isROKR] [bit] not null,
	[isFictive] [bit] not null,
	[isDomofonContrag] [bit] null,
 constraint [PK_REF_CONTRAG] primary key nonclustered 
(
	[ID] asc
)with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on) on [PRIMARY]
) on [PRIMARY]

alter table [dbo].[ref_contrag] add  constraint [DF_isROKR]  default ((0)) for [isROKR]
alter table [dbo].[ref_contrag] add  constraint [DF_isFictive]  default ((0)) for [isFictive]
alter table [dbo].[ref_contrag]  with check add  constraint [check_isROKR] check  (([isROKR]=case when [isKRcontrag]=(1) then (1) else (0) end or [isROKR]=(0)))
alter table [dbo].[ref_contrag] check constraint [check_isROKR]

/*****************************************************************************/

create table [dbo].[ref_houses](
	[id] [int] not null,
	[id_street] [int] not null,
	[house] [int] not null,
	[building] [varchar](10) null,
	[kind] [int] null,
	[REGIONKIND] [int] null,
	[SecAdr] [bit] null,
	[IsParking] [bit] null,
 constraint [PK_ref_houses] primary key clustered 
(
	[id] asc
)with (pad_index = off, statistics_norecompute = off, ignore_dup_key = off, allow_row_locks = on, allow_page_locks = on) on [PRIMARY]
) on [PRIMARY]
go

alter table [dbo].[ref_houses]  with check add  constraint [FK_rh_StreetID] foreign key([id_street])
references [dbo].[REF] ([ID])

alter table [dbo].[ref_houses] check constraint [FK_rh_StreetID]

/*****************************************************************************/

create table [dbo].[dedEconom](
	[id] [int] identity(1,1) not null,
	[parentid] [int] not null,
	[ded] [money] not null,
	[tariff] [decimal](15, 5) null,
	[volume] [float] null,
	[id_serv] [int] not null,
	[id_contrag] [int] not null,
	[pmonth] [date] not null,
	[ddate] [date] not null,
	[uchid] [int] null,
	[dataid] [int] null,
	[dednp] [money] not null,
	[initial_id_serv] [int] null,
	[previous_ded_econom] [int] null
) on [PRIMARY]

alter table [dbo].[dedEconom] add  default ((0)) for [ded]
alter table [dbo].[dedEconom] add  default ((0)) for [tariff]
alter table [dbo].[dedEconom] add  default ((0)) for [volume]
alter table [dbo].[dedEconom] add  default ((0)) for [dednp]

/*****************************************************************************/

CREATE TABLE [dbo].[HousePUVolumes](
	[id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[id_serv] [int] NOT NULL,
	[id_house] [int] NOT NULL,
	[id_contrag] [int] NOT NULL,
	[pMonth] [smalldatetime] NOT NULL,
	[DDate] [smalldatetime] NOT NULL,
	[scaleType] [tinyint] NOT NULL,
	[volume] [money] NOT NULL,
	[uninhabitedVolume] [money] NOT NULL,
	[volumeGk] [money] NULL,
	[uninhabitedVolumeGK] [money] NULL,
	[NotActual] [bit] NOT NULL,
	[doc_hpuv] [int] NULL,
	[IsCounted] [bit] NULL,
	[HasIndividualPU] [bit] NULL,
	[puser_id] [int] NULL,
	[IsCredit] [bit] NULL,
	[IdCredit] [int] NULL,
	[isTest] [bit] NULL,
	[id_EntranceGroup] [int] NULL,
	[sourceValues] [smallint] NULL,
	[HO_load] [int] NULL,
	[SharedParkingVolume] [money] NULL,
	[storedHouseVolumeId] [int] NULL,
	[uchId] [int] NULL,
	[OutsideWateringVolume] [money] NULL,
	[isCorrection] [bit] NOT NULL,
CONSTRAINT [PK_HousePUVolumes] PRIMARY KEY NONCLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

ALTER TABLE [dbo].[HousePUVolumes] ADD  CONSTRAINT [DF_HousePUVolumes_scaleType]  DEFAULT ((0)) FOR [scaleType]
ALTER TABLE [dbo].[HousePUVolumes] ADD  CONSTRAINT [DF_HousePUVolumes_actual]  DEFAULT ((1)) FOR [NotActual]
ALTER TABLE [dbo].[HousePUVolumes] ADD  DEFAULT ((0)) FOR [isCorrection]

/*****************************************************************************/

create table [dbo].[dedTransfer](
	[id] [int] identity(1,1) not null,
	[parentid] [int] not null,
	[ded] [money] not null,
	[tariff] [decimal](15, 5) null,
	[id_serv] [int] not null,
	[id_contrag] [int] not null,
	[fdate] [date] not null,
	[ddate] [date] not null,
	[pmonth] [date] not null,
	[uchid] [int] null,
	[dataid] [int] null,
	[dednp] [money] not null,
	[volume] [float] null,
	[initial_id_serv] [int] null,
	[positive_ded_id] [int] null,
	[economy_id] [int] null,
	[transfer_ded_id] [int] null
) on [PRIMARY]

alter table [dbo].[dedTransfer] add  default ((0)) for [ded]
alter table [dbo].[dedTransfer] add  default ((0)) for [tariff]
alter table [dbo].[dedTransfer] add  default ((0)) for [dednp]