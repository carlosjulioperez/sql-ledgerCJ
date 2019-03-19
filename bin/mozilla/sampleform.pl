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

sub select_parts {
   my $query = qq|SELECT id, partnumber, description FROM parts ORDER BY partnumber|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectparts} = "";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectparts} .= qq|<option value="$ref->{partnumber}--$ref->{id}">$ref->{partnumber}--$ref->{description}\n|;
   }
   $dbh->disconnect;
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
sub display_form {
  &print_header($form->{title});
  &start_form;
  &start_table;

  $form->{selectparts} = $form->unescape($form->{selectparts});
  if ($form->{parts_id}){
     $form->{selectparts} =~ s/ selected//;
     $form->{selectparts} =~ s/(\Q--$form->{parts_id}"\E)/$1 selected/;
  }

  &print_form_text('Reference', 'reference', 15);
  &print_form_date('Date', 'transdate');
  &print_select('Number', 'parts');
  &print_form_text('Description', 'description', 35);
  &print_form_text('Quantity', 'qty', 10);
  &print_form_text('Cost', 'cost', 10);
  &print_form_text('Notes', 'notes', 35);
  &end_table;
  print qq|<hr>|;
  &add_button('Update');
  &add_button('Save');
  &add_button('Save as new') if $form->{id};
  &add_button('Delete') if $form->{id};

  # create hidden variables
  &print_hidden('title');
  &print_hidden('id');

  $form->{selectparts} = $form->escape($form->{selectparts},1);
  &print_hidden('selectparts');

  &end_form;
}

#---------------------------------------
sub add {
  if (!$form->{callback}){
     $form->{callback} = qq|$form->{script}?action=add&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}|;
     $form->{callback} = $form->escape($form->{callback},1);
  }

  $form->{title} = 'Add Transaction';
  &select_parts;
  &display_form;
}

#---------------------------------------
sub edit {
   my $dbh = $form->dbconnect(\%myconfig);
   my $query = qq|SELECT * FROM production WHERE id = $form->{id}|;
   my $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $ref = $sth->fetchrow_hashref(NAME_lc);
   foreach $key (keys %$ref) {
      $form->{$key} = $ref->{$key};
   }
   $sth->finish;
   $dbh->disconnect;

   $form->{title} = 'Edit Transaction';
   &select_parts;
   &display_form;
}

#---------------------------------------
sub update {
   ($form->{partnumber}, $form->{parts_id}) = split(/--/, $form->{parts});
   &display_form;
}

#-------------------------------
sub delete {

  $form->header;
  print qq|<body><form method=post action=$form->{script}>|;

  $form->{action} = "yes";
  $form->hide_form;

  print qq|<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>
	<h4>|.$locale->text('Are you sure you want to delete Transaction ').qq| $form->{reference}</h4>
	<p><input name=action class=submit type=submit value="|.$locale->text('Yes').qq|"></form>|;
}

#-------------------------------
sub yes {
  $dbh = $form->dbconnect_noauto(\%myconfig);
  $query = qq|DELETE FROM production WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

   # Now commit the whole tranaction 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $form->{callback} = $form->unescape($form->{callback});
  $form->redirect($locale->text('Transaction deleted!'));
}


#-------------------------------
sub save_as_new {
  delete $form->{id};
  &save;
}

#-------------------------------
sub save {
  $form->isblank('reference', 'Reference cannot be blank');

  ($null, $form->{parts_id}) = split(/--/, $form->{parts});
  $form->{parts_id} *= 1;

  $dbh = $form->dbconnect_noauto(\%myconfig);
  ($null, $form->{employee_id}) = $form->get_employee($dbh);

  # numeric columns: get rid of anything bad
  $form->{qty} *= 1;
  $form->{cost} *= 1;

  # quote text columns with $dbh->quote
  if ($form->{id}){
     $query = qq|UPDATE production SET
		   reference = |.$dbh->quote($form->{reference}).qq|,
		   transdate = '$form->{transdate}',
		   parts_id = $form->{parts_id},
		   description = |.$dbh->quote($form->{description}).qq|,
		   qty = $form->{qty},
		   cost = $form->{cost},
		   notes = |.$dbh->quote($form->{notes}).qq|,
		   employee_id = $form->{employee_id}
		WHERE id = $form->{id}
		|;
  } else {
    $query = qq|INSERT INTO production (
			reference, 
			transdate, 
			parts_id,
			description, 
			qty, 
			cost,
			notes, 
			employee_id
		) VALUES (
			|.$dbh->quote($form->{reference}).qq|,
			'$form->{transdate}',
			$form->{parts_id},
			|.$dbh->quote($form->{description}).qq|,
			$form->{qty},
			$form->{cost},
			|.$dbh->quote($form->{notes}).qq|,
			$form->{employee_id}
		)|;

  }
  $dbh->do($query) || $form->dberror($query);
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $form->{callback} = $form->unescape($form->{callback});
  $form->redirect($locale->text('Transaction saved!'));
}

#---------------------------------------
sub search {
  &print_header('Production List');
  &start_form;
  &start_table;
  &print_form_text('Reference', 'reference', 15);
  &print_form_date('From', 'datefrom');
  &print_form_date('To', 'dateto');
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

   &print_header('Production List');

   # Build WHERE cluase
   my $reference = $form->like(lc $form->{reference}); 
   my $where = qq| (1 = 1)|;
   $where .= qq| AND LOWER(production.reference) LIKE '$reference' | if $form->{reference}; 
   $where .= qq| AND production.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND production.transdate <= '$form->{dateto}'| if $form->{dateto};

   my $query = qq|
	SELECT 
		production.id, 
		production.reference, 
		production.transdate,
		parts.partnumber,
		production.description,
		production.qty,
		production.cost,
		production.notes
	FROM production
	JOIN parts ON (parts.id = production.parts_id)
	ORDER BY reference;
   |;

   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);

   &start_table;
   &begin_heading_row;
   &print_heading('No.');
   &print_heading('Reference');
   &print_heading('Date');
   &print_heading('Number');
   &print_heading('Description');
   &print_heading('Qty');
   &print_heading('Cost');
   &print_heading('Notes');
   &end_row;

   my $total_qty = 0;

   my $i = 0; my $j = 1; 
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
   	$link = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	&begin_data_row($i);
	&print_integer($j);
	&print_text($ref->{reference}, $link);
	&print_text($ref->{transdate});
	&print_text($ref->{partnumber});
	&print_text($ref->{description});
	&print_number($ref->{qty});
	&print_number($ref->{cost});
	&print_text($ref->{notes});
	&end_row;

	# update totals etc
        $total_qty += $ref->{qty};
	$i++; $i %= 2; $j++;
   }
   
   # print fotter
   &begin_total_row;
   &print_text('&nbsp;'); # blank cell
   &print_text('&nbsp;');
   &print_text('&nbsp;');
   &print_text('&nbsp;');
   &print_text('&nbsp;');
   &print_number($total_qty);
   &print_text('&nbsp;');
   &print_text('&nbsp;');
   &end_row;
   &end_table;

   print qq|<hr><br>|;
   &start_form;
   &add_button('Add');
   &end_form;
   
}

#######################
#
# EOF: sampleform.pl
#
#######################

