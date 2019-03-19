1;

sub continue { &{$form->{nextsub}} };

sub fuse_pos {

  my $dbh = $form->dbconnect_noauto(\%myconfig);
  use DBIx::Simple;
  my $db = DBIx::Simple->connect($dbh);

  $form->header;
  my $po_list;
  if ($form->{rowcount}){
     for (1 .. $form->{rowcount}){
	if ($form->{"id_$_"}){
	   #print qq|PO: $form->{"po_$_"}<br/>|;
	   $po_list .= qq|$form->{"po_$_"},|;
	}
     }
     chop $po_list;

     $form->error('No POs selected ...') if !$po_list;

     print qq|<h1>Following POs have been fused into a new one</h1>|;
     my $query = qq|SELECT oe.id, oe.ordnumber, oe.transdate, vc.name, oe.amount
			FROM oe
			JOIN vendor vc ON (vc.id = oe.vendor_id)
			WHERE oe.id IN ($po_list)
			ORDER BY oe.ordnumber
		|;
     my @rows = $db->query($query)->hashes;

     print qq|<table border=0 cellspacing=2 cellpadding=2>
<tr class="listheading">
<th>PO Number</th>
<th>Company</th>
<th>Date</th>
<th>Amount</th>
</tr>
|;

     my $i = 1;
     for (@rows){
   	print qq|<tr class=listrow0>|;
	print qq|<td>$_->{ordnumber}</td>|;
	print qq|<td>$_->{name}</td>|;
	print qq|<td>$_->{transdate}</td>|;
	print qq|<td align="right">$_->{amount}</td>|;
	print qq|</tr>\n|;
	$i++;
     }
     print qq|</table>|;

     $query = qq|UPDATE oe SET closed = '1' WHERE id IN ($po_list)|;
     $dbh->do($query);

     $query = qq|
	SELECT i.parts_id, i.description, i.unit, i.qty, i.sellprice, c.netweight, c.grossweight, p.partnumber,
		i.sellprice2, i.lotnum, i.expiry, i.warehouse_id, i.internal_freight, i.fob_price,
		i.shipping_freight, i.shipping_insurance, i.cif_price, i.advaloren, i.fodinfa, i.customs_price,
		i.total_expenses, i.warehouse_price, i.cb2
	FROM orderitems i
	JOIN parts p ON (p.id = i.parts_id)
	LEFT JOIN cargo c ON (c.trans_id = i.id)
	WHERE i.trans_id IN ($po_list)
     |;
     @rows = $db->query($query)->hashes;

     $newform = new Form;

     my $vendor_id = $db->query("SELECT id FROM vendor WHERE UPPER(name)='ATVER CORP'")->list;
     $newform->{type} = 'purchase_order';
     $newform->{formname} = 'purchase_order';
     $newform->{defaultcurrency} = 'USD';
     $newform->{currency} = 'USD';
     $newform->{oldcurrency} = 'USD';
     $newform->{vc} = 'vendor';
     $newform->{oldtransdate} = $newform->current_date(\%myconfig);
     $newform->{transdate} = $newform->current_date(\%myconfig);
     $newform->{vendor_id} = $vendor_id;
     $newform->{oldvendor} = "ATVER CORP--$vendor_id"; 
     $newform->{vendor} = "ATVER CORP--$vendor_id"; 

     $i = 1;
     for my $row (@rows){
	  $newform->{"id_$i"} = $row->{parts_id};
	  $newform->{"description_$i"} = $row->{description};
	  $newform->{"unit_$i"} = $row->{unit};
	  $newform->{"qty_$i"} = $row->{qty};
	  $newform->{"sellprice_$i"} = $row->{sellprice};
	  $newform->{"netweight_$i"} = $row->{netweight};
	  $newform->{"grossweight_$i"} = $row->{grossweight};
	  $newform->{"partnumber_$i"} = $row->{partnumber};
	  $newform->{"sellprice2_$i"} = $row->{sellprice2};
	  $newform->{"lotnum_$i"} = $row->{lotnum};
	  $newform->{"expiry_$i"} = $row->{expiry};
	  $newform->{"warehouse_id_$i"} = $row->{warehouse_id};
	  $newform->{"internal_freight_$i"} = $row->{interal_freight};
	  $newform->{"fob_price_$i"} = $row->{fob_price};
	  $newform->{"shipping_freight_$i"} = $row->{shipping_freight};
	  $newform->{"shipping_insurance_$i"} = $row->{shipping_insurance};
	  $newform->{"cif_price_$i"} = $row->{cif_price};
	  $newform->{"advaloren_$i"} = $row->{advaloren};
	  $newform->{"fodinfa_$i"} = $row->{fodinfa};
	  $newform->{"customs_price_$i"} = $row->{customs_price};
	  $newform->{"total_expenses_$i"} = $row->{total_expenses};
	  $newform->{"warehouse_price_$i"} = $row->{warehouse_price};
	  $newform->{"cb2_$i"} = $row->{cb2};
          $i++;
     }
     $newform->{rowcount} = $i;


     use SL::OE;
     OE->save(\%myconfig, \%$newform);

  }
  $dbh->commit;
  $dbh->disconnect;
}

sub po_list {
   $form->header;
   $form->{fromdate} = $form->current_date(\%myconfig);
   $form->{todate} = $form->current_date(\%myconfig);
   print qq|<h1>Fuse POs</h1>
<form action="po2.pl" method="get">|.
$locale->text('PO Number') . 
qq| <input type=text size=10 name=ponumber1 value="$form->{po_number1}"> 
- <input type=text size=10 name=ponumber2 value="$form->{po_number2}"><br/>|.
$locale->text('From') . qq| <input type=text size=12 name=fromdate value="$form->{fromdate}" title="$myconfig{dateformat}">|.
$locale->text('To') . qq| <input type=text size=12 name=todate value="$form->{todate}" title="$myconfig{dateformat}">
<hr/>
<input type=hidden name=nextsub value=po_list>
<input type=submit class=submit name=action value=Continue>
<input type=submit class=submit name=action value="Fuse POs">
|;

   use DBIx::Simple;
   my $dbh = $form->dbconnect(\%myconfig);
   my $db = DBIx::Simple->connect($dbh);

   my $query = qq|
	SELECT oe.id, oe.ordnumber, vc.name, oe.transdate, oe.amount
	FROM oe
	JOIN vendor vc ON (oe.vendor_id = vc.id)
	WHERE quotation = '0'
	AND transdate BETWEEN ? AND ?
	AND closed = '0'
	ORDER BY 1, 2
   |;
   my @rows = $db->query($query, $form->{fromdate}, $form->{todate})->hashes;

   print qq|<table border=0 cellspacing=2 cellpadding=2>
<tr class="listheading">
<th>&nbsp;</th>
<th>PO Number</th>
<th>Company</th>
<th>Date</th>
<th>Amount</th>
</tr>
|;

   my $i = 1;
   for (@rows){
   	print qq|<tr class=listrow0>|;
	print qq|<td><input type=checkbox name="id_$i" value="1"></td>|;
	print qq|<input type=hidden name=po_$i value="$_->{id}">|;
	print qq|<td>$_->{ordnumber}</td>|;
	print qq|<td>$_->{name}</td>|;
	print qq|<td>$_->{transdate}</td>|;
	print qq|<td align="right">$_->{amount}</td>|;
	print qq|</tr>\n|;
	$i++;
   }
   $i--;
   print qq|<input type=hidden name=rowcount value=$i>\n|;
   $form->hide_form(qw(path login));
   print qq|</form>|;
}

