1;

sub arapipost {
   my $query = qq|SELECT t.customer_id, c.name, t.transdate, t.invnumber, t.amount 
		  FROM importedtrans t
		  JOIN customer c ON (c.id = t.customer_id)
		|;
   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
      for (qw(id invnumber)) { delete $form->{$_} };
      for (qw(amount_1 description_1 AR_amount_1 oldinvtotal rowcount)) { delete $form->{$_} }; 
      for (qw(datepaid_1 source_1 memo_1 paid_1 AR_paid_1 oldtotalpaid paidaccounts)) { delete $form->{$_} }; 
 
      for (keys %$form) { delete $form->{$_} };

      $form->{vc} = 'customer';
      $form->{type} = 'transaction';

      $form->{customer} = "$ref->{name}--$ref->{customer_id}";
      $form->{oldcustomer} = "$ref->{name}--$ref->{customer_id}";
      $form->{customer_id} = $ref->{customer_id};
      $form->{AR}= '1100';
      $form->{currency} = 'GBP';
      $form->{defaultcurrency}='GBP';
      $form->{employee}= 'Armaghan Saqib--10133';
      $form->{invnumber} = $ref->{invnumber};
      $form->{transdate} = $ref->{transdate};
      $form->{duedate} = $ref->{transdate};
      $form->{notes} = 'POS data imported';

      if ($ref->{amount} > 0){
         # Set following variables for charge
         $form->{amount_1} = $ref->{amount};
         $form->{description_1} = 'Test description';
         $form->{AR_amount_1} = '4000';
         $form->{oldinvtotal} = $ref->{amount};
         $form->{rowcount} = 2;
      } else {
         # Set following variables for payment
         $form->{datepaid_1} = $ref->{transdate};
         $form->{source_1} = 'source1';
         $form->{memo_1} = 'memo1';
         $form->{paid_1} = 0 - $ref->{amount};
         $form->{AR_paid_1} = '1200';
         $form->{oldtotalpaid} = 0 - $ref->{amount};
         $form->{paidaccounts} = 2;
      }
      $form->{display_form} = "api_quit";
      &post;
   }
}
# EOF

