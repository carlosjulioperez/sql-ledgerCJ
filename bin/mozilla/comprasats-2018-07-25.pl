#=====================================================================
# Sample for SQL-Ledger ERP
# Copyright (c) 2007
#
#  Author: Armaghan Saqib
#     Web: http://www.ledger123.com
#
#  Version: 0.10
#
#======================================================================
1;

#---------------------------------------
sub continue { &{$form->{nextsub}} };

#########################################################################
## These one liners hide the clutter of html from report processing code.
## This helps newbies to modify the report.
#########################################################################
sub begin_table {
  print qq|<table width=100%>|;
}

sub end_table {
  print qq|</table>|;
}

sub print_header {
  $form->{title} = shift;
  $form->header;
  print qq|<body><table width=100%><tr><th class=listtop>$form->{title}</th></tr></table><br>|;
}

sub begin_form {
  print qq|<form method=post action=$form->{script}>|;
}

sub end_form {
  print qq|<input type=submit class=submit name=action value="|.$locale->text('Continue').qq|">|;
  $form->hide_form(qw(title path nextsub login));
  print qq|</form>|;
}

sub print_form_text {
   my ($prompt, $cname, $size) = @_;
   print qq|<tr><th align=right>$prompt</th><td><input type=name name=$cname size=$size value='$form->{"$cname"}'></td></tr>|;
}

sub print_form_date {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><input type=name name=$cname size=11 value='$form->{"$cname"}' title='$myconfig{dateformat}'></td></tr>|;
}

sub end_page {
  print qq|</body></html>|;
}

sub begin_heading_row {
   print qq|<tr class=listheading>|;
}

sub begin_data_row {
   my $i = shift;
   print qq|<tr class=listrow$i>|;
}

sub begin_total_row {
   print qq|<tr class=listtotal>|;
}

sub end_row {
   print qq|</tr>|;
}

sub print_heading {
   my $prompt = shift;
   print qq|<th>$prompt</th>|;
}

sub print_text {
   my $data = shift;
   print qq|<td>$data</td>|;
}

sub print_integer {
   my $data = shift;
   print qq|<td align=right>$data</td>|;
}

sub print_number {
   my $data = shift;
   print qq|<td align=right>| . $form->format_amount(\%myconfig, $data, 2) . qq|</td>|;
}

sub print_select {
   my ($prompt, $cname) = @_;
   print qq|<tr><th align=right>$prompt</th><td><select name=$cname>$form->{"select$cname"}</select></td></tr>|;
}

sub select_vendor {
   my $query = qq|SELECT gifi_accno, name FROM vendor ORDER BY name|;
   my $dbh = $form->dbconnect(\%myconfig);
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);
   $form->{selectvendor} = "<option>\n";
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
      $form->{selectvendor} .= qq|<option value="$ref->{name}--$ref->{gifi_accno}">$ref->{name}\n|;
   }
   $dbh->disconnect;
}


###########################################################################
##
##  ACTUAL REPORT PROCEDURES
##
##  These two procedures 'customer_search' and 'customer_report' implement
##  a very simple report.
##
##  Copy these procedures and rename appropriatly to create as many
##  reports as you like within this single .pl file.
##
###########################################################################
#---------------------------------------
sub comprasats_search {
  print_header('Compras ATS');
  begin_form;
  begin_table;

  select_vendor;
  print_select('Vendor', 'vendor');

  $form->{codRet} = ''; # default for search form.
  print_form_text('Codigo de Retencion', 'codRet', 5);
  print_form_text('Tipo de Documento', 'tipoDoc', 2);
  print_form_date('From', 'datefrom');
  print_form_date('To', 'dateto');
  end_table;
  print qq|<br><hr>|;
  $form->{nextsub} = 'comprasats_report';
  end_form;
  end_page;
}

