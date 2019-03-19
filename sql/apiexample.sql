CREATE TABLE importedtrans AS
SELECT 
  invnumber,
  transdate,
  customer_id,
  amount
FROM ar
