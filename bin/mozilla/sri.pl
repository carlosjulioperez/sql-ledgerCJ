##############
## SRI script
##############

require "$form->{path}/mylib.pl";
require "$form->{path}/lib.pl";

1;

#-------------------------------
sub bld_vendor {
    my ($fldname) = @_;
    $fldname = 'vendor' if !$fldname;
    $query = qq|SELECT id, name FROM vendor ORDER BY name|;
    $dbh = $form->dbconnect(\%myconfig);
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    $form->{"select$fldname"} = "<option>\n";
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
        $form->{"select$fldname"} .= qq|<option value="$ref->{name}--$ref->{id}">$ref->{name}\n|;
    }
}

#-------------------------------
sub bld_tiporet {
    my ($fldname) = @_;
    $fldname = 'tiporet' if !$fldname;
    $query = qq|SELECT id, description FROM tiporet ORDER BY id|;
    my $dbh = $form->dbconnect(\%myconfig);
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    $form->{"select$fldname"} = "<option>\n";
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
# carper 03-ene-2018
#       $form->{"select$fldname"} .= qq|<option value="$ref->{id}--$ref->{description}">$ref->{id}--$ref->{description}\n|;
        $form->{"select$fldname"} .= qq|<option value="$ref->{description}--$ref->{id}">$ref->{id}--$ref->{description}\n|;
    }
    $dbh->disconnect;
}

#-------------------------------
sub bld_cuenta {
    my ($fldname) = @_;
    $fldname = 'cuenta' if !$fldname;
    $query = qq|SELECT id, accno, description 
	FROM chart WHERE
	accno BETWEEN '2.1.3.01.002' AND '2.1.3.01.006' OR
	accno BETWEEN '2.1.3.02.002' AND '2.1.3.02.004'
	ORDER BY description|;
    $dbh = $form->dbconnect(\%myconfig);
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror;

    $form->{"select$fldname"} = "<option>\n";
    while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
	$form->{"select$fldname"} .= qq|<option value="$ref->{accno}--$ref->{id}">$ref->{description}\n|;
    }
    $dbh->disconnect;
}


#===============================
sub continue { &{$form->{nextsub}} };

#-------------------------------
sub display_form {
  &form_header;
  &form_footer;
}

