-- 12-Apr-2008 - Table to record stock assembly transactions
CREATE TABLE build (
	id		integer PRIMARY KEY DEFAULT nextval(('id'::text)::regclass),
	reference	text,
	transdate	date,
	department_id	integer,
	warehouse_id	integer,
	employee_id	integer
);

