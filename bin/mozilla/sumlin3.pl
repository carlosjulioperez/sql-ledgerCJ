#=====================================================================
# Sample form for SQL-Ledger
#
# Copyright (c) 2008
#
#  Author: Armaghan Saqib
#     Web: http://www.ledger123.com
#   Email: saqib@ledger123.com
#
#  Version: 0.10
#
#======================================================================
1;
#---------------------------------------
sub continue { &{$form->{nextsub}} };

#########################################################################
##
## These one liners hide the clutter of html from processing code.
## This helps newbies to modify the form easily.
##
## Normally you do not need to edit these procedures.
##
#########################################################################
sub start_table {
  print qq|<table width=100%>|;
}

sub end_table {
  print qq|</table>|;
}

sub print_header {
  $form->{title} = shift;
  $form->header;
  print qq|<body><table width=100%><tr><th class=listtop>$form->{title}</th></tr></table><br>\n|;
}

sub start_form {
  print qq|<form method=post action=$form->{script}>|;
}

sub add_button {
  my $action = shift;
  print qq|<input type=submit class=submit name=action value="$action">\n|;
}

sub end_form {
  for (qw(nextsub path login callback title)){
    if ($form->{$_}) {
      print qq|<input type=hidden name=$_ value="$form->{$_}">\n|;
    }
  }
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

sub print_select {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><select name=$cname>$form->{"select$cname"}</select></td></tr>|;
}

sub print_checkbox {
    my ($fldname, $fldprompt, $checked, $extratag) = @_;
    print qq|<input name=$fldname class=checkbox type=checkbox value=Y $checked> $fldprompt\n|;
    print qq|$extratag| if $extratag;
}

sub rpt_int {
  my $column_data = shift;
  my $str = qq|<td align=right>$column_data</td>|;
  $str;
}

# format header column
sub rpt_hdr {
  my $column_name = shift;
  my $column_heading = shift;
  my $href = shift;
  my $str;
  if ($href){
     $str = qq|<th><a class=listheading href=$href&sort=$column_name>$column_heading</a></th>|;
  } else {
     $str = qq|<th class=listheading>$column_heading</th>|;
  }
  $str;
}

# format text column
sub rpt_txt {
  my $column_data = shift;
  my $link = shift;
  my $str;
  if ($link) {
     $str = qq|<td><a href="$link">$column_data</a></td|;
  } else {
     $str = qq|<td>$column_data</td>|;
  }
  $str;
}

sub rpt_dec {
  my ($column_data, $precision) = @_;
  $precision = 0 if !($precision);
  my $str = qq|<td align=right>| . $form->format_amount(\%myconfig, $column_data, $precision) . qq|</td>|;
  $str;
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

sub print_title {
    $form->header;
    print qq|<body><table width=100%><tr><th class=listtop>$form->{title}</th></tr></table>\n|;
}

sub print_criteria {
   my ($fldname, $fldprompt) = @_;
   print qq|$fldprompt : $form->{"$fldname"}<br>\n| if $form->{"$fldname"};
}

sub print_heading {
   my $prompt = shift;
   print qq|<th>$prompt</th>|;
}

sub print_text {
   my ($data, $link) = @_;
   if ($link) {
      print qq|<td><a href="$link">$data</a></td>|;
   } else {
      print qq|<td>$data</td>|;
   }
}

sub print_integer {
   my $data = shift;
   print qq|<td align=right>$data</td>|;
}

sub print_number {
   my $data = shift;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $data, 2) . qq|</td>|;
}

sub print_hidden {
    my ($fldname) = @_;
    print qq|<input type=hidden name=$fldname value="$form->{$fldname}">\n|;
}


###########################################################################
##
##  ACTUAL FORM PROCEDURES
##
##  Edit the following procedures with your table columns info to make a 
##  new form for your custom table.
##
###########################################################################
#---------------------------------------
sub search {
  &print_header('Reporte de Utilidad por Lineas de Producto');
  &start_form;
  &start_table;
  &print_form_text('Linea', 'linumber', 15);
  &print_form_date('From', 'datefrom');
  &print_form_date('To', 'dateto');
  
  print qq|<tr><th align=right>| . $locale->text('Incluir en Reporte') . qq|</th><td>|;

  &print_checkbox('l_no', $locale->text('No.'), 'checked', '<br>');
  &print_checkbox('l_trans_id', $locale->text('TransID'), '', '<br>');
  &print_checkbox('l_transdate', $locale->text('Date'), '', '<br>');
  &print_checkbox('l_linea', $locale->text('Linea Grupo'), 'checked', '<br>');
  &print_checkbox('l_linumber', $locale->text('Linea Item '), 'checked', '<br>');
  &print_checkbox('l_description', $locale->text('Item '), 'checked', '<br>');
  &print_checkbox('l_qty', $locale->text('Qty '), 'checked', '<br>');
  &print_checkbox('l_costprice', $locale->text('Cost Price '), 'checked', '<br>');
  &print_checkbox('l_sellprice', $locale->text('Sell Price '), 'checked', '<br>');
  &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '<br>');

  print qq|</td></tr>|;
  
  
  
  
  &end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'report';
  &add_button('Continue');
  &end_form;
  &end_page;
}

