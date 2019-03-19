
require "$form->{path}/lib.pl";
require "$form->{path}/mylib.pl";

1;

#===============================
sub continue { &{$form->{nextsub}} };

#===================================
#
# Sale Qty Summary Report
#
#===================================
#-----------------------------------
sub aa_qty_search {
  $form->get_partsgroup(\%myconfig, { searchitems => 'parts'});
  $form->all_years(\%myconfig);

  if (@{ $form->{all_partsgroup} }) {
    $partsgroup = qq|<option>\n|;

    for (@{ $form->{all_partsgroup} }) { $partsgroup .= qq|<option value="|.$form->quote($_->{partsgroup}).qq|--$_->{id}">$_->{partsgroup}\n| }

    $partsgroup = qq| 
        <th align=right nowrap>|.$locale->text('Group').qq|</th>
	<td><select name=partsgroup>$partsgroup</select></td>
|;

    $l_partsgroup = qq|<input name=l_partsgroup class=checkbox type=checkbox value=Y> |.$locale->text('Group');
  }

  if (@{ $form->{all_years} }) {
    $selectfrom = qq|
        <tr>
 	  <th align=right>|.$locale->text('Include Months').qq|</th>
	  <td colspan=3>
	    <table>
	      <tr>
		<td>
		  <table>
		    <tr>
|;

    for (sort keys %{ $form->{all_month} }) {
      $i = ($_ * 1) - 1;
      if (($i % 3) == 0) {
	$selectfrom .= qq|
		    </tr>
		    <tr>
|;
      }

      $i = $_ * 1;
	
      $selectfrom .= qq|
		      <td nowrap><input name="l_month_$i" class checkbox type=checkbox value=Y checked>&nbsp;|.$locale->text($form->{all_month}{$_}).qq|</td>\n|;
    }
		
    $selectfrom .= qq|
		    </tr>
		  </table>
		</td>
	      </tr>
	    </table>
	  </td>
        </tr>
|;
  } else {
    $form->error($locale->text('No History!'));
  }


   if ($form->{vc} eq 'customer'){
	$form->{title} = $locale->text('Sale Qty Summary');
   } else {
   	$form->{title} = $locale->text('Purchase Qty Summary');
   }
   &print_title;
   &start_form;
   &start_table;

   &print_text('partnumber', 'Number', 20);
   &print_text('name', 'Name', 30);
   &print_date('fromdate', 'From');
   &print_date('todate', 'To');

   print qq|<tr>$partsgroup</tr>|;
   print $selectfrom;
  
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '<br>');
   &print_checkbox('l_category', $locale->text('Category'), 'checked', '<br>');
   &print_checkbox('l_description', $locale->text('Description'), 'checked', '<br>');
   &print_checkbox('l_onhand', $locale->text('Onhand'), 'checked', '<br>');
   &print_checkbox('l_lastcost', $locale->text('Last Cost'), 'checked', '<br>');
   &print_checkbox('l_extended', $locale->text('Extended'), 'checked', '<br>');
   #&print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '<br>');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');
   &print_checkbox('l_allitems', $locale->text('All'), '', '<br>');
   #&print_checkbox('l_sql', $locale->text('SQL'), '');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'aa_qty_list';
   &print_hidden('nextsub');
   &print_hidden('vc');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub aa_qty_list {
  # callback to report list
   my $callback = qq|$form->{script}?action=aa_qty_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('partsgroup,warehouse');
   $form->{partsgroup_id} *= 1;

   my $aa = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
   my $AA = ($form->{vc} eq 'customer') ? 'AR' : 'AP';
   my $sign = ($form->{vc} eq 'customer') ? 1 : -1;

   $partnumber = $form->like(lc $form->{partnumber});
   $name = $form->like(lc $form->{name});
   $description = $form->like(lc $form->{description});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (aa.transdate >= '$form->{fromdate}')| if $form->{fromdate};
   $where .= qq| AND (aa.transdate <= '$form->{todate}')| if $form->{todate};
   $where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
   $where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   $where .= qq| AND (LOWER(p.description) LIKE '$description')| if $form->{description};
   $where .= qq| AND (LOWER(cv.name) LIKE '$name')| if $form->{name};

   @columns = qw(partnumber category description);
   splice @columns, 0, 0, 'no'; # No. columns should always come first
   # Select columns selected for report display
   foreach $item (@columns) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }

   my $months_count = 0;
   for (1 .. 12) {
     if ($form->{"l_month_$_"}) {
       $callback .= qq|&l_month_$_=$form->{"l_month_$_"}|;
       push @column_index, $_;
       $month{$_} = 1;
       $months_count++;
     }
   }

   @columns2 = qw(onhand lastcost extended);
   foreach $item (@columns2) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }
   push @columns, @columns2;

   # if this is first time we are running this report.
   $form->{sort} = "partnumber" if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	
			partnumber => 1,
			category => 2,
			description => 3,
			onhand => $months_count + 4,
			lastcost => $months_count + 5,
			extended => $months_count + 6
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

   $callback .= "&l_subtotal=$form->{l_subtotal}";
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   $query = qq|SELECT
		p.id,
		p.partnumber,
		substring(p.partnumber from 5) as category,
		p.description,
		p.onhand,
		p.lastcost,
		p.onhand * p.lastcost AS extended,
		EXTRACT (MONTH FROM aa.transdate) AS month,
		SUM(i.qty) AS qty

		FROM invoice i
		JOIN $aa aa ON (aa.id = i.trans_id)
		JOIN customer cv ON (cv.id = aa.customer_id)
		JOIN parts p ON (p.id = i.parts_id)

		WHERE $where
		GROUP BY 1,2,3,4,5,6,7,8
		ORDER BY $form->{sort} $form->{direction}|;
		#ORDER BY $sort_order|;

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   my %parts;
   if ($form->{l_allitems}){
      my $allitemsquery = qq|
	SELECT 
	  p.id,
	  p.partnumber,
	  substring(p.partnumber from 5) as category,
	  p.description,
	  p.onhand,
	  p.lastcost,
	  p.onhand * p.lastcost AS extended
	FROM parts p
	ORDER BY 1|;
      my $allitemssth = $dbh->prepare($allitemsquery);
      $allitemssth->execute;
      while (my $ref = $allitemssth->fetchrow_hashref(NAME_lc)){
	$parts{$ref->{id}} = $ref;
      }
   }
   while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
     if (exists $parts{$ref->{id}}) {
       $parts{$ref->{id}}->{$ref->{month}} = $ref->{qty};
       $parts{$ref->{id}}->{qty} += $ref->{qty};
     } else {
       $ref->{$ref->{month}} = $ref->{qty};
       $parts{$ref->{id}} = $ref;
     }
   }
   $sth->finish;

   if ($form->{sort} =~ /(onhand|lastcost|extended)/){
     # sort numberically
     if ($form->{direction} eq 'ASC'){
        for (sort { $parts{$a}->{$form->{sort}} <=> $parts{$b}->{$form->{sort}} } keys %parts) {
           push @{ $form->{parts} }, $parts{$_};
        }
     } else {
        for (sort { $parts{$b}->{$form->{sort}} <=> $parts{$a}->{$form->{sort}} } keys %parts) {
           push @{ $form->{parts} }, $parts{$_};
        }
     }
   } else {
     # sort alphabetically
     for (sort { $parts{$a}->{$form->{sort}} cmp $parts{$b}->{$form->{sort}} } keys %parts) {
        push @{ $form->{parts} }, $parts{$_};
     }
   }
   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{partnumber} 		= rpt_hdr('partnumber', $locale->text('Number'), $href);
   $column_header{category} 		= rpt_hdr('category', $locale->text('Category'), $href);
   $column_header{description} 		= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{onhand} 		= rpt_hdr('onhand', $locale->text('Onhand'), $href);
   $column_header{lastcost} 		= rpt_hdr('lastcost', $locale->text('Last Cost'), $href);
   $column_header{extended} 		= rpt_hdr('extended', $locale->text('Extended'), $href);

   $form->all_years(\%myconfig);
   for (1 .. 12) { $column_header{$_} = qq|<th class=listheading nowrap>|.$locale->text($locale->{SHORT_MONTH}[$_-1]).qq|</th>| }

   if ($form->{l_csv} eq 'Y'){
	&ref_to_csv('parts', "qty_summary", \@column_index);
	exit;
   }

   if ($form->{vc} eq 'customer'){
	$form->{title} = $locale->text('Sale Qty Summary');
   } else {
   	$form->{title} = $locale->text('Purchase Qty Summary');
   }
   &print_title;

   # Print report criteria
   &print_criteria('partnumber', 'Number');
   &print_criteria('name', 'Name');
   &print_criteria('description', 'Description');
   &print_criteria('fromdate', 'From Date');
   &print_criteria('todate', 'To');
   &print_criteria('partsgroup_name', 'Group');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $balance_subtotal = 0;
   my $onhand_total = 0;
   my %extended_total = 0;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';

   foreach $ref (@{ $form->{parts} }) {
   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	$groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
	if ($form->{l_subtotal}){
	   if ($groupbreak ne $ref->{$form->{sort}}){
		$groupbreak = $ref->{$form->{sort}};
		# prepare data for footer

   		$column_data{no}   			= rpt_txt('&nbsp;');
   		$column_data{partnumber}  		= rpt_txt('&nbsp;');
   		$column_data{description}  		= rpt_txt('&nbsp;');
   		$column_data{jan} 			= rpt_dec('&nbsp;');

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$balance_subtotal = 0;
	   }
	}

	$column_data{no}   		= rpt_txt($no);
   	$column_data{partnumber}	= rpt_txt($ref->{partnumber});
   	$column_data{category}		= rpt_txt($ref->{category});
   	$column_data{description}	= rpt_txt($ref->{description}, $form->{link});
   	$column_data{onhand}		= rpt_dec($ref->{onhand},0);
   	$column_data{lastcost}		= rpt_dec($ref->{lastcost},2);
   	$column_data{extended}		= rpt_dec($ref->{extended},2);

	for (1 .. 12){
	    $column_data{$_} = rpt_dec($ref->{$_},0);
	    $total{$_} += $ref->{$_};
        }

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$onhand_total += $ref->{onhand};
	$extended_total += $ref->{extended};
   }

   # prepare data for footer
   $column_data{no}   			= rpt_txt('&nbsp;');
   $column_data{partnumber}  		= rpt_txt('&nbsp;');
   $column_data{category}  		= rpt_txt('&nbsp;');
   $column_data{description}   		= rpt_txt('&nbsp;');
   $column_data{lastcost}   		= rpt_txt('&nbsp;');

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   for (1 .. 12){
      $column_data{$_} = rpt_dec($total{$_},0);
      $total{$_} += $ref->{$_};
   }

   $column_data{onhand}   		= rpt_dec($onhand_total,0);
   $column_data{extended}   		= rpt_dec($extended_total,2);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}


