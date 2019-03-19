require "$form->{path}/lib.pl";

1;

sub continue { &{ $form->{nextsub} } }

#===================================
#
# Repost COGS
#
#===================================
#-----------------------------------
sub ask_repost {
    $form->{title} = $locale->text("Repost COGS");
    &print_title;
    &start_form;
    &bld_warehouse;

    print qq|<h2 class=confirm> Continue with COGS reposting?</h1>|;
    print qq|
<table>
<tr><th align=right>| . $locale->text('Number') . qq|</th><td><input type=text name=partnumber size=20></td></tr>
<tr><th align=right>Warehouse</th><td><select name=warehouse>$form->{selectwarehouse}</select></td></tr>
<tr><th></th><td nowrap="nowrap"><input name="build_invoicetax" class="checkbox" value="Y" type="checkbox"> Build invoicetax table (not normally needed, see wiki.ledger123.com)</td></tr>
<tr><th></th><td nowrap="nowrap"><input name="debug" class="checkbox" value="Y" type="checkbox"> Show debugging information</td></tr>
</table>
<br>
|;
    $form->{nextsub} = 'repost_cogs';
    &print_hidden('nextsub');
    &add_button('Continue');
    &end_form;
}

#-----------------------------------
sub repost_cogs {
    my $dbh = $form->dbconnect( \%myconfig );
    use DBIx::Simple;
    my $dbs = DBIx::Simple->connect($dbh);

    my ( $warehouse, $warehouse_id ) = split( /--/, $form->{warehouse} );
    $warehouse_id *= 1;
    $form->info("Reposting COGS for warehouse $warehouse\n") if $form->{warehouse};

    # If user has specified a partnumber
    my $parts_id;
    my $parts_where = qq|1 = 1|;
    if ( $form->{partnumber} ) {
        $query = qq|SELECT id FROM parts WHERE partnumber='$form->{partnumber}'|;
        ($parts_id) = $dbh->selectrow_array($query);
        $parts_where .= qq| AND parts_id = $parts_id|;
    }

    # Build invoicetax table
    if ( $form->{build_invoicetax} ) {
        $form->info("Building invoicetax table<br>\n");
        $query = qq|DELETE FROM invoicetax|;
        $dbh->do($query) || $form->dberror($query);

        my $query = qq|
	    SELECT i.id, i.trans_id, i.parts_id, 
		(i.qty * i.sellprice * tax.rate) AS taxamount, 
		ptax.chart_id
	    FROM invoice i
	    JOIN partstax ptax ON (ptax.parts_id = i.parts_id)
	    JOIN tax ON (tax.chart_id = ptax.chart_id)
	    WHERE i.trans_id = ?
	    AND ptax.chart_id = ?|;
        my $itsth = $dbh->prepare($query) || $form->dberror($query);

        $query = qq|INSERT INTO invoicetax (trans_id, invoice_id, chart_id, taxamount)
		   VALUES (?, ?, ?, ?)|;
        my $itins = $dbh->prepare($query) || $form->dberror($query);

        $query = qq|SELECT ar.id, ar.customer_id, ctax.chart_id 
		FROM ar
		JOIN customertax ctax ON (ar.customer_id = ctax.customer_id)|;
        $sth = $dbh->prepare($query) || $form->dberror($query);
        $sth->execute;
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $itsth->execute( $ref->{id}, $ref->{chart_id} );
            while ( $itref = $itsth->fetchrow_hashref(NAME_lc) ) {
                $itins->execute( $itref->{trans_id}, $itref->{id}, $itref->{chart_id}, $itref->{taxamount} );
            }
        }
    }

    $form->info("Reposting COGS<br>\n");

    # First update transdate and warehouse_id in invoice table
    $form->info("Updating dates and warehouse information in invoice table<br>\n");
    $query = qq|
        UPDATE invoice 
        SET transdate = (SELECT transdate FROM ar WHERE ar.id = invoice.trans_id)
		WHERE trans_id IN (SELECT id FROM ar)
    |;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|
        UPDATE invoice 
        SET transdate = (SELECT transdate FROM ap WHERE ap.id = invoice.trans_id)
		WHERE trans_id IN (SELECT id FROM ap)|;
    $dbh->do($query) || $form->dberror($query);

    # Now Empty fifo table
    if ( $form->{warehouse} ) {
        $query = qq|DELETE FROM fifo WHERE warehouse_id = $warehouse_id AND $parts_where|;
    }
    else {
        $query = qq|DELETE FROM fifo WHERE $parts_where|;
    }
    $dbh->do($query) || $form->dberror($query);

    # Now update lastcost column in invoice table for AP
    $form->info("Updating AP lastcost<br>\n");
    $query = qq|UPDATE invoice SET lastcost = sellprice WHERE trans_id IN (SELECT id FROM ap)|;
    $dbh->do($query) || $form->dberror($query);
    $query = qq|UPDATE invoice SET lastcost = sellprice WHERE trans_id IN (SELECT id FROM trf)|;
    $dbh->do($query) || $form->dberror($query);

    # Now update lastcost column in invoice table for AR
    $form->info("Updating AR lastcost<br>\n");
    $query = qq|
           SELECT i.parts_id, i.lotnum, i.transdate, i.id, i.sellprice, 'AR' AS aa
	       FROM invoice i
	       JOIN ar ON (ar.id = i.trans_id)
	       WHERE $parts_where

	       UNION ALL

	       SELECT i.parts_id, i.lotnum, i.transdate, i.id, i.sellprice, 'AP' AS aa
	       FROM invoice i
	       JOIN ap ON (ap.id = i.trans_id)
	       WHERE $parts_where

	       UNION ALL

	       SELECT i.parts_id, i.lotnum, i.transdate, i.id, i.sellprice, 'AR' AS aa
	       FROM invoice i
	       JOIN trf t ON (t.id = i.trans_id)
	       WHERE i.qty > 0 AND $parts_where

	       UNION ALL

	       SELECT i.parts_id, i.lotnum, i.transdate, i.id, i.sellprice, 'AP' AS aa
	       FROM invoice i
	       JOIN trf t ON (t.id = i.trans_id)
	       WHERE i.qty < 0 AND $parts_where

	       ORDER BY 1,2,3,4
   |;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;

    $query = qq|UPDATE invoice SET lastcost = ? WHERE id = ?|;
    $updateinvoice = $dbh->prepare($query) || $form->error($query);

    my $parts_id = 0;
    my $lastcost = 0;
    my $lotnum;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        if ( $parts_id != $ref->{parts_id} ) {
            $parts_id = $ref->{parts_id};
            $lastcost = 0;
            print qq|... Updating part $parts_id<br/>\n|;
        }
        if ( $lotnum ne $ref->{lotnum} ) {
            $lotnum   = $ref->{lotnum};
            $lastcost = 0;
        }
        if ( $ref->{aa} eq 'AP' ) {
            $lastcost = $ref->{sellprice};
        }
        else {
            $updateinvoice->execute( $lastcost, $ref->{id} );
        }
    }

    # COGS Reposting. First re-post invoices based on FIFO
    $form->info("Reallocating inventory<br>\n");

    # Remove all current allocations

    $query = qq|UPDATE invoice SET allocated = 0, cogs = 0 WHERE $parts_where|;
    $dbh->do($query) || $form->dberror($query);

    $query = qq|UPDATE invoice SET cogs = qty * lastcost WHERE qty < 0|;
    $dbh->do($query) || $form->dberror($query);

    # CREATE INDEX trf_trftype ON trf (trftype);
    $query = qq|UPDATE inventory SET cogs = 0 WHERE trans_id NOT IN (SELECT id FROM trf WHERE trftype IN ('transfer'))|;
    $dbh->do($query) || $form->dberror($query);

    # Prepare statements for use in inserts/updates
    $query           = qq|UPDATE invoice SET allocated = allocated + ?, cogs = cogs + ? WHERE id = ?|;
    $invoiceupdate   = $dbh->prepare($query) || $form->dberror($query);
    $query           = qq|UPDATE inventory SET cogs = cogs + ?, cost = ? WHERE invoice_id = ?|;
    $inventoryupdate = $dbh->prepare($query) || $form->dberror($query);

    $query = qq|
        INSERT INTO fifo (
            trans_id, transdate, parts_id, 
			qty, costprice, sellprice,
			warehouse_id, invoice_id, lotnum)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    |;
    $fifoadd = $dbh->prepare($query) || $form->dberror($query);

    my $whwhere = '';
    $whwhere = qq| AND warehouse_id = $warehouse_id| if $form->{warehouse};

    ###################################################
    ##
    ## 1. First calculate FIFO cost for standard parts
    ##
    ###################################################
    $apquery = qq|
        SELECT id, qty, lastcost AS sellprice, trans_id, transdate
		FROM invoice 
		WHERE parts_id = ? 
		$whwhere 
        AND $parts_where
		AND qty < 0 
		ORDER BY trans_id|;
    $apsth = $dbh->prepare($apquery) || $form->dberror($apquery);

    $arquery = qq|
            SELECT id, trans_id, transdate, qty, sellprice, qty+allocated AS unallocated
			FROM invoice 
			WHERE parts_id = ?
			$whwhere 
            AND $parts_where
			AND qty > 0 
			AND (qty + allocated) > 0
			ORDER BY trans_id|;
    $arsth = $dbh->prepare($arquery) || $form->dberror($arquery);

    # lastcost update for regular parts
    $query = qq|UPDATE parts SET lastcost = ? WHERE id = ?|;
    $partslastcost = $dbh->prepare($query) || $form->dberror($query);

    # SELECT parts with unallocated quantities
    $query = qq|
        SELECT id, partnumber, description 
		FROM parts 
		WHERE id IN (SELECT DISTINCT parts_id FROM invoice WHERE qty < 0 AND $parts_where)
		AND inventory_accno_id IS NOT NULL
		AND uselots = 'N'|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;

    print qq|<h3>First parts</h3>|;
    while ( $partsref = $sth->fetchrow_hashref(NAME_lc) ) {
        print "--- Processing $partsref->{partnumber}--$partsref->{description}<br>\n";
        $apsth->execute( $partsref->{id} );
        while ( $apref = $apsth->fetchrow_hashref(NAME_lc) ) {
            $qty2allocate = 0 - $apref->{qty};    # qty IN is always -ve so change sign for clarity
                                                  # select unallocated sale invoice transactions
            $arsth->execute( $partsref->{id} );
            $inventoryupdate->execute( $apref->{sellprice} * $apref->{qty} * -1, $apref->{sellprice}, $apref->{id} );
            $partslastcost->execute( $apref->{sellprice}, $partsref->{parts_id} );
            while ( $arref = $arsth->fetchrow_hashref(NAME_lc) ) {
                if ( $qty2allocate != 0 ) {
                    if ( $qty2allocate > $arref->{unallocated} ) {
                        $thisallocation = $arref->{unallocated};
                        $qty2allocate -= $thisallocation;
                    }
                    else {
                        $thisallocation = $qty2allocate;
                        $qty2allocate   = 0;
                    }
                    $invoiceupdate->execute( $thisallocation, 0, $apref->{id} ) || $form->error('Error updating AP');
                    $invoiceupdate->execute( 0.00 - $thisallocation, $apref->{sellprice} * $thisallocation, $arref->{id} ) || $form->error('Error updating AR');
                    $inventoryupdate->execute( $apref->{sellprice} * $thisallocation * -1, $apref->{sellprice}, $arref->{id} );
                    $fifoadd->execute( $arref->{trans_id}, "$arref->{transdate}", $partsref->{id}, $thisallocation, $apref->{sellprice}, $arref->{sellprice}, $warehouse_id, $apref->{id}, '' );
                    print "----- $apref->{transdate} -- $arref->{transdate} -- $apref->{trans_id} -- $arref->{trans_id} -- $apref->{sellprice} -- $arref->{sellprice}<br>\n" if $form->{debug};
                }
            }
        }
    }
    $apsth->finish;
    $arsth->finish;
    $sth->finish;

    ####################################################
    ##
    ## 2. Now calculate FIFO cost for lots enabled parts
    ##
    ####################################################

    # CREATE INDEX invoice_lotnum_parts_id ON invoice (lotnum, parts_id);
    $apquery = qq|
        SELECT id, qty, lastcost AS sellprice, trans_id, transdate, parts_id
		FROM invoice 
		WHERE lotnum = ? 
        AND parts_id = ?
		$whwhere 
        AND $parts_where
		AND qty < 0 
		ORDER BY trans_id|;
    $apsth = $dbh->prepare($apquery) || $form->dberror($apquery);

    $arquery = qq|
            SELECT id, trans_id, transdate, qty, sellprice, qty+allocated AS unallocated
			FROM invoice 
			WHERE lotnum = ? AND parts_id = ?
			$whwhere 
            AND $parts_where
			AND qty > 0 
			AND (qty + allocated) > 0
			ORDER BY trans_id|;
    $arsth = $dbh->prepare($arquery) || $form->dberror($arquery);

    # lastcost update for LOTS
    $query = qq|UPDATE lots SET lastcost = ? WHERE parts_id = ? AND lotnum = ?|;
    $lotslastcost = $dbh->prepare($query) || $form->dberror($query);

    # SELECT parts with unallocated quantities
    # CREATE INDEX lots_parts_id ON lots (lotnum, parts_id);
    $query = qq|SELECT DISTINCT lotnum, parts_id FROM lots ORDER BY lotnum|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;

    print qq|<h3>Now lots</h3>|;
    while ( $partsref = $sth->fetchrow_hashref(NAME_lc) ) {
        print "--- Processing lot $partsref->{lotnum}<br>\n";
        $apsth->execute( $partsref->{lotnum}, $partsref->{parts_id} );
        while ( $apref = $apsth->fetchrow_hashref(NAME_lc) ) {
            $qty2allocate = 0 - $apref->{qty};    # qty IN is always -ve so change sign for clarity
                                                  # select unallocated sale invoice transactions
            $arsth->execute( $partsref->{lotnum}, $partsref->{parts_id} );
            $inventoryupdate->execute( $apref->{sellprice} * $apref->{qty} * -1, $apref->{sellprice}, $apref->{id} );
            $lotslastcost->execute( $apref->{sellprice}, $partsref->{parts_id}, $partsref->{lotnum} );
            while ( $arref = $arsth->fetchrow_hashref(NAME_lc) ) {
                if ( $qty2allocate != 0 ) {
                    if ( $qty2allocate > $arref->{unallocated} ) {
                        $thisallocation = $arref->{unallocated};
                        $qty2allocate -= $thisallocation;
                    }
                    else {
                        $thisallocation = $qty2allocate;
                        $qty2allocate   = 0;
                    }
                    $invoiceupdate->execute( $thisallocation, 0, $apref->{id} ) || $form->error('Error updating AP');
                    $invoiceupdate->execute( 0.00 - $thisallocation, $apref->{sellprice} * $thisallocation, $arref->{id} ) || $form->error('Error updating AR');
                    $inventoryupdate->execute( $apref->{sellprice} * $thisallocation * -1, $apref->{sellprice}, $arref->{id} );
                    $fifoadd->execute( $arref->{trans_id}, "$arref->{transdate}", $apref->{parts_id}, $thisallocation, $apref->{sellprice}, $arref->{sellprice},
                        $warehouse_id, $apref->{id}, $partsref->{lotnum} );
                    print "----- $apref->{transdate} -- $arref->{transdate} -- $apref->{trans_id} -- $arref->{trans_id} -- $apref->{sellprice} -- $arref->{sellprice}<br>\n" if $form->{debug};
                }
            }
        }
    }
    $apsth->finish;
    $arsth->finish;
    $sth->finish;

    $form->info("Reposting COGS<br>\n");

    # Delete old COGS
    $query = qq|
        DELETE FROM acc_trans
		WHERE chart_id IN (
		  SELECT id
		  FROM chart
		  WHERE (link LIKE '%IC_cogs%')
		  OR (link = 'IC'))
		AND trans_id IN (
		  SELECT id 
		  FROM ar 
		  WHERE invoice is true
		  $whwhere)
   |;
    $dbh->do($query) || $form->dberror($query);

    # Also delete all stock inventory transactions
    $query = qq|DELETE FROM acc_trans WHERE trans_id IN (SELECT id FROM trf)|;
    $dbh->do($query) || $form->dberror($query);

    # Post new COGS
    my $cogsquery = qq|
            INSERT INTO acc_trans(
			    trans_id, chart_id, amount, 
			    transdate, source, id)
            VALUES (?, ?, ?, ?, ?, ?)|;
    my $cogssth = $dbh->prepare($cogsquery) or $form->dberror($cogsquery);

    my $where;
    $where .= qq| AND f.warehouse_id = $warehouse_id| if $form->{warehouse};

    # first invoices
    $query = qq|
        SELECT f.trans_id, f.transdate, 
		      f.qty * f.costprice AS amount,
		      p.inventory_accno_id, p.expense_accno_id,
		      f.invoice_id
		FROM fifo f JOIN parts p ON (p.id = f.parts_id)
   		WHERE f.trans_id IN (SELECT id FROM ar)
		$where AND $parts_where|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $cogssth->execute( $ref->{trans_id}, $ref->{inventory_accno_id}, $ref->{amount}, $ref->{transdate}, 'COGS', $ref->{invoice_id} );
        $cogssth->execute( $ref->{trans_id}, $ref->{expense_accno_id}, 0 - ( $ref->{amount} ), $ref->{transdate}, 'COGS', $ref->{invoice_id} );
    }

    # then assemblies components from inventory transfer form.
    $query = qq|SELECT f.trans_id, f.transdate, 
		      f.qty * f.costprice AS amount,
		      p.inventory_accno_id, p.expense_accno_id,
		      f.invoice_id
		FROM fifo f JOIN parts p ON (p.id = f.parts_id)
   		WHERE f.trans_id IN (SELECT id FROM trf)
		$where AND $parts_where|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $cogssth->execute( $ref->{trans_id}, $ref->{inventory_accno_id}, $ref->{amount}, $ref->{transdate}, 'COMP', $ref->{invoice_id} );
        $cogssth->execute( $ref->{trans_id}, $ref->{expense_accno_id}, 0 - ( $ref->{amount} ), $ref->{transdate}, 'COMP', $ref->{invoice_id} );
    }

    # Reverse COGS for sale returns / credit invoices
    $query = qq|SELECT i.id, i.trans_id, i.transdate,
			i.qty * i.lastcost AS amount,
			p.inventory_accno_id, p.expense_accno_id,
			i.parts_id, i.sellprice, i.warehouse_id,
			i.qty, i.lastcost, i.lotnum
		FROM invoice i JOIN parts p ON (p.id = i.parts_id)
		WHERE trans_id IN (SELECT id FROM ar WHERE netamount < 0)
		$whwhere AND $parts_where
   |;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $cogssth->execute( $ref->{trans_id}, $ref->{inventory_accno_id}, $ref->{amount}, $ref->{transdate}, 'COGS', $ref->{id} );
        $cogssth->execute( $ref->{trans_id}, $ref->{expense_accno_id}, 0 - ( $ref->{amount} ), $ref->{transdate}, 'COGS', $ref->{id} );

        $fifoadd->execute( $ref->{trans_id}, "$ref->{transdate}", $ref->{parts_id}, $ref->{qty}, $ref->{lastcost}, $ref->{sellprice}, $warehouse_id, $ref->{id}, $ref->{lotnum} );
    }

    # Post GL transactions for the assemblies built using inventory transfer form.
    $query = qq|SELECT i.trans_id, i.transdate, 
		      i.qty * i.sellprice AS amount,
		      p.inventory_accno_id,
		      p.expense_accno_id,
		      i.id AS invoice_id
		FROM invoice i JOIN parts p ON (p.id = i.parts_id)
   		WHERE i.trans_id IN (SELECT id FROM trf WHERE trftype='assembly')
		$where AND $parts_where|;
    $sth = $dbh->prepare($query) || $form->dberror($query);
    $sth->execute;
    while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
        $cogssth->execute( $ref->{trans_id}, $ref->{inventory_accno_id}, $ref->{amount}, $ref->{transdate}, 'ASM', $ref->{invoice_id} );
        $cogssth->execute( $ref->{trans_id}, $ref->{expense_accno_id}, 0 - ( $ref->{amount} ), $ref->{transdate}, 'ASM', $ref->{invoice_id} );
    }
    $sth->finish;
    $dbh->disconnect;
    print qq|<h2 class=confirm>Completed</h2>|;
}

