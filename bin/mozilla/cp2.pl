#
# Pay multiple vendor invoices with one check
#
# Ticket # 1144

1;

sub continue { &{$form->{nextsub}} };

sub invoices_search {
  $form->{title} = $locale->text('Payments');
  $form->header;

  my $dbh = $form->dbconnect(\%myconfig);
  my $query = qq|SELECT id, name FROM vendor ORDER BY name|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     $form->{selectvendor} .= "$ref->{name}--$ref->{id}\n";
  }
  $sth->finish;

  my $query = qq|SELECT id, description FROM department ORDER BY description|;
  $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute;
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     $form->{selectdepartment} .= "$ref->{description}--$ref->{id}\n";
  }
  $sth->finish;
  $dbh->disconnect;

  print qq|
<body>
<form method=post action=$form->{script}>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>
      <table width=100%>
        <tr valign=top>
          <th align=right>|.$locale->text('Vendor').qq|</th>
	  <td><input type=text name=name size=30 ></td>
        </tr>
        <tr valign=top>
          <th align=right>|.$locale->text('Department').qq|</th>
	  <td><select name=department><option>\n|.$form->select_option($form->{selectdepartment},0,1).qq|</td>
        </tr>
        <tr valign=top>
          <th align=right>|.$locale->text('Invoice Date From').qq|</th>
	  <td><input type=text name=fromdate size=11 title='$myconfig->{dateformat}'></td>
        </tr>
        <tr valign=top>
          <th align=right>|.$locale->text('Invoice Date To').qq|</th>
	  <td><input type=text name=todate size=11 title='$myconfig->{dateformat}'></td>
        </tr>
        <tr valign=top>
          <th align=right>|.$locale->text('Petty Cash Vendor').qq|</th>
	  <td><select name=petty_cash_vendor>|.$form->select_option($form->{selectvendor},0,1).qq|</td>
        </tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">|;

  $form->{nextsub} = 'form_header';
  $form->hide_form(qw(nextsub path login));

  print qq|
</form>
</body>
</html>
|;

}

sub form_header {
  my $callback = qq|$form->{script}?action=form_header|;
  for (qw(path login)) { $callback .= "&$_=$form->{$_}" }

  ($form->{petty_cash_vendor_name}, $form->{petty_cash_vendor_id}) = split(/--/, $form->{petty_cash_vendor});
  ($form->{department_name}, $form->{department_id}) = split(/--/, $form->{department});

  $form->{title} = $locale->text('Payments');
  $form->header;

  print qq|
<script language="JavaScript">
<!--

function CheckAll() {

  var frm = document.forms[0]
  var el = frm.elements
  var re = /checked_/;

  for (i = 0; i < el.length; i++) {
    if (el[i].type == 'checkbox' && re.test(el[i].name)) {
      el[i].checked = frm.allbox_select.checked
    }
  }
}

javascript:window.history.forward(1);

// -->
</script>
|;

  print qq|
<body>
<form method=post action=$form->{script}>
<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
  </tr>
</table>
|;

  my $dbh = $form->dbconnect(\%myconfig);
  my $query = qq|SELECT c.accno, c.description, c.link
		FROM chart c
		WHERE c.link LIKE '%AP%'
		ORDER BY c.accno
	|;
  my $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
     if ($ref->{link} =~ /AP_paid/){
        $form->{selectAP_paid} .= "$ref->{accno}--$ref->{description}\n";
     } elsif ($ref->{link} eq 'AP') {
        $form->{selectAP} .= "$ref->{accno}--$ref->{description}\n";
     }
  }

  my $dbh = $form->dbconnect(\%myconfig);

  $form->{currencies} = $form->get_currencies($dbh, \%$myconfig);
  @curr = split /:/, $form->{currencies};
  $form->{defaultcurrency} = $curr[0];
  chomp $form->{defaultcurrency};

  $form->{selectcurrency} = "";
  for (@curr) { $form->{selectcurrency} .= "$_\n" }

  $form->{currency} ||= $form->{defaultcurrency};

  print qq|