#-------------------------------
sub form_header {
   &print_title;
   &start_form($form->{script});
   &start_table;
   # unescape all select lists and select the correct value
   $form->{selectvendor} = $form->unescape($form->{selectvendor});
   $form->{selectchart} = $form->unescape($form->{selectchart});
   $form->{selecttiporet} = $form->unescape($form->{selecttiporet});
   $form->{selectcuenta} = $form->unescape($form->{selectcuenta});

   if ($form->{vendor_id}){
      $form->{"selectvendor"} =~ s/ selected//;
      $form->{"selectvendor"} =~ s/(\Q--$form->{vendor_id}"\E)/$1 selected/;
   }

   if ($form->{chart_id}){
      $form->{"selectchart"} =~ s/ selected//;
      $form->{"selectchart"} =~ s/(\Q--$form->{chart_id}"\E)/$1 selected/;
   }

   # create hidden variables
   &print_hidden('title');
   &print_hidden('id');

   # Left column
   print qq|<tr><td valign=top><table>|;
   &print_select('vendor', $locale->text('Proveedor'));
   &print_select('chart', $locale->text('AP'));
   &print_date('transdate', $locale->text('Date'), "$form->{transdate}");
   &print_text('retnumber', $locale->text('Retenc. Nbr'), 10, "$form->{retnumber}");
   &print_text('ordnumber', $locale->text('Autoriz. Nbr'), 10, "$form->{ordnumber}");
   &print_text('memo', $locale->text('Memo'), 25, "$form->{memo}");
   &print_text('totalret', $locale->text('Total Retenido'), 10, "$form->{totalret}");

   # Right column
   print qq|</table></td><td valign=top><table>|;
   print qq|</table></td></tr>|;
   &end_table;

   #---------------
   # Retension List
   #---------------
   &start_table;
   &start_heading_row;
   print &tbl_hdr($locale->text('Tipo Retencion'));
   print &tbl_hdr($locale->text('Base 0'));
   print &tbl_hdr($locale->text('Base <> 0'));
   print &tbl_hdr($locale->text('Base no Iva'));
   print &tbl_hdr($locale->text('% Retencion'));
   print &tbl_hdr($locale->text('Valor Reten'));
   print &tbl_hdr($locale->text('Cuenta'));
   &end_row;

   my $j = 1;
   for $i (1 .. $form->{rowcount}){
	if (($form->{"base0_$j"} + $form->{"based0_$j"} + $form->{"baseni_$j"} == 0) and ($i != $form->{rowcount})) {
	   # Get rid of lines with blank partnumber
	} else {
   	   if ($form->{"tiporet_$i"}){
      		$form->{"selecttiporet"} =~ s/ selected//;
      		$form->{"selecttiporet"} =~ s/(\Q"$form->{"tiporet_$i"}"\E)/$1 selected/;
   	   }
   	   if ($form->{"cuenta_$i"}){
      		$form->{"selectcuenta"} =~ s/ selected//;
      		$form->{"selectcuenta"} =~ s/(\Q"$form->{"cuenta_$i"}"\E)/$1 selected/;
   	   }

	   print qq|<tr>|;
	   print qq|<td><select name="tiporet_$j">$form->{selecttiporet}</select></td>\n|;
	   print qq|<td><input name="base0_$j" type=text size=10 value='$form->{"base0_$i"}'></td>\n|;
	   print qq|<td><input name="based0_$j" type=text size=5 value='$form->{"based0_$i"}'></td>\n|;
	   print qq|<td><input name="baseni_$j" type=text size=5 value='$form->{"baseni_$i"}'></td>\n|;
	   print qq|<td><input name="porcret_$j" type=text size=5 value='$form->{"porcret_$i"}'></td>\n|;
	   print qq|<td><input name="valret_$j" type=text size=5 value='$form->{"valret_$i"}'></td>\n|;
	   print qq|<td><select name="cuenta_$j">$form->{selectcuenta}</select></td>\n|;
	   print qq|</tr>\n|;
	   $j++;
	}
   }
   &end_table;
   $j--;
   $form->{rowcount} = $j;

   #--------------
   # Invoices List
   #--------------
   &start_table;
   &start_heading_row;
   print &tbl_hdr($locale->text('Invoice'));
   print &tbl_hdr($locale->text('Invoice Date'));
   print &tbl_hdr($locale->text('Due Date'));
   print &tbl_hdr($locale->text('Amount'));
   print &tbl_hdr($locale->text('Due'));
   print &tbl_hdr('&nbsp;');
   print &tbl_hdr($locale->text('Adjusted'));
   &end_row;

   my $firstchecked = 'no';
   for $i (1 .. $form->{rowcount2}){
	print qq|<tr>|;
	print qq|<td>$form->{"invnumber_$i"}</td>\n|;
	print qq|<td>$form->{"transdate_$i"}</td>\n|;
	print qq|<td>$form->{"duedate_$i"}</td>\n|;
	print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{"netamount_$i"}, 2) . qq|</td>\n|;
	print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{"dueamount_$i"}, 2) . qq|</td>\n|;
        my $checked;
	if (($firstchecked eq 'no') and ($form->{"checked_$i"})){
	   $checked = 'checked';
	   $firstchecked = 'yes';
	   $form->{"adjusted_$i"} = $form->{"totalret"};
	} else {
	   $form->{"adjusted_$i"} = 0;
	}
	&print_hidden("invnumber_$i");
	&print_hidden("transdate_$i");
	&print_hidden("duedate_$i");
	&print_hidden("netamount_$i");
	&print_hidden("dueamount_$i");
	
	print qq|<td><input name="checked_$i" type=checkbox class=checkbox $checked></td>\n|;
	print qq|<td><input name="adjusted_$i" type=text size=10 value='$form->{"adjusted_$i"}'></td>\n|;
	print qq|<input type=hidden name=id_$i value=$form->{"id_$i"}>|;
	print qq|<input type=hidden name=invnumber_$i value='$form->{"invnumber_$i"}'>|;
	print qq|</tr>\n|;

   }
   print qq|<tr class=listtotal>|;
   print qq|<td>&nbsp;</td>\n|;
   print qq|<td>&nbsp;</td>\n|;
   print qq|<td>&nbsp;</td>\n|;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{total_netamount}, 2) . qq|</td>\n|;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{total_dueamount}, 2) . qq|</td>\n|;
   print qq|<td>&nbsp;</td>\n|;
   print qq|<td>| . $form->format_amount(\%myconfig, $form->{total_adjusted}, 2) . qq|</td>\n|;
   print qq|</tr>\n|;
   print qq|<input type=hidden name=rowcount2 value=$form->{rowcount2}>|;
   &end_table;


   # Now save select lists as hidden variables after escaping them
   $form->{selectchart} = $form->escape($form->{selectchart},1);
   $form->{selectvendor} = $form->escape($form->{selectvendor},1);
   $form->{selecttiporet} = $form->escape($form->{selecttiporet},1);
   $form->{selectcuenta} = $form->escape($form->{selectcuenta},1);

   &print_hidden('rowcount');
   &print_hidden('selectchart');
   &print_hidden('selectvendor');
   &print_hidden('selecttiporet');
   &print_hidden('selectcuenta');

   print('<hr size=3 noshade>');

   &add_button($locale->text('Update'));
   &add_button($locale->text('Print'));
   &add_button($locale->text('Save'));
   &add_button($locale->text('Delete')) if $form->{id};
   &end_form;
}

