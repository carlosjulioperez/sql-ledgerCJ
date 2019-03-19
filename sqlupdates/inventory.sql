DELETE FROM inventory WHERE trans_id IN (SELECT id FROM ar);

INSERT INTO inventory (
	warehouse_id, parts_id, trans_id,
	orderitems_id, qty, shippingdate,
	employee_id, department_id, serialnumber,
	itemnotes)
  SELECT ar.warehouse_id, i.parts_id, ar.id,
	1, 0 - i.qty, ar.transdate,
	ar.employee_id, ar.department_id, i.serialnumber,
	i.itemnotes
  FROM invoice i
  JOIN ar ON ar.id = i.trans_id;

DELETE FROM inventory WHERE trans_id IN (SELECT id FROM ap);

INSERT INTO inventory (
	warehouse_id, parts_id, trans_id,
	orderitems_id, qty, shippingdate,
	employee_id, department_id, serialnumber,
	itemnotes)
  SELECT ap.warehouse_id, i.parts_id, ap.id,
	1, 0 - i.qty, ap.transdate,
	ap.employee_id, ap.department_id, i.serialnumber,
	i.itemnotes
  FROM invoice i
  JOIN ap ON ap.id = i.trans_id

