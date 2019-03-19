1;

sub renumber {

   $form->header;
   my $dbh = $form->dbconnect(\%myconfig);
   my $query = qq|SELECT id, name FROM customer ORDER BY name|;
   my $sth = $dbh->prepare($query);
   $sth->execute or $form->dberror($query);
   my $updatequery = qq|UPDATE customer SET customernumber = ? WHERE id = ?|;
   my $updatesth = $dbh->prepare($updatequery);
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
  	$form->{customernumber} = $form->update_defaults($myconfig, "customernumber", $dbh);
	$updatesth->execute($form->{customernumber}, $ref->{id});
	print qq|$form->{customernumber} assigned to $ref->{name}<br>|;
	
   }
   $dbh->disconnect;

}

