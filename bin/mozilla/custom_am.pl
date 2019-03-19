
1;

require "$form->{path}/lib.pl";
require "$form->{path}/mylib.pl";

#--------------------------------------
sub continue { &{$form->{nextsub} } };

sub ask_closing {
   $form->{title} = 'Close year';
   $form->header;
   print qq|
<h1>Close year</h1>

Continuing with this process will:
<ul>
<li>Remove all transactions from current dataset</li>
<li>Add beginning balance transactions<li>
</ul>
|;

   &start_form;
   &start_table;
   my $closing_date = $form->current_date(\%myconfig);
   &print_date('closing_date', 'Closing Date', $closing_date);
   &print_text('ar_account', 'AR Account', 20, '1130101');
   &print_text('ap_account', 'AP Account', 20, '2120101');
   &print_text('equity_account', 'Equity Account', 20, '3110103');
   $form->{nextsub} = "do_closing";
   for (qw(path login nextsub)) { $form->hide_form($_) }
   &end_table;
   &add_button('Continue');
   &end_form;
}

sub do_closing {
   $form->{title} = 'Close year';
   $form->header;
   print qq|<h1>Closing in process</h1>|;
   $dbh = $form->dbconnect(\%myconfig);
   my $query;

   ##---------------------------------------------------------------------------------
   ##
   ## Aim: 
   ##   Create a new database with beginning balances for customers,vendors,parts,gl
   ##
   ## How:
   ##   1. Create a new blank database (psql -U postgres newdb2010 etc.)
   ##   2. Restore the backup from old database
   ##   3. Run this closing procedure on this new database
   ##  The new database is now ready for new year transactions.
   ##
   ##
   ## Notes: The equity_account should be marked as receivables/income, 
   ##        payables/expense account on chart screen so that 
   ##        transactions can be opened correctly.
   ##
   ##----------------------------------------------------------------------------------

   ## 1. AR invoices list which were open at the time of closing_date
   $query = qq|
	CREATE TABLE ar_open_invoices AS
	SELECT ar.id
	FROM ar 
	JOIN acc_trans ac ON (ac.trans_id = ar.id)
	JOIN chart ch ON (ch.id = ac.chart_id)
	WHERE ac.transdate <= '$form->{closing_date}'
	AND ch.link = 'AR'
	GROUP BY ar.id
	HAVING ROUND(CAST (SUM(ac.amount) AS NUMERIC), 2) <> 0
   |;
   $dbh->do($query) || $form->dberror($query);

   ## 2. AP invoices which were open at the time of closing_date
   $query = qq|
	CREATE TABLE ap_open_invoices AS
	SELECT ap.id
	FROM ap
	JOIN acc_trans ac ON (ac.trans_id = ap.id)
	JOIN chart ch ON (ch.id = ac.chart_id)
	WHERE ac.transdate <= '$form->{closing_date}'
	AND ch.link = 'AP'
	GROUP BY ap.id
	HAVING ROUND(CAST (SUM(ac.amount) AS NUMERIC), 2) <> 0
   |;
   $dbh->do($query) || $form->dberror($query);

   ## 3. opening_gl
   $query = qq|
	CREATE TABLE opening_gl AS
	SELECT dt.department_id, ac.chart_id, SUM(ac.amount) AS amount
	FROM acc_trans ac
	LEFT JOIN dpt_trans dt ON (dt.trans_id = ac.trans_id)
	WHERE ac.transdate <= '$form->{closing_date}'
	AND ac.trans_id NOT IN (
	  SELECT id FROM ar_open_invoices UNION SELECT id FROM ap_open_invoices
  	)
	GROUP BY dt.department_id, ac.chart_id
   |;
   $dbh->do($query) || $form->dberror($query);

   ## 4. opening_inventory
   $query = qq|
      CREATE TABLE opening_inventory AS
      SELECT
	i.parts_id,
	i.warehouse_id,
	p.lastcost,
	SUM(i.qty) AS onhand
      FROM inventory i
      JOIN parts p ON (p.id = i.parts_id)
      WHERE shippingdate <= '$form->{closing_date}'
      GROUP BY 1, 2, 3
      HAVING SUM(i.qty) <> 0
      ORDER BY 1
   |;
   #$dbh->do($query) || $form->dberror($query);

   ## Delete closed invoices lines
   $query = qq|
	DELETE FROM invoice 
	WHERE trans_id NOT IN (
	  SELECT id FROM ap_open_invoices
	  UNION
	  SELECT id FROM ar_open_invoices
	)
	AND transdate <= '$form->{closing_date}'
   |;
   $dbh->do($query) || $form->dberror($query);

   ## Delete all account transactions except those for the open invoices.
   $query = qq|
	DELETE FROM acc_trans
	WHERE trans_id NOT IN (
	  SELECT id FROM ap_open_invoices
	  UNION
	  SELECT id FROM ar_open_invoices
	)
	AND transdate <= '$form->{closing_date}'
   |;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|
	DELETE FROM ar 
	WHERE id NOT IN (SELECT id FROM ar_open_invoices)
	AND transdate <= '$form->{closing_date}'
   |;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|
	DELETE FROM ap
	WHERE id NOT IN (SELECT id FROM ap_open_invoices)
	AND transdate <= '$form->{closing_date}'
   |;
   $dbh->do($query) || $form->dberror($query);

   for (qw(oe gl trf)){
     $dbh->do("DELETE FROM $_ WHERE transdate <= '$form->{closing_date}'") || $form->dberror("Error deleting $_");
   }
   $query = qq|DELETE FROM inventory WHERE shippingdate <= '$form->{closing_date}'|;
   $dbh->do($query) || $form->dberror($query);
   $form->info("...completed");

   ### Create new opening transactions
   ## 3. GL
   $query = qq|
	INSERT INTO gl (reference, department_id, transdate)
	SELECT 'beginning balance', id, '$form->{closing_date}'
	FROM department
   |;
   $dbh->do($query) || $form->dberror($query);

   # Opening for blank department.
   $query = qq|
	INSERT INTO gl (reference, department_id, transdate)
	VALUES ('beginning balance', 0, '$form->{closing_date}');
   |;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|UPDATE opening_gl SET department_id = 0 WHERE department_id IS NULL|;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|
	INSERT INTO acc_trans(trans_id, chart_id, amount, transdate, source)
	SELECT (SELECT id FROM gl
		  WHERE gl.department_id = opening_gl.department_id
		  AND gl.reference = 'beginning balance') AS trans_id,
		chart_id, amount, '$form->{closing_date}' AS transdate, 'gl opening'
	FROM opening_gl
   |;
   $dbh->do($query) || $form->dberror($query);

   ## 4. Inventory
   $query = qq|
	INSERT INTO trf (id, transdate, trfnumber)
	VALUES (0, '$form->{closing_date}', 'beginning balance')|;
   #$dbh->do($query) || $form->dberror($query);

   $query = qq|
	INSERT INTO inventory(trans_id, warehouse_id, parts_id, qty, cost, shippingdate)
	SELECT 0, warehouse_id, parts_id, onhand, lastcost, '$form->{closing_date}'
	FROM opening_inventory|;
   #$dbh->do($query) || $form->dberror($query);

   $query = qq|DELETE FROM parts WHERE obsolete
		AND id NOT IN (SELECT parts_id FROM invoice)|;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|DELETE FROM customer WHERE enddate = '12-31-2009'
		AND id NOT IN (SELECT id FROM ar)|;
   $dbh->do($query) || $form->dberror($query);

   $query = qq|DELETE FROM vendor WHERE enddate = '12-31-2009'
		AND id NOT IN (SELECT id FROM ap)|;
   $dbh->do($query) || $form->dberror($query);


   ## Finish off by removing the opening transactions tables.
   #for (qw(opening_ar opening_ap opening_gl opening_inventory)){ $dbh->do("DROP TABLE $_") }
}