#===================================
#
# Repost Transactions
#
#===================================
#-----------------------------------
sub ask_repost_all_trans {
    $form->{title} = $locale->text("Repost All Tranactions");
    &print_title;
    &start_form;

    print qq|<h2 class=confirm> Continue with All Transactions reposting?</h1>|;
    $form->{nextsub} = 'repost_cogs';
    &print_hidden('nextsub');
    &add_button('Continue');
    &end_form;
}

#-----------------------------------
sub repost_all_trans {
    my $query;
    my $dbh = $form->dbconnect( \%myconfig );

    # 1. AP Transactions
    $form->info("AR: Deleting transactions ...<br>\n");

    # Step 1: Delete existing tax postings
    $query = qq|DELETE FROM acc_trans 
		WHERE link LIKE '%AR_tax%'
		AND trans_id IN (SELECT id FROM ar WHERE NOT invoice)|;
    $dbh->do($query) || $form->dberror($query);

    # Step 2: Delete existing AR postings. This includes payment if one is made against this trans.
    $query = qq|DELETE FROM acc_trans
		WHERE link = 'AR'
		AND trans_id IN (SELECT id FROM ar WHERE NOT invoice)|;
    $dbh->do($query) || $form->dberror($query);

    # Now we are left with only the income account postings. We shall
    # use these to calculate and post tax as well as post AR to customer.

    # 2. AR Transactions

    # 3. AP Invoices

    # 4. AR Invoices
}

