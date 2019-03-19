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
sub ask_renumber {
  print_header('Renumber all transaction IDs');
  begin_form;
  begin_table;

  print qq|<br><hr>|;
  $form->{nextsub} = 'do_renumber';
  end_form;
  end_page;
}

#---------------------------------------
sub do_renumber {
   #$form->isblank('partnumber', 'Part number cannot be blank');
   print_header('Renumber all transaction IDs');

   my $dbh = $form->dbconnect(\%myconfig);
   # Build WHERE cluase

   $form->info("Renumbering transactions ...<br>\n");

   my $dbh = $form->dbconnect(\%myconfig);

   $dbh->do('DROP TABLE new_ids');
   $dbh->do('DROP SEQUENCE new_id');

   $query = qq|
	CREATE TABLE new_ids(
	   old_id integer,
	   transdate date,
	   transtype varchar(10),
	   new_id integer
	)|;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|
	CREATE SEQUENCE new_id|;
   $dbh->do($query) || $form->dberror($query);

   #$query = qq|SELECT nextval('new_id')|;
   #$dbh->do($query) || $form->dberror($query);

   $form->info("Adding AP transactions<br>\n");
   $query = qq|
	INSERT INTO new_ids (old_id, transdate, transtype)
	SELECT id, transdate, '01-AP' FROM ar|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Adding AR transactions<br>\n");
   $query = qq|
	INSERT INTO new_ids (old_id, transdate, transtype)
	SELECT id, transdate, '01-AR' FROM ap|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Adding OE transactions<br>\n");
   $query = qq|
	INSERT INTO new_ids (old_id, transdate, transtype)
	SELECT id, transdate, '01-OE' FROM oe|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Adding GL transactions<br>\n");
   $query = qq|
	INSERT INTO new_ids (old_id, transdate, transtype)
	SELECT id, transdate, '01-GL' FROM gl|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs<br>\n");
   $query = qq|UPDATE new_ids 
		SET new_id = (SELECT nextval('new_id'))
		WHERE old_id = ?|;
   $updsth = $dbh->prepare($query) || $form->dberror($query);
   
   $query = qq|SELECT old_id FROM new_ids ORDER BY transdate, transtype|;
   $sth = $dbh->prepare($query) || $form->dberror($query);
   $sth->execute || $form->dberror($query);
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	$updsth->execute($ref->{old_id});
   }
   $sth->finish;

   $form->info("Updating new IDs in AR<br>\n");
   $query = qq|UPDATE ar SET id = (SELECT new_id FROM new_ids WHERE old_id = ar.id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in AP<br>\n");
   $query = qq|UPDATE ap SET id = (SELECT new_id FROM new_ids WHERE old_id = ap.id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in OE<br>\n");
   $query = qq|UPDATE oe SET id = (SELECT new_id FROM new_ids WHERE old_id = oe.id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in GL<br>\n");
   $query = qq|UPDATE gl SET id = (SELECT new_id FROM new_ids WHERE old_id = gl.id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in INVOICE<br>\n");
   $query = qq|UPDATE invoice SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = invoice.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in INVOICETAX<br>\n");
   $query = qq|UPDATE invoicetax SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = invoicetax.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in ORDERITEMS<br>\n");
   $query = qq|UPDATE orderitems SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = orderitems.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in INVENTORY<br>\n");
   $query = qq|UPDATE inventory SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = inventory.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in ACC_TRANS<br>\n");
   $query = qq|UPDATE acc_trans SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = acc_trans.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in DPT_TRANS<br>\n");
   $query = qq|UPDATE dpt_trans SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = dpt_trans.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $form->info("Updating new IDs in FIFO<br>\n");
   $query = qq|UPDATE fifo SET trans_id = (SELECT new_id FROM new_ids WHERE old_id = fifo.trans_id)|;
   $dbh->do($query) || $form->dberror($query);

   $dbh->disconnect;
}

###################
#
# EOF: renumber.pl
#
###################