<!--
<table width=100%>
<tr>
   <td valign=top>
     <table>
        <tr>
          <th align=right>|.$locale->text('Department').qq|</th>
	  <td><select name=department>|.$form->select_option($form->{selectdepartment}, $form->{department},1).qq|</select></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('AP').qq|</th>
	  <td><select name=AP>|.$form->select_option($form->{selectAP}, $form->{AP}).qq|</td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Payment').qq|</th>
	  <td><select name=AP_paid>|.$form->select_option($form->{selectAP_paid}, $form->{AP_paid}).qq|</td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Memo').qq|</th>
	  <td><input type=text size=10 name=memo value='$form->{memo}'></td>
        </tr>
     </table>
   </td>
   <td valign=top>
     <table>
        <tr>
          <th align=right>|.$locale->text('Date').qq|</th>
          <td><input type=text size=11 name=transdate title='$myconfig{dateformat}' value='$form->{transdate}'></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Currency').qq|</th>
	  <td><select name=currency>|.$form->select_option($form->{selectcurrency}, $form->{currency}).qq|</td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Source').qq|</th>
	  <td><input type=text size=10 name=source value='$form->{source}'></td>
        </tr>
        <tr>
          <th align=right>|.$locale->text('Amount').qq|</th>
	  <td><input type=text size=10 name=amount value='$form->{paid_total}'></td>
        </tr>

     </table>
   </td>
</tr>
</table>
-->
|;

  my $where = qq|(1 = 1)|;
  $name = $form->like(lc $form->{name});
  $where .= qq| AND LOWER(v.name) LIKE '$name'| if $form->{name};
  $where .= qq| AND ap.transdate >= '$form->{fromdate}'| if $form->{fromdate};
  $where .= qq| AND ap.transdate <= '$form->{todate}'| if $form->{todate};
  $where .= qq| AND ap.department_id = $form->{department_id}| if $form->{department};

  for (qw(name fromdate todate petty_cash_vendor department department_id)){ $form->hide_form($_) }

  print $locale->text('Vendor') . ":  $form->{name}<br>" if $form->{name};
  print $locale->text('From') . ":  $form->{fromdate}<br>" if $form->{fromdate};
  print $locale->text('To') . ":  $form->{todate}<br>" if $form->{todate};
  my @columns = qw(invnumber name transdate duedate amount paid);
  $form->{sort} = "invnumber" if !$form->{sort};
  $form->{oldsort} = 'none' if !$form->{oldsort};
  $form->{direction} = 'ASC' if !$form->{direction};
  @columns = $form->sort_columns(@columns);
  
  my %ordinal = (	invnumber => 1, 
			name => 2, 
			transdate => 3, 
			duedate => 4, 
			amount => 5,
			paid => 6);

  my $sort_order = $form->sort_order(\@columns, \%ordinal);
  splice @columns, 0,0, 'id';