sub dashboard {
  $form->{title} = $locale->text('Dashboard');
  $form->header;

  if (-f "dashboards/dashboard.txt"){
     open FH, "dashboards/dashboard.txt" or $form->error("dashboards/dashboard.txt : $!");
     while (<FH>){
       next if /^(#|;|\s)/;
       chop;
       my ($urltext, $url) = split (/--/, $_);
       if ($url){
          for (qw(path login)){
	     $url .= qq|&$_=$form->{$_}|;
          }
          print qq|<li><a href=$url>$urltext</a></li>|;
       } else {
          print qq|<h3>$urltext</h3>|;
       }
     }
  }

  if (-f "dashboards/$form->{login}_dashboard.txt"){
     open FH, "dashboards/$form->{login}_dashboard.txt" or $form->error("dashboards/$form->{login}_dashboard.txt : $!");
     while (<FH>){
       next if /^(#|;|\s)/;
       chop;
       my ($urltext, $url) = split (/--/, $_);
       if ($url){
          for (qw(path login)){
	     $url .= qq|&$_=$form->{$_}|;
          }
          print qq|<li><a href=$url>$urltext</a></li>|;
       } else {
          print qq|<h3>$urltext</h3>|;
       }
     }
  }
}

sub ask_dbcheck {
  $form->{title} = $locale->text('Ledger Doctor');
  $form->header;
  my $dbh = $form->dbconnect(\%myconfig);
  my ($firstdate) = $dbh->selectrow_array("SELECT MIN(transdate) FROM acc_trans");
  my ($lastdate) = $dbh->selectrow_array("SELECT MAX(transdate) FROM acc_trans");
  print qq|
<body>
  <table width=100%>
     <tr><th class=listtop>$form->{title}</th></tr>
  </table><br />

<h1>Check for database inconsistancies</h1>
<form method=post action='$form->{script}'>
  <table>
    <tr>
	<th>|.$locale->text('First transaction date').qq|</th>
	<td><input name=firstdate size=11 value='$firstdate' title='$myconfig{dateformat}'></td>
    </tr>
    <tr>
	<th>|.$locale->text('Last transaction date').qq|</th>
	<td><input name=lastdate size=11 value='$lastdate' title='$myconfig{dateformat}'></td>
     </tr>
  </table>|.
$locale->text('All transactions outside this date range will be reported as having invalid dates.').qq|
<br><br><hr/>
<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">
|;

  $form->{nextsub} = 'do_dbcheck';
  $form->hide_form(qw(title path nextsub login));

print qq|
</table>
</form>
</body>
|;
}

sub do_dbcheck {
  $form->{title} = $locale->text('Ledger Doctor');
  $form->header;
  print qq|<body><table width=100%><tr><th class=listtop>$form->{title}</th></tr></table><br />|;
  my $dbh = $form->dbconnect(\%myconfig);
  my $query, $sth, $i;
  my $callback = "$form->{script}?action=do_dbcheck&firstdate=$form->{firstdate}&lastdate=$form->{lastdate}&path=$form->{path}&login=$form->{login}";
  $callback = $form->escape($callback);

  #------------------
  # 1. Invalid Dates
  #------------------
  print qq|<h2>Invalid Dates</h2>|;
  $query = qq|
		SELECT 'AR' AS module, id, invnumber, transdate 
		FROM ar
		WHERE transdate < '$form->{firstdate}'
		OR transdate > '$form->{lastdate}'

		UNION ALL

		SELECT 'AP' AS module, id, invnumber, transdate 
		FROM ap
		WHERE transdate < '$form->{firstdate}'
		OR transdate > '$form->{lastdate}'

		UNION ALL

		SELECT 'GL' AS module, id, reference, transdate 
		FROM gl
		WHERE transdate < '$form->{firstdate}'
		OR transdate > '$form->{lastdate}'
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Module').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Invoice Number / Reference').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Date').qq|</td>|;
  print qq|</tr>|;
  $i = 0;

  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     $module = lc $ref->{module};
     $module = 'ir' if $ref->{invoice} and $ref->{module} eq 'AP';
     $module = 'is' if $ref->{invoice} and $ref->{module} eq 'AR';

     print qq|<tr class=listrow$i>|;
     print qq|<td>$ref->{module}</td>|;
     print qq|<td><a href=$module.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}</a></td>|;
     print qq|<td>$ref->{transdate}</td>|;
     print qq|</tr>|;
  }
  print qq|</table>|;

  #------------------------
  # 2. Unbalanced Journals
  #------------------------
  print qq|<h3>Unbalanced Journals</h3>|;
  $query = qq|
	SELECT 'GL' AS module, gl.reference AS invnumber, gl.id,
		gl.transdate, false AS invoice, SUM(ac.amount) AS amount
	FROM acc_trans ac
	JOIN gl ON (gl.id = ac.trans_id)
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(ac.amount) <> 0

	UNION ALL

	SELECT 'AR' AS module, ar.invnumber, ar.id,
		ar.transdate, ar.invoice, SUM(ac.amount) AS amount
	FROM acc_trans ac
	JOIN ar ON (ar.id = ac.trans_id)
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(ac.amount) <> 0

	UNION ALL

	SELECT 'AP' AS module, ap.invnumber, ap.id,
		ap.transdate, ap.invoice, SUM(ac.amount) AS amount
	FROM acc_trans ac
	JOIN ap ON (ap.id = ac.trans_id)
	GROUP BY 1, 2, 3, 4, 5
	HAVING SUM(ac.amount) <> 0

	ORDER BY 3
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Module').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Invoice Number / Reference').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Date').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Amount').qq|</td>|;
  print qq|</tr>|;
  $i = 0;

  my $module;
  my $total_amount;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     $module = lc $ref->{module};
     $module = 'ir' if $ref->{invoice} and $ref->{module} eq 'AP';
     $module = 'is' if $ref->{invoice} and $ref->{module} eq 'AR';

     if ($form->round_amount($ref->{amount}, 2) != 0){
     	print qq|<tr class=listrow$i>|;
     	print qq|<td>$ref->{module}</td>|;
     	print qq|<td><a href=$module.pl?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback>$ref->{invnumber}</a></td>|;
     	print qq|<td>$ref->{transdate}</td>|;
     	print qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{amount}, 2).qq|</td>|;
     	print qq|</tr>|;
	$total_amount += $ref->{amount};
     }
  }
  print qq|<tr class=listtotal><td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td><td>|.