#===================================
#
# Old Invoices Reposting Script by DS
#
# Not recommended. Use the repost_cogs
# instead which can be run any number
# of times.
#
# This is here just for reference.
#
#===================================
#-----------------------------------
sub repost_invoices {

    $form->{title} = $locale->text('Repost Invoices');

    $form->header;

    print qq|
<body>

<form method=post action=$form->{script}>

<table width=100%>
  <tr class=listtop>
    <th>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table>
	<tr>
	  <td>| . $locale->text('Beginning date') . qq|
	  
          <td><input name=transdate size=11 class=date title="$myconfig{dateformat}"></td>
	</tr>
      </table>
    </td>
  </tr>
</table>

<hr size=3 noshade>

<br>
<input class=submit type=submit name=action value="| . $locale->text('Continue') . qq|">
<input type=hidden name=nextsub value=do_repost_invoices>
|;

    $form->hide_form(qw(path login));

    print qq|
</form>

</body>
</html>
|;

}

sub do_repost_invoices {

    $form->isblank( 'transdate', $locale->text('Date missing') );

    $form->header;
    print "Reposting Invoices ... ";
    if ( $ENV{HTTP_USER_AGENT} ) {
        print "<blink><font color=red>please wait</font></blink><br>";
    }
    else {
        print "please wait\n";
    }

    $SIG{INT} = 'IGNORE';

    open( FH, ">$userspath/nologin" );
    close(FH);

    $myconfig{numberformat} = '1000.00';

    # connect to database
    my $dbh = $form->dbconnect( \%myconfig );

    my $query;

    # set up default AR account
    $query = qq|SELECT c.accno
              FROM chart c
	      WHERE link = 'AR'|;
    ( $form->{defaultAR} ) = $dbh->selectrow_array($query);
    if ( !$form->{defaultAR} ) {
        unlink "$userspath/nologin";
        $form->error('AR account does not exist!');
    }

    # disable triggers
    $query = qq|UPDATE "pg_class" SET "reltriggers" = 0
              WHERE "relname" = 'ar'|;
    $dbh->do($query) || &dberror($query);

    my $uid = time;

    $query = qq|CREATE TABLE invoice$uid
              AS SELECT i.* FROM invoice i, ar a
	      WHERE i.trans_id = a.id
	      AND a.transdate >= date '$form->{transdate}'|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE ar$uid
              AS SELECT * FROM ar
	      WHERE invoice = '1'
	      AND transdate >= date '$form->{transdate}'|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE shipto$uid
              AS SELECT s.* FROM shipto s, ar$uid a
	      WHERE a.id = s.trans_id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE cargo$uid
              AS SELECT c.* FROM cargo c, ar$uid a
	      WHERE a.id = c.trans_id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE acc_trans$uid
              AS SELECT * FROM acc_trans
	      WHERE trans_id = 0|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE recurring$uid
              AS SELECT r.* FROM recurring r, ar$uid a
	      WHERE a.id = r.id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE recurringemail$uid
              AS SELECT r.* FROM recurringemail r, ar$uid a
	      WHERE a.id = r.id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE recurringprint$uid
              AS SELECT r.* FROM recurringprint r, ar$uid a
	      WHERE a.id = r.id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|CREATE TABLE payment$uid
              AS SELECT p.* FROM payment p, ar$uid a
	      WHERE a.id = p.trans_id|;
    $dbh->do($query) || &dberror($query);

    $query = qq|SELECT id FROM ar$uid
              ORDER BY transdate, id|;
    my $sth = $dbh->prepare($query);
    $sth->execute || &dberror($query);

    $dbh->{AutoCommit} = 0;

    while ( ( $form->{id} ) = $sth->fetchrow_array ) {
        push @id, $form->{id};

        # save account links
        $query = qq|INSERT INTO acc_trans$uid
                SELECT * FROM acc_trans
		WHERE trans_id = $form->{id}|;
        $dbh->do($query) || &dberror($query);

        # reverse the invoice, keep exchangerate on file
        IS::reverse_invoice( $dbh, $form );

        # remove ar record
        $query = qq|DELETE FROM ar
                WHERE id = $form->{id}|;
        $dbh->do($query) || &dberror($query);

        $dbh->commit;

    }
    $sth->finish;

    # get defaultcurrency
    $query = qq|SELECT curr
	      FROM curr
	      WHERE rn = 1|;
    ( $form->{defaultcurrency} ) = $dbh->selectrow_array($query);

    foreach $id (@id) {

        # save default currency and AR account
        for (qw(defaultcurrency defaultAR)) { $oldvar{$_} = $form->{$_} }

        # re-initialize
        for ( keys %$form ) { delete $form->{$_} }

        for ( keys %oldvar ) { $form->{$_} = $oldvar{$_} }

        # get ar and payment accounts
        $query = qq|SELECT c.accno FROM chart c
                JOIN acc_trans$uid a ON (a.chart_id = c.id)
		WHERE c.link = 'AR'
		AND a.trans_id = $id|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        ( $form->{AR} ) = $sth->fetchrow_array;
        $sth->finish;

        $form->{AR} ||= $form->{defaultAR};

        # get payment accounts
        $query = qq|SELECT c.accno, a.amount, a.transdate, a.source, a.memo,
                p.exchangerate, p.paymentmethod_id
                FROM acc_trans$uid a
		LEFT JOIN payment$uid p ON (p.id = a.id AND p.trans_id = a.trans_id)
		JOIN chart c ON (a.chart_id = c.id)
		WHERE c.link like '%AR_paid%'
		AND NOT a.fx_transaction
		AND a.trans_id = $id|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        $i = 0;
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            $i++;
            $form->{"AR_paid_$i"}  = $ref->{accno};
            $form->{"paid_$i"}     = $ref->{amount} * -1;
            $form->{"datepaid_$i"} = $form->{"olddatepaid_$i"} = $ref->{transdate};

            for (qw(source memo cleared vr_id exchangerate)) { $form->{"${_}_$i"} = $ref->{$_} }
            $form->{paymentmethod} = "--$ref->{paymentmethod_id}";
        }
        $sth->finish;
        $form->{paidaccounts} = $i + 1;

        # get ar entry
        $query = qq|SELECT a.invnumber, a.transdate, a.transdate AS invdate,
                a.customer_id, a.taxincluded, a.duedate, a.invoice,
		a.shippingpoint, a.terms, a.notes, a.curr AS currency,
		a.ordnumber, a.employee_id, a.quonumber, a.intnotes,
		a.department_id, a.shipvia, a.till, a.language_code,
		a.ponumber, a.approved, a.cashdiscount, a.discountterms,
		a.waybill,
		a.warehouse_id, a.description, a.onhold, a.exchangerate,
		a.dcn, a.bank_id, a.paymentmethod_id,
		ct.name AS customer, ad.address1, ad.address2, ad.city,
		ad.state, ad.zipcode, ad.country,
		ct.contact, ct.phone, ct.fax, ct.email,
                e.login
		FROM ar$uid a
		JOIN customer ct ON (a.customer_id = ct.id)
		JOIN address ad ON (ad.trans_id = ct.id)
		LEFT JOIN employee e ON (a.employee_id = e.id)
                WHERE a.id = $id|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # get name and tax accounts for customer
        $query = qq|SELECT c.accno, t.rate
                FROM chart c
		JOIN customertax ct ON (ct.chart_id = c.id)
		JOIN tax t ON (t.chart_id = c.id)
		WHERE (t.validto >= '$form->{transdate}' OR t.validto IS NULL)
		AND ct.customer_id = $form->{customer_id}
		ORDER BY accno, validto|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        %tax = ();
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {
            if ( !exists $tax{ $ref->{accno} } ) {
                $form->{taxaccounts} .= "$ref->{accno} ";
                $form->{"$ref->{accno}_rate"} = $ref->{rate};
            }
            $tax{ $ref->{accno} } = 1;
        }
        chop $form->{taxaccounts};
        $sth->finish;

        # get shipto
        $query = qq|SELECT shiptoname, shiptoaddress1, shiptoaddress2,
                shiptocity, shiptostate, shiptozipcode, shiptocountry,
		shiptocontact, shiptophone, shiptofax, shiptoemail
		FROM shipto$uid
                WHERE trans_id = $id|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        $ref = $sth->fetchrow_hashref(NAME_lc);
        for ( keys %$ref ) { $form->{$_} = $ref->{$_} }
        $sth->finish;

        # get individual items
        $query = qq|SELECT i.id, i.parts_id, i.description, i.qty,
                i.fxsellprice AS sellprice, i.discount, i.unit,
		i.project_id, i.deliverydate,
		i.serialnumber, i.itemnotes, i.lineitemdetail
		FROM invoice$uid i
		WHERE NOT i.assemblyitem
		AND i.trans_id = $id|;
        $sth = $dbh->prepare($query);
        $sth->execute || &dberror($query);

        $i = 0;
        while ( $ref = $sth->fetchrow_hashref(NAME_lc) ) {

            # get tax accounts for part
            $query = qq|SELECT c.accno
                  FROM chart c
		  JOIN partstax pt ON (c.id = pt.chart_id)
		  WHERE pt.parts_id = $ref->{id}|;
            my $pth = $dbh->prepare($query);
            $pth->execute || &dberror($query);
            while ( ($accno) = $pth->fetchrow_array ) {
                $ref->{taxaccounts} .= "$accno ";
            }
            chop $ref->{taxaccounts};
            $pth->finish;

            $i++;
            $ref->{discount} *= 100;

            for ( keys %$ref ) { $form->{"${_}_$i"} = $ref->{$_} }

            $form->{"id_$i"} = $ref->{parts_id};

            # get cargo information
            $query = qq|SELECT * FROM cargo$uid
                  WHERE trans_id = $id
		  AND id = $ref->{id}|;
            ( $form->{"package_$i"}, $form->{"netweight_$i"}, $form->{"grossweight_$i"}, $form->{"volume_$i"} ) = $dbh->selectrow_array($query);

        }
        $form->{rowcount} = $i + 1;

        $sth->finish;

        # post a new invoice
        for (qw(employee department warehouse)) { $form->{$_} = qq|--$form->{"${_}_id"}| }
        $form->{type} = "invoice";

        IS->post_invoice( \%myconfig, \%$form );

        print " $form->{invnumber}";

        # insert recurring from recurring$uid
        for (qw(recurring recurringemail recurringprint)) {
            $query = qq|INSERT INTO $_
                  SELECT *
		  FROM $_$uid
		  WHERE id = $id|;
            $dbh->do($query) || &dberror($query);

            $query = qq|UPDATE $_
                  SET id = $form->{id}
		  WHERE id = $id|;
            $dbh->do($query) || &dberror($query);
        }

        $dbh->commit;

    }

    for (qw(invoice ar shipto cargo acc_trans recurring recurringemail recurringprint payment)) {
        $query = qq|DROP TABLE $_$uid|;
        $dbh->do($query) || &dberror($query);
    }

    # enable triggers
    $query = qq|UPDATE pg_class SET reltriggers = (SELECT count(*) FROM pg_trigger where pg_class.oid = tgrelid) WHERE relname = 'ar'|;
    $dbh->do($query) || &dberror($query);

    $dbh->commit;
    $dbh->disconnect;

    unlink "$userspath/nologin";

    print "... done\n";

}

sub dberror {
    my $query = shift;

    unlink "$userspath/nologin";
    $form->dberror($query);

}

##
## EOF
##

