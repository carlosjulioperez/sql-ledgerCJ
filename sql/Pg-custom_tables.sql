--------------------------------------------
-- Inventory transfers module
--------------------------------------------
CREATE TABLE trf (
    id 			integer PRIMARY KEY DEFAULT nextval('id'),
    transdate 		date,
    trfnumber 		text,
    description 	text,
    notes 		text,
    department_id 	integer,
    from_warehouse_id	integer,
    to_warehouse_id 	integer DEFAULT 0,
    employee_id		integer DEFAULT 0
);

-- Customisations of 'inventory' table for transfer module
-- linetype:
---- 0 for transactions from ar, ap, oe etc.
---- 1 for transaction entered by user in trf
---- 2 for offsetting transaction generated by system in trf
---- 3 Inventory taken out to build assembly
---- 4 Assembly built
ALTER TABLE inventory 
	ADD COLUMN department_id 	integer,
	ADD COLUMN warehouse_id2 	integer,
	ADD COLUMN serialnumber 	text,
	ADD COLUMN itemnotes 		text,
	ADD COLUMN cost 		float,
	ADD COLUMN linetype 		CHAR(1) DEFAULT '0'
;

-- delivereddate will be updated by a seperate form when good will be 'received' at the other warehouse.
ALTER TABLE trf ADD COLUMN delivereddate DATE;

ALTER TABLE invoice ADD COLUMN transdate DATE;
-- Invoices reposting / FIFO reports.
-- trans_id = ar invoice id
CREATE TABLE fifo (
	trans_id	integer,
	transdate	date,
	parts_id	integer,
	qty		float,
	costprice	float,
	sellprice	float
);

-- 9-Mar-2008
ALTER TABLE invoice ADD COLUMN lastcost float;


-- 16-Mar-2008
CREATE TABLE invoicetax (
	trans_id	integer,
 	invoice_id	integer,
	chart_id	integer,
	taxamount	float
);

-- 28-Mar-2008
CREATE INDEX invoice_parts_id ON invoice (parts_id); 
CREATE INDEX fifo_parts_id ON fifo (parts_id);

-- 12-Apr-2008 - Table to record stock assembly transactions
CREATE TABLE build (
	id		integer PRIMARY KEY DEFAULT nextval(('id'::text)::regclass),
	reference	text,
	transdate	date,
	department_id	integer,
	warehouse_id	integer,
	employee_id	integer
);

-- 08-Jun-2008 - description column stores user-modified description of item 
--               from invoices and transfer screen.
ALTER TABLE inventory ADD COLUMN description TEXT;

-- 10-Jun-2008 - FIFO is based on warehouse now.
-- TODO: Tune indexes on FIFO for new warehouse column.
ALTER TABLE fifo ADD COLUMN warehouse_id INTEGER;
ALTER TABLE invoice ADD COLUMN warehouse_id INTEGER;

-- 08-Sep-2008 - invoice_id reference stored in acc_trans for COGS posting
ALTER TABLE fifo ADD COLUMN invoice_id INTEGER;

-- 19-Nov-2008 - Added ticket_id for RT integration
ALTER TABLE ar ADD COLUMN ticket_id INTEGER;
ALTER TABLE ap ADD COLUMN ticket_id INTEGER;
ALTER TABLE gl ADD COLUMN ticket_id INTEGER;
ALTER TABLE oe ADD COLUMN ticket_id INTEGER;
ALTER TABLE trf ADD COLUMN ticket_id INTEGER;

----------------------Tablas para modulo SRI

----------------------ADD VENDOR----------------------
DROP TABLE tipoid;
DROP TABLE tipodoc;
DROP TABLE tiporet;
DROP TABLE retenc;

CREATE TABLE tipoid
(
  id int4 NOT NULL,
  description varchar(30)
);
ALTER TABLE tipoid OWNER TO "sql-ledger";

insert into tipoid values ('1', 'Registro Unico Contribuyente');
insert into tipoid values ('2', 'Cedula de Identidad');
insert into tipoid values ('3', 'Pasaporte');

---------------------------------------------------------------------
------Agregamos campos a las tablas ap y vendor------