$form->format_amount(\%myconfig, $total_amount, 2).qq|</td></tr></table>|;

  #-------------------
  # 3. Orphaned Rows
  #-------------------
  print qq|<h3>Orphaned Rows</h3>|;
  $form->info('To delete these rows run the following in psql. Make sure you have backup before running.');
  print qq|
<pre>
DELETE FROM acc_trans
WHERE trans_id NOT IN 
	(SELECT id FROM ar 
	UNION ALL  
	SELECT id FROM ap
	UNION ALL
	SELECT id FROM gl
	UNION ALL
	SELECT id FROM trf);
</pre>|;
  $query = qq|
		SELECT * FROM acc_trans
		WHERE trans_id NOT IN 
			(SELECT id FROM ar 
			UNION ALL  
			SELECT id FROM ap
			UNION ALL
			SELECT id FROM gl
			UNION ALL
			SELECT id FROM trf)
		ORDER BY transdate, trans_id
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Date').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Trans ID').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Amount').qq|</td>|;
  print qq|</tr>|;
  $i = 0;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     print qq|<tr class=listrow$i>|;
     print qq|<td>$ref->{transdate}</td>|;
     print qq|<td>$ref->{trans_id}</td>|;
     print qq|<td align="right">|.$form->format_amount(\%myconfig, $ref->{amount},2).qq|</td>|;
     print qq|</tr>|;
  }
  print qq|</table>|;

  #---------------------------------------
  # 4. Transactions with Deleted Accounts
  #---------------------------------------
  print qq|<h3>Deleted Accounts</h3>|;
  $query = qq|
		SELECT trans_id, chart_id, source, transdate, amount
		FROM acc_trans
		WHERE chart_id NOT IN (SELECT id FROM chart)
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Chart ID').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Source').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Date').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Amount').qq|</td>|;
  print qq|</tr>|;
  $i = 0;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     print qq|<tr class=listrow$i>|;
     print qq|<td>$ref->{chart_id}</td>|;
     print qq|<td>$ref->{source}</td>|;
     print qq|<td>$ref->{transdate}</td>|;
     print qq|<td align=right>$ref->{amount}</td>|;
     print qq|</tr>|;
  }
  print qq|</table>|;


  #----------------------------
  # 5. Duplicate Part Numbers
  #----------------------------
  print qq|<h3>Duplicate Parts</h3>|;
  $query = qq|
		SELECT partnumber, COUNT(*) AS cnt
		FROM parts
		GROUP BY partnumber
		HAVING COUNT(*) > 1
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Number').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Duplicates').qq|</td>|;
  print qq|</tr>|;
  $i = 0;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     print qq|<tr class=listrow$i>|;
     print qq|<td>$ref->{partnumber}</td>|;
     print qq|<td align=right>$ref->{cnt}</td>|;
     print qq|</tr>|;
  }
  print qq|</table>|;

  #-----------------------------
  # 6. Invoices with Deleted Parts
  #-----------------------------
  print qq|<h3>Deleted Parts</h3>|;
  $query = qq|
		SELECT trans_id, parts_id, description, qty
		FROM invoice
		WHERE parts_id NOT IN (SELECT id FROM parts)
  |;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  print qq|<table>|;
  print qq|<tr class=listheading>|;
  print qq|<th class=listheading>|.$locale->text('Part ID').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Description').qq|</td>|;
  print qq|<th class=listheading>|.$locale->text('Qty').qq|</td>|;
  print qq|</tr>|;
  $i = 0;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     print qq|<tr class=listrow$i>|;
     print qq|<td>$ref->{parts_id}</td>|;
     print qq|<td>$ref->{description}</td>|;
     print qq|<td align=right>$ref->{qty}</td>|;
     print qq|</tr>|;
  }
  print qq|
</table>
</body>
</html>|;
  $dbh->disconnect;
}

######
# EOF 
######

