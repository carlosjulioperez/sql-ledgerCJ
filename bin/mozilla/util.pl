
use SL::IM;
use SL::AA;
require "$form->{path}/lib.pl";

1;
# end of main

sub continue { &{$form->{nextsub}} };

#===========================================
#
# Post finance charges for overdue invoices
#
#===========================================
sub ask_postfc {
   $form->{title} = $locale->text("Post finance charges");
   &print_title;
   &start_form;
 
   $form->{ARAP} = 'AR';
   IM->paymentaccounts(\%myconfig, \%$form);
   if (@{ $form->{all_paymentaccount} }) {
      @curr = split /:/, $form->{currencies};
      $form->{defaultcurrency} = $curr[0];
      chomp $form->{defaultcurrency};

      for (@curr) { $form->{selectcurrency} .= "$_\n" }
      
      $selectarapaccounts = "";
      for (@{ $form->{arap_accounts} }) { $selectarapaccounts .= qq|$_->{accno}--$_->{description}\n| }
      $arapaccounts = qq|
         <tr>
	  <th align=right>|.$locale->text("AR Account").qq|</th>
	  <td>
	    <select name=arapaccount>|.$form->select_option($selectarapaccounts)
	    .qq|</select>
	  </td>
	</tr>|;

      $selectincomeaccounts = "";
      for (@{ $form->{income_accounts} }) { $selectincomeaccounts .= qq|$_->{accno}--$_->{description}\n| }
      $incomeaccounts = qq|
         <tr>
	  <th align=right>|.$locale->text("Income Account").qq|</th>
	  <td>
	    <select name=incomeaccount>|.$form->select_option($selectincomeaccounts)
	    .qq|</select>
	  </td>
	</tr>|;
   }

   $form->{postdate} = $form->current_date(\%myconfig);
   print qq|<h2 class=confirm> Post finance charges</h2>|;
   print qq|
<table>
<tr><th align=right>Posting Date</th><td><input name=postdate size=11 type=text title='$myconfig{dateformat}' value='$form->{postdate}'></td></tr>
<tr><th align=right>Overdue days >=</th><td><input name=overduedays size=2 type=text></td></tr>
<tr><th align=right>Overdue Amount >=</th><td><input name=overdueamount size=10 type=text value='1'></td></tr>
<tr><th align=right>Finance Charge %</th><td><input name=fcrate size=5 type=text value='1.5'></td></tr>
$arapaccounts
$incomeaccounts
$expenseaccounts
</table>
<br>
|;
   $form->{nextsub} = 'list_fc_invoices';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

sub list_fc_invoices {
   $form->{title} = $locale->text("Post finance charges");
   &print_title;
   &start_form;
   $form->{overduedays} *= 1;
   $form->{overdueamount} *= 1;
   $form->{fcrate} *= 1;
   my $dbh = $form->dbconnect(\%myconfig);
   my $query = qq|
	SELECT a.id, a.invnumber, a.transdate, a.duedate,
		'$form->{postdate}' - a.duedate AS duedays,
		c.name, a.amount - a.paid AS dueamount,
		('$form->{postdate}' - a.duedate) * (((a.amount - a.paid) * $form->{fcrate})/(30 * 100)) AS fcamount
	FROM ar a
	JOIN customer c ON (a.customer_id = c.id)
	WHERE '$form->{postdate}' - a.duedate >= $form->{overduedays}
	AND (a.amount - a.paid) >= $form->{overdueamount}
   |;
#$form->error($query);
   my $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   print qq|
<table width=100%>
<tr class=listheading>
<th>&nbsp;</th>
<th>Invoice Number</th>
<th>Name</th>
<th>Invoice Date</th>
<th>Due Date</th>
<th>Days</th>
<th>Due Amount</th>
<th>Finance Charge</th>
</tr>
|;

   my $i = 1; my $j = 1;
   my $tatal_overdueamount;
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
	print qq|<tr class=listrow$i>|;
	print qq|<td><input type=checkbox name=postfc_$j class=checkbox value=1 checked></td>|;
	print qq|<input type=hidden name=id_$j value=$ref->{id}>|;
	print qq|<td>$ref->{invnumber}</td>|;
	print qq|<td>$ref->{name}</td>|;
	print qq|<td>$ref->{transdate}</td>|;
	print qq|<td>$ref->{duedate}</td>|;
	print qq|<td align=right>$ref->{duedays}</td>|;
	print qq|<td align=right>|. $form->format_amount(\%myconfig, $ref->{dueamount},2) . qq|</td>|;
	print qq|<td align=right>|. $form->format_amount(\%myconfig, $ref->{fcamount},2) . qq|</td>|;
	print qq|</tr>\n|;
	$total_overdueamount += $ref->{overdueamount};
	$total_fcamount += $ref->{fcamount};
	$i++; $i %= 2; $j++;
   }
    print qq|
<tr class=listtotal>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td align=right>| . $form->format_amount(\%myconfig, $total_dueamount, 2) . qq|</td>
<td align=right>| . $form->format_amount(\%myconfig, $total_fcamount, 2) . qq|</td>
</tr>
|;
   print qq|</table>|;
   $form->{rowcount} = $j;
   $form->{nextsub} = 'post_finance_charges';
   $form->hide_form(qw(postdate overduedays overdueamount fcrate arapaccount incomeaccount rowcount nextsub));
   &add_button('Post Finance Charges');
   &end_form;
}

