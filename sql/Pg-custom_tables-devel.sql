-- 17-Mar-2008
ALTER TABLE invoice ADD COLUMN lotnumber text;
ALTER TABLE invoice ADD COLUMN expiry date;

CREATE TABLE lots (
	id		integer,
	invoice_id	integer,
	lotnumber	text,
	expiry		date,
	warehouse_id	integer,
	qty		float,
	allocated	float,
	costprice	float,
	sellprie	float
);