#===================================
#
# Customer / Vendor Balances Report
#
#==================================
#-------------------------------
sub vc_search {
   if ($form->{vc} eq 'customer'){
	$form->{title} = $locale->text('Customer Balances');
   } else {
   	$form->{title} = $locale->text('Vendor Balances');
   }
   &print_title;


   &start_form;
   &start_table;

   &print_text('name', 'Name', 30);
   &print_date('todate', 'Upto Date');
   

   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox("l_$form->{vc}number", $locale->text('Number'), 'checked', '<br>');
   &print_checkbox('l_name', $locale->text('Name'), 'checked', '<br>');
   &print_checkbox('l_balance', $locale->text('Balance'), 'checked', '<br>');
   #&print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '<br>');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');
   &print_checkbox('l_sql', $locale->text('SQL'), '');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'vc_list';
   &print_hidden('nextsub');
   &print_hidden('vc');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub vc_list {
  # callback to report list
   my $callback = qq|$form->{script}?action=vc_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   #&split_combos('department,from_warehouse,to_warehouse,expense_accno');
   #$form->{department_id} *= 1;
   my $aa = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
   my $AA = ($form->{vc} eq 'customer') ? 'AR' : 'AP';
   my $sign = ($form->{vc} eq 'customer') ? 1 : -1;

   $vcnumber = $form->like(lc $form->{"$form->{vc}number"});
   $name = $form->like(lc $form->{name});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (ac.transdate <= '$form->{todate}')| if $form->{todate};
   $where .= qq| AND (LOWER("$form->{vc}number") LIKE '$vcnumber')| if $form->{"$form->{vc}number"};
   $where .= qq| AND (LOWER(name) LIKE '$name')| if $form->{name};
   $where .= qq| AND (c.link = '$AA')|;

   @columns = ("id", "$form->{vc}number", "name", "balance");
   # if this is first time we are running this report.
   $form->{sort} = "$form->{vc}number" if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	id => 1,
			"$form->{vc}number" => 2,
			name => 3,
			balance => 4
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

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
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   $query = qq|SELECT 
		ct.id, 
		ct.$form->{vc}number, 
		ct.name, 
		(SUM(0 - ac.amount) * $sign) AS balance

		FROM $form->{vc} ct
		JOIN $aa aa ON (ct.id = aa.$form->{vc}_id)
		JOIN acc_trans ac ON (aa.id = ac.trans_id)
		JOIN chart c ON (c.id = ac.chart_id)

		WHERE $where
		GROUP BY 1,2,3
		ORDER BY $form->{sort} $form->{direction}|;
		#ORDER BY $sort_order|;

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{"$form->{vc}number"} 	= rpt_hdr("$form->{vc}number", $locale->text('Number'), $href);
   $column_header{name}    		= rpt_hdr('name', $locale->text('Name'), $href);
   $column_header{balance}  		= rpt_hdr('balance', $locale->text('Balance'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, "$form->{vc}_balances");
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);


   if ($form->{vc} eq 'customer'){
   	$form->{title} = $locale->text('Customer Balances');
   } else {
   	$form->{title} = $locale->text('Vendor Balances');
   }
   &print_title;

   # Print report criteria
   &print_criteria('name', 'Name');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $balance_subtotal = 0;
   my $balance_total = 0;

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

   		$column_data{no}   			= rpt_txt('&nbsp;');
   		$column_data{"$form->{vc}number"}  	= rpt_txt('&nbsp;');
   		$column_data{name}    			= rpt_txt('&nbsp;');
   		$column_data{balance} 			= rpt_dec('&nbsp;');

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$balance_subtotal = 0;
	   }
	}

	$column_data{no}   			= rpt_txt($no);
   	$column_data{"$form->{vc}number"}	= rpt_txt($ref->{"$form->{vc}number"});
   	$column_data{name} 			= rpt_txt($ref->{name}, $form->{link});
   	$column_data{balance}    		= rpt_dec($ref->{balance});

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$balance_subtotal += $ref->{balance};
	$balance_total += $ref->{balance};
   }

   # prepare data for footer
   $column_data{no}   			= rpt_txt('&nbsp;');
   $column_data{"$form->{vc}number"}  	= rpt_txt('&nbsp;');
   $column_data{name}    		= rpt_txt('&nbsp;');
   $column_data{balance} 		= rpt_txt('&nbsp;');

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{balance} = rpt_dec($balance_total);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}