ALTER TABLE vendor ADD COLUMN tipoid_id int4;
ALTER TABLE customer ADD COLUMN tipoid_id int4;
ALTER TABLE ap ADD COLUMN tipodoc_id int4;
ALTER TABLE ar ADD COLUMN tipodoc_id int4;

----------------------ADD INVOICE - TRANSACTINO----------------------
CREATE TABLE tipodoc
(
  id int4 NOT NULL,
  description varchar(50),
  code varchar (3)
);
ALTER TABLE tipodoc OWNER TO "sql-ledger";

insert into tipodoc values ('1', 'Factura','FAC');
insert into tipodoc values ('2', 'Nota de Venta','NVT');
insert into tipodoc values ('3', 'Liquidacion de Compra','LIQ');
insert into tipodoc values ('4', 'Nota de Debito','NDB');
insert into tipodoc values ('5', 'Nota de Credito','NCR');
insert into tipodoc values ('11','Pasajes emitidos por empresas de aviacion','PAS');
insert into tipodoc values ('12','Documentos Emitidos Por IF','DIF');
insert into tipodoc values ('20','Documentos de Instituciones Del Estado','DIE');
insert into tipodoc values ('41','Comprobante De Venta Emitido Por Reembolso','CVR');
insert into tipodoc values ('47','N/C Por Reembolso Emitida Por Intermediario','NCI');
insert into tipodoc values ('48','N/D Por Reembolso Emitida Por Intermediario','NDI');

----------------------ADD RETENCION----------------------
CREATE TABLE tiporet
(
  id int4 NOT NULL,
  description varchar(120),
  porcret int4,
  impuesto varchar(10)
); 
ALTER TABLE tiporet OWNER TO "sql-ledger";

insert into tiporet values ('303','Honorarios, comisiones y dietas','8', 'Renta');
insert into tiporet values ('304','Remuneracion a otros trabajadores','1', 'Renta');
insert into tiporet values ('305','Honorarios a extranjeros S. ocacionales','25', 'Renta');
insert into tiporet values ('306','Por compras locales materia prima','1', 'Renta');
insert into tiporet values ('307','Por compras locales bienes','1', 'Renta');
insert into tiporet values ('308','Por compras locales de materia prima sin retencion','0','Renta'); 	
insert into tiporet values ('309','Por suministros y materiales','1','Renta');
insert into tiporet values ('310','Por repuestos y herramientas','1','Renta');
insert into tiporet values ('311','Por lubricantes','1','Renta');
insert into tiporet values ('312','Por activos fijos','1','Renta');
insert into tiporet values ('313','Servicio Transporte', '1', 'Renta');
insert into tiporet values ('314','Por regalias, derechos, marcas, patentes- PN (8%)','8','Renta');  
insert into tiporet values ('314','Por regalias, derechos, marcas, patentes- PN (2%)','2','Renta');
insert into tiporet values ('316','Por pagos realizados a notarios y registradores','8','Renta');
insert into tiporet values ('317','Por comisiones pagadas a sociedades','2','Renta');
insert into tiporet values ('318','Por promocion y publicidad','2','Renta');
insert into tiporet values ('319','Por arrendamiento mercantil local','2','Renta');
insert into tiporet values ('320','Por arrendamiento de personas naturales','8','Renta');
insert into tiporet values ('321','Por arrendamiento a sociedades','8','Renta');
insert into tiporet values ('322','Por seguros y reaseguros','2','Renta');
insert into tiporet values ('323','Por rendimientos financieros (no aplica para ifis)','2','Renta');
insert into tiporet values ('325','Por loterias, rifas, apuestas y similares','15','Renta');
insert into tiporet values ('329','Por otros servicios','2','Renta');
insert into tiporet values ('331','Por agua y telecomunicaciones','2','Renta');
insert into tiporet values ('331','Por pago de energia electrica','1','Renta');
insert into tiporet values ('332','Otras compras no sujetas a retencion','0','Renta');
insert into tiporet values ('333','Convenio de Debito o Recaudacion','0','Renta');
insert into tiporet values ('334','Pago con Tarjeta de Credito','0','Renta');
insert into tiporet values ('336','Reembolso Gastos - Compra del Intermediario','0','Renta');
insert into tiporet values ('337','Reembolso Gastos - Quien Asume el Gasto','0','Renta');
insert into tiporet values ('701','Iva Servicios Profesionales', '100', 'Iva');
insert into tiporet values ('702','Iva Arriendo P. Natural', '100', 'Iva');
insert into tiporet values ('708','Iva Otros Servicios', '70', 'Iva');
insert into tiporet values ('711','Iva Compra Bienes', '30', 'Iva');