#-------------------------------
sub form_footer {
  # stub only. required by bin/mozilla/io.pl
  # will be needed when we use io.pl display_row procedure
}

#-------------------------------
sub add {
   $form->{title} = $locale->text('Retenciones');
   $form->{title2} = $locale->text('SRI Fields');
   $form->{callback} = qq|$form->{script}?action=add&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}|;
   $form->{callback} = $form->escape($form->{callback},1);
   &bld_chart('AP', 'selectchart');
   &bld_vendor('vendor');
   &bld_cuenta;
   &bld_tiporet;

   $form->{transdate} = $form->current_date(\%myconfig);
   $form->{rowcount} = 1;
   &form_header;
}

#-------------------------------
sub update {
   &split_combos('vendor,chart,cuenta,tiporet');

   $form->{totalret} = 0;
   $form->{vendor_id} *= 1;
   $form->{chart_id} *= 1;
   $form->{cuenta_id} *= 1;
   $form->{tiporet_id} *= 1;

   my $dbh = $form->dbconnect(\%myconfig);
   $query = qq|SELECT id, invnumber, transdate, 
		duedate, amount, amount - paid AS dueamount
		FROM ap 
		WHERE vendor_id = $form->{vendor_id}
		AND amount - paid <> 0|;
   my $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   my $i = 1;
   $form->{total_adjusted} = 0;
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	foreach $key (keys %$ref){
	   $form->{"${key}_${i}"} = $ref->{$key};
	}
	$form->{total_netamount} += $form->{"netamount_$i"};
	$form->{total_dueamount} += $form->{"dueamount_$i"};
	$form->{total_adjusted} += $form->{"adjusted_$i"};
	$i++;
   }
   $i--;
   $form->{rowcount2} = $i;
   ## multi-line processing
  my $j = 1;
  for $i (1 .. $form->{rowcount}){
     if (($form->{"base0_$i"} + $form->{"based0_$i"} + $form->{"baseni_$i"}) != 0){

	my ($null, $tiporet_id) = split(/--/, $form->{"tiporet_$i"});
	$tiporet_id *= 1;
	my $dbh = $form->dbconnect(\%myconfig);
	$query = qq|SELECT porcret FROM tiporet WHERE id = $tiporet_id|;
 	($form->{"porcret_$i"}) = $dbh->selectrow_array($query);
	$dbh->disconnect;

	$form->{"tiporet_$j"} = $form->{"tiporet_$i"}; 
	$form->{"cuenta_$j"} = $form->{"cuenta_$i"};

	$form->{"base0_$j"} = $form->{"base0_$i"};
	$form->{"based0_$j"} =  $form->{"based0_$i"};
	$form->{"baseni_$j"} =  $form->{"baseni_$i"};
	$form->{"porcret_$j"} =  $form->{"porcret_$i"};

	$form->{"valret_$j"} = (($form->{"base0_$j"} + $form->{"based0_$j"} + $form->{"baseni_$j"}) * $form->{"porcret_$j"}) / 100;
        $form->{"valret_$j"} = $form->round_amount($form->{"valret_$j"}, 2);
	$form->{totalret} += $form->{"valret_$j"};
	$j++;
     }
   }
   # remove blank partnumber lines
   $j = $form->{rowcount};
   if (($form->{"base0_$j"} + $form->{"based0_$j"} + $form->{"baseni_$j"}) != 0){
	$j++;
	$form->{"tiporet_$j"} = "";
	$form->{"cuenta_$j"} = "";
	$form->{"base0_$j"} = "";
	$form->{"based0_$j"} = "";
	$form->{"baseni_$j"} = "";
	$form->{"porcret_$j"} = "";
	$form->{"valret_$j"} = "";
	$form->{rowcount} = $j;
   }
   &form_header;
}

