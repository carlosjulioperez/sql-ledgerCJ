require "$form->{path}/lib.pl";
require "$form->{path}/mylib.pl";

1;

#===================================
#
# Reporte de Retenciones
#
#==================================
#-------------------------------
sub continue { &{$form->{nextsub}} };
#-------------------------------

sub print_form_text {
   my ($prompt, $cname, $size) = @_;
   print qq|<tr><th align=right>$prompt</th><td><input type=name name=$cname size=$size value='$form->{"$cname"}'></td></tr>|;
}

sub end_table {
  print qq|</table>|;
}

sub search {
   $form->{title} = $locale->text('Reporte de Retenciones');
   &print_title;
   &start_form;
   &start_table;

   &bld_employee;

  &print_form_text('Proveedor','proveedor', 20);
  &print_form_text('Tipo Doc','code', 3);
  &print_form_text('Sec. Retención', 'secret', 7);
  &print_form_text('Tipo Retención', 'tiporet', 3);
  &print_date('datefrom','Fact Date From');
  &print_date('dateto','Fact Date To');

   print qq|<tr><th align=right>| . $locale->text('Incluir en Reporte') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), 'checked', '<br>');
   &print_checkbox('l_proveedor', $locale->text('Proveedor'), 'checked', '<br>');
   &print_checkbox('l_estab', $locale->text('Estab. Factura'), 'checked', '<br>');
   &print_checkbox('l_ptoemi', $locale->text('Pto. Emision Factura'), 'checked', '<br>');
   &print_checkbox('l_sec', $locale->text('Secuencial Factura'), 'checked', '<br>');
   &print_checkbox('l_code', $locale->text('Tipo Doc'), 'checked', '<br>');
   &print_checkbox('l_transdate', $locale->text('Fecha Factura'), '', '<br>');
   &print_checkbox('l_tiporet_id', $locale->text('Tipo Ret.'), 'checked', '<br>');
   &print_checkbox('l_estabret', $locale->text('Estab. Retencion'),'', '<br>');
   &print_checkbox('l_ptoemiret', $locale->text('Pto. Emision Retencion'), '', '<br>');
   &print_checkbox('l_secret', $locale->text('Secuencial Retencion'), 'checked', '<br>');
   &print_checkbox('l_transdateret', $locale->text('Fecha Retencion'), 'checked', '<br>');
   &print_checkbox('l_base', $locale->text('Sumatoria / Base'), 'checked', '<br>');
   &print_checkbox('l_base0', $locale->text('Base igual a 0'),'', '<br>');
   &print_checkbox('l_based0', $locale->text('Base Diferente de 0'), '', '<br>');
   &print_checkbox('l_baseni', $locale->text('Base No IVA'), '', '<br>');
   &print_checkbox('l_porcret', $locale->text('% Ret'), 'checked', '<br>');
   &print_checkbox('l_valret', $locale->text('Valor Ret'), 'checked', '<br>');
   &print_checkbox('l_subtotal', $locale->text('Subtotal'), '', '<br>');
   &print_checkbox('l_csv', $locale->text('CSV'), '', '<br>');

   print qq|</td></tr>|;
   &end_table;
   print('<hr size=3 noshade>');
   $form->{nextsub} = 'report';
   &print_hidden('nextsub');
   &add_button('Continue');
   &end_form;
}