sub post_finance_charges {
   $form->{title} = $locale->text("Post finance charges");
   &print_title;

   $newform = new Form;
   my $dbh = $form->dbconnect_noauto(\%myconfig);
   my ($employee_name, $employee_id) = $form->get_employee($dbh);

   $query = qq/
	SELECT a.invnumber, a.transdate, a.duedate,
		a.curr AS currency, a.customer_id,
		'$form->{postdate}' - a.duedate AS duedays,
		c.name || '--' || a.customer_id AS customer,
		amount - paid AS dueamount
	FROM ar a
	JOIN customer c ON (c.id = a.customer_id)
	WHERE a.id = ?
   /;
   my $sth = $dbh->prepare($query);

   for $i (1 .. $form->{rowcount}){
     if ($form->{"postfc_$i"}){
      $form->info("Posting finance charges for invoice");
      $sth->execute($form->{"id_$i"}) || $form->dberror($query);
      my $ref = $sth->fetchrow_hashref(NAME_lc);
      for (keys %$ref){ $newform->{$_} = $ref->{$_} }

      $newform->{vc} = 'customer';
      $newform->{type} = 'transaction';

      $newform->{oldcustomer} = $newform->{customer};
      $newform->{AR}= $form->{arapaccount};
      $newform->{defaultcurrency}='USD';
      $newform->{employee}= qq|$employee_name--$employee_id|;
      $newform->{notes} = 'Finance charge';

      # Calculate finance charge
      $fcamount = $newform->{dueamount} * 1;
      $fcamount = ($fcamount * $form->{fcrate} * $newform->{duedays})/(30 * 100);

      $newform->{amount_1} = $fcamount;
      $newform->{description_1} = "Finance charge for $newform->{duedays} days, Invoice $newform->{invnumber}";
      $newform->{AR_amount_1} = $form->{incomeaccount};
      $newform->{oldinvtotal} = $fcamount;
      $newform->{rowcount} = 2;

      if (AA->post_transaction(\%myconfig, \%$newform)) {
	$arquery = qq/
		UPDATE ar
		SET intnotes = intnotes || '
Due date updated to $form->{postdate} 
from $newform->{duedate} 
by finance charge posting.',
		duedate = '$form->{postdate}'
		WHERE id = $form->{"id_$i"}/;
	$dbh->do($arquery) || $form->error($arquery);
	$form->info(qq| $newform->{"invnumber"}|);
	$form->info(" ... ".$locale->text('ok')."\n");
      } else {
	$form->error($locale->text('Posting failed!'));
      }
     }
   }
   $sth->finish;
   $dbh->commit;
   $dbh->disconnect;
}

#####
# EOF
#####