#-------------------------------
sub save {
#  $form->isblank('retnumber', $locale->text('Retenc. Nbr. cannot be blank'));
#  $form->isblank('ordnumber', $locale->text('Autoriz. Nbr. cannot be blank')) if $form->{closed} eq 'Y';

  &split_combos('department,from_warehouse,to_warehouse');
  $form->{department_id} *= 1;
  $form->{from_warehouse_id} *= 1;
  $form->{to_warehouse_id} *= 1;

  $dbh = $form->dbconnect_noauto(\%myconfig);
  my ($null, $employee_id) = $form->get_employee($dbh); # Get employee_id of current login

  # select the first invoice which has adjusted amount.
  for $i (1 .. $form->{rowcount2}){
     if ($form->{"checked_$i"}){
	$form->{id} = $form->{"id_$i"};
	$form->{invnumber} = $form->{"invnumber_$i"};
	last;
     }
  }

  my ($null, $vendor_id) = split(/--/, $form->{vendor});
  $vendor_id *= 1;

  # invnumber parts
  $estab = substr($form->{invnumber}, 0, 3);
  $ptoemi = substr($form->{invnumber}, 4, 3);
  $sec = substr($form->{invnumber}, 8, 9);
  $sec *= 1;

  # retnumber parts
  $estabret = substr($form->{retnumber}, 0, 3);
  $ptoemiret = substr($form->{retnumber}, 4, 3);
  $secret = substr($form->{retnumber}, 8, 9);
  $secret *= 1;

  $vquery = qq|SELECT tipoid_id, gifi_accno 
		FROM vendor WHERE id = $vendor_id|;
  my ($tipoid_id, $gifi_accno) = $dbh->selectrow_array($vquery);

  $apquery = qq|SELECT ordnumber, transdate, tipodoc_id
		FROM ap WHERE id = $form->{id}|;
  my ($ordnumber, $transdate, $tipodoc_id) = $dbh->selectrow_array($apquery);
  $tipodoc_id *= 1;

  for $i (1 .. $form->{rowcount} - 1){
     my ($null, $chart_id) = split(/--/, $form->{"cuenta_$i"});
     my ($null, $tiporet_id) = split(/--/, $form->{"tiporet_$i"});
     $form->{"base0_$i"} *= 1;
     $form->{"based0_$i"} *= 1;
     $form->{"baseni_$i"} *= 1;
     $form->{"valret_$i"} *= 1;
     $form->{"porcret_$i"} *= 1;
     $query = qq|
	INSERT INTO retenc 
		(id, vendor_id,
		transdate, ordnumber, 
		tiporet_id, base0, based0, 
		baseni, valret, chart_id,
		estab, ptoemi, sec,
		estabret, ptoemiret, secret,
		tipoid_id, idprov, ordnumberret,
		transdateret, tipodoc_id, porcret)
	VALUES ($form->{id}, $vendor_id,
		'$transdate', '$ordnumber',
		$tiporet_id, $form->{"base0_$i"}, $form->{"based0_$i"},
		$form->{"baseni_$i"}, $form->{"valret_$i"}, $chart_id,
		'$estab', '$ptoemi', $sec,
		'$estabret', '$ptoemiret', $secret,
		$tipoid_id, '$gifi_accno', '$form->{ordnumber}',
		'$form->{transdate}', $tipodoc_id, $form->{"porcret_$i"})
        |;
     $dbh->do($query) || $form->dberror($query);

     $query = qq|
	INSERT INTO acc_trans
		(trans_id, chart_id, amount,
		transdate, source, memo)
	VALUES ($form->{id}, $chart_id, $form->{"valret_$i"},
		'$form->{transdate}', '$form->{retnumber}', '$form->{memo}')
	|;

     $dbh->do($query) || $form->dberror($query);
  }

  # Debit AP account
  my ($null, $chart_id) = split(/--/, $form->{chart});
  my $totalret = $form->{totalret} * -1;
  $query = qq|
	INSERT INTO acc_trans
		(trans_id, chart_id, amount,
		transdate, source, memo)
	VALUES ($form->{id}, $chart_id, $totalret,
		'$form->{transdate}', '$form->{retnumber}', '$form->{memo}')
	|;
  $dbh->do($query) || $form->dberror($query);

  # Update vendor with paid amount
  $query = qq|
	UPDATE ap SET
		paid = paid + $form->{totalret},
		datepaid = '$form->{transdate}'
	WHERE id = $form->{id}
  |;
  $dbh->do($query) || $form->dberror($query);

  # Now commit the whole tranaction 
  my $rc = $dbh->commit;
  $dbh->disconnect;

  $form->{callback} = $form->unescape($form->{callback});
  $form->redirect($locale->text('Retencion saved!'));
}