#===================================
#
# Customer / Vendor Activity Report
#
#==================================
#-------------------------------
sub vcactivity_search {
   if ($form->{vc} eq 'customer'){
	$form->{title} = $locale->text('Customer Activity');
   } else {
   	$form->{title} = $locale->text('Vendor Activity');
   }
   &print_title;
   &start_form;
   &start_table;

   &print_text("$form->{vc}number", 'Number', 10);
   &print_text('name', 'Name', 30);
   &print_date('todate', 'Upto Date');
   
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox("l_$form->{vc}number", $locale->text('Number'), 'checked', '<br>');
   &print_checkbox('l_name', $locale->text('Name'), 'checked', '<br>');
   &print_checkbox('l_transdate', $locale->text('Date'), 'checked', '<br>');
   &print_checkbox('l_invnumber', $locale->text('Invoice Number'), 'checked', '<br>');
   &print_checkbox('l_description', $locale->text('Description'), 'checked', '<br>');
   &print_checkbox('l_debit', $locale->text('Debit'), 'checked', '<br>');
   &print_checkbox('l_credit', $locale->text('Credit'), 'checked', '<br>');
   &print_checkbox('l_balance', $locale->text('Balance'), 'checked', '<br>');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '<br>');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');
   &print_checkbox('l_sql', $locale->text('SQL'), '');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'vcactivity_list';
   &print_hidden('nextsub');
   &print_hidden('vc');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub vcactivity_list {
  # callback to report list
   my $callback = qq|$form->{script}?action=vc_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   #&split_combos('department,from_warehouse,to_warehouse,expense_accno');
   #$form->{department_id} *= 1;
   my $aa = ($form->{vc} eq 'customer') ? 'ar' : 'ap';
   my $AA = ($form->{vc} eq 'customer') ? 'AR' : 'AP';
   my $sign = ($form->{vc} eq 'customer') ? 1 : -1;

   $vcnumber = $form->like(lc $form->{"$form->{vc}number"});
   $name = $form->like(lc $form->{name});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (ac.transdate <= '$form->{todate}')| if $form->{todate};
   $where .= qq| AND (LOWER("$form->{vc}number") LIKE '$vcnumber')| if $form->{"$form->{vc}number"};
   $where .= qq| AND (LOWER(name) LIKE '$name')| if $form->{name};
   $where .= qq| AND (c.link = '$AA')|;

   @columns = ("id", "$form->{vc}number", "name", "transdate", "invnumber", "description", "debit", "credit", "balance");
   # if this is first time we are running this report.
   $form->{sort} = "$form->{vc}number" if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	id => 1,
			"$form->{vc}number" => 2,
			name => 3,
			transdate => 4,
			invnumber => 5,
			description => 6,
			debit => 7,
			credit => 8,
			balance => 9
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

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
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   $query = qq|SELECT 
		ct.$form->{vc}number, 
		ct.name, 
		ac.transdate,
		aa.invnumber,
		aa.description,
		CASE WHEN ac.amount * $sign < 0 THEN  0 - ac.amount ELSE 0 END AS debit,
		CASE WHEN ac.amount * $sign > 0 THEN  ac.amount ELSE 0 END AS credit

		FROM $aa aa
		JOIN $form->{vc} ct ON (ct.id = aa.$form->{vc}_id)
		JOIN acc_trans ac ON (aa.id = ac.trans_id)
		JOIN chart c ON (c.id = ac.chart_id)

		WHERE $where
		ORDER BY $form->{sort} $form->{direction}|;
		#ORDER BY $sort_order|;

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{"$form->{vc}number"} 	= rpt_hdr("$form->{vc}number", $locale->text('Number'), $href);
   $column_header{name}    		= rpt_hdr('name', $locale->text('Name'), $href);
   $column_header{transdate}    	= rpt_hdr('transdate', $locale->text('Date'), $href);
   $column_header{invnumber}    	= rpt_hdr('invnumber', $locale->text('Invoice Number'), $href);
   $column_header{description}    	= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{debit}  		= rpt_hdr('debit', $locale->text('Debit'), $href);
   $column_header{credit}  		= rpt_hdr('credit', $locale->text('Credit'), $href);
   $column_header{balance}  		= rpt_hdr('balance', $locale->text('Balance'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, "$form->{vc}_activity");
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   if ($form->{vc} eq 'customer'){
   	$form->{title} = $locale->text('Customer Activity');
   } else {
   	$form->{title} = $locale->text('Vendor Activity');
   }
   &print_title;

   # Print report criteria
   &print_criteria('name', 'Name');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $debit_subtotal = 0;
   my $credit_subtotal = 0;

   my $debit_total = 0;
   my $credit_total = 0;

   my $balance_subtotal = 0;
   my $balance_total = 0;

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

   		$column_data{no}   			= rpt_txt('&nbsp;');
   		$column_data{"$form->{vc}number"}  	= rpt_txt('&nbsp;');
   		$column_data{name}    			= rpt_txt('&nbsp;');
   		$column_data{transdate}  		= rpt_txt('&nbsp;');
   		$column_data{invnumber} 		= rpt_txt('&nbsp;');
   		$column_data{description} 		= rpt_txt('&nbsp;');
   		$column_data{debit} 			= rpt_dec($debit_subtotal);
   		$column_data{credit} 			= rpt_dec($credit_subtotal);
   		$column_data{balance} 			= rpt_dec('&nbsp;');

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$debit_subtotal = 0;
		$credit_subtotal = 0;
		$balance_subtotal = 0;
	   }
	}

	$column_data{no}   			= rpt_txt($no);
   	$column_data{"$form->{vc}number"}	= rpt_txt($ref->{"$form->{vc}number"});
   	$column_data{name} 			= rpt_txt($ref->{name});
   	$column_data{transdate} 		= rpt_txt($ref->{transdate});
   	$column_data{invnumber} 		= rpt_txt($ref->{invnumber}, $form->{link});
   	$column_data{description} 		= rpt_txt($ref->{description});
   	$column_data{debit}  	  		= rpt_dec($ref->{debit});
   	$column_data{credit}    		= rpt_dec($ref->{credit});
   	$column_data{balance} 			= rpt_txt('&nbsp;');

	$debit_subtotal += $ref->{debit};
	$credit_subtotal += $ref->{credit};
	$balance_subtotal += $ref->{debit} - $ref->{credit};

	$debit_total += $ref->{debit};
	$credit_total += $ref->{credit};
	$balance_total += $ref->{debit} - $ref->{credit};

   	$column_data{balance}    		= rpt_dec($balance_subtotal);

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;
   }

   # prepare data for footer
   $column_data{no}   			= rpt_txt('&nbsp;');
   $column_data{"$form->{vc}number"}  	= rpt_txt('&nbsp;');
   $column_data{name}    		= rpt_txt('&nbsp;');
   $column_data{transdate}  		= rpt_txt('&nbsp;');
   $column_data{invnumber} 		= rpt_txt('&nbsp;');
   $column_data{description} 		= rpt_txt('&nbsp;');
   $column_data{debit} 			= rpt_dec($debit_subtotal);
   $column_data{credit} 		= rpt_dec($credit_subtotal);
   $column_data{balance} 		= rpt_dec('&nbsp;');

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{debit} 			= rpt_dec($debit_total);
   $column_data{credit} 		= rpt_dec($credit_total);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}