#-------------------------------
sub report {
  # callback to report list
   my $callback = qq|$form->{script}?action=report|;
   for (qw(path login sessionid)) { $callback .= "&$_=$form->{$_}" }

   my $proveedor = $form->like(lc $form->{proveedor});
   my $code = $form->like(lc $form->{code});
   my $tiporet = $form->like(lc $form->{tiporet});
   my $secret = $form->like(lc $form->{secret});

   my $where = qq| (1 = 1)|;
   $where .= qq| AND LOWER(v.name) LIKE '$proveedor' | if $form->{proveedor};
   $where .= qq| AND LOWER(t.code) LIKE '$code' | if $form->{code};
   $where .= qq| AND LOWER(r.tiporet_id) LIKE '$tiporet' | if $form->{tiporet};
   $where .= qq| AND LOWER(r.secret) LIKE '$secret' | if $form->{secret};
   $where .= qq| AND r.transdateret >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND r.transdateret <= '$form->{dateto}'| if $form->{dateto};

   @columns = qw(proveedor estab ptoemi sec code transdate tiporet_id estabret ptoemiret secret transdateret base base0 based0 baseni porcret valret);
   # if this is first time we are running this report.
   $form->{sort} = 'proveedor' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	proveedor => 1,
			estab => 2,
			ptoemi => 3,
			sec => 4,
			code => 5,
			transdate => 6,
			tiporet_id => 7,
			estabret => 8,
			ptoemiret => 9,
			secret => 10,
			transdateret => 11,
			base => 12,
			base0 => 13,
			based0 => 14,
			baseni => 15,
			porcret => 16,
			valret => 17
   );

   my $sort_order = $form->sort_order(\@columns, \%ordinal);


   foreach (qw(l_subtotal datefrom dateto proveedor code tiporet secret)){
       $callback .= "&$_=$form->{$_}";
   }
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);




   $query = qq|
      SELECT 	v.name as proveedor,
                r.estab,
                r.ptoemi,
                r.sec,
                t.code,
                r.transdate,
                r.tiporet_id,
                r.estabret,
              	r.ptoemiret,
                r.secret,
                r.transdateret,
                (r.base0 + r.based0 + r.baseni) as base,
                r.base0,
                r.based0,
                r.baseni,
                r.porcret,
                r.valret
      FROM retenc r
      INNER JOIN vendor v ON
		r.vendor_id = v.id
      INNER JOIN tipodoc t ON
		r.tipodoc_id = t.id
      WHERE $where
      ORDER BY $form->{sort} $form->{direction}
   |;

   # No. columns should always come first
   splice @columns, 0, 0, 'no';

   # Select columns selected for report display
   foreach $item (@columns) {
     if ($form->{"l_$item"} eq "Y") {
       push @column_index, $item;

       # add column to href and callback
       $callback .= "&l_$item=Y";
     }
   }
   
   
