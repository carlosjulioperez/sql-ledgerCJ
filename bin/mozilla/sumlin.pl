
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
	$form->{title} = $locale->text('Sumaroria De Ventas Por Linea');
   } else {
   	$form->{title} = $locale->text('Purchase Qty Summary');
   }
   &print_title;
   &start_form;
   &start_table;

   &print_text('partnumber', 'Number', 20);
   &print_text('linumber', 'Linea', 30);
   &print_date('fromdate', 'From');
   &print_date('todate', 'To');

   print qq|<tr>$partsgroup</tr>|;
   print $selectfrom;
  
   print qq|<tr><th align=right>| . $locale->text('Include in Report') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox('l_partnumber', $locale->text('Number'), 'checked', '<br>');
   &print_checkbox('l_category', $locale->text('Category'), 'checked', '<br>');
   &print_checkbox('l_linumber', $locale->text('Linea'), 'checked', '<br>');
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
   $description = $form->like(lc $form->{description});
   $linumber = $form->like(lc $form->{linumber});
   
   my $where = qq| (1 = 1)|;
   $where .= qq| AND (aa.transdate >= '$form->{fromdate}')| if $form->{fromdate};
   $where .= qq| AND (aa.transdate <= '$form->{todate}')| if $form->{todate};
   $where .= qq| AND (p.partsgroup_id = $form->{partsgroup_id})| if $form->{partsgroup};
   $where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   $where .= qq| AND (LOWER(l.linumber) LIKE '$linumber')| if $form->{linumber};
   $where .= qq| AND (LOWER(p.description) LIKE '$description')| if $form->{description};

   @columns = qw(partnumber category linumber description);
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
#   $form->{sort} = "partnumber" if !$form->{sort};
   $form->{sort} = "linumber" if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	
			linumber => 1,
			partnumber => 2,
			category => 3,
			description => 4,
			onhand => $months_count + 5,
			lastcost => $months_count + 6,
			extended => $months_count + 7
   );
   my $sort_order = $form->sort_order(\@columns, \%ordinal);



#   $callback .= "&l_subtotal=$form->{l_subtotal}";

   foreach (qw(l_subtotal datefrom dateto partnumber linumber)){
       $callback .= "&$_=$form->{$_}";
   }
   
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
		SUM(i.qty) AS qty,
                l.linumber
		FROM invoice i
		JOIN $aa aa ON (aa.id = i.trans_id)
		JOIN customer cv ON (cv.id = aa.customer_id)
		JOIN parts p ON (p.id = i.parts_id)
		JOIN lineitem l ON (p.tariff_hscode = cast (l.id as text))

		WHERE $where
		GROUP BY 10,1,2,3,4,5,6,7,8
		ORDER BY $form->{sort} $form->{direction}|;

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
   $column_header{linumber} 		= rpt_hdr('linumber', $locale->text('Linea'), $href);
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
	$form->{title} = $locale->text('Sumaroria De Ventas Por Linea');
   } else {
   	$form->{title} = $locale->text('Purchase Qty Summary');
   }
   &print_title;

   # Print report criteria
   &print_criteria('partnumber', 'Number');
   &print_criteria('name', 'Name');
   &print_criteria('linumber', 'Linea');
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
   	$column_data{linumber}		= rpt_txt($ref->{linumber});
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
   $column_data{linumber}  		= rpt_txt('&nbsp;');
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



#######
## EOF
#######