#===================================
#
# Inventory Onhand by Warehouse
#
#==================================
#-------------------------------
sub onhand_search {
   $form->{title} = $locale->text('Inventroy Onhand');
   &print_title;

   &start_form;
   &start_table;

   &bld_department;
   &bld_warehouse;
   &bld_partsgroup;

   &print_date('dateto', 'To');
   &print_text('partnumber', 'Number', 30);
   &print_select('partsgroup', 'Group');
   &print_select('department', 'Department');
   &print_select('warehouse', 'Warehouse');
 
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_radio;
   &print_checkbox('l_no', $locale->text('No.'), '', '');
   &print_checkbox('l_warehouse', $locale->text('Warehouse'), 'checked', '');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '');
   &print_checkbox('l_description', $locale->text('Description'), 'checked', '');
   &print_checkbox('l_partsgroup', $locale->text('Group'), 'checked', '');
   &print_checkbox('l_unit', $locale->text('Unit'), 'checked', '');
   &print_checkbox('l_onhand', $locale->text('Onhand'), 'checked', '<br>');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '');
   #&print_checkbox('l_sql', $locale->text('SQL'), '');
   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'onhand_list';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub onhand_list {
  # callback to report list
   my $callback = qq|$form->{script}?action=onhand_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('department,warehouse,partsgroup');
   $form->{department_id} *= 1;
   $form->{warehouse_id} *= 1;
   $form->{partsgroup_id} *= 1;
   $partnumber = $form->like(lc $form->{partnumber});
   $description = $form->like(lc $form->{description});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   $where .= qq| AND (LOWER(p.description) LIKE '$name')| if $form->{description};
   $where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
   $where .= qq| AND (i.department_id = $form->{department_id})| if $form->{department};
   $where .= qq| AND (i.warehouse_id = $form->{warehouse_id})| if $form->{warehouse};
   $where .= qq| AND (i.shippingdate <= '$form->{dateto}')| if $form->{dateto};

   @columns = qw(id warehouse partnumber description partsgroup unit onhand);
   # if this is first time we are running this report.
   $form->{sort} = 'partnumber' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	id => 1,
			warehouse => 2,
			partnumber => 3,
			description => 4,
			partsgroup => 5,
			unit => 6,
			onhand => 7
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

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
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   if ($form->{summary}){
   	$query = qq|SELECT 
			p.id, 
			p.partnumber, 
			p.description, 
			pg.partsgroup,
			p.unit, 
			SUM(i.qty) AS onhand
			FROM inventory i
			JOIN parts p ON (p.id = i.parts_id)
			JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
			WHERE $where
			GROUP BY 1, 2, 3, 4, 5
			ORDER BY $form->{sort} $form->{direction}|;
   } else {
   	$query = qq|SELECT 
			p.id, 
			w.description AS warehouse,
			p.partnumber, 
			p.description, 
			pg.partsgroup,
			p.unit, 
			SUM(i.qty) AS onhand
			FROM inventory i
			JOIN parts p ON (p.id = i.parts_id)
			JOIN warehouse w ON (w.id = i.warehouse_id)
			JOIN partsgroup pg ON (pg.id = p.partsgroup_id)
			WHERE $where
			GROUP BY 1, 2, 3, 4, 5, 6
			ORDER BY $form->{sort} $form->{direction}|;

   }
   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{warehouse} 		= rpt_hdr('warehouse', $locale->text('Warehouse'), $href);
   $column_header{partnumber} 		= rpt_hdr('partnumber', $locale->text('Number'), $href);
   $column_header{description} 		= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{partsgroup}  		= rpt_hdr('partsgroup', $locale->text('Group'), $href);
   $column_header{unit}  		= rpt_hdr('unit', $locale->text('Unit'), $href);
   $column_header{onhand}  		= rpt_hdr('onhand', $locale->text('Onhand'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'parts_onhand');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Inventory Onhand');
   &print_title;
   &print_criteria('partnumber','Number');
   &print_criteria('warehouse_name', 'Warehouse');
   &print_criteria('department_name', 'Department');
   &print_criteria('dateto', 'To');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $amount_subtotal = 0;
   my $amount_total = 0;

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
   		$column_data{warehouse}  	= rpt_txt('&nbsp;');
   		$column_data{partnumber}  	= rpt_txt('&nbsp;');
   		$column_data{description} 	= rpt_txt('&nbsp;');
   		$column_data{partsgroup} 	= rpt_txt('&nbsp;');
   		$column_data{unit} 		= rpt_txt('&nbsp;');
   		$column_data{onhand} 		= rpt_txt('&nbsp;');

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$amount_subtotal = 0;
	   }
	}

	$column_data{no}   		= rpt_txt($no);
   	$column_data{warehouse}		= rpt_txt($ref->{warehouse});
   	$column_data{partnumber}	= rpt_txt($ref->{partnumber});
   	$column_data{description} 	= rpt_txt($ref->{description}, $form->{link});
   	$column_data{partsgroup}    	= rpt_txt($ref->{partsgroup});
   	$column_data{unit}    		= rpt_txt($ref->{unit});
   	$column_data{onhand}    	= rpt_dec($ref->{onhand});

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$amount_subtotal += $ref->{amount};
	$amount_total += $ref->{amount};
   }

   # prepare data for footer
   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{warehouse}  	= rpt_txt('&nbsp;');
   $column_data{partnumber}  	= rpt_txt('&nbsp;');
   $column_data{description} 	= rpt_txt('&nbsp;');
   $column_data{partsgroup} 	= rpt_txt('&nbsp;');
   $column_data{unit} 		= rpt_txt('&nbsp;');
   $column_data{onhand} 	= rpt_txt('&nbsp;');


   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{amount} = rpt_dec($amount_total);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}

#===================================
#
# Inventory Activity
#
#==================================
#-------------------------------
sub iactivity_search {

   $form->{title} = $locale->text('Inventory Activity'); 
   &print_title;
   
   &start_form;
   &start_table;

   &bld_department('selectdepartment', 1);
   &bld_warehouse;
   &bld_partsgroup;

   &print_text('partnumber', 'Number', 30);
   &print_date('datefrom', 'From');
   &print_date('dateto', 'To');
   &print_select('partsgroup', 'Group');
   &print_select('department', 'Department');
   &print_select('warehouse', 'Warehouse');
  
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox('l_shippingdate', $locale->text('Date'), 'checked', '');
   &print_checkbox('l_reference', $locale->text('Reference'), 'checked', '');
   &print_checkbox('l_department', $locale->text('Department'), '', '');
   &print_checkbox('l_warehouse', $locale->text('Warehouse'), 'checked', '');
   &print_checkbox('l_warehouse2', $locale->text('Warehouse2'), 'checked', '<br>');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '');
   &print_checkbox('l_description', $locale->text('Description'), '', '');
   &print_checkbox('l_unit', $locale->text('Unit'), 'checked', '');
   &print_checkbox('l_in', $locale->text('In'), 'checked', '');
   &print_checkbox('l_out', $locale->text('Out'), 'checked', '');
   &print_checkbox('l_onhand', $locale->text('Onhand'), 'checked', '<br>');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), 'checked', '');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '');
   #&print_checkbox('l_sql', $locale->text('SQL'), '', '<br>');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'iactivity_list';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub iactivity_list {
   # callback to report list
   my $callback = qq|$form->{script}?action=iactivity_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('department,warehouse,partsgroup');
   $form->{department_id} *= 1;
   $form->{warehouse_id} *= 1;
   $form->{partsgroup_id} *= 1;
   $partnumber = $form->like(lc $form->{partnumber});
   $description = $form->like(lc $form->{description});
   
   my $where = qq| (1 = 1)|;
   my $openingwhere;

   $where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   $where .= qq| AND (LOWER(p.description) LIKE '$name')| if $form->{description};
   $where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
   $where .= qq| AND (i.shippingdate >= '$form->{datefrom}')| if $form->{datefrom};
   $openingwhere .= qq| AND (shippingdate < '$form->{datefrom}')| if $form->{datefrom};
   $where .= qq| AND (i.shippingdate <= '$form->{dateto}')| if $form->{dateto};
   if ($form->{department_id}){
      $where .= qq| AND (i.department_id = $form->{department_id})|;
      $openingwhere .= qq| AND (department_id = $form->{department_id})|;
      $form->{l_department} = '';
   }
   if ($form->{warehouse_id}){
      $where .= qq| AND (i.warehouse_id = $form->{warehouse_id})|;
      $openingwhere .= qq| AND (warehouse_id = $form->{warehouse_id})|;
      $form->{l_warehouse} = '';
   }


   @columns = qw(partnumber description id shippingdate reference department warehouse warehouse2 in out onhand);
   # if this is first time we are running this report.
   $form->{sort} = 'partnumber' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (
			partnumber => 1,
			description => 2,
			shippingdate => 3,
			reference => 4,
			department => 5,
			warehouse => 6,
			warehouse2 => 7,
			in => 8,
			out => 9,
			onhand => 10
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

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
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   $query = qq/SELECT
		i.parts_id,
		p.partnumber, 
		p.description, 
		i.trans_id, 
		i.shippingdate,
		i.qty,
		d.description AS department,
		w.description AS warehouse, 
		w2.description AS warehouse2,
		trf.trfnumber AS reference,
		ap.invnumber AS ap_reference,
		ar.invnumber AS ar_reference
	      FROM inventory i
		JOIN parts p ON (p.id = i.parts_id)
		LEFT JOIN department d ON (i.department_id = d.id)
		JOIN warehouse w ON (i.warehouse_id = w.id)
		LEFT JOIN warehouse w2 ON (i.warehouse_id2 = w2.id)
		LEFT JOIN trf ON (i.trans_id = trf.id)
		LEFT JOIN ap ON (i.trans_id = ap.id)
		LEFT JOIN ar ON (i.trans_id = ar.id)
		WHERE $where
		ORDER BY p.partnumber, i.shippingdate/;
		#ORDER BY $form->{sort} $form->{direction}|;

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{shippingdate} 	= rpt_hdr('shippingdate', $locale->text('Date'), $href);
   $column_header{reference} 		= rpt_hdr('reference', $locale->text('Reference'), $href);
   $column_header{department} 		= rpt_hdr('department', $locale->text('Department'), $href);
   $column_header{warehouse} 		= rpt_hdr('warehouse', $locale->text('Warehouse'), $href);
   $column_header{warehouse2} 		= rpt_hdr('warehouse2', $locale->text('Warehouse2'), $href);
   $column_header{partnumber} 		= rpt_hdr('partnumber', $locale->text('Number'), $href);
   $column_header{description} 		= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{in}  			= rpt_hdr('in', $locale->text('In'), $href);
   $column_header{out}  		= rpt_hdr('out', $locale->text('Out'), $href);
   $column_header{onhand}  		= rpt_hdr('onhand', $locale->text('Onhand'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'inventory_activity');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Inventory Activity');
   &print_title;
   &print_criteria('partnumber','Number');
   &print_criteria('warehouse_name', 'Warehouse');
   &print_criteria('department_name', 'Department');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $in_subtotal = 0;
   my $in_total = 0;
   my $out_subtotal = 0;
   my $out_total = 0;
   my $onhand = 0;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	#$groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
	#$groupbreak = $ref->{partnumber} if $groupbreak eq 'none';
	if ($form->{l_subtotal}){
	   #if ($groupbreak ne $ref->{$form->{sort}}){
	   if ($groupbreak ne $ref->{partnumber}){
		#$groupbreak = $ref->{$form->{sort}};
		$groupbreak = $ref->{partnumber};

		# prepare data for footer
   		$column_data{no}   		= rpt_txt('&nbsp;');
   		$column_data{shippingdate} 	= rpt_txt('&nbsp;');
   		$column_data{reference} 	= rpt_txt('&nbsp;');
   		$column_data{department} 	= rpt_txt('&nbsp;');
   		$column_data{warehouse} 	= rpt_txt('&nbsp;');
   		$column_data{warehouse2} 	= rpt_txt('&nbsp;');
   		$column_data{partnumber}  	= rpt_txt('&nbsp;');
   		$column_data{description} 	= rpt_txt('&nbsp;');
   		$column_data{unit} 		= rpt_txt('&nbsp;');
   		$column_data{in} 		= rpt_dec($in_subtotal);
   		$column_data{out} 		= rpt_dec($out_subtotal);
   		$column_data{onhand} 		= rpt_txt('&nbsp;');

	        $in_subtotal = 0;
		$out_subtotal = 0;
		$onhand = 0;

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";
		if ($form->{datefrom}){
   		   my $openingquery = qq|
			SELECT SUM(qty) 
			FROM inventory 
			WHERE parts_id = $ref->{parts_id}
			$openingwhere
		   |;
		   my $openingqty = $dbh->selectrow_array($openingquery);
		   if ($openingqty != 0){
		      $onhand = $openingqty;
   		      $column_data{in} 		= rpt_dec($in_subtotal);
   		      $column_data{out} 	= rpt_dec($out_subtotal);
   		      $column_data{onhand} 	= rpt_dec($onhand);

		      # print footer
		      print "<tr valign=top class=listrow0>";
		      for (@column_index) { print "\n$column_data{$_}" }
		      print "</tr>";
		   }
		}
	   }
	}
	$in  = ($ref->{qty} > 0) ? $ref->{qty} : 0;
	$out = ($ref->{qty} < 0) ? 0 - $ref->{qty} : 0;

	$in_subtotal += $in;
	$in_total += $in;
	$out_subtotal += $out;
	$out_total += $out;
        $onhand += ($in - $out);

	$column_data{no}   		= rpt_txt($no);
   	$column_data{shippingdate}    	= rpt_txt($ref->{shippingdate});
   	$column_data{reference}    	= rpt_txt($ref->{reference} . $ref->{ap_reference} . $ref->{ar_reference});
   	$column_data{department}    	= rpt_txt($ref->{department});
   	$column_data{warehouse}    	= rpt_txt($ref->{warehouse});
   	$column_data{warehouse2}    	= rpt_txt($ref->{warehouse2});
   	$column_data{partnumber}	= rpt_txt($ref->{partnumber});
   	$column_data{description} 	= rpt_txt($ref->{description});
   	$column_data{unit}    		= rpt_txt($ref->{unit});
   	$column_data{in}    		= rpt_dec($in);
   	$column_data{out}    		= rpt_dec($out);
   	$column_data{onhand}    	= rpt_dec($onhand);

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;
   }

   # prepare data for footer
   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{shippingdate} 	= rpt_txt('&nbsp;');
   $column_data{reference} 	= rpt_txt('&nbsp;');
   $column_data{department} 	= rpt_txt('&nbsp;');
   $column_data{warehouse} 	= rpt_txt('&nbsp;');
   $column_data{warehouse2} 	= rpt_txt('&nbsp;');
   $column_data{partnumber}  	= rpt_txt('&nbsp;');
   $column_data{description} 	= rpt_txt('&nbsp;');
   $column_data{unit} 		= rpt_txt('&nbsp;');
   $column_data{in} 		= rpt_dec($in_subtotal);
   $column_data{out} 		= rpt_dec($out_subtotal);
   $column_data{onhand} 	= rpt_txt('&nbsp;');

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{in} = rpt_dec($in_total);
   $column_data{out} = rpt_dec($out_total);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}

