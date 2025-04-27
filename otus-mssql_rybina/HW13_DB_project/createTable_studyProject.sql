/*
Описание таблиц учебного проекта.
Сфера ЖКХ. Ежемесячно для Абонентов проводятся начисления за потребление коммунальных услуг по переданным объемам от управляющих компаний и абонентов.
Список Лицевых счетов, для которых проходят расчеты лежит в таблице ls

Ежемесячно проходят начисления по потребляемым объемам по услугам.
В HouseVolume лежат общедомовые объемы по дому (передает управляющая компания),  LsVolume - объемы по лицевому счету (передает абонент). 
Согласно этим данным происходит расчет и выставляется определенная сумма к оплате

contract - договор. Показывает для какого дома действует контрагент и услуга, по которым проходит начисление.
ls_services - соответствие лс и услуги. Показывает какие услуги открыты в лицевом счете и по ним проходит начисление.
Jrn_volume - журнал, который указывает когда были переданы объемы и кем

ref_street, ref_house, ref_contrag, ref_service - справочники
*/

SET XACT_ABORT ON

BEGIN TRANSACTION QUICKDBD

CREATE TABLE [ref_street] (
    [id_street] int  NOT NULL ,
    [NameStreet] nvarchar(50)  NOT NULL 
)

CREATE TABLE [ref_house] (
    [id_house] int  NOT NULL ,
    [id_street] int  NOT NULL ,
    [House] int  NOT NULL ,
    [Building] nvarchar(5)  NOT NULL 
)

CREATE TABLE [ref_contrag] (
    [id_contrag] int  NOT NULL ,
    [NameContrag] nvarchar(100)  NOT NULL 
)

CREATE TABLE [ref_service] (
    [id_serv] int  NOT NULL ,
    [NameServ] nvarchar(50)  NOT NULL 
)

CREATE TABLE [contract] (
    [id_contract] int  NOT NULL ,
    [nameContract] nvarchar(100)  NOT NULL ,
    [id_house] int  NOT NULL ,
    [id_contrag] int  NOT NULL ,
    [id_serv] int  NOT NULL ,
    [openDate] date  NOT NULL ,
    [closeDate] date  NOT NULL 
)

CREATE TABLE [ls] (
    [id_go] int  NOT NULL ,
    [id_house] int  NOT NULL ,
    [id_ls] int  NOT NULL ,
    [ls] nvarchar(10)  NOT NULL ,
    [flats] nvarchar(10)  NOT NULL ,
    [openDateLs] date  NOT NULL ,
    [closeDateLs] date  NOT NULL 
)

CREATE TABLE [ls_services] (
    [id_ls] int  NOT NULL ,
    [id_contrag] int  NOT NULL ,
    [id_service] int  NOT NULL ,
    [openDateServices] date  NOT NULL ,
    [closeDateServices] date  NOT NULL 
)

CREATE TABLE [Jrn_volume] (
    [id_task] int  NOT NULL ,
    [createDate] date  NOT NULL ,
    [id_user] int  NOT NULL ,
    [description] int  NOT NULL ,
    [isIndividuals] bit  NOT NULL 
)

CREATE TABLE [HouseVolume] (
    [id_task] int  NOT NULL ,
    [id_house] int  NOT NULL ,
    [id_contrag] int  NOT NULL ,
    [id_service] int  NOT NULL ,
    [perMonth] date  NOT NULL ,
    [currentMonth] date  NOT NULL ,
    [scale] int  NOT NULL ,
    [volume] decimal(10,2)  NOT NULL 
)

CREATE TABLE [LsVolume] (
    [id_task] int  NOT NULL ,
    [id_ls] int  NOT NULL ,
    [id_service] int  NOT NULL ,
    [perMonth] date  NOT NULL ,
    [currentMonth] date  NOT NULL ,
    [scale] int  NOT NULL ,
    [volume] decimal(10,2)  NOT NULL 
)

ALTER TABLE [ref_house] WITH CHECK ADD CONSTRAINT [FK_ref_house_id_street] FOREIGN KEY([id_street])
REFERENCES [ref_street] ([id_street])

ALTER TABLE [ref_house] CHECK CONSTRAINT [FK_ref_house_id_street]

ALTER TABLE [contract] WITH CHECK ADD CONSTRAINT [FK_contract_id_house] FOREIGN KEY([id_house])
REFERENCES [ref_house] ([id_house])

ALTER TABLE [contract] CHECK CONSTRAINT [FK_contract_id_house]

ALTER TABLE [contract] WITH CHECK ADD CONSTRAINT [FK_contract_id_contrag] FOREIGN KEY([id_contrag])
REFERENCES [ref_contrag] ([id_contrag])

ALTER TABLE [contract] CHECK CONSTRAINT [FK_contract_id_contrag]

ALTER TABLE [contract] WITH CHECK ADD CONSTRAINT [FK_contract_id_serv] FOREIGN KEY([id_serv])
REFERENCES [ref_service] ([id_serv])

ALTER TABLE [contract] CHECK CONSTRAINT [FK_contract_id_serv]

ALTER TABLE [ls] WITH CHECK ADD CONSTRAINT [FK_ls_id_house] FOREIGN KEY([id_house])
REFERENCES [ref_house] ([id_house])

ALTER TABLE [ls] CHECK CONSTRAINT [FK_ls_id_house]

ALTER TABLE [ls_services] WITH CHECK ADD CONSTRAINT [FK_ls_services_id_ls] FOREIGN KEY([id_ls])
REFERENCES [ls] ([id_ls])

ALTER TABLE [ls_services] CHECK CONSTRAINT [FK_ls_services_id_ls]

ALTER TABLE [HouseVolume] WITH CHECK ADD CONSTRAINT [FK_HouseVolume_id_task] FOREIGN KEY([id_task])
REFERENCES [Jrn_volume] ([id_task])

ALTER TABLE [HouseVolume] CHECK CONSTRAINT [FK_HouseVolume_id_task]

ALTER TABLE [HouseVolume] WITH CHECK ADD CONSTRAINT [FK_HouseVolume_id_house] FOREIGN KEY([id_house])
REFERENCES [ref_house] ([id_house])

ALTER TABLE [HouseVolume] CHECK CONSTRAINT [FK_HouseVolume_id_house]

ALTER TABLE [LsVolume] WITH CHECK ADD CONSTRAINT [FK_LsVolume_id_task] FOREIGN KEY([id_task])
REFERENCES [Jrn_volume] ([id_task])

ALTER TABLE [LsVolume] CHECK CONSTRAINT [FK_LsVolume_id_task]

ALTER TABLE [LsVolume] WITH CHECK ADD CONSTRAINT [FK_LsVolume_id_ls] FOREIGN KEY([id_ls])
REFERENCES [ls] ([id_ls])

ALTER TABLE [LsVolume] CHECK CONSTRAINT [FK_LsVolume_id_ls]

COMMIT TRANSACTION QUICKDBD