#-------------------------------
sub print {
   &print_title;
   &start_form($form->{script});
   &start_table;
   # unescape all select lists and select the correct value
   $form->{selectvendor} = $form->unescape($form->{selectvendor});
   $form->{selectchart} = $form->unescape($form->{selectchart});
   $form->{selecttiporet} = $form->unescape($form->{selecttiporet});
   $form->{selectcuenta} = $form->unescape($form->{selectcuenta});

   if ($form->{vendor_id}){
      $form->{"selectvendor"} =~ s/ selected//;
      $form->{"selectvendor"} =~ s/(\Q--$form->{vendor_id}"\E)/$1 selected/;
   }

   if ($form->{chart_id}){
      $form->{"selectchart"} =~ s/ selected//;
      $form->{"selectchart"} =~ s/(\Q--$form->{chart_id}"\E)/$1 selected/;
   }

  print qq|
<html>
<head><title>Retenciones</title></head>
<body>
<table width=100%>
<tr><td>Rentenciones</td></tr></table>
<tr><table>
	<tr><th>Proveedor</th><td>vendor name</td>
	<tr><th>Date</th><td>$form->{transdate}</td></tr>
	<tr><th>Retenc. Nbr.</th><td>$form->{retnumber}</td></tr>
	<tr><th>Autoriz. Nbr.</th><td>$form->{ordnumber}</td></tr>
	<tr><th>Total Retenido</th><td>$form->{totalret}</td></tr>
</tr></table>|;

print qq|<tr><table width=100%>
<tr class=listheading>
<th>Tipo Retencion</th>
<th>Base 0</th>
<th>Base <> 0</th>
<th>Base no Iva</th>
<th>% Retencion</th>
<th>Valor Reten</th>
<th>Cuenta</th>
</tr>|;
for $i (1 .. $form->{rowcount} - 1){
   my ($tiporet) = split(/--/, $form->{"tiporet_$i"});
   my ($cuenta) = split(/--/, $form->{"cuenta_$i"});
   $base0 = "$base0_$i";
   print qq|
<tr>
<td>$tiporet</td>
<td>$form->{"base0_$i"}</td>
<td>$form->{"based0_$i"}</td>
<td>$form->{"baseni_$i"}</td>
<td>$form->{"porcret_$i"}</td>
<td>$form->{"valret_$i"}</td>
<td>$cuenta</td>
</tr>
|;
}
print qq|</table>
</tr><tr>
<table width=100%>
<tr class=listheading>
<th>Invoice</th>
<th>Invoice Date</th>
<th>Due Date</th>
<th>Amount</th>
<th>Due</th>
<th>Adjusted</th>
</tr>|;

for $i (1 .. $form->{rowcount2}){
   if ($form->{"adjusted_$i"}){ 
	print qq|<tr>|;
	print qq|<td>$form->{"invnumber_$i"}</td>\n|;
	print qq|<td>$form->{"transdate_$i"}</td>\n|;
	print qq|<td>$form->{"duedate_$i"}</td>\n|;
	print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{"netamount_$i"}, 2) . qq|</td>\n|;
	print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{"dueamount_$i"}, 2) . qq|</td>\n|;
	print qq|<td align=right>| . $form->format_amount(\%myconfig, $form->{"adjusted_$i"}, 2) . qq|</td>\n|;
	print qq|</tr>\n|;
   }
}

print qq|
</body>
</html>
|;

}

#######
## EOF
#######