#===================================
#
# Audit Trail Report
#
#==================================
#-------------------------------
sub audit_search {
   $form->{title} = $locale->text('Audit Trail Report');
   &print_title;
   &start_form;
   &start_table;

   &bld_employee;

   &print_text('trans_id', 'Trans ID', 15);
   &print_text('tablename', 'Table', 15);
   &print_text('refernece', 'Refernce', 15);
   &print_text('formname', 'Form', 15);
   &print_text('formaction', 'Action', 15);
   &print_date('fromtransdate', 'From Trans Date');
   &print_date('totransdate', 'To Trans Date');
   &print_select('employee', 'Employee');
 
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox('l_trans_id', $locale->text('Trans ID'), 'checked', '<br>');
   &print_checkbox('l_tablename', $locale->text('Table'), 'checked', '<br>');
   &print_checkbox('l_reference', $locale->text('Reference'), 'checked', '<br>');
   &print_checkbox('l_formname', $locale->text('Form'), 'checked', '<br>');
   &print_checkbox('l_action', $locale->text('Action'), 'checked', '<br>');
   &print_checkbox('l_transdate', $locale->text('Trans Date'), 'checked', '<br>');
   &print_checkbox('l_name', $locale->text('Employee'), 'checked', '<br>');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');
   #&print_checkbox('l_sql', $locale->text('SQL'), '', '<br>');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'audit_list';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub audit_list {
  # callback to report list
   my $callback = qq|$form->{script}?action=audit_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('employee');
   $form->{employee_id} *= 1;
   $tablename = lc $form->{tablename};
   $reference = $form->like(lc $form->{reference});
   $formname = lc $form->{formname};
   $formaction = lc $form->{formaction};
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (a.trans_id = $form->{trans_id})| if $form->{trans_id};
   $where .= qq| AND (a.tablename = '$tablename')| if $form->{tablename};
   $where .= qq| AND (a.LOWER(reference) LIKE '$reference')| if $form->{reference};
   $where .= qq| AND (a.formname = '$formname')| if $form->{formname};
   $where .= qq| AND (a.action = '$formaction')| if $form->{formaction};
   $where .= qq| AND (a.transdate >= '$form->{fromtransdate}')| if $form->{fromtransdate};
   $where .= qq| AND (a.transdate <= '$form->{totransdate}')| if $form->{totransdate};
   $where .= qq| AND (a.employee_id = $form->{employee_id})| if $form->{employee};

   @columns = qw(trans_id tablename reference formname action transdate employee_id);
   # if this is first time we are running this report.
   $form->{sort} = 'tablename' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	trans_id => 1,
			tablename => 2,
			reference => 3,
			formname => 4,
			action => 5,
			transdate => 6,
			name => 7
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

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
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   $query = qq|SELECT 
		a.trans_id, 
		a.tablename, 
		a.reference, 
		a.formname,
		a.action,
		a.transdate,
		e.name
		FROM audittrail a
		LEFT JOIN employee e ON (e.id = a.employee_id)
		WHERE $where
		ORDER BY $form->{sort} $form->{direction}|;
		#ORDER BY $sort_order|;

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{trans_id} 		= rpt_hdr('trans_id', $locale->text('Trans ID'), $href);
   $column_header{tablename} 		= rpt_hdr('tablename', $locale->text('Table'), $href);
   $column_header{reference}  		= rpt_hdr('reference', $locale->text('Reference'), $href);
   $column_header{formname}  		= rpt_hdr('formname', $locale->text('Form'), $href);
   $column_header{action}  		= rpt_hdr('action', $locale->text('Action'), $href);
   $column_header{transdate}  		= rpt_hdr('transdate', $locale->text('Date'), $href);
   $column_header{name}  		= rpt_hdr('name', $locale->text('Employee'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'audit_trail');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Audit Trail');
   &print_title;
   &print_criteria('tablename','Table');
   &print_criteria('reference', 'Reference');
   &print_criteria('formname', 'Form');
   &print_criteria('formaction', 'Action');
   &print_criteria('fromtransdate', 'From');
   &print_criteria('totransdate', 'To');
   &print_criteria('employee_name', 'Employee');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;

	$column_data{no}   		= rpt_txt($no);
   	$column_data{trans_id}		= rpt_txt($ref->{trans_id});
   	$column_data{tablename}		= rpt_txt($ref->{tablename});
   	$column_data{reference} 	= rpt_txt($ref->{reference});
   	$column_data{formname}    	= rpt_txt($ref->{formname});
   	$column_data{action}   		= rpt_txt($ref->{action});
   	$column_data{transdate}    	= rpt_txt($ref->{transdate});
   	$column_data{name}    		= rpt_txt($ref->{name});

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

   }
   print qq|</table>|;

   $sth->finish;
   $dbh->disconnect;
}

