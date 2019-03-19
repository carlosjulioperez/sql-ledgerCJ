# post vendor invoices as new
#
# [Repost Vendor Invoices] 
# module=ir.pl
# action=repost_invoices

1;

##### repost_invoices
sub repost_invoices {

  $form->{title} = $locale->text('Repost Invoices');

  $form->header;

  $form->{action} = "do_repost_invoices";
  $form->{nextsub} = "do_repost_invoices";
  
  print qq|
<body>

<form method=post action=$form->{script}>

<h2 class=confirm>|.$locale->text('Confirm!').qq|</h2>

<h4>|.$locale->text('Are you sure you want to repost all vendor invoices').qq|</h4>

<p>
<input name=action class=submit type=submit value="|.$locale->text('Continue').qq|">|;


  $form->hide_form(qw(action nextsub path login));
  
  print qq|
</form>

</body>
</html>
|;

}


sub do_repost_invoices {
  
  $myconfig{vclimit} = 0;
  $myconfig{numberformat} = '1000.00';

  my $dbh = $form->dbconnect(\%myconfig);
  my $query = qq|SELECT id FROM ap
                 WHERE invoice
                 ORDER BY transdate|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  my %temp = ( type => invoice,
              login => $form->{login},
	       path => $form->{path} );

  $form->info("Reposting Invoices ... ");

  if ($ENV{HTTP_USER_AGENT}) {
    print "<blink><font color=red>please wait</font></blink><br>";
  } else {
    print "please wait\n";
  }

  $SIG{INT} = 'IGNORE';

  # disable triggers
  $query = qq|UPDATE "pg_class" SET "reltriggers" = 0
              WHERE "relname" = 'ar'|;
  $dbh->do($query) || $form->dberror($query);
  
  while (my ($id) = $sth->fetchrow_array) {

    for (keys %$form) { delete $form->{$_} }

    for (keys %temp) { $form->{$_} = $temp{$_} }
    $form->{id} = $id;

    &invoice_links;
    &prepare_invoice;

    delete $form->{id};
    
    if (! IR->post_invoice(\%myconfig, \%$form)) {
      $form->error('Failed to post new invoice!');
    }
    
    $form->{id} = $id;

    if (! IR->delete_invoice(\%myconfig, \%$form, $spool)) {
      $form->error("Failed to delete invoice : $form->{invnumber}");
    }

    print "$form->{invnumber} ";

  }
  $sth->finish;
  
  # enable triggers
  $query = qq|UPDATE pg_class SET reltriggers = (SELECT count(*) FROM pg_trigger where pg_class.oid = tgrelid) WHERE relname = 'ap'|;
  $dbh->do($query) || &dberror($query);
  
  $dbh->disconnect;

}

sub dberror {
  my $query = shift;

  unlink "$userspath/nologin";
  $form->dberror($query);

}

#########
###
### EOF
###
#########

