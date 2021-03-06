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