#===================================
#
# AR/AP Transactions Report
#
#===================================
#-----------------------------------
sub trans_search {
   $form->{title} = $locale->text("$form->{aa} Transactions");
   &print_title;

   &bld_department;
   &bld_warehouse;
   &bld_partsgroup;
   &bld_employee;

   &start_form;
   &start_table;

   my $table = lc $form->{aa};
   my $db = ($table eq 'ar') ? 'customer' : 'vendor';
   my $employee_caption = ($table eq 'ar') ? 'Salesperson' : 'Employee';

   &print_text("${db}number", (ucfirst $db) . ' Number', 15);
   &print_text('name', 'Name', 30);
   &print_text('invnumber', 'Invoice Number', 15);
   &print_text('description', 'Description', 30);
   &print_text('notes', 'Notes', 30);
   &print_date('fromdate', 'From Date');
   &print_date('todate', 'To Date');

   &print_select('department', 'Department');
   &print_select('warehouse', 'Warehouse');
   &print_select('employee', $employee_caption);

   &print_text('partnumber', 'Number', 15);
   &print_select('partsgroup', 'Group');

   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;
   &print_radio;
   &print_checkbox('invoices', $locale->text('Invoices'), 'checked','');
   &print_checkbox('trans', $locale->text('Transactions'), '', '<br>');
   &print_checkbox('l_no', $locale->text('No.'), '', '');
   &print_checkbox("l_${db}number", $locale->text('Number'), 'checked', '');
   &print_checkbox('l_name', $locale->text('Name'), 'checked', '');
   &print_checkbox('l_invnumber', $locale->text('Invoice Number'), 'checked', '');
   &print_checkbox('l_transdate', $locale->text('Invoice Date'), 'checked', '<br>');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '');
   &print_checkbox('l_description', $locale->text('Description'), 'checked', '');
   &print_checkbox('l_qty', $locale->text('Qty'), 'checked', '');
   &print_checkbox('l_sellprice', $locale->text('Sell Price'), 'checked', '<br>');
   &print_checkbox('l_amount', $locale->text('Amount'), 'checked', '');
   &print_checkbox('l_tax', $locale->text('Tax'), '', '');
   &print_checkbox('l_total', $locale->text('Total'), '', '');
   if ($form->{aa} eq 'AR'){
      &print_checkbox('l_cogs', $locale->text('COGS'), 'checked', '');
#      &print_checkbox('l_markup', $locale->text('Markup %'), 'checked', '');
   }

   &print_checkbox('l_employee', $locale->text($salesperson_caption), 'checked', '<br>');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '');
   &print_checkbox('l_subtotalonly', $locale->text('Subtotal Only'), '', '');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');
   &print_checkbox('l_sql', $locale->text('SQL'), '');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'trans_list';
   &print_hidden('nextsub');
   &print_hidden('aa');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub trans_list {
   # callback to report list
   my $callback = qq|$form->{script}?action=trans_list|;
   for (qw(path login)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('department,warehouse,partsgroup,employee');
   $form->{department_id} *= 1;
   $form->{warehouse_id} *= 1;
   $form->{partsgroup_id} *= 1;
   $form->{employee_id} *= 1;


   my $table = lc $form->{aa};
   my $db = ($table eq 'ar') ? 'customer' : 'vendor';
   my $employee_caption = ($table eq 'ar') ? 'Salesperson' : 'Employee';
   my $sign = ($table eq 'ar') ? 1 : -1;

   $vcnumber = $form->like(lc $form->{"${db}number"});
   $name = $form->like(lc $form->{name});
   $invnumber = $form->like(lc $form->{invnumber});
   $description = $form->like(lc $form->{description});
   $notes = $form->like(lc $form->{notes});
   $partnumber = $form->like(lc $form->{partnumber});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (aa.transdate >= '$form->{fromdate}')| if $form->{fromdate};
   $where .= qq| AND (aa.transdate <= '$form->{todate}')| if $form->{todate};
   $where .= qq| AND (aa.department_id = $form->{department_id})| if $form->{department};
   $where .= qq| AND (aa.warehouse_id = $form->{warehouse_id})| if $form->{warehouse};
   $where .= qq| AND (aa.employee_id = $form->{employee_id})| if $form->{employee};
   $where .= qq| AND (LOWER("ct.${db}number") LIKE '$vcnumber')| if $form->{"$form->{db}number"};
   $where .= qq| AND (LOWER(ct.name) LIKE '$name')| if $form->{name};
   $where .= qq| AND (LOWER(aa.invnumber) LIKE '$invnumber')| if $form->{invnumber};
   $where .= qq| AND (LOWER(aa.description) LIKE '$description')| if $form->{description};
   $where .= qq| AND (LOWER(aa.notes) LIKE '$notes')| if $form->{notes};

   if (!$form->{summary}){
     $where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
     $where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   }
   if ($form->{invoices} || $form->{trans}){
      if ($form->{invoices}){
         $where .= qq| AND aa.invoice| unless $form->{trans};
      }
      if ($form->{trans}){
	 $where .= qq| AND NOT aa.invoice | unless $form->{invoices};
      }
   }
   @columns = (qw(id invnumber transdate customernumber vendornumber name partnumber description qty sellprice amount tax total cogs markup employee));

   # if this is first time we are running this report.
   $form->{sort} = "invnumber" if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	id => 1,
			invnumber => 2,
			transdate => 3,
			customernumber => 4,
			vendornumber => 4,
			name => 5,
			partnumber => 6,
			description => 7,
			qty => 8,
			sellprice => 9,
			amount => 10,
			tax => 11,
			total => 12,
			cogs => 13,
			markup => 14
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

   # No. columns should always come first
   splice @columns, 0, 0, 'no';

   # Remove columns based on report type
   if ($form->{summary}){
      for (qw(partnumber description qty sellprice)) { $form->{"l_$_"} = ""}
   } else {
      for (qw(total)) { $form->{"l_$_"} = ""}
   }

   # Select columns selected for report display
   foreach $item (@columns) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }
   for (qw(aa l_subtotal l_subtotalonly summary)){ $callback .= "&$_=$form->{$_}" }
   for (qw(customernumber vendornumber invnumber description notes fromdate todate partnumber department warehouse partsgroup employee)){ $callback .= "&$_=".$form->escape($form->{$_},1) }

   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   if ($form->{summary}){
   	$query = qq|
		SELECT 
		  aa.id, 
		  aa.invnumber,
		  aa.transdate,
		  ct.${db}number, 
		  ct.name, 
		  e.name AS employee,
		  aa.netamount AS amount,
		  aa.amount - aa.netamount AS tax,
		  aa.amount AS total,

	(SELECT SUM(0-ac.amount) 
	FROM acc_trans ac 
	JOIN chart c ON (c.id = ac.chart_id) 
	WHERE ac.trans_id = aa.id 
	AND c.link LIKE '%IC_cogs%') AS cogs,

		aa.invoice,
		aa.till

		FROM $table aa
		JOIN $db ct ON (ct.id = aa.${db}_id)
		LEFT JOIN employee e ON (e.id = aa.employee_id)

		WHERE $where
		ORDER BY $form->{sort} $form->{direction}|;
   } else {
   	$query = qq|
		SELECT 
		  aa.id, 
		  aa.invnumber,
		  aa.transdate,
		  ct.${db}number, 
		  ct.name, 
		  e.name AS employee,
		  p.partnumber,
		  p.description,
		  i.qty * $sign AS qty,
		  i.sellprice,
		  i.qty * i.sellprice * $sign AS amount,

	(SELECT SUM(taxamount)
	FROM invoicetax it
	WHERE it.invoice_id = i.id) AS tax,

		  0 AS total,

	(SELECT SUM(qty * costprice)
	FROM fifo f
	WHERE f.trans_id = aa.id
	AND f.parts_id = i.parts_id) AS cogs,

		aa.invoice,
		aa.till

		FROM $table aa
		JOIN invoice i ON (i.trans_id = aa.id)
		JOIN parts p ON (p.id = i.parts_id)
		JOIN $db ct ON (ct.id = aa.${db}_id)
		LEFT JOIN employee e ON (e.id = aa.employee_id)

		WHERE $where
		ORDER BY $form->{sort} $form->{direction}|;
   }

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{invnumber}    	= rpt_hdr('invnumber', $locale->text('Invoice Number'), $href);
   $column_header{transdate}    	= rpt_hdr('transdate', $locale->text('Invoice Date'), $href);
   $column_header{"${db}number"} 	= rpt_hdr("${db}number", $locale->text('Number'), $href);
   $column_header{name}    		= rpt_hdr('name', $locale->text('Name'), $href);
   $column_header{partnumber}    	= rpt_hdr('partnumber', $locale->text('Number'), $href);
   $column_header{description}  	= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{qty}  		= rpt_hdr('qty', $locale->text('Qty'), $href);
   $column_header{sellprice}  		= rpt_hdr('sellprice', $locale->text('Price'), $href);
   $column_header{amount}  		= rpt_hdr('amount', $locale->text('Amount'), $href);
   $column_header{tax}  		= rpt_hdr('tax', $locale->text('Tax'), $href);
   $column_header{total}  		= rpt_hdr('total', $locale->text('Total'), $href);
   $column_header{cogs}  		= rpt_hdr('cogs', $locale->text('COGS'), $href);
   $column_header{markup}  		= rpt_hdr('markup', $locale->text('%'));
   $column_header{employee}  		= rpt_hdr('employee', $locale->text($employee_caption), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, "${table}_transactions");
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text("$form->{aa} Transactions");
   &print_title;

   # Print report criteria
   &print_criteria("${db}number", 'Number');
   &print_criteria('name', 'Name');
   &print_criteria('invnumber', 'Invoice Number');
   &print_criteria('description', 'Description');
   &print_criteria('notes', 'Notes');
   &print_criteria('fromdate', 'From Date');
   &print_criteria('todate', 'To Date');
   &print_criteria('department_name', 'Department');
   &print_criteria('warehouse_name', 'Warehouse');
   &print_criteria('employee_name', $employee_caption);
   &print_criteria('partnumber', 'Number');
   &print_criteria('partsgroup_name', 'Group');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $qty_subtotal = 0;
   my $amount_subtotal = 0;
   my $tax_subtotal = 0;
   my $total_subtotal = 0;
   my $cogs_subtotal = 0;

   my $qty_total = 0;
   my $amount_total = 0;
   my $tax_total = 0;
   my $total_total = 0;
   my $cogs_total = 0;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';
   my $oldgroupbreak;
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
        $module = ($ref->{invoice}) ? ($form->{aa} eq 'AR') ? "is.pl" : "ir.pl" : "$table.pl";
        $module = ($ref->{till}) ? "ps.pl" : $module;
   	$form->{link} = qq|$module?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$form->{callback}|;
	$groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
	if ($form->{l_subtotal}){
	   if ($groupbreak ne $ref->{$form->{sort}}){
		$oldgroupbreak = $groupbreak;
		$groupbreak = $ref->{$form->{sort}};
		# prepare data for footer

   		$column_data{no}   			= rpt_txt('&nbsp;');
   		$column_data{invnumber}   		= rpt_txt('&nbsp;');
   		$column_data{transdate}   		= rpt_txt('&nbsp;');
   		$column_data{"${db}number"}  		= rpt_txt('&nbsp;');
   		$column_data{name}    			= rpt_txt('&nbsp;');
   		$column_data{partnumber}    		= rpt_txt('&nbsp;');
   		$column_data{description}    		= rpt_txt('&nbsp;');
   		$column_data{qty} 			= rpt_dec($qty_subtotal);
   		$column_data{sellprice} 		= rpt_txt('&nbsp;');
   		$column_data{amount} 			= rpt_dec($amount_subtotal);
   		$column_data{tax} 			= rpt_dec($tax_subtotal);
   		$column_data{total} 			= rpt_dec($total_subtotal);
   		$column_data{cogs} 			= rpt_dec($cogs_subtotal);
   		$column_data{employee}   		= rpt_txt('&nbsp;');
		# Print subtotal value of sorted column as heading
		$column_data{$form->{sort}}		= rpt_txt($oldgroupbreak) if $form->{l_subtotalonly};
		my $markup = 0;
		if ($amount_subtotal > 0){
		   $markup = (($amount_subtotal - $cogs_subtotal) * 100)/$amount_subtotal;
		}
   		$column_data{markup} 			= rpt_dec($markup);

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

   		$qty_subtotal = 0;
   		$amount_subtotal = 0;
   		$tax_subtotal = 0;
   		$total_subtotal = 0;
   		$cogs_subtotal = 0;
	   }
	}

	$column_data{no}   			= rpt_txt($no);
   	$column_data{invnumber} 		= rpt_txt($ref->{invnumber}, $form->{link});
   	$column_data{transdate} 		= rpt_txt($ref->{transdate});
   	$column_data{"${db}number"}		= rpt_txt($ref->{"${db}number"});
   	$column_data{name} 			= rpt_txt($ref->{name});
   	$column_data{partnumber} 		= rpt_txt($ref->{partnumber});
   	$column_data{description} 		= rpt_txt($ref->{description});
   	$column_data{qty}    			= rpt_dec($ref->{qty});
   	$column_data{sellprice}    		= rpt_dec($ref->{sellprice});
   	$column_data{amount}    		= rpt_dec($ref->{amount});
   	$column_data{tax}    			= rpt_dec($ref->{tax});
   	$column_data{total}    			= rpt_dec($ref->{total});
   	$column_data{cogs}    			= rpt_dec($ref->{cogs});
	if ($ref->{amount} > 0){
   	  $column_data{markup}    		= rpt_dec((($ref->{amount} - $ref->{cogs})* 100)/$ref->{amount});
	} else {
   	  $column_data{markup}    		= rpt_dec(0);
	}
   	$column_data{employee} 			= rpt_txt($ref->{employee});

	if (!$form->{l_subtotalonly}){
	   print "<tr valign=top class=listrow$i>";
	   for (@column_index) { print "\n$column_data{$_}" };
	   print "</tr>";
	}
	$i++; $i %= 2; $no++;

   	$qty_subtotal += $ref->{qty};
   	$amount_subtotal += $ref->{amount};
   	$tax_subtotal += $ref->{tax};
   	$total_subtotal += $ref->{total};
   	$cogs_subtotal += $ref->{cogs};

   	$qty_total += $ref->{qty};
   	$amount_total += $ref->{amount};
   	$tax_total += $ref->{tax};
   	$total_total += $ref->{total};
   	$cogs_total += $ref->{cogs};
   }

   # prepare data for footer
   $column_data{no}   			= rpt_txt('&nbsp;');
   $column_data{invnumber}   		= rpt_txt('&nbsp;');
   $column_data{transdate}   		= rpt_txt('&nbsp;');
   $column_data{"${db}number"}  	= rpt_txt('&nbsp;');
   $column_data{name}    		= rpt_txt('&nbsp;');
   $column_data{partnumber}    		= rpt_txt('&nbsp;');
   $column_data{description}   		= rpt_txt('&nbsp;');

   $column_data{qty} 			= rpt_dec($qty_subtotal);
   $column_data{sellprice} 		= rpt_txt('&nbsp;');
   $column_data{amount} 		= rpt_dec($amount_subtotal);
   $column_data{tax} 			= rpt_dec($tax_subtotal);
   $column_data{total} 			= rpt_dec($total_subtotal);
   $column_data{cogs} 			= rpt_dec($cogs_subtotal);
   $column_data{employee}    		= rpt_txt('&nbsp;');

   # Print subtotal value of sorted column as heading
   $column_data{$form->{sort}}		= rpt_txt($groupbreak) if $form->{l_subtotalonly};
	
   my $markup = 0;
   if ($form->{l_subtotal}){
   	if ($amount_subtotal > 0){
     	   $markup = (($amount_subtotal - $cogs_subtotal) * 100)/$amount_subtotal;
   	}
   	$column_data{markup} 		= rpt_dec($markup);

	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{qty} 			= rpt_dec($qty_total);
   $column_data{sellprice} 		= rpt_txt('&nbsp;');
   $column_data{amount} 		= rpt_dec($amount_total);
   $column_data{tax} 			= rpt_dec($tax_total);
   $column_data{total} 			= rpt_dec($total_total);
   $column_data{cogs} 			= rpt_dec($cogs_total);
   $markup = 0;
   if ($amount_total > 0){
      $markup = (($amount_total - $cogs_total) * 100)/$amount_total;
   }
   $column_data{markup} 		= rpt_dec($markup);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}