--------------------------------------------------------------------------------

CREATE TABLE retenc(
  id               int4 NOT NULL,                        
  vendor_id        int4,         
  tipoid_id        varchar(2), 
  idprov           varchar,     
  tipodoc_id       int4,        
  estab            varchar (3),
  ptoEmi           varchar (3),
  sec              varchar (7),
  ordnumber        text,       
  transdate        date,       
  estabRet         varchar (3),
  ptoEmiRet        varchar (3),
  secRet           varchar (7),
  ordnumberRet     text,  
  transdateRet     date,  
  tiporet_id       int4,  
  porcret          int4,  
  base0            float8,
  based0           float8,
  baseni           float8,
  valret           NUMERIC(6,2),
  chart_id         int4
);
ALTER TABLE retenc OWNER TO "sql-ledger";

-----------------------------------------------------------------------------
-- '4' - Components used to make assembly. '5' - The actual assembly made
ALTER TABLE invoice ADD COLUMN linetype CHAR(1) DEFAULT '0';
ALTER TABLE trf ADD COLUMN trftype VARCHAR(10) default 'transfer';
-- ctrfnumber will contain the transfer number of components issue
-- to calculate the cost of assemblies built.
ALTER TABLE trf ADD COLUMN ctrfnumber TEXT;

-----------------------------------------------------------------------------
-- 22-July-2009 old_vendor_id refers to the orignal vendor before the invoice 
-- was transferred to the petty cash vendor
ALTER TABLE ap ADD COLUMN old_vendor_id INTEGER DEFAULT 0;

-- 1-Aug-2009 (tkt 1145)
ALTER TABLE invoice ADD COLUMN lotnum TEXT;
ALTER TABLE invoice ADD COLUMN expiry DATE;


-- First 3 cols will be PK
CREATE TABLE lots(
   lotnum text,
   parts_id integer,
   warehouse_id integer,
   expiry date,
   qty float default 0,
   allocated float default 0
);

CREATE UNIQUE INDEX lots_pk ON lots (lotnum, parts_id, warehouse_id);

ALTER TABLE inventory ADD COLUMN invoice_id INTEGER;
CREATE INDEX inventory_invoice_id ON inventory (invoice_id);
ALTER TABLE invoice ADD COLUMN cogs float;
ALTER TABLE inventory ADD COLUMN cogs float;
UPDATE lots SET allocated=0 WHERE allocated IS NULL;

ALTER TABLE inventory ADD COLUMN lotnum text;
ALTER TABLE inventory ADD COLUMN expiry date;
ALTER TABLE inventory ADD COLUMN reporttype VARCHAR(3);

ALTER TABLE parts ADD COLUMN uselots CHAR(1) DEFAULT 'N';
ALTER TABLE fifo ADD COLUMN lotnum TEXT;

ALTER TABLE lots ADD COLUMN lastcost FLOAT DEFAULT 0;

-- Added for closing script
ALTER TABLE acc_trans ADD COLUMN cv_id INTEGER;

CREATE TABLE partswarehouse (
  parts_id	INTEGER,
  warehouse_id	INTEGER,
  lastcost	NUMERIC(6,2)
);

CREATE UNIQUE INDEX partswarehouse_key ON partswarehouse (parts_id, warehouse_id);

ALTER TABLE partscustomer ADD COLUMN discount NUMERIC (10,2);

ALTER TABLE partscustomer ADD discount NUMERIC(10,2) DEFAULT 0;

-- 3-feb-2011 - For use on new purchase order system.
ALTER TABLE orderitems ADD sellprice2 NUMERIC(10,2) DEFAULT 0;

-- 4-apr-2011
ALTER TABLE orderitems ADD newcost NUMERIC(10,2) DEFAULT 0;

