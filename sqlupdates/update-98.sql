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