#===================================
#
# Stock Assemblies Transactions
#
#==================================
#-------------------------------
sub build_search {
   $form->{title} = $locale->text('Stock Assembly');
   &print_title;

   &start_form;
   &start_table;

   &bld_department;
   &bld_warehouse;
   &bld_partsgroup;

   &print_text('reference', 'Reference', 15);
   &print_date('datefrom', 'From');
   &print_date('dateto', 'To');

   #&print_text('partnumber', 'Number', 30);
   #&print_select('partsgroup', 'Group');
   &print_select('department', 'Department');
   &print_select('warehouse', 'Warehouse');
 
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_radio;
   &print_checkbox('l_no', $locale->text('No.'), '', '');
   &print_checkbox('l_reference', $locale->text('Reference'), 'checked', '');
   &print_checkbox('l_transdate', $locale->text('Date'), 'checked', '');
   &print_checkbox('l_department', $locale->text('Warehouse'), 'checked', '');
   &print_checkbox('l_warehouse', $locale->text('Warehouse'), 'checked', '<br />');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '');
   &print_checkbox('l_description', $locale->text('Description'), 'checked', '');
   &print_checkbox('l_qty', $locale->text('Qty'), 'checked', '');
   &print_checkbox('l_unit', $locale->text('Unit'), 'checked', '<br />');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '');
   #&print_checkbox('l_sql', $locale->text('SQL'), '');
   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'build_list';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub build_list {
   # callback to report list
   my $callback = qq|$form->{script}?action=build_list|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   &split_combos('department,warehouse');
   $form->{department_id} *= 1;
   $form->{warehouse_id} *= 1;
   #$form->{partsgroup_id} *= 1;
   $reference = $form->like(lc $form->{reference});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (LOWER(b.reference) LIKE '$reference')| if $form->{reference};
   #$where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
   $where .= qq| AND (b.department_id = $form->{department_id})| if $form->{department};
   $where .= qq| AND (b.warehouse_id = $form->{warehouse_id})| if $form->{warehouse};
   $where .= qq| AND (b.transdate >= '$form->{datefrom}')| if $form->{datefrom};
   $where .= qq| AND (b.transdate <= '$form->{dateto}')| if $form->{dateto};

   @columns = qw(id reference transdate department warehouse partnumber description qty unit);
   # if this is first time we are running this report.
   $form->{sort} = 'reference' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	id => 1,
			reference => 2,
			transdate => 3,
			department => 4,
			warehouse => 5,
			partnumber => 6,
			description => 7,
			amount => 8
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);

   # No. columns should always come first
   splice @columns, 0, 0, 'no';

   if ($form->{summary}){
	for (qw(l_partnumber l_description l_qty l_unit)){ delete $form->{$_} }
   }
   # Select columns selected for report display
   foreach $item (@columns) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }
   $callback .= "&l_subtotal=$form->{l_subtotal}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   if ($form->{summary}){
   	$query = qq|SELECT 
			b.id, 
			b.reference,
			b.transdate,
			w.description AS warehouse,	
			d.description AS department
			FROM build b
			JOIN department d ON (d.id = b.department_id)
			JOIN warehouse w ON (w.id = b.warehouse_id)
			WHERE $where
			ORDER BY $form->{sort} $form->{direction}|;
   } else {
   	$query = qq|SELECT 
			b.id, 
			b.reference,
			b.transdate,
			w.description AS warehouse,	
			d.description AS department,
			p.partnumber,
			p.description,
			i.qty,
			p.unit
			FROM build b
			JOIN department d ON (d.id = b.department_id)
			JOIN warehouse w ON (w.id = b.warehouse_id)
			JOIN inventory i ON (i.trans_id = b.id)
			JOIN parts p ON (p.id = i.parts_id)
			WHERE $where
			ORDER BY $form->{sort} $form->{direction}, i.linetype DESC|;
   }
   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{reference} 		= rpt_hdr('reference', $locale->text('Reference'), $href);
   $column_header{transdate} 		= rpt_hdr('transdate', $locale->text('Date'), $href);
   $column_header{department} 		= rpt_hdr('department', $locale->text('Department'), $href);
   $column_header{warehouse} 		= rpt_hdr('warehouse', $locale->text('Warehouse'), $href);
   $column_header{partnumber} 		= rpt_hdr('partnumber', $locale->text('Number'), $href);
   $column_header{description} 		= rpt_hdr('description', $locale->text('Description'), $href);
   $column_header{qty}  		= rpt_hdr('qty', $locale->text('Qty'), $href);
   $column_header{unit}  		= rpt_hdr('unit', $locale->text('Unit'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'stock_assembly');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Stock Assembly');
   &print_title;
   &print_criteria('datefrom', 'From');
   &print_criteria('dateto', 'To');
   &print_criteria('reference','Reference');
   &print_criteria('department_name', 'Department');
   &print_criteria('warehouse_name', 'Warehouse');
   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|; 

   # Subtotal and total variables
   my $qty_subtotal = 0;
   my $qty_total = 0;

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
   		$column_data{reference}  	= rpt_txt('&nbsp;');
   		$column_data{transdate}  	= rpt_txt('&nbsp;');
   		$column_data{department}  	= rpt_txt('&nbsp;');
   		$column_data{warehouse}  	= rpt_txt('&nbsp;');
   		$column_data{partnumber}  	= rpt_txt('&nbsp;');
   		$column_data{description} 	= rpt_txt('&nbsp;');
   		$column_data{qty} 		= rpt_dec($qty_subtotal);
   		$column_data{unit} 		= rpt_txt('&nbsp;');
		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";
		$qty_subtotal = 0;
	   }
	}
	$column_data{no}   		= rpt_txt($no);
   	$column_data{reference}		= rpt_txt($ref->{reference});
   	$column_data{transdate}		= rpt_txt($ref->{transdate});
   	$column_data{department}	= rpt_txt($ref->{department});
   	$column_data{warehouse}		= rpt_txt($ref->{warehouse});
   	$column_data{partnumber}	= rpt_txt($ref->{partnumber});
   	$column_data{description} 	= rpt_txt($ref->{description});
   	$column_data{qty}    		= rpt_dec($ref->{qty});
   	$column_data{unit}    		= rpt_txt($ref->{unit});

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$qty_subtotal += $ref->{qty};
	$qty_total += $ref->{qty};
   }

   # prepare data for footer
   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{reference}  	= rpt_txt('&nbsp;');
   $column_data{transdate}  	= rpt_txt('&nbsp;');
   $column_data{department}  	= rpt_txt('&nbsp;');
   $column_data{warehouse}  	= rpt_txt('&nbsp;');
   $column_data{partnumber}  	= rpt_txt('&nbsp;');
   $column_data{description} 	= rpt_txt('&nbsp;');
   $column_data{qty} 		= rpt_dec($qty_subtotal);
   $column_data{unit} 		= rpt_txt('&nbsp;');

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total
   $column_data{qty} = rpt_dec($qty_total);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;
   $sth->finish;
   $dbh->disconnect;
}

#######
## EOF
#######

