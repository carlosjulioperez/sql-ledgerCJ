#=====================================================================
# Sample for SQL-Ledger ERP
# Copyright (c) 2007-2008
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

###########################################################################
##
##  ACTUAL REPORT PROCEDURES
##
##  These two procedures 'customer_search' and 'customer_report' implment
##  a very simple report.
##
##  Copy these procedures and rename appropriatly to create as many
##  reports as you like within this single .pl file.
##
###########################################################################
#---------------------------------------
sub ret_search {
  print_header('Last retentions list');
  begin_form;
  begin_table;
  print_form_text('Customer', 'name', 20);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'ret_report';
  end_form;
  end_page;
}

#---------------------------------------
sub ret_report {
   print_header('Last retentions list');

   # Build WHERE cluase
   my $name = $form->like(lc $form->{name}); 
   my $where = qq| (1 = 1)|;
   $where .= qq| AND LOWER(customer.name) LIKE '$name' | if $form->{name}; 
   $where .= qq| AND customer.startdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND customer.startdate <= '$form->{dateto}'| if $form->{dateto};

   my $dbh = $form->dbconnect(\%myconfig);
   my $query = qq|SELECT vendor_id, MAX(id) AS id FROM retenc GROUP BY 1 ORDER BY 1,2|;
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   my $query = qq|
		SELECT v.name, r.* FROM retenc r 
		JOIN vendor v ON v.id = r.vendor_id
		WHERE r.id = ?|;
   my $sth2 = $dbh->prepare($query);

   begin_table;
   begin_heading_row;
   print_heading('No.');
   print_heading('Vendor');
   print_heading('idprov');
   print_heading('ordnum');
   print_heading('transdate');
   end_row;

   my $i = 0; my $j = 1; 
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	$sth2->execute($ref->{id});
	while ($ref2 = $sth2->fetchrow_hashref(NAME_lc)){
	   begin_data_row($i);
	   print_integer($j);
	   print_text($ref2->{name});
	   print_text($ref2->{idprov});
	   print_text($ref2->{ordnum});
	   print_text($ref2->{transdate});
	   #print_number($ref->{creditlimit});
	   end_row;
	   # update totals etc
           #$total_creditlimit += $ref->{creditlimit};
	   $i++; $i %= 2; $j++;
	}
   }
   
   # print fotter
   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   #print_number($total_creditlimit);
   end_row;
   end_table;
}

#######################
#
# EOF: lastret.pl
#
#######################

