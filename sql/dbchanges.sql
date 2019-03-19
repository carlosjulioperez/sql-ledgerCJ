ALTER TABLE orderitems ADD COLUMN lotnum TEXT;
ALTER TABLE orderitems ADD COLUMN expiry DATE;
ALTER TABLE orderitems ADD COLUMN warehouse_id INTEGER;

ALTER TABLE parts ADD partnumber2 text;
ALTER TABLE parts ADD fodinfa numeric(5,2) DEFAULT 0;
ALTER TABLE parts ADD advaloren numeric(5,2) DEFAULT 0;

ALTER TABLE oe ADD internal_freight numeric(12,2) default 0;
ALTER TABLE oe ADD shipping_freight numeric(12,2) default 0;
ALTER TABLE oe ADD shipping_insurance numeric(12,2) default 0;
ALTER TABLE oe ADD airport_expenses numeric(12,2) default 0;
ALTER TABLE oe ADD local_freight numeric(12,2) default 0;
ALTER TABLE oe ADD other_expenses numeric(12,2) default 0;
ALTER TABLE oe ADD total_expenses numeric(12,2) default 0;
ALTER TABLE oe ADD total_customs numeric(12,2) default 0;

ALTER TABLE oe ADD netweight numeric(12,2) default 0;
ALTER TABLE oe ADD grossweight numeric(12,2) default 0;

ALTER TABLE orderitems ADD internal_freight numeric(12,2) default 0;
ALTER TABLE orderitems ADD fob_price numeric(12,2) default 0;
ALTER TABLE orderitems ADD shipping_freight numeric(12,2) default 0;
ALTER TABLE orderitems ADD shipping_insurance numeric(12,2) default 0;
ALTER TABLE orderitems ADD cif_price numeric(12,2) default 0;
ALTER TABLE orderitems ADD advaloren numeric(12,2) default 0;
ALTER TABLE orderitems ADD fodinfa numeric(12,2) default 0;
ALTER TABLE orderitems ADD customs_price numeric(12,2) default 0;
ALTER TABLE orderitems ADD total_expenses numeric(12,2) default 0;
ALTER TABLE orderitems ADD warehouse_price numeric(12,2) default 0;

ALTER TABLE orderitems ADD cb2 boolean;
