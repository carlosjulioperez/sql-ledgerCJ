--------------------------------------------------------
-- Primary keys for duplicate check at various places
--------------------------------------------------------
DROP INDEX ap_invnumber_key;
CREATE UNIQUE INDEX ap_invnumber_key ON ap (invnumber);

DROP INDEX ar_invnumber_key;
CREATE UNIQUE INDEX ar_invnumber_key ON ar (invnumber);

DROP INDEX customer_customernumber_key;
CREATE UNIQUE INDEX customer_customernumber_key ON customer (customernumber);

DROP INDEX vendor_vendornumber_key;
CREATE UNIQUE INDEX vendor_vendornumber_key ON vendor (vendornumber);

DROP INDEX parts_partnumber_key;
CREATE UNIQUE INDEX parts_partnumber_key ON parts (partnumber);

DROP INDEX gl_reference_key;
CREATE UNIQUE INDEX gl_reference_key ON gl (reference);

CREATE UNIQUE INDEX department_key ON department (description);
CREATE UNIQUE INDEX warehouse_key ON warehouse (description);
CREATE UNIQUE INDEX employee_employeenumber_key ON employee (employeenumber);


