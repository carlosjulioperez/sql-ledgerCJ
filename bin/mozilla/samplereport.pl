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

sub select_warehouse {
   my $query = qq|SELECT id, description FROM warehouse ORDER BY description|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectwarehouse} = "<option>\n";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectwarehouse} .= qq|<option value="$ref->{description}--$ref->{id}">$ref->{description}\n|;
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
  print_header('Sales and Purchase Report');
  begin_form;
  begin_table;

  select_warehouse;
  print_select('Warehouse', 'warehouse');

#  $form->{partnumber} = ''; # default for search form.
  print_form_text('Part Number', 'partnumber', 20);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'inventory_report';
  end_form;
  end_page;
}

#---------------------------------------
sub inventory_report {
   #$form->isblank('partnumber', 'Part number cannot be blank');
   my $dbh = $form->dbconnect(\%myconfig);
   my $partnumber = $form->like(lc $form->{partnumber}); 
   my $query = qq|SELECT description, onhand FROM parts WHERE LOWER(partnumber) LIKE '$partnumber'|;
   my ($description, $onhand) = $dbh->selectrow_array($query);

   print_header('Sales and Purchase Report');

   # Build WHERE cluase
   my $where = qq| (1 = 1)|;

   my ($warehouse, $warehouse_id) = split(/--/, $form->{warehouse});
   $warehouse_id *= 1;
   $where .= qq| AND aa.warehouse_id = $warehouse_id| if $form->{warehouse};
   my $partnumber = $form->like(lc $form->{partnumber}); 
   $where .= qq| AND LOWER(p.partnumber) LIKE '$partnumber' | if $form->{partnumber};

   $where .= qq| AND aa.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND aa.transdate <= '$form->{dateto}'| if $form->{dateto};
 
   print qq|<table>|;
   print qq|<tr><th>Warehouse</th><td>$warehouse</td></tr>| if $form->{warehouse};
   print qq|<tr><th>Part Number</th><td>$form->{partnumber}</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Description</th><td>$description</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Onhand</th><td>$onhand</td></tr>| if $form->{partnumber};
   print qq|<tr><th>From Date</th><td>$form->{datefrom}</td></tr>| if $form->{datefrom};
   print qq|<tr><th>To Date</th><td>$form->{dateto}</td></tr>| if $form->{dateto};
   print qq|</table>|;

   my $query = qq|
	SELECT 
		i.parts_id,
		p.partnumber,
		p.description,
		p.onhand,
		TO_CHAR(aa.transdate, 'MON-YY') AS month,
		'compras' AS tipo, 
		w.description AS warehouse,
		aa.invnumber, 
		v.name,
		aa.transdate,
		p.unit,
		(i.qty * -1) AS qty,
		(i.qty * -1) * i.sellprice AS cost,
		i.sellprice
	FROM invoice i
	JOIN ap aa ON (i.trans_id = aa.id)
	JOIN vendor v ON (aa.vendor_id = v.id)
	LEFT JOIN warehouse w ON (w.id = aa.warehouse_id)
	JOIN parts p ON (p.id = i.parts_id)
	WHERE $where

	UNION ALL

	SELECT 
		i.parts_id,
		p.partnumber,
		p.description,
		p.onhand,
		TO_CHAR(aa.transdate, 'MON-YY') AS month,
		'ventas' AS tipo,
		w.description AS warehouse,
		aa.invnumber,
		c.name,
		aa.transdate,
		p.unit,
		(i.qty * -1) AS qty,
		(SELECT SUM(qty * costprice) 
		FROM fifo 
		WHERE fifo.parts_id = i.parts_id
		AND fifo.trans_id = i.trans_id) * -1 AS cost,
		i.sellprice
	FROM invoice i
	JOIN ar aa ON (i.trans_id = aa.id)
	JOIN customer c ON (aa.customer_id = c.id)
	LEFT JOIN warehouse w ON (w.id = aa.warehouse_id)
	JOIN parts p ON (p.id = i.parts_id)
	WHERE $where

	ORDER BY partnumber, transdate;
   |;

   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   begin_table;
   begin_heading_row;
   print_heading('Part Number');
   print_heading('Month');
   print_heading('Tipo');
   print_heading('WH');
   print_heading('Invoice Number');
   print_heading('Invoice Date');
   print_heading('Name');
   print_heading('Unit');
   print_heading('Qty');
   print_heading('Price');
   print_heading('Balance');
   print_heading('Cost');
   end_row;


   my $i = 0; my $j = 1; 
   my $subtotal_qty = 0;
   my $subtotal_cost = 0;

   $partnumber_group = 'none';
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	if ($partnumber_group ne $ref->{partnumber}){
	   if ($partnumber_group ne 'none'){
		my $costquery = qq|SELECT avgcost FROM parts WHERE partnumber='$partnumber_group'|;
		my ($avgcost) = $dbh->selectrow_array($costquery);
		my $bookvalue = $avgcost * $subtotal_qty;
   	   	# print group fotter
   	   	begin_total_row;
   	   	print_text('&nbsp;'); # blank cell
   	   	print_text('&nbsp;');
   	   	print_text('&nbsp;');
   	   	print_text('&nbsp;');
   	   	print_text('&nbsp;');
   	   	print_text('&nbsp;');
   	  	print_text('&nbsp;');
   	  	print_text('&nbsp;');
   	   	print_number($subtotal_qty);
   	   	print_number($bookvalue);
   	   	print_text('&nbsp;');
   	   	print_number($subtotal_cost);
   	   	end_row;
	   }

	  $partnumber_group = $ref->{partnumber};
   	  $subtotal_qty = 0; 
   	  $subtotal_cost = 0; 
   	  if ($form->{datefrom}){
		my $opening_where = qq| (1 = 1)|;
   		$opening_where .= qq| AND aa.warehouse_id = $warehouse_id| if $form->{warehouse};
		$opening_where .= qq| AND aa.transdate < '$form->{datefrom}'|;
		$opening_where .= qq| AND i.parts_id = $ref->{parts_id}|;
		my $apquery = qq|SELECT SUM(0 - qty)
			FROM invoice i
			JOIN parts p ON (p.id = i.parts_id)
			JOIN ap aa ON (aa.id = i.trans_id)
			WHERE $opening_where|;
		my ($apbal) = $dbh->selectrow_array($apquery);

		my $arquery = qq|SELECT SUM(0 - qty)
			FROM invoice i
			JOIN parts p ON (p.id = i.parts_id)
			JOIN ar aa ON (aa.id = i.trans_id)
			WHERE $opening_where|;
		my ($arbal) = $dbh->selectrow_array($arquery);
		$subtotal_qty = $apbal + $arbal;
   	   }
	   # print opening balance
   	   if ($subtotal_qty != 0){
   	      begin_data_row(1);
   	      print_text('&nbsp;'); # blank cell
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
	      print_number($subtotal_qty);
   	      print_text('&nbsp;');
   	      print_text('&nbsp;');
   	      print_number($subtotal_cost);
   	      end_row;
   	   }
	 }
	# update totals etc
        $subtotal_qty += $ref->{qty};
        $subtotal_cost += $ref->{cost};

	begin_data_row($i);
	print_text($ref->{partnumber});
	print_text($ref->{month});
	print_text($ref->{tipo});
	print_text($ref->{warehouse});
	print_text($ref->{invnumber});
	print_text($ref->{transdate});
	print_text($ref->{name});
	print_text($ref->{unit});
	print_number($ref->{qty});
	print_number($ref->{sellprice});
	print_number($subtotal_qty);
	print_number($ref->{cost});
	end_row;

	$i++; $i %= 2; $j++;
   }
   my $costquery = qq|SELECT avgcost FROM parts WHERE partnumber='$partnumber_group'|;
   my ($avgcost) = $dbh->selectrow_array($costquery);
   my $bookvalue = $avgcost * $subtotal_qty;

   # print fotter
   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_number($subtotal_qty);
   print_number($bookvalue);
   print_text('&nbsp;');
   print_number($subtotal_cost);
   end_row;
   end_table;
}

###################
#
# EOF: reports.pl
#
###################