#---------------------------------------
sub report {
   # callback to report
   my $callback = qq|$form->{script}?action=report|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &print_header('Reporte de Utilidad por Lineas de Producto');

   # Build WHERE cluase
   my $linumber = $form->like(lc $form->{linumber});
   my $where = qq| (1 = 1)|;
   $where .= qq| AND LOWER(l.linumber) LIKE '$linumber' | if $form->{linumber};
   $where .= qq| AND f.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND f.transdate <= '$form->{dateto}'| if $form->{dateto};

   @columns = qw( trans_id transdate linea linumber description qty costprice sellprice);
   # if this is first time we are running this report.
   $form->{sort} = 'linea' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (
                        linea => 1,
			linumber => 2,
			transdate => 3,
			trans_id => 4,
			description => 5,
			qty => 6,
			costprice => 7,
			sellprice => 8
   );

   my $sort_order = $form->sort_order(\@columns, \%ordinal);


   foreach (qw(l_subtotal datefrom dateto linumber)){
       $callback .= "&$_=$form->{$_}";
   }
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);


   $query = qq|
	SELECT
               f.trans_id,
               f.transdate,
               substring(l.linumber, 1, 2) as linea,
               l.linumber,
               p.description,
               SUM(f.qty) AS qty,
               SUM(f.qty * f.costprice) AS costprice,
               SUM(f.qty * f.sellprice) AS sellprice
	FROM fifo f
	JOIN parts p ON (p.id = f.parts_id)
        LEFT JOIN lineitem l ON (l.id = p.tariff_hscode)
   	WHERE $where
   	GROUP BY 3,4,1,2,5
        ORDER BY $form->{sort} $form->{direction}
   |;

   # No. columns should always come first
   splice @columns, 0, 0, 'no';

   # Select columns selected for report display
   foreach $item (@columns) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }


