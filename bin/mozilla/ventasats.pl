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

sub select_customer {
   my $query = qq|SELECT id, name FROM customer ORDER BY name|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectcustomer} = "<option>\n";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectcustomer} .= qq|<option value="$ref->{name}--$ref->{id}">$ref->{name}\n|;
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
sub ventasats_search {
  print_header('Ventas ATS');
  begin_form;
  begin_table;

  select_customer;
  print_select('Customer', 'customer');

#  $form->{partnumber} = ''; # default for search form.
#  print_form_text('Part Number', 'partnumber', 20);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'ventasats_report';
  end_form;
  end_page;
}

#---------------------------------------
sub ventasats_report {
   #$form->isblank('partnumber', 'Part number cannot be blank');
   my $dbh = $form->dbconnect(\%myconfig);
   my $partnumber = $form->like(lc $form->{partnumber}); 
   my $query = qq|SELECT description, onhand FROM parts WHERE LOWER(partnumber) LIKE '$partnumber'|;
   my ($description, $onhand) = $dbh->selectrow_array($query);

   print_header('Ventas ATS');

   # Build WHERE cluase
   my $where = qq| (1 = 1)|;
   
   my ($customer, $customer_id) = split(/--/, $form->{customer});
   $customer_id *= 1;
   $where .= qq| AND ar.customer_id = $customer_id| if $form->{customer};
   
   $where .= qq| AND ar.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND ar.transdate <= '$form->{dateto}'| if $form->{dateto};
 
   print qq|<table>|;
   print qq|<tr><th>Customer</th><td>$customer</td></tr>| if $form->{customer};
   #print qq|<tr><th>Part Number</th><td>$form->{partnumber}</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Description</th><td>$description</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Onhand</th><td>$onhand</td></tr>| if $form->{partnumber};
   print qq|<tr><th>From Date</th><td>$form->{datefrom}</td></tr>| if $form->{datefrom};
   print qq|<tr><th>To Date</th><td>$form->{dateto}</td></tr>| if $form->{dateto};
   print qq|</table>|;

   my $query = qq|
	SELECT
	  cc.id AS customerid,
	  cc.name AS customer,
	  cc.taxnumber AS ruc,
	
	(SELECT COUNT(ar.id) FROM ar WHERE ar.customer_id = cc.id) AS facturas,
	(SELECT sum(ar.amount) FROM ar WHERE ar.customer_id = cc.id) AS balance,
	(SELECT sum(ar.amount - ar.netamount) FROM ar WHERE ar.customer_id = cc.id) AS iva,

	(SELECT sum(0-ac.amount)
		FROM acc_trans ac
		JOIN ar on (ac.trans_id = ar.id)
		WHERE $where
		AND ar.customer_id = cc.id
		AND ac.chart_id = '10853'
	) AS rta

	FROM customer cc
	WHERE 1 = 1
	ORDER BY 1;
   |;

   #AND ar.customer_id = $ref->{customerid}
   
   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   
 
   
   begin_table;
   begin_heading_row;
   print_heading('Customer');
   print_heading('RUC');
   print_heading('Facturas');
   print_heading('Base0');
   print_heading('Base12');
   print_heading('Iva');
   print_heading('Rta');
   end_row;


   my $i = 0; my $j = 1; 
   my $subtotal_base0 = 0;
   my $subtotal_base12 = 0;
   my $subtotal_iva = 0;
   my $subtotal_rta = 0;
   my $base0 = 0;
   my $base12 = 0;
   
   $partnumber_group = 'none';
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	# update totals etc
        $subtotal_base0 += $base0;
        $subtotal_base12 += $base12;
        $subtotal_iva += $ref->{iva};
        $subtotal_rta += $ref->{rta};
        $base12 = ($ref->{iva})/0.12;
		$base0 = ($ref->{balance}) - $base12 - ($ref->{iva});
        
        
	begin_data_row($i);
	print_text($ref->{customer});
	print_text($ref->{ruc});
	print_integer($ref->{facturas});
	print_number($base0);
	print_number($base12);
	print_number($ref->{iva});
	print_number($ref->{rta});
	end_row;

	$i++; $i %= 2; $j++;
   }

   # print fotter
   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_integer('&nbsp;');
   print_number($subtotal_base0);
   print_number($subtotal_base12);
   print_number($subtotal_iva);
   print_number($subtotal_rta);
   end_row;
   end_table;
}

###################
#
# EOF: reports.pl
#
###################