#   $callback .= "&l_subtotal=$form->{l_subtotal}";

   foreach (qw(l_subtotal datefrom dateto proveedor code secret tiporet)){
       $callback .= "&$_=$form->{$_}";
   }

   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{proveedor} 		= rpt_hdr('proveedor', $locale->text('Proveedor'), $href);
   $column_header{estab} 		= rpt_hdr('estab', $locale->text('F.estab.'), $href);
   $column_header{ptoemi}  		= rpt_hdr('ptoemi', $locale->text('F.proEmi'), $href);
   $column_header{sec}  		= rpt_hdr('sec', $locale->text('F.sec'), $href);
   $column_header{code}  		= rpt_hdr('code', $locale->text('Tipo Doc'), $href);
   $column_header{transdate}  		= rpt_hdr('transdate', $locale->text('F.fecha'), $href);
   $column_header{tiporet_id}  		= rpt_hdr('tiporet_id', $locale->text('TipoRet'), $href);
   $column_header{estabret} 		= rpt_hdr('estabret', $locale->text('estabRet'), $href);
   $column_header{ptoemiret}  		= rpt_hdr('ptoemiret', $locale->text('proEmiRet'), $href);
   $column_header{secret}  		= rpt_hdr('secret', $locale->text('secRet'), $href);
   $column_header{transdateret}  	= rpt_hdr('transdateret', $locale->text('fechaRet'), $href);
   $column_header{base}  		= rpt_hdr('base', $locale->text('Base'), $href);
   $column_header{base0}  		= rpt_hdr('base', $locale->text('Base 0'), $href);
   $column_header{based0}  		= rpt_hdr('base', $locale->text('Base <> 0'), $href);
   $column_header{baseni}  		= rpt_hdr('base', $locale->text('Base No Iva'), $href);
   $column_header{porcret}  		= rpt_hdr('porcret', $locale->text('porcret'), $href);
   $column_header{valret}  		= rpt_hdr('valret', $locale->text('valret'), $href);

   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'retenciones');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('Reporte de Retenciones');
   &print_title;
   &print_criteria('proveedor','Proveedor');
   &print_criteria('sec', 'F.Sec');
   &print_criteria('transdate', 'F.fecha');
   &print_criteria('tiporet_id', 'Tipo Ret');
   &print_criteria('secret', 'SecRet');
   &print_criteria('transdateret', 'F.Reten');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|;


   # Subtotal and total variables
   my $valret_subtotal = 0;
   my $valret_total = 0;

   my $base_subtotal = 0;
   my $base_total = 0;

   my $base0_subtotal = 0;
   my $base0_total = 0;

   my $based0_subtotal = 0;
   my $based0_total = 0;

   my $baseni_subtotal = 0;
   my $baseni_total = 0;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';

   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	$groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
	if ($form->{l_subtotal}){
	   if ($groupbreak ne $ref->{$form->{sort}}){
		$groupbreak = $ref->{$form->{sort}};
		# prepare data for footer
                $column_data{no}   		= rpt_txt('&nbsp;');
                $column_data{proveedor}	        = rpt_txt('&nbsp;');
                $column_data{estab}		= rpt_txt('&nbsp;');
                $column_data{ptoemi}            = rpt_txt('&nbsp;');
                $column_data{sec}           	= rpt_txt('&nbsp;');
                $column_data{code}              = rpt_txt('&nbsp;');
                $column_data{transdate}    	= rpt_txt('&nbsp;');
                $column_data{tiporet_id}   	= rpt_txt('&nbsp;');
                $column_data{estabret}	        = rpt_txt('&nbsp;');
                $column_data{ptoemiret}         = rpt_txt('&nbsp;');
                $column_data{secret}    	= rpt_txt('&nbsp;');
                $column_data{transdateret}      = rpt_txt('&nbsp;');
                $column_data{base}    	        = rpt_txt($base_subtotal);
                $column_data{base0}    	        = rpt_txt($base0_subtotal);
                $column_data{based0}   	        = rpt_txt($based0_subtotal);
                $column_data{baseni}   	        = rpt_txt($baseni_subtotal);
                $column_data{porcret}    	= rpt_txt('&nbsp;');
                $column_data{valret}    	= rpt_int($valret_subtotal);

		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$valret_subtotal = 0;
		$base_subtotal = 0;
        	$base0_subtotal = 0;
		$based0_subtotal = 0;
		$baseni_subtotal = 0;
	   }
	}

	$column_data{no}   		= rpt_txt($no);
   	$column_data{proveedor}		= rpt_txt($ref->{proveedor});
   	$column_data{estab}		= rpt_txt($ref->{estab});
   	$column_data{ptoemi} 	        = rpt_txt($ref->{ptoemi});
   	$column_data{sec}             	= rpt_txt($ref->{sec});
   	$column_data{code}             	= rpt_txt($ref->{code});
   	$column_data{transdate}    	= rpt_txt($ref->{transdate});
   	$column_data{tiporet_id}   	= rpt_txt($ref->{tiporet_id});
   	$column_data{estabret}		= rpt_txt($ref->{estabret});
   	$column_data{ptoemiret}         = rpt_txt($ref->{ptoemiret});
   	$column_data{secret}    	= rpt_txt($ref->{secret});
   	$column_data{transdateret}    	= rpt_txt($ref->{transdateret});
   	$column_data{base}    		= rpt_txt($ref->{base});
   	$column_data{base0}    		= rpt_txt($ref->{base0});
   	$column_data{based0}   		= rpt_txt($ref->{based0});
   	$column_data{baseni}   		= rpt_txt($ref->{baseni});
   	$column_data{porcret}    	= rpt_txt($ref->{porcret});
   	$column_data{valret}    	= rpt_int($ref->{valret});

	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$valret_subtotal += $ref->{valret};
	$valret_total += $ref->{valret};

	$base_subtotal += $ref->{base};
	$base_total += $ref->{base};

	$base0_subtotal += $ref->{base0};
	$base0_total += $ref->{base0};

	$based0_subtotal += $ref->{based0};
	$based0_total += $ref->{based0};

	$baseni_subtotal += $ref->{baseni};
	$baseni_total += $ref->{baseni};



   }

   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{proveedor}	= rpt_txt('&nbsp;');
   $column_data{estab}		= rpt_txt('&nbsp;');
   $column_data{ptoemi}         = rpt_txt('&nbsp;');
   $column_data{sec}           	= rpt_txt('&nbsp;');
   $column_data{code}           = rpt_txt('&nbsp;');
   $column_data{transdate}    	= rpt_txt('&nbsp;');
   $column_data{tiporet_id}   	= rpt_txt('&nbsp;');
   $column_data{estabret}	= rpt_txt('&nbsp;');
   $column_data{ptoemiret}      = rpt_txt('&nbsp;');
   $column_data{secret}    	= rpt_txt('&nbsp;');
   $column_data{transdateret}   = rpt_txt('&nbsp;');
   $column_data{base}    	= rpt_txt($base_subtotal);
   $column_data{base0}    	= rpt_txt($base0_subtotal);
   $column_data{based0}   	= rpt_txt($based0_subtotal);
   $column_data{baseni}   	= rpt_txt($baseni_subtotal);
   $column_data{porcret}    	= rpt_txt('&nbsp;');
   $column_data{valret}    	= rpt_int($valret_subtotal);

   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total

   $column_data{base}   		= rpt_dec($base_total,2);
   $column_data{base0}   		= rpt_dec($base0_total,2);
   $column_data{based0}   		= rpt_dec($based0_total,2);
   $column_data{baseni}   		= rpt_dec($baseni_total,2);
   $column_data{valret}   		= rpt_dec($valret_total,2);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;

   $sth->finish;
   $dbh->disconnect;
}

