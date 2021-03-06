#=====================================================================
# SQL-Ledger ERP
# Copyright (C) 2006
#
#  Author: DWS Systems Inc.
#     Web: http://www.sql-ledger.com
#
#======================================================================
#
# General ledger backend code
#
#======================================================================

package GL;


sub delete_transaction {
  my ($self, $myconfig, $form) = @_;
  
  # connect to database
  my $dbh = $form->dbconnect_noauto($myconfig);
  
  my %audittrail = ( tablename  => 'gl',
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => 'deleted',
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  if ($form->{batchid}) {
    $query = qq|SELECT sum(amount)
		FROM acc_trans
		WHERE trans_id = $form->{id}
		AND amount < 0|;
    my ($mount) = $dbh->selectrow_array($query);
    
    $amount = $form->round_amount($amount, $form->{precision});
    $form->update_balance($dbh,
			  'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $amount);
    
    $query = qq|DELETE FROM vr WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  $query = qq|DELETE FROM gl WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  for (qw(acc_trans dpt_trans yearend)) {
    $query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  for (qw(recurring recurringemail recurringprint)) {
    $query = qq|DELETE FROM $_ WHERE id = $form->{id}|;
    $dbh->do($query) || $form->dberror($query);
  }
  
  $form->remove_locks($myconfig, $dbh, 'gl');

  # commit and redirect
  my $rc = $dbh->commit;
  $dbh->disconnect;
  
  $rc;
  
}


sub post_transaction {
  my ($self, $myconfig, $form, $dbh) = @_;
  
  my $null;
  my $project_id;
  my $department_id;
  my $i;
  my $keepcleared;
  
  my $disconnect = ($dbh) ? 0 : 1;

  # connect to database, turn off AutoCommit
  if (! $dbh) {
    $dbh = $form->dbconnect_noauto($myconfig);
  }

  my $query;
  my $sth;
  
  my $approved = ($form->{pending}) ? '0' : '1';
  my $action = ($approved) ? 'posted' : 'saved';

  my %defaults = $form->get_defaults($dbh, \@{['precision']});
  $form->{precision} = $defaults{precision};

  if ($form->{id}) {
    $keepcleared = 1;
    
    if ($form->{batchid}) {
      $query = qq|SELECT * FROM vr
		  WHERE trans_id = $form->{id}|;
      $sth = $dbh->prepare($query) || $form->dberror($query);
      $sth->execute || $form->dberror($query);
      $ref = $sth->fetchrow_hashref(NAME_lc);
      $form->{voucher}{transaction} = $ref;
      $sth->finish;
     
      $query = qq|SELECT SUM(amount)
		  FROM acc_trans
		  WHERE amount < 0
		  AND trans_id = $form->{id}|;
      ($amount) = $dbh->selectrow_array($query);
      
      $form->update_balance($dbh,
			    'br',
			    'amount',
			    qq|id = $form->{batchid}|,
			    $amount);
      
      # delete voucher
      $query = qq|DELETE FROM vr
                  WHERE trans_id = $form->{id}|;
      $dbh->do($query) || $form->dberror($query);

    }

    $query = qq|SELECT id FROM gl
                WHERE id = $form->{id}|;
    ($form->{id}) = $dbh->selectrow_array($query);

    if ($form->{id}) {
      # delete individual transactions
      for (qw(acc_trans dpt_trans)) {
	$query = qq|DELETE FROM $_ WHERE trans_id = $form->{id}|;
	$dbh->do($query) || $form->dberror($query);
      }
    }
  }
  
  if (!$form->{id}) {
   
    my $uid = localtime;
    $uid .= $$;

    $query = qq|INSERT INTO gl (reference, employee_id, approved)
                VALUES ('$uid', (SELECT id FROM employee
		                 WHERE login = '$form->{login}'),
		'$approved')|;
    $dbh->do($query) || $form->dberror($query);
    
    $query = qq|SELECT id FROM gl
                WHERE reference = '$uid'|;
    ($form->{id}) = $dbh->selectrow_array($query);
  }
  
  ($null, $department_id) = split /--/, $form->{department};
  $department_id *= 1;

  $form->{reference} = $form->update_defaults($myconfig, 'glnumber', $dbh) unless $form->{reference};
  $form->{reference} ||= $form->{id};

  $form->{currency} ||= $form->{defaultcurrency};

  my $exchangerate = $form->parse_amount($myconfig, $form->{exchangerate});
  $exchangerate ||= 1;

  $query = qq|UPDATE gl SET 
	      reference = |.$dbh->quote($form->{reference}).qq|,
	      description = |.$dbh->quote($form->{description}).qq|,
	      notes = |.$dbh->quote($form->{notes}).qq|,
	      transdate = '$form->{transdate}',
	      department_id = $department_id,
	      curr = '$form->{currency}',
	      exchangerate = $exchangerate
	      WHERE id = $form->{id}|;
  $dbh->do($query) || $form->dberror($query);

  if ($department_id) {
    $query = qq|INSERT INTO dpt_trans (trans_id, department_id)
                VALUES ($form->{id}, $department_id)|;
    $dbh->do($query) || $form->dberror($query);
  }

  my $amount;
  my $debit;
  my $credit;
  my $cleared = 'NULL';
  my $bramount = 0;
 
  # insert acc_trans transactions
  for $i (1 .. $form->{rowcount}) {

    $amount = 0;
    
    $debit = $form->parse_amount($myconfig, $form->{"debit_$i"});
    $credit = $form->parse_amount($myconfig, $form->{"credit_$i"});

    # extract accno
    ($accno) = split(/--/, $form->{"accno_$i"});
    
    if ($credit) {
      $amount = $credit;
      $bramount += $form->round_amount($amount * $exchangerate, $form->{precision});
    }
    if ($debit) {
      $amount = $debit * -1;
    }

    # add the record
    ($null, $project_id) = split /--/, $form->{"projectnumber_$i"};
    $project_id ||= 'NULL';
    
    if ($keepcleared) {
      $cleared = $form->dbquote($form->{"cleared_$i"}, SQL_DATE);
    }

    if ($form->{"fx_transaction_$i"} *= 1) {
      $cleared = $form->dbquote($form->{transdate}, SQL_DATE);
    }
    
    if ($amount || $form->{"source_$i"} || $form->{"memo_$i"} || ($project_id ne 'NULL')) {
      $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
		  source, fx_transaction, project_id, memo, cleared, approved)
		  VALUES
		  ($form->{id}, (SELECT id
				 FROM chart
				 WHERE accno = '$accno'),
		   $amount, '$form->{transdate}', |.
		   $dbh->quote($form->{"source_$i"}) .qq|,
		  '$form->{"fx_transaction_$i"}',
		  $project_id, |.$dbh->quote($form->{"memo_$i"}).qq|,
		  $cleared, '$approved')|;
      $dbh->do($query) || $form->dberror($query);

      if ($form->{currency} ne $form->{defaultcurrency}) {

	$amount = $form->round_amount($amount * ($exchangerate - 1), $form->{precision});
	
	if ($amount) {
	  $query = qq|INSERT INTO acc_trans (trans_id, chart_id, amount, transdate,
		      source, project_id, fx_transaction, memo, cleared, approved)
		      VALUES
		      ($form->{id}, (SELECT id
				     FROM chart
				     WHERE accno = '$accno'),
		       $amount, '$form->{transdate}', |.
		       $dbh->quote($form->{"source_$i"}) .qq|,
		      $project_id, '1', |.$dbh->quote($form->{"memo_$i"}).qq|,
		      $cleared, '$approved')|;
	  $dbh->do($query) || $form->dberror($query);
	}
      }
    }
  }

  if ($form->{batchid}) {
    # add voucher
    $form->{voucher}{transaction}{vouchernumber} = $form->update_defaults($myconfig, 'vouchernumber', $dbh) unless $form->{voucher}{transaction}{vouchernumber};

    $query = qq|INSERT INTO vr (br_id, trans_id, id, vouchernumber)
                VALUES ($form->{batchid}, $form->{id}, $form->{id}, |
		.$dbh->quote($form->{voucher}{transaction}{vouchernumber}).qq|)|;
    $dbh->do($query) || $form->dberror($query);

    # update batch
    $form->update_balance($dbh,
			  'br',
			  'amount',
			  qq|id = $form->{batchid}|,
			  $bramount);
   
  }
  
  my %audittrail = ( tablename  => 'gl',
                     reference  => $form->{reference},
		     formname   => 'transaction',
		     action     => $action,
		     id         => $form->{id} );
 
  $form->audittrail($dbh, "", \%audittrail);

  $form->save_recurring($dbh, $myconfig);

  $form->remove_locks($myconfig, $dbh, 'gl');

  # commit and redirect
  my $rc;
  
  if ($disconnect) {
    $rc = $dbh->commit;
    $dbh->disconnect;
  }

  $rc;

}


sub transactions {
  my ($self, $myconfig, $form) = @_;

  # connect to database
  my $dbh = $form->dbconnect($myconfig);
  my $query;
  my $sth;
  my $var;
  my $null;
  
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my ($glwhere, $arwhere, $apwhere) = ("g.approved = '1'", "a.approved = '1'", "a.approved = '1'");
  
  if ($form->{reference}) {
    $var = $form->like(lc $form->{reference});
    $glwhere .= " AND lower(g.reference) LIKE '$var'";
    $arwhere .= " AND lower(a.invnumber) LIKE '$var'";
    $apwhere .= " AND lower(a.invnumber) LIKE '$var'";
    $bldwhere .= " AND lower(t.trfnumber) LIKE '$var'";
  }
  if ($form->{description}) {
    $var = $form->like(lc $form->{description});
    $glwhere .= " AND lower(g.description) LIKE '$var'";
    $arwhere .= " AND lower(a.description) LIKE '$var'";
    $apwhere .= " AND lower(a.description) LIKE '$var'";
    $bldwhere .= " AND lower(t.description) LIKE '$var'";
  }
  if ($form->{name}) {
    $var = $form->like(lc $form->{name});
    $glwhere .= " AND lower(g.description) LIKE '$var'";
    $arwhere .= " AND lower(ct.name) LIKE '$var'";
    $apwhere .= " AND lower(ct.name) LIKE '$var'";
  }
  if ($form->{vcnumber}) {
    $var = $form->like(lc $form->{vcnumber});
    $glwhere .= " AND g.id = 0";
    $arwhere .= " AND lower(ct.customernumber) LIKE '$var'";
    $apwhere .= " AND lower(ct.vendornumber) LIKE '$var'";
  }
  if ($form->{department}) {
    ($null, $var) = split /--/, $form->{department};
    $glwhere .= " AND g.department_id = $var";
    $arwhere .= " AND a.department_id = $var";
    $apwhere .= " AND a.department_id = $var";
    $bldwhere .= " AND t.department_id = $var";
  }
  
  my $gdescription = "''";
  my $invoicejoin;
  my $lineitem = "''";
 
  if ($form->{lineitem}) {
    $var = $form->like(lc $form->{lineitem});
    $glwhere .= " AND lower(ac.memo) LIKE '$var'";
    $arwhere .= " AND lower(i.description) LIKE '$var'";
    $apwhere .= " AND lower(i.description) LIKE '$var'";
    $bldwhere .= " AND lower(i.description) LIKE '$var'";

    $gdescription = "ac.memo";
    $lineitem = "i.description";
    $invoicejoin = qq|
		 LEFT JOIN invoice i ON (i.id = ac.id)|;
  }
 
  if ($form->{l_lineitem}) {
    $gdescription = "ac.memo";
    $lineitem = "i.description";
    $invoicejoin = qq|
                 LEFT JOIN invoice i ON (i.id = ac.id)|;
  }

  if ($form->{source}) {
    $var = $form->like(lc $form->{source});
    $glwhere .= " AND lower(ac.source) LIKE '$var'";
    $arwhere .= " AND lower(ac.source) LIKE '$var'";
    $apwhere .= " AND lower(ac.source) LIKE '$var'";
    $bldwhere .= " AND lower(ac.source) LIKE '$var'";
  }
  
  my $where;

  if ($form->{accnofrom}) {
    $where = " AND c.accno >= '$form->{accnofrom}'";
    $where .= " AND c.accno <= '$form->{accnoto}'" if $form->{accnoto};
    $glwhere .= $where;
    $arwhere .= $where;
    $apwhere .= $where;
    $bldwhere .= $where;
  }

  if ($form->{memo}) {
    $var = $form->like(lc $form->{memo});
    $glwhere .= " AND lower(ac.memo) LIKE '$var'";
    $arwhere .= " AND lower(ac.memo) LIKE '$var'";
    $apwhere .= " AND lower(ac.memo) LIKE '$var'";
  }
  
  ($form->{datefrom}, $form->{dateto}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};
  
  if ($form->{datefrom}) {
    $glwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $arwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $apwhere .= " AND ac.transdate >= '$form->{datefrom}'";
    $bldwhere .= " AND ac.transdate >= '$form->{datefrom}'";
  }
  if ($form->{dateto}) {
    $glwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $arwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $apwhere .= " AND ac.transdate <= '$form->{dateto}'";
    $bldwhere .= " AND ac.transdate <= '$form->{dateto}'";
  }
  if ($form->{amountfrom}) {
    $glwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $arwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $apwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
    $bldwhere .= " AND abs(ac.amount) >= $form->{amountfrom}";
  }
  if ($form->{amountto}) {
    $glwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $arwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $apwhere .= " AND abs(ac.amount) <= $form->{amountto}";
    $bldwhere .= " AND abs(ac.amount) <= $form->{amountto}";
  }
  if ($form->{notes}) {
    $var = $form->like(lc $form->{notes});
    $glwhere .= " AND lower(g.notes) LIKE '$var'";
    $arwhere .= " AND lower(a.notes) LIKE '$var'";
    $apwhere .= " AND lower(a.notes) LIKE '$var'";
    $bldwhere .= " AND lower(t.notes) LIKE '$var'";
  }
  if ($form->{accno}) {
    $glwhere .= " AND c.accno = '$form->{accno}'";
    $arwhere .= " AND c.accno = '$form->{accno}'";
    $apwhere .= " AND c.accno = '$form->{accno}'";
    $bldwhere .= " AND c.accno = '$form->{accno}'";
  }
  if ($form->{gifi_accno}) {
    $glwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $arwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $apwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
    $bldwhere .= " AND c.gifi_accno = '$form->{gifi_accno}'";
  }
  if ($form->{category} ne 'X') {
    $glwhere .= " AND c.category = '$form->{category}'";
    $arwhere .= " AND c.category = '$form->{category}'";
    $apwhere .= " AND c.category = '$form->{category}'";
    $bldwhere .= " AND c.category = '$form->{category}'";
  }

  if ($form->{accno} || $form->{gifi_accno}) {
    
    # get category for account
    if ($form->{accno}) {
      $query = qq|SELECT c.category, c.link, c.contra, c.description,
                  l.description AS translation
		  FROM chart c
		  LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
		  WHERE c.accno = '$form->{accno}'|;
      ($form->{category}, $form->{link}, $form->{contra}, $form->{account_description}, $form->{account_translation}) = $dbh->selectrow_array($query);
      $form->{account_description} = $form->{account_translation} if $form->{account_translation};
    }
    
    if ($form->{gifi_accno}) {
      $query = qq|SELECT c.category, c.link, c.contra, g.description
		  FROM chart c
		  LEFT JOIN gifi g ON (g.accno = c.gifi_accno)
		  WHERE c.gifi_accno = '$form->{gifi_accno}'|;
      ($form->{category}, $form->{link}, $form->{contra}, $form->{gifi_account_description}) = $dbh->selectrow_array($query);
    }
 
    if ($form->{datefrom}) {
      $where = $glwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN gl g ON (g.id = ac.trans_id)
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      my ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;


      $where = $arwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN ar a ON (a.id = ac.trans_id)
		  JOIN customer ct ON (ct.id = a.customer_id)
		  $invoicejoin
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;

 
      $where = $apwhere;
      $where =~ s/(AND)??ac.transdate.*?(AND|$)//g;
      
      $query = qq|SELECT SUM(ac.amount)
		  FROM acc_trans ac
		  JOIN chart c ON (ac.chart_id = c.id)
		  JOIN ap a ON (a.id = ac.trans_id)
		  JOIN vendor ct ON (ct.id = a.vendor_id)
		  $invoicejoin
		  WHERE $where
		  AND ac.transdate < date '$form->{datefrom}'
		  |;
      
      ($balance) = $dbh->selectrow_array($query);
      $form->{balance} += $balance;

    }
  }
  

  my $false = ($myconfig->{dbdriver} =~ /Pg/) ? FALSE : q|'0'|;

  my %ordinal = ( id => 1,
                  reference => 4,
		  description => 5,
                  transdate => 6,
                  source => 7,
                  accno => 9,
		  department => 15,
		  memo => 16,
		  lineitem => 19,
		  name => 20,
		  vcnumber => 21);
  
  my @a = qw(id transdate reference accno);
  my $sortorder = $form->sort_order(\@a, \%ordinal);
  
  my $query = qq|SELECT g.id, 'gl' AS type, $false AS invoice, g.reference,
                 g.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, g.notes, c.link,
		 '' AS till, ac.cleared, d.description AS department,
		 ac.memo, '0' AS name_id, '' AS db,
		 $gdescription AS lineitem, '' AS name, '' AS vcnumber,
		 '' AS address1, '' AS address2, '' AS city,
		 c.description AS accdescription,
		 '' AS zipcode, '' AS country
                 FROM gl g
		 JOIN acc_trans ac ON (g.id = ac.trans_id)
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN department d ON (d.id = g.department_id)
                 WHERE $glwhere
	UNION ALL
	         SELECT a.id, 'ar' AS type, a.invoice, a.invnumber,
		 a.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 a.till, ac.cleared, d.description AS department,
		 ac.memo, ct.id AS name_id, 'customer' AS db,
		 $lineitem AS lineitem, ct.name, ct.customernumber,
		 ad.address1, ad.address2, ad.city,
		 c.description AS accdescription,
		 ad.zipcode, ad.country
		 FROM ar a
		 JOIN acc_trans ac ON (a.id = ac.trans_id)
		 $invoicejoin
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN customer ct ON (a.customer_id = ct.id)
		 JOIN address ad ON (ad.trans_id = ct.id)
		 LEFT JOIN department d ON (d.id = a.department_id)
		 WHERE $arwhere
	UNION ALL
	         SELECT a.id, 'ap' AS type, a.invoice, a.invnumber,
		 a.description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, a.notes, c.link,
		 a.till, ac.cleared, d.description AS department,
		 ac.memo, ct.id AS name_id, 'vendor' AS db,
		 $lineitem AS lineitem, ct.name, ct.vendornumber,
		 ad.address1, ad.address2, ad.city,
		 c.description AS accdescription,
		 ad.zipcode, ad.country
		 FROM ap a
		 JOIN acc_trans ac ON (a.id = ac.trans_id)
		 $invoicejoin
		 JOIN chart c ON (ac.chart_id = c.id)
		 JOIN vendor ct ON (a.vendor_id = ct.id)
		 JOIN address ad ON (ad.trans_id = ct.id)
		 LEFT JOIN department d ON (d.id = a.department_id)
		 WHERE $apwhere

	UNION ALL

	         SELECT t.id, 'trf' AS type, $false AS invoice, trfnumber AS invnumber,
		 '' AS description, ac.transdate, ac.source,
		 ac.amount, c.accno, c.gifi_accno, '' AS notes, c.link,
		 '' AS till, ac.cleared, d.description AS department,
		 ac.memo, '0' AS name_id, 'trf' AS db,
		 $lineitem AS lineitem, '' AS name, '' AS vendornumber,
		 '' AS address1, '' AS address2, '' AS city,
		 c.description AS accdescription,
		 '' AS zipcode, '' AS country
		 FROM trf t
		 JOIN acc_trans ac ON (t.id = ac.trans_id)
		 $invoicejoin
		 JOIN chart c ON (ac.chart_id = c.id)
		 LEFT JOIN department d ON (d.id = t.department_id)
		 WHERE (1 = 1) $bldwhere

	         ORDER BY $sortorder|;

  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  while (my $ref = $sth->fetchrow_hashref(NAME_lc)) {

    # gl
    if ($ref->{type} eq "gl") {
      $ref->{module} = "gl";
    }

    # transfers
    if ($ref->{type} eq "trf") {
      $ref->{module} = "trf";
    }

    # ap
    if ($ref->{type} eq "ap") {
      $ref->{memo} ||= $ref->{lineitem};
      if ($ref->{invoice}) {
        $ref->{module} = "ir";
      } else {
        $ref->{module} = "ap";
      }
    }

    # ar
    if ($ref->{type} eq "ar") {
      $ref->{memo} ||= $ref->{lineitem};
      if ($ref->{invoice}) {
        $ref->{module} = ($ref->{till}) ? "ps" : "is";
      } else {
        $ref->{module} = "ar";
      }
    }

    if ($ref->{amount} < 0) {
      $ref->{debit} = $ref->{amount} * -1;
      $ref->{credit} = 0;
    } else {
      $ref->{credit} = $ref->{amount};
      $ref->{debit} = 0;
    }

    for (qw(address1 address2 city zipcode country)) { $ref->{address} .= "$ref->{$_} " }
    
    push @{ $form->{GL} }, $ref;
    
  }

  $sth->finish;
  $dbh->disconnect;

}


sub transaction {
  my ($self, $myconfig, $form) = @_;
  
  my $query;
  my $sth;
  my $ref;
  my @a;
  
  # connect to database
  my $dbh = $form->dbconnect($myconfig);

  $form->remove_locks($myconfig, $dbh, 'gl');
  
  my %defaults = $form->get_defaults($dbh, \@{[qw(closedto revtrans precision)]});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $form->{currencies} = $form->get_currencies($dbh, $myconfig);
  
  if ($form->{id}) {
    $query = qq|SELECT g.*, 
                d.description AS department,
		br.id AS batchid, br.description AS batchdescription
                FROM gl g
	        LEFT JOIN department d ON (d.id = g.department_id)
		LEFT JOIN vr ON (vr.trans_id = g.id)
		LEFT JOIN br ON (br.id = vr.br_id)
	        WHERE g.id = $form->{id}|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);

    $ref = $sth->fetchrow_hashref(NAME_lc);
    for (keys %$ref) { $form->{$_} = $ref->{$_} }
    $form->{currency} = $form->{curr};
    $sth->finish;
  
    # retrieve individual rows
    $query = qq|SELECT ac.*, c.accno, c.description, p.projectnumber,
                l.description AS translation
	        FROM acc_trans ac
	        JOIN chart c ON (ac.chart_id = c.id)
	        LEFT JOIN project p ON (p.id = ac.project_id)
		LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	        WHERE ac.trans_id = $form->{id}
	        ORDER BY accno|;
    $sth = $dbh->prepare($query);
    $sth->execute || $form->dberror($query);
    
    while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
      $ref->{description} = $ref->{translation} if $ref->{translation};
      push @a, $ref;
      if ($ref->{fx_transaction}) {
	$fxdr += $ref->{amount} if $ref->{amount} < 0;
	$fxcr += $ref->{amount} if $ref->{amount} > 0;
      }
    }
    $sth->finish;
    
    if ($fxdr < 0 || $fxcr > 0) {
      $form->{fxadj} = 1 if $form->round_amount($fxdr * -1, $form->{precision}) != $form->round_amount($fxcr, $form->{precision});
    }

    if ($form->{fxadj}) {
      @{ $form->{GL} } = @a;
    } else {
      foreach $ref (@a) {
	if (! $ref->{fx_transaction}) {
	  push @{ $form->{GL} }, $ref;
	}
      }
    }
    
    # get recurring transaction
    $form->get_recurring($dbh);

    $form->create_lock($myconfig, $dbh, $form->{id}, 'gl');

  } else {
    $form->{transdate} = $form->current_date($myconfig);
  }

  # get chart of accounts
  $query = qq|SELECT c.accno, c.description,
              l.description AS translation
              FROM chart c
	      LEFT JOIN translation l ON (l.trans_id = c.id AND l.language_code = '$myconfig->{countrycode}')
	      WHERE c.charttype = 'A'
              ORDER by c.accno|;
  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  
  while ($ref = $sth->fetchrow_hashref(NAME_lc)) {
    $ref->{description} = $ref->{translation} if $ref->{translation};
    push @{ $form->{all_accno} }, $ref;
  }
  $sth->finish;

  # get departments
  $form->all_departments($myconfig, $dbh);
  
  # get projects
  $form->all_projects($myconfig, $dbh, $form->{transdate});
  
  $dbh->disconnect;

}


1;