#   $callback .= "&l_subtotal=$form->{l_subtotal}";

   foreach (qw(l_subtotal datefrom dateto linumber)){
       $callback .= "&$_=$form->{$_}";
   }
   
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{trans_id} 		= rpt_hdr('trans_id', $locale->text('TransID'), $href);
   $column_header{transdate} 		= rpt_hdr('transdate', $locale->text('Date'), $href);
   $column_header{linea}  		= rpt_hdr('linea', $locale->text('Linea Grupo'), $href);
   $column_header{linumber}  		= rpt_hdr('linumber', $locale->text('Linea Item'), $href);
   $column_header{description} 		= rpt_hdr('description', $locale->text('Item'), $href);
   $column_header{qty}  		= rpt_hdr('qty', $locale->text('Qty'), $href);
   $column_header{costprice}  		= rpt_hdr('costprice', $locale->text('Cost Price'), $href);
   $column_header{sellprice} 		= rpt_hdr('sellprice', $locale->text('Sell Price'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'utilLin');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Reporte de Utilidad por Lineas de Producto');
   &print_title;
   &print_criteria('linea', 'Linea Grupo');
   &print_criteria('linumber','Linea Item');
   &print_criteria('transdate', 'Date');
   &print_criteria('trans_id', 'TransId');
   &print_criteria('description', 'Item');
   &print_criteria('costprice', 'Cost Price');
   &print_criteria('sellprice', 'Sell Price');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|;


   # Subtotal and total variables
   my $subtotal_qty = 0;
   my $subtotal_costprice = 0;
   my $subtotal_sellprice = 0;
   my $total_qty = 0;
   my $total_costprice = 0;
   my $total_sellprice = 0;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';
   
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	$groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
	if ($form->{l_subtotal}){
	   if ($groupbreak ne $ref->{$form->{sort}}){
		$groupbreak = $ref->{$form->{sort}};
		# prepare data for footer
                $column_data{no}   		= rpt_txt('&nbsp;');
                $column_data{trans_id} 	        = rpt_txt('&nbsp;');
                $column_data{transdate} 	= rpt_txt('&nbsp;');
                $column_data{linea}  		= rpt_txt($ref->{linea});
                $column_data{linumber}  	= rpt_txt($ref->{linumber});
                $column_data{description} 	= rpt_txt('&nbsp;');
                $column_data{qty}  		= rpt_int($subtotal_qty);
                $column_data{costprice}  	= rpt_dec($subtotal_costprice,2);
                $column_data{sellprice} 	= rpt_dec($subtotal_sellprice,2);
   

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$subtotal_qty = 0;
                $subtotal_costprice = 0;
                $subtotal_sellprice = 0;
	   }
	}

	$column_data{no}   		= rpt_txt($no);
   	$column_data{trans_id}		= rpt_txt($ref->{trans_id});
   	$column_data{transdate}		= rpt_txt($ref->{transdate});
   	$column_data{linea} 	        = rpt_txt($ref->{linea});
   	$column_data{linumber}         	= rpt_txt($ref->{linumber});
   	$column_data{description}      	= rpt_txt($ref->{description});
   	$column_data{qty}    		= rpt_int($ref->{qty});
   	$column_data{costprice}   	= rpt_dec($ref->{costprice},2);
   	$column_data{sellprice}		= rpt_dec($ref->{sellprice},2);

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$subtotal_qty += $ref->{qty};
	$total_qty += $ref->{qty};
	
        $subtotal_costprice += $ref->{costprice};
        $total_costprice += $ref->{costprice};

        $subtotal_sellprice += $ref->{sellprice};
        $total_sellprice += $ref->{sellprice};
   }

   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{trans_id}	= rpt_txt('&nbsp;');
   $column_data{transdate}	= rpt_txt('&nbsp;');
   $column_data{linea}          = rpt_txt('&nbsp;');
   $column_data{linumber}    	= rpt_txt('&nbsp;');
   $column_data{description}    = rpt_txt('&nbsp;');
   $column_data{qty}   	        = rpt_int($subtotal_qty);
   $column_data{costprice}    	= rpt_dec($subtotal_costprice,2);
   $column_data{cellprice}    	= rpt_dec($subtotal_sellprice,2);
   
  if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total

   $column_data{qty}   	            	= rpt_int($total_qty);
   $column_data{costprice}   		= rpt_dec($total_costprice,2);
   $column_data{sellprice}   		= rpt_dec($total_sellprice,2);


   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;

   $sth->finish;
   $dbh->disconnect;
}





#######################
#
# EOF: sampleform.pl
#
#######################