#---------------------------------------
sub comprasats_report {
   my $dbh = $form->dbconnect(\%myconfig);
   print_header('Compras ATS');

   # Build WHERE cluase
   my $where = qq| (1 = 1)|;
  
   my ($vendor, $vendor_gifi_accno) = split(/--/, $form->{vendor});
   $vendor_gifi_accno *= 1;
   
   $where .= qq| AND rt.idprov LIKE '%$vendor_gifi_accno%'| if $form->{vendor};
   #$where .= qq| AND (LOWER(p.partnumber) LIKE '$partnumber')| if $form->{partnumber};
   $where .= qq| AND rt.tiporet_id = '$form->{codRet}'| if $form->{codRet};
   $where .= qq| AND rt.tipodoc_id = '$form->{tipoDoc}'| if $form->{tipoDoc};
   $where .= qq| AND rt.transdate >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND rt.transdate <= '$form->{dateto}'| if $form->{dateto};
 
   print qq|<table>|;
   print qq|<tr><th colspan='2'>Este Reporte esta filtrado por los siguientes campos:</th></tr>|;
   print qq|<tr><th>Vendor</th><td>$vendor</td></tr>| if $form->{vendor};
   print qq|<tr><th>RUC</th><td>$vendor_gifi_accno</td></tr>| if $form->{vendor};
   print qq|<tr><th>Cod Retencion</th><td>$form->{codRet}</td></tr>| if $form->{codRet};
   print qq|<tr><th>Tipo Documento</th><td>$form->{tipoDoc}</td></tr>| if $form->{tipoDoc};
   print qq|<tr><th>From Date</th><td>$form->{datefrom}</td></tr>| if $form->{datefrom};
   print qq|<tr><th>To Date</th><td>$form->{dateto}</td></tr>| if $form->{dateto};
   print qq|</table>|;

   my $query = qq|
	SELECT 	rt.tiporet_id,
			rt.tipoid_id,
			rt.idprov,
			rt.tipodoc_id,
			rt.ordnumber,
			rt.estab,
			rt.ptoemi,
			rt.sec,
			rt.transdate,
			rt.porcret,
			rt.base0,
			rt.based0,
			rt.valret,
			rt.ordnumberret,
			rt.estabret,
			rt.ptoemiret,
			rt.secret,
			rt.transdateret,
			(	SELECT valret
				FROM retenc
				WHERE sec = rt.sec
				AND secret = rt.secret
				AND tiporet_id = '1'
			) AS retiva30,
			(	SELECT valret
				FROM retenc
				WHERE sec = rt.sec
				AND secret = rt.secret
				AND tiporet_id = '2'
			) AS retiva70,
			(	SELECT valret
				FROM retenc
				WHERE sec = rt.sec
				AND secret = rt.secret
				AND tiporet_id = '3'
			) AS retiva100

	FROM retenc rt   
	WHERE $where
	AND rt.tiporet_id <> '1'
	AND rt.tiporet_id <> '2'
	AND rt.tiporet_id <> '3'
	ORDER BY 1,2,3;
   |;

   #AND ar.customer_id = $ref->{customerid}
   #($ref->{secuencial})
   
   my $dbh = $form->dbconnect(\%myconfig);
   my $sth = $dbh->prepare($query); 
   $sth->execute || $form->dberror($query);
   #$sth->finish;
   
   $sec=$ref->{sec};
   $secret=$ref->{secret};

   #finalizo mi busqueda   
   
   begin_table;
   begin_heading_row;
   print_heading('No');
   print_heading('Sustento');
   print_heading('codRetAir');
   print_heading('tpIdProv');
   print_heading('IdProv');
   print_heading('tipoComp');
   print_heading('aut');
   print_heading('estab');
   print_heading('ptoEmi');
   print_heading('sec');
   print_heading('fechaEmiCom');
   print_heading('porcentaje');
   print_heading('base0');
   print_heading('baseGrav');
   print_heading('baseRet');
   print_heading('valRetAir');
   print_heading('autRet');
   print_heading('estabRet');
   print_heading('ptoEmiRet');
   print_heading('secRet');
   print_heading('fechaEmiRet');
   print_heading('Ret IVA 30');
   print_heading('Ret IVA 70');
   print_heading('Ret IVA 100');
   end_row;


   my $i = 0; my $j = 1; 
   my $subtotal_valret = 0;
   my $subtotal_retiva30 = 0;
   my $subtotal_retiva70 = 0;
   my $subtotal_retiva100 = 0;
   my $baseret = 0;
   my $numero = 0;
   my $sustento = "";

   
   $partnumber_group = 'none';
   while ($ref = $sth->fetchrow_hashref(NAME_lc)){
	# update totals etc
        $subtotal_valret += $ref->{valret};
        $subtotal_retiva30 += $ref->{retiva30};
        $subtotal_retiva70 += $ref->{retiva70};
        $subtotal_retiva100 += $ref->{retiva100};
        
        
        $baseret=$ref->{base0}+$ref->{based0};
        $numero++;
        $sustento="01";
   		my $str = sprintf("%03.0f", $numero);        
        if ($ref->{tiporet_id}==336)
        {
	        $sustento="08"
        }
        else
        {
	        if ($ref->{tipodoc_id}==41)
	        {
				$sustento="1"
	        }
	        else
	        {
		        if ($ref->{tiporet_id}==312)
		        {
					$sustento="06"
		        }
				else
				{
			        if ($ref->{tipodoc_id}==1)
			        {
						$sustento="1"        
			        }
					else			
			       	{
				       	$sustento="2"        
			       	}
		   		}
	   		}
		}        
	begin_data_row($i);
	
	print_text("compra$str");
	print_text($sustento);
	print_text($ref->{tiporet_id});
	print_text($ref->{tipoid_id});
	print_text($ref->{idprov});
	print_text($ref->{tipodoc_id});
	print_text($ref->{ordnumber});
	print_text($ref->{estab});
	print_text($ref->{ptoemi});
	print_text($ref->{sec});
	print_text($ref->{transdate});
	print_text($ref->{porcret});
	print_text($ref->{base0});
	print_text($ref->{based0});
	print_number($baseret);
	print_number($ref->{valret});
	print_text($ref->{ordnumberret});
	print_text($ref->{estabret});
	print_text($ref->{ptoemiret});
	print_text($ref->{secret});
	print_text($ref->{transdateret});
	print_number($ref->{retiva30});
	print_number($ref->{retiva70});
	print_number($ref->{retiva100});
	
	end_row;

	$i++; $i %= 2; $j++;
   }

   # print fotter
   begin_total_row;
   print_text('&nbsp;'); # blank cell
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_number($subtotal_valret);
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_text('&nbsp;');
   print_number($subtotal_retiva30);
   print_number($subtotal_retiva70);
   print_number($subtotal_retiva100);
   end_row;
   end_table;
}

###################
#
# EOF: reports.pl
#
###################

