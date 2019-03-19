----------------------Tablas para modulo SRI

----------------------ADD VENDOR----------------------
DROP TABLE tipoid;
DROP TABLE tipodoc;
DROP TABLE tiporet;
--DROP TABLE retenc;

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
ALTER TABLE ap ADD COLUMN tipodoc_id int4;


----------------------ADD INVOICE - TRANSACTINO----------------------
CREATE TABLE tipodoc
(
  id int4 NOT NULL,
  description varchar(50)
);
ALTER TABLE tipodoc OWNER TO "sql-ledger";

insert into tipodoc values ('1', 'Factura');
insert into tipodoc values ('2', 'Nota de Venta');
insert into tipodoc values ('3', 'Liquidacion de Compra');
insert into tipodoc values ('4', 'Nota de Debito');
insert into tipodoc values ('5', 'Nota de Credito');
insert into tipodoc values ('11','Pasajes emitidos por empresas de aviacion');
insert into tipodoc values ('12','Documentos Emitidos Por IF');
insert into tipodoc values ('20','Documentos de Instituciones Del Estado');
insert into tipodoc values ('41','Comprobante De Venta Emitido Por Reembolso');
insert into tipodoc values ('47','N/C Por Reembolso Emitida Por Intermediario');
insert into tipodoc values ('48','N/D Por Reembolso Emitida Por Intermediario');



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
  valret           float8,
  chart_id         int4
);
ALTER TABLE retenc OWNER TO "sql-ledger";


-----------------------------------------------------------------------------





