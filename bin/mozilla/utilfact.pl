#=====================================================================
# Sample for SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: Armaghan Saqib
#     Web: http://www.ledger123.com
#
#  Version: 0.10
#
#======================================================================
1;

#---------------------------------------
sub continue { &{$form->{nextsub}} };

#########################################################################
## These one liners hide the clutter of html from report processing code.
## This helps newbies to modify the report.
#########################################################################
sub begin_table {
  print qq|<table width=100%>|;
}

sub end_table {
  print qq|</table>|;
}

sub print_header {
  $form->{title} = shift;
  $form->header;
  print qq|<body><table width=100%><tr><th class=listtop>$form->{title}</th></tr></table><br>|;
}

sub begin_form {
  print qq|<form method=post action=$form->{script}>|;
}

sub end_form {
  print qq|<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">|;
  $form->hide_form(qw(title path nextsub login));
  print qq|</form>|;
}

sub print_form_text {
   my ($prompt, $cname, $size) = @_;
   print qq|<tr><th align=right>$prompt</th><td><input type=name name=$cname size=$size value='$form->{"$cname"}'></td></tr>|;
}

sub print_form_date {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><input type=name name=$cname size=11 value='$form->{"$cname"}' title='$myconfig{dateformat}'></td></tr>|;
}

sub end_page {
  print qq|</body></html>|;
}

sub begin_heading_row {
   print qq|<tr class=listheading>|;
}

sub begin_data_row {
   my $i = shift;
   print qq|<tr class=listrow$i>|;
}

sub begin_total_row {
   print qq|<tr class=listtotal>|;
}

sub begin_subtotal_row {
   print qq|<tr class=listsubtotal>|;
}

sub end_row {
   print qq|</tr>|;
}

sub print_heading {
   my $prompt = shift;
   print qq|<th>$prompt</th>|;
}

sub print_text {
   my $data = shift;
   print qq|<td>$data</td>|;
}

sub print_integer {
   my $data = shift;
   print qq|<td align=right>$data</td>|;
}

sub print_number {
   my $data = shift;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $data, 2) . qq|</td>|;
}

sub print_select {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><select name=$cname>$form->{"select$cname"}</select></td></tr>|;
}

sub select_parts {
   my $query = qq|SELECT id, partnumber, description FROM parts ORDER BY partnumber|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectparts} = "<option>\n";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectparts} .= qq|<option value="$ref->{partnumber}--$ref->{id}">$ref->{partnumber}--$ref->{description}\n|;
   }
   $dbh->disconnect;
}

sub select_empleado {
   my $query = qq|SELECT id, name FROM employee ORDER BY name|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectempleado} = "<option>\n";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectempleado} .= qq|<option value="$ref->{name}--$ref->{id}">$ref->{name}\n|;
   }
   $dbh->disconnect;
}

###########################################################################
##
##  ACTUAL REPORT PROCEDURES
##
##  These two procedures 'customer_search' and 'customer_report' implement
##  a very simple report.
##
##  Copy these procedures and rename appropriatly to create as many
##  reports as you like within this single .pl file.
##
###########################################################################
#---------------------------------------
sub inventory_search {
  print_header('Utilidad por facturas de Venta');
  begin_form;
  begin_table;


  $form->{selectsort} = qq|
	<option value=1>Invoice\n
	<option value=2>Date\n
	<option value=6>Employee\n
  |;

  select_empleado;
  print_select('Empleado', 'empleado');
  print_form_text('Cliente', 'customer', 20);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  print_select('Sort','sort'); 
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'inventory_report';
  end_form;
  end_page;
}

