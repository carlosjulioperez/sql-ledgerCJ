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

sub print_entero {
   my $data = shift;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $data, 0) . qq|</td>|;
}

sub print_select {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><select name=$cname>$form->{"select$cname"}</select></td></tr>|;
}

sub select_partsgroup {
    $query = qq|SELECT id, partsgroup FROM partsgroup ORDER BY partsgroup|;
    $dbh = $form->dbconnect(\%myconfig);
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    $form->{selectpartsgroup} = "<option>\n";
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
		$form->{selectpartsgroup} .= qq|<option value="$ref->{partsgroup}--$ref->{id}">$ref->{partsgroup}\n|;
    }
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
sub impsales_search {
  print_header('Conciliacion de Inventarios');
  begin_form;
  begin_table;

  select_partsgroup;
  print_select('Group', 'partsgroup');

#  $form->{partnumber} = ''; # default for search form.
#  print_form_text('Part Number', 'partnumber', 20);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'impsales_report';
  end_form;
  end_page;
}

#---------------------------------------
sub impsales_report {
   #$form->isblank('partnumber', 'Part number cannot be blank');
   my $dbh = $form->dbconnect(\%myconfig);
   #my $partnumber = $form->like(lc $form->{partnumber}); 
   #my $query = qq|SELECT description, onhand FROM parts WHERE LOWER(partnumber) LIKE '$partnumber'|;
   #my ($description, $onhand) = $dbh->selectrow_array($query);

   print_header('Conciliacion de Inventarios');

   # Build WHERE cluase
   my $where = qq| (1 = 1)|;
   
   my ($partsgroup, $partsgroup_id) = split('--', $form->{partsgroup});
   #$partsgroup_id *= 1;
   #$where .= qq| AND p.partsgroup_id = $partsgroup_id| if $form->{partsgroup};
   $where .= qq| AND ar.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND ar.transdate <= '$form->{dateto}'| if $form->{dateto};
   
   $where .= qq| AND ap.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND ap.transdate <= '$form->{dateto}'| if $form->{dateto};
 
   print qq|<table>|;
   print qq|<tr><th>Group</th><td>$partsgroup</td></tr>| if $form->{partsgroup};
   #print qq|<tr><th>Part Number</th><td>$form->{partnumber}</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Description</th><td>$description</td></tr>| if $form->{partnumber};
   #print qq|<tr><th>Onhand</th><td>$onhand</td></tr>| if $form->{partnumber};
#
   print qq|<tr><th>From Date</th><td>$form->{datefrom}</td></tr>| if $form->{datefrom};
   print qq|<tr><th>To Date</th><td>$form->{dateto}</td></tr>| if $form->{dateto};
   print qq|</table>|;

   my $query = qq|
	SELECT
		p.id,
		p.partnumber,
		p.description,
		p.partsgroup_id,
		p.lastcost,
		
		(SELECT SUM(i.qty) AS onhand
		FROM inventory i
		JOIN ap ON (ap.id = i.trans_id)
		WHERE ap.transdate < '$form->{datefrom}'
		AND i.parts_id = p.id
		AND reporttype = 'CXP') AS scomprado,
		
		(SELECT SUM(0-i.qty) AS onhand
		FROM inventory i
		JOIN ar ON (ar.id = i.trans_id)
		WHERE ar.transdate < '$form->{datefrom}' 
		AND i.parts_id = p.id
		AND reporttype = 'CXC') AS svendido,
		
		(SELECT SUM(i.qty) AS onhand
		FROM inventory i
		JOIN ap ON (ap.id = i.trans_id)
		WHERE ap.transdate >= '$form->{datefrom}'
		AND ap.transdate <= '$form->{dateto}'
		AND i.parts_id = p.id
		AND reporttype = 'CXP') AS comprado,
		
		(SELECT SUM(0-i.qty) AS onhand
		FROM inventory i
		JOIN ar ON (ar.id = i.trans_id)
		WHERE ar.transdate >= '$form->{datefrom}' 
		AND ar.transdate <= '$form->{dateto}'
		AND i.parts_id = p.id
		AND reporttype = 'CXC') AS vendido,
		
		(SELECT SUM(i.qty) AS onhand
		FROM inventory i
		where i.parts_id = p.id
		and i.warehouse_id = '12952') AS bodega,
		
		(SELECT SUM(i.qty) AS onhand
		FROM inventory i
		where i.parts_id = p.id
		and i.warehouse_id = '24161') AS ensambles,
		
		SUM(i.qty) AS onhand
		
		
	FROM parts p
	LEFT JOIN inventory i ON (i.parts_id = p.id)
	WHERE 1 = 1
	AND p.partsgroup_id = $partsgroup_id
	
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 1;
   |;

   #AND onhand > '0'
   
   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   
 
   
   begin_table;
   begin_heading_row;
   print_heading('codigo');
   print_heading('Descripcion');
   print_heading('Saldo Inicial');
   print_heading('Comprado');
   print_heading('Vendido');
   print_heading('Bodega Disponible');
   print_heading('Ensambles');
   print_heading('Diferencia');
   print_heading('Valorizado');
   end_row;


   my $i = 0; my $j = 1; 
   my $subtotal_comprado = 0;
   my $subtotal_vendido = 0;
   my $subtotal_scomprado = 0;
   my $subtotal_svendido = 0;
   my $subtotal_sonhand = 0;
   my $subtotal_ensambles = 0;
   my $subtotal_dif = 0;
   my $valorizado = 0;
   my $subtotal_valorizado = 0;
   
   my $dif = 0;
   my $sonhand = 0;
   
   $partnumber_group = 'none';
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	# update totals etc
        $subtotal_comprado += $ref->{comprado};
		$subtotal_vendido += $ref->{vendido};
		$subtotal_scomprado += $ref->{scomprado};
		$subtotal_svendido += $ref->{svendido};
		$subtotal_onhand += $ref->{onhand};
		$subtotal_bodega += $ref->{bodega};
		$subtotal_ensambles += $ref->{ensambles};
        $dif = $sonhand + $ref->{comprado} - $ref->{vendido} - $ref->{bodega};
        $valorizado = $dif * $ref->{lastcost};
        $sonhand = $ref->{scomprado} - $ref->{svendido};
        $subtotal_dif += $dif;
        $subtotal_valorizado += $valorizado;
        
        
	begin_data_row($i);
	print_text($ref->{partnumber});
	print_text($ref->{description});
	print_entero($sonhand);
	print_entero($ref->{comprado});
	print_entero($ref->{vendido});
	print_entero($ref->{bodega});
	print_entero($ref->{ensambles});
	print_entero($dif);
	print_number($valorizado);
	end_row;

	$i++; $i %= 2; $j++;
   }

   # print fotter
   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_entero($subtotal_sonhand);   
   print_entero($subtotal_comprado);
   print_entero($subtotal_vendido);
   print_entero($subtotal_bodega);
   print_entero($subtotal_ensambles);
   print_entero($subtotal_dif);
   print_number($subtotal_valorizado);
   end_row;
   end_table;
}

###################
#
# EOF: reports.pl
#
###################