$form->{l_id} = 'Y';
$form->{l_invnumber} = 'Y';
$form->{l_name} = 'Y';
$form->{l_transdate} = 'Y';
$form->{l_duedate} = 'Y';
$form->{l_amount} = 'Y';
$form->{l_paid} = 'Y';

  foreach $item (@columns) {
     if ($form->{"l_$item"} eq 'Y'){
       push @column_index, $item;
       $callback .= "&l_$item=Y";
     }
  }
  $callback .= "&l_subtotal=$form->{l_subtotal}";
  $href = $callback;
  $form->{callback} = $form->escape($callback,1);

  my $query = qq|
		SELECT ap.id, ap.invnumber, 
		ap.transdate, ap.duedate, v.name, 
		ap.amount - ap.paid AS amount
		FROM ap
		JOIN vendor v ON (v.id = ap.vendor_id)
		WHERE $where
		AND ap.vendor_id <> $form->{petty_cash_vendor_id}
		AND ap.amount - ap.paid <> 0
		AND ap.old_vendor_id = 0
		ORDER BY $form->{sort} $form->{direction}
  |;
  $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

  $form->{deselect} = 1 if !$form->{deselect};
  $form->{allbox_select} = 0 if !$form->{allbox_select};

  $form->{allbox_select} = ($form->{allbox_select}) ? "checked" : "";
  $action = ($form->{deselect}) ? "deselect_all" : "select_all";

  $column_header{id} = qq|<th><input name="allbox_select" type=checkbox class=checkbox value="1" $form->{allbox_select} onChange="CheckAll(); javascript:document.forms[0].submit()" ><input type=hidden name=action value="$action"></th>|;

  $column_header{invnumber} = qq|<th><a class=listheading href=$href&sort=invnumber>|.$locale->text('Invoice').qq|</a></th>|;
  $column_header{name} = qq|<th><a class=listheading href=$href&sort=name>|.$locale->text('Name').qq|</a></th>|;
  $column_header{transdate} = qq|<th><a class=listheading href=$href&sort=transdate>|.$locale->text('Date').qq|</a></th>|;
  $column_header{duedate} = qq|<th><a class=listheading href=$href&sort=duedate>|.$locale->text('Due Date').qq|</a></th>|;
  $column_header{amount} = qq|<th><a class=listheading href=$href&sort=amount>|.$locale->text('Amount').qq|</a></th>|;
  $column_header{paid} = qq|<th>|.$locale->text('Paid').qq|</a></th>|;

  $form->error($query) if $form->{l_sql};

  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  $sth = $dbh->prepare($query);
  $sth->execute || $form->dberror($query);

  print qq|<table width=100%><tr class=listheading>|;
  for (@column_index) { print "\n$column_header{$_}" }
  print qq|</tr>|;

  my $amount_total = 0;
  my $paid_total = 0;

  my $i = 1; my $j = 1;
  while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
     $j++; $j %= 2;

     $form->{"checked_$i"} = ($form->{"checked_$i"}) ? "checked" : "";
     $column_data{id} = qq|<td align=center><input type=checkbox name="checked_$i" $form->{"checked_$i"}></td>|;
     $column_data{invnumber} = qq|<td>$ref->{invnumber}</td>|;
     $column_data{name} = qq|<td>$ref->{name}</td>|;
     $column_data{transdate} = qq|<td align=right>$ref->{transdate}</td>|;
     $column_data{duedate} = qq|<td align=right>$ref->{duedate}</td>|;
     $column_data{amount} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{amount}, $form->{precision}).qq|</td>|;
     if ($form->{"id_$i"} eq $ref->{id}){
        if ($form->{"checked_$i"}){
            $form->{"paid_$i"} = $form->format_amount(\%myconfig, $ref->{amount}, 2);
        } else {
	    $form->{"paid_$i"} = 0;
        }
     } else {
        $form->{"paid_$i"} = 0;
     }
     $column_data{paid} = qq|<td align=right><input type=text size=10 name="paid_$i" value='$form->{"paid_$i"}' READONLY></td>|;
     print qq|<input type=hidden name="id_$i" value="$ref->{id}">\n|;
     print qq|<input type=hidden name="invnumber_$i" value="$ref->{invnumber}">\n|;
     print qq|<tr class=listrow$j>|;
     for (@column_index) { print qq|\n$column_data{$_}| };
     print qq|</tr>|;
     $amount_total += $ref->{amount};
     $paid_total += $form->parse_amount(\%myconfig, $form->{"paid_$i"});
     $i++;
  }
  print qq|<input type=hidden name=rowcount value=$i>\n|;
  for (@column_index) { $column_data{$_} = qq|<td>&nbsp;</td>| };
  print qq|<tr class=listtotal>|;
  $column_data{amount} = qq|<th class=listtoal align=right>|.$form->format_amount(\%myconfig, $amount_total, $form->{precision}).qq|</th>|;
  $column_data{paid} = qq|<th class=listtoal align=right>|.$form->format_amount(\%myconfig, $paid_total, $form->{precision}).qq|</th>|;
  for (@column_index) { print qq|\n$column_data{$_}| }
  print qq|</tr></table>|;


  print qq|<table width=100%>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<br>
<input class=submit type=submit name=action value="|.$locale->text('Update').qq|">
<input class=submit type=submit name=action value="|.$locale->text('Move to').qq|">
 <b>$form->{petty_cash_vendor_name}</b>|;

  $form->{nextsub} = 'form_header';
  $form->hide_form(qw(nextsub path login));

  print qq|
</form>
</body>
</html>
|;

}

sub calc_total {
   $form->{paid_total} = 0;
   for $i (1 .. $form->{rowcount} - 1){
      $form->{paid_total} += $form->parse_amount(\%myconfig, $form->{"paid_$i"}) if $form->{"checked_$i"}; 
   }
}
sub update {
  &calc_total;
  &form_header;
}

sub deselect_all {
  &calc_total;
  &form_header;
}

sub select_all {
  &calc_total;
  &form_header;
}

sub move_to {
  ($form->{petty_cash_vendor_name}, $form->{petty_cash_vendor_id}) = split(/--/, $form->{petty_cash_vendor});
  my $dbh = $form->dbconnect(\%myconfig);
  for $i (1 .. $form->{rowcount} - 1){
     if ($form->{"checked_$i"}){
	my ($old_vendor_name) = $dbh->selectrow_array(qq|
		SELECT name FROM vendor 
		WHERE id = (SELECT vendor_id FROM ap WHERE id = $form->{"id_$i"})
	|);
	$dbh->do(qq|
		UPDATE ap SET 
		  old_vendor_id = vendor_id,
		  notes = '$old_vendor_name',
		  vendor_id = $form->{petty_cash_vendor_id}
		WHERE id = $form->{"id_$i"}|
	);
        $form->info(qq|Moved invoice $form->{"invnumber_$i"} to petty cash vendor\n|);
     }
  }
}

#######
# EOF
#######