#---------------------------------------
sub inventory_report {
   my $dbh = $form->dbconnect(\%myconfig);
   print_header('Utilidad por facturas de Venta');

   # Construccion de la clausula Where
   my $where = qq| (1 = 1)|;

   my ($empleado, $employee_id) = split(/--/, $form->{empleado});
   $employee_id *= 1;
   $where .= qq| AND aa.employee_id = $employee_id| if $form->{empleado};

   my $customer = $form->like(lc $form->{customer}); 
   $where .= qq| AND LOWER(c.name) LIKE '$customer' | if $form->{customer};
   $where .= qq| AND aa.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND aa.transdate <= '$form->{dateto}'| if $form->{dateto};

   print qq|<table>|;
   print qq|<tr><th>Warehouse</th><td>$warehouse</td></tr>| if $form->{warehouse};
   print qq|<tr><th>Part Number</th><td>$form->{partnumber}</td></tr>| if $form->{partnumber};
   print qq|<tr><th>From Date</th><td>$form->{datefrom}</td></tr>| if $form->{datefrom};
   print qq|<tr><th>To Date</th><td>$form->{dateto}</td></tr>| if $form->{dateto};
   print qq|</table>|;

   my $query = qq|
	SELECT 
	aa.invnumber, 
	aa.transdate,
	c.name, 
	aa.amount, 
	aa.netamount, 
	e.name as employee,
	(SELECT SUM(0-at.amount) 
	FROM acc_trans at 
	JOIN chart ch	ON (ch.id = at.chart_id) 
	WHERE at.trans_id = aa.id 
	AND ch.link LIKE '%IC_cogs%') AS cost 
	FROM ar aa 
	JOIN customer c 	ON  (aa.customer_id=c.id) 
	JOIN employee e 	ON  (aa.employee_id=e.id) 
      WHERE  $where 
	ORDER BY c.name, $form->{sort};
   |;

   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   begin_table;
   begin_heading_row;
   print_heading('Factura #');
   print_heading('Fecha Factura');
   print_heading('Cliente');
   print_heading('Vendedor');
   print_heading('Monto');
   print_heading('IVA');

   $total_iva = 0;
   $total_marg = 0;
   $total_amount = 0;
   $total_cost = 0;

   $grandtotal_iva = 0;
   $grandtotal_marg = 0;
   $grandtotal_amount = 0;
   $grandtotal_cost = 0;

   print_heading('Costo');
   print_heading('Margen');
   print_heading('%');
   print_heading(' ');
   end_row;

   my $i = 0; my $j = 1; 
   #En esta seccion agrupo el reporte por cliente para sacar subtotales
   $customer_group = 'none';
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	if ($customer_group ne $ref->{name}){
	   if ($customer_group ne 'none'){
		# Saca el total por grupo
   		#$iva  = $ref->{amount} - $ref->{netamount};
   		#$marg = $ref->{netamount} - $ref->{cost};
   		$porc = ($marg / ($ref->{netamount} + 0.0000000001 )) *100;
   	   	# print group fotter
   	   	begin_subtotal_row;
   		print_text('&nbsp;'); # blank cell
   		print_text('&nbsp;');
   		print_text('&nbsp;');
   		print_text('&nbsp;');
		print_number($total_amount);
		print_number($total_iva);
		print_number($total_cost);
		print_number($total_marg);
		print_number($porc);
   	   	end_row;

		$total_iva = 0;
		$total_marg = 0;
		$total_amount = 0;
		$total_cost = 0;
	   }

	  $customer_group = $ref->{name};
	  #Saco la sumatoria de todos los registros para el campo amount
   	  if ($form->{datefrom}){
		my $opening_where = qq| (1 = 1)|;
   		$opening_where .= qq| AND aa.employee_id = $employee_id| if $form->{empleado};
		$opening_where .= qq| AND aa.transdate < '$form->{datefrom}'|;
		$opening_where .= qq| AND ch.accno = '1130101' AND at.amount < '0'|;

		my $amquery = qq|SELECT SUM(0 - amount)
			FROM   
			acc_trans at 	JOIN ar aa 
			ON  (at.trans_id=aa.id)
				JOIN chart ch 
			ON  (at.chart_id=ch.id) 
				JOIN customer c 
			ON  (aa.customer_id=c.id) 
				JOIN employee e 
			ON  (aa.employee_id=e.id)
			WHERE $opening_where|;
   	   }
	 }

	#Imprime cada registro de factura
      $iva  = $ref->{amount} - $ref->{netamount};
      $marg = $ref->{netamount} - $ref->{cost};
      $porc = ($marg / ($ref->{netamount} + 0.0000000001 )) *100;

	$total_iva  += $iva;
	$total_marg += $marg;
	$total_amount += $ref->{amount};
	$total_cost += $ref->{cost};
	$total_porc = ($total_marg / ($total_netamount + 0.0000000001 )) *100;

	$grandtotal_iva  += $iva;
	$grandtotal_marg += $marg;
	$grandtotal_amount += $ref->{amount};
	$grandtotal_cost += $ref->{cost};

	begin_data_row($i);
	print_text($ref->{invnumber});
	print_text($ref->{transdate});
	print_text($ref->{name});
	print_text($ref->{employee});
	print_number($ref->{amount});
	print_number($iva);
	print_number($ref->{cost});
	print_number($marg);
	print_number($porc);

	end_row;

	$i++; $i %= 2; $j++;
   }

   # print fotter
   $total_porc = ($total_marg / ($total_amount + 0.0000000001 )) *100;

   begin_subtotal_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_number($total_amount);
   print_number($total_iva);
   print_number($total_cost);
   print_number($total_marg);
   print_number($total_porc);
   end_row;

   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_number($grandtotal_amount);
   print_number($grandtotal_iva);
   print_number($grandtotal_cost);
   print_number($grandtotal_marg);
   print_number($total_porc);
   end_row;

   end_table;
}

###################
#
# EOF: reports.pl
#
###################

