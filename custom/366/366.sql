-- retenc values
--> vendor_id = ap.vendor_id
--> tipoid_id = vendor.tipoid_id
--> idprov = vendor.gifi_accno
--> tipodoc_id = ap.tipodoc_id
--> ordnumber = ap.ordnumber
--> ordnumberRet = screen[Autoriz. Nbr]

CREATE TABLE retenc(
 id int4 NOT NULL,
 vendor_id int4,
 tipoid_id varchar(2),
 idprov varchar,
 tipodoc_id int4,
 estab varchar (3),
 ptoEmi varchar (3),
 sec varchar (7),
 ordnumber text,
 transdate date,
 estabRet varchar (3),
 ptoEmiRet varchar (3),
 secRet varchar (7),
 ordnumberRet text,
 transdateRet date,
 tiporet_id int4,
 porcret int4,
 base0 float8,
 based0 float8,
 baseni float8,
 valret float8,
 chart_id int4
);


CREATE TABLE tiporet (
id int4 NOT NULL,
description varchar(120),
porcret int4
);

--insert into tiporet values ('303', 'Honorarios, comisiones...','8');
--insert into tiporet values ('304', 'Remuneracion a otros trabajadores','2');
--insert into tiporet values ('305', 'Honorarios a extranjeros...','25');
--insert into tiporet values ('306', 'Por compras locales materia prima','2');
--insert into tiporet values ('307', 'Por compras locales bienes','2');

ALTER TABLE retenc 
   ADD COLUMN estab INTEGER,
   ADD COLUMN ptoemi INTEGER,
   ADD COLUMN sec INTEGER,
   ADD COLUMN estabret INTEGER,
   ADD COLUMN ptoemiret INTEGER,
   ADD COLUMN secret INTEGER
;


