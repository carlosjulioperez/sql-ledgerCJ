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

  &print_date('datefrom','Fact Date From');
  &print_date('dateto','Fact Date To');

   print qq|<tr><th align=right>| . $locale->text('Incluir en Reporte') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), '', '<br>');
   &print_checkbox('l_ruc', $locale->text('RUC'), 'checked', '<br>');
   &print_checkbox('l_anio', $locale->text('Año'), 'checked', '<br>');
   &print_checkbox('l_mes', $locale->text('Mes'), 'checked', '<br>');
   &print_checkbox('l_tipoid_id', $locale->text('Tipo ID Proveedor'), 'checked', '<br>');
   &print_checkbox('l_gifi_accno', $locale->text('ID Proveedor'), 'checked', '<br>');
   &print_checkbox('l_tipodoc_id', $locale->text('Tipo Doc'), 'checked', '<br>');
   &print_checkbox('l_ordnumber', $locale->text('Autorizacion Factura'), 'checked', '<br>');
   &print_checkbox('l_estab', $locale->text('Estab. Factura'), 'checked', '<br>');
   &print_checkbox('l_ptoemi', $locale->text('Pto. Emision Factura'), 'checked', '<br>');
   &print_checkbox('l_sec', $locale->text('Secuencial Factura'), 'checked', '<br>');
   &print_checkbox('l_transdate', $locale->text('Fecha Factura'), 'checked', '<br>');
   &print_checkbox('l_tiporet_id', $locale->text('Tipo Ret.'), 'checked', '<br>');
   &print_checkbox('l_porcret', $locale->text('% Ret'), 'checked', '<br>');
   &print_checkbox('l_base0', $locale->text('Base igual a 0'),'checked', '<br>');
   &print_checkbox('l_based0', $locale->text('Base Diferente de 0'), 'checked', '<br>');
   &print_checkbox('l_baseni', $locale->text('Base No IVA'), 'checked', '<br>');
   &print_checkbox('l_valret', $locale->text('Valor Ret'), 'checked', '<br>');
   &print_checkbox('l_ordnumberret', $locale->text('Autorizacion Retencion'), 'checked', '<br>');
   &print_checkbox('l_estabret', $locale->text('Estab. Retencion'),'checked', '<br>');
   &print_checkbox('l_ptoemiret', $locale->text('Pto. Emision Retencion'), 'checked', '<br>');
   &print_checkbox('l_secret', $locale->text('Secuencial Retencion'), 'checked', '<br>');
   &print_checkbox('l_transdateret', $locale->text('Fecha Retencion'), 'checked', '<br>');
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

   my $where = qq| (1 = 1)|;
   $where .= qq| AND r.transdateret >= '$form->{datefrom}'| if $form->{datefrom};
   $where .= qq| AND r.transdateret <= '$form->{dateto}'| if $form->{dateto};

   @columns = qw(ruc anio mes tipoid_id gifi_accno tipodoc_id ordnumber estab ptoemi sec transdate tiporet_id porcret base0 based0 baseni valret ordnumberret estabret ptoemiret secret transdateret);
   # if this is first time we are running this report.
   $form->{sort} = 'ruc' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	ruc => 1,
			tipodoc_id => 2,
			estab => 3,
			ptoemi => 4,
			sec => 5,
			transdate => 6,
			tiporet_id => 7,
			porcret => 8,
			base0 => 9,
			based0 => 10,
			baseni => 11,
			valret => 12,
			estabret => 13,
			ptoemiret => 14,
			secret => 15,
			transdateret => 16
   );

   my $sort_order = $form->sort_order(\@columns, \%ordinal);

   $query = qq|
      SELECT 	(select fldvalue
                from defaults
                where fldname ='businessnumber') AS ruc,
      		TO_CHAR(r.transdate, 'YYYY') AS anio,
      		TO_CHAR(r.transdate, 'MM') AS mes,
      		v.tipoid_id,
      		v.gifi_accno,
                r.tipodoc_id,
                r.ordnumber,
                r.estab,
                r.ptoemi,
                r.sec,
                r.transdate,
                r.tiporet_id,
                r.porcret,
                r.base0,
                r.based0,
                r.baseni,
                r.valret,
                r.ordnumberret,
                r.estabret,
              	r.ptoemiret,
                r.secret,
                r.transdateret
      FROM retenc r
      INNER JOIN vendor v ON
		r.vendor_id = v.id
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

   foreach (qw(l_subtotal datefrom dateto tipodoc_id secret tiporet)){
       $callback .= "&$_=$form->{$_}";
   }

   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   		= rpt_hdr('no', $locale->text('No.'));
   $column_header{ruc}                  = rpt_hdr('ruc', $locale->text('numeroRuc'), $href);
   $column_header{anio}		        = rpt_hdr('anio', $locale->text('anio'), $href);
   $column_header{mes}		        = rpt_hdr('mes', $locale->text('mes'), $href);
   $column_header{tipoid_id}	        = rpt_hdr('tipoid_id', $locale->text('tpIdProv'), $href);
   $column_header{gifi_accno}	        = rpt_hdr('gifi_accno', $locale->text('idProv'), $href);
   $column_header{tipodoc_id}  		= rpt_hdr('tipodoc_id', $locale->text('tipoComp'), $href);
   $column_header{ordnumber} 		= rpt_hdr('ordnumber', $locale->text('aut'), $href);
   $column_header{estab} 		= rpt_hdr('estab', $locale->text('estab'), $href);
   $column_header{ptoemi}  		= rpt_hdr('ptoemi', $locale->text('ptoEmi'), $href);
   $column_header{sec}  		= rpt_hdr('sec', $locale->text('sec'), $href);
   $column_header{transdate}  		= rpt_hdr('transdate', $locale->text('fechaEmiCom'), $href);
   $column_header{tiporet_id}  		= rpt_hdr('tiporet_id', $locale->text('codRetAir'), $href);
   $column_header{porcret}  		= rpt_hdr('porcret', $locale->text('porcentaje'), $href);
   $column_header{base0}  		= rpt_hdr('base0', $locale->text('base0'), $href);
   $column_header{based0}  		= rpt_hdr('based0', $locale->text('baseGrav'), $href);
   $column_header{baseni}  		= rpt_hdr('baseni', $locale->text('baseNoGrav'), $href);
   $column_header{valret}  		= rpt_hdr('valret', $locale->text('valRetAir'), $href);
   $column_header{ordnumberret} 	= rpt_hdr('ordnumberret', $locale->text('autRet'), $href);
   $column_header{estabret} 		= rpt_hdr('estabret', $locale->text('estabRet'), $href);
   $column_header{ptoemiret}  		= rpt_hdr('ptoemiret', $locale->text('ptoEmiRet'), $href);
   $column_header{secret}  		= rpt_hdr('secret', $locale->text('secRet'), $href);
   $column_header{transdateret}  	= rpt_hdr('transdateret', $locale->text('fechaEmiRet'), $href);

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
   &print_criteria('sec', 'F.Sec');
   &print_criteria('transdate', 'F.fecha');
   &print_criteria('tiporet_id', 'Tipo Ret');
   &print_criteria('secret', 'SecRet');
   &print_criteria('transdateret', 'F.Reten');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|;

   # print data
   my $i = 1; my $no = 1;
   my $groupbreak = 'none';
   
   my $valret_total;

   $tiporet_group = 'none';
   while (my $ref = $sth->fetchrow_hashref(NAME_lc)){
	if ($tiporet_group ne $ref->{tiporet_id}){
	   if ($tiporet_group ne 'none'){
		my $valretquery = qq|SELECT valret FROM retenc WHERE tiporet_id='$tiporet_group'|;
		my ($valretgrp) = $dbh->selectrow_array($valretquery);
   	   	# print group fotter
                $column_data{no}   		= rpt_txt('&nbsp;');
                $column_data{ruc}	        = rpt_txt('&nbsp;');
                $column_data{anio}	        = rpt_txt('&nbsp;');
                $column_data{mes}	        = rpt_txt('&nbsp;');
                $column_data{tipoid_id}	        = rpt_txt('&nbsp;');
                $column_data{gifi_accno}        = rpt_txt('&nbsp;');
                $column_data{tipodoc_id}        = rpt_txt('&nbsp;');
                $column_data{ordnumber}		= rpt_txt('&nbsp;');
                $column_data{estab}		= rpt_txt('&nbsp;');
                $column_data{ptoemi}            = rpt_txt('&nbsp;');
                $column_data{sec}           	= rpt_txt('&nbsp;');
                $column_data{transdate}    	= rpt_txt('&nbsp;');
                $column_data{tiporet_id}   	= rpt_txt('&nbsp;');
                $column_data{porcret}    	= rpt_txt('&nbsp;');
                $column_data{base0}    	        = rpt_txt('&nbsp;');
                $column_data{based0}   	        = rpt_txt('&nbsp;');
                $column_data{baseni}   	        = rpt_txt('&nbsp;');
                $column_data{valret}    	= rpt_int($valretgrp);
                $column_data{ordnumberret}	= rpt_txt('&nbsp;');
                $column_data{estabret}	        = rpt_txt('&nbsp;');
                $column_data{ptoemiret}         = rpt_txt('&nbsp;');
                $column_data{secret}    	= rpt_txt('&nbsp;');
                $column_data{transdateret}      = rpt_txt('&nbsp;');
           }

        $tiporet_group = $ref->{tiporet_id};

   	  if ($form->{datefrom}){
		my $opening_where = qq| (1 = 1)|;
                $opening_where .= qq| AND LOWER(r.tiporet_id) LIKE '$tiporet' | if $form->{tiporet};
                $opening_where .= qq| AND LOWER(r.secret) LIKE '$secret' | if $form->{secret};
       		$opening_where .= qq| AND r.transdateret < '$form->{datefrom}'|;

                my $valretquery = qq|SELECT SUM(0 - valret)
			FROM retenc r
			WHERE $opening_where|;
		my ($valretbal) = $dbh->selectrow_array($valretquery);

   	   }

	   # print opening balance
   	   if ($valretbal != 0){
     	      begin_data_row(1);
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
   	      end_row;
   	   }
          }


   	$form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&sessionid=$form->{sessionid}&callback=$form->{callback}|;
	$column_data{no}   		= rpt_txt($no);
   	$column_data{ruc}		= rpt_txt($ref->{ruc});
   	$column_data{anio}		= rpt_txt($ref->{anio});
   	$column_data{mes}		= rpt_txt($ref->{mes});
   	$column_data{tipoid_id}		= rpt_txt($ref->{tipoid_id});
   	$column_data{gifi_accno}	= rpt_txt($ref->{gifi_accno});
   	$column_data{tipodoc_id}       	= rpt_txt($ref->{tipodoc_id});
   	$column_data{ordnumber}		= rpt_txt($ref->{ordnumber});
   	$column_data{estab}		= rpt_txt($ref->{estab});
   	$column_data{ptoemi} 	        = rpt_txt($ref->{ptoemi});
   	$column_data{sec}             	= rpt_txt($ref->{sec});
   	$column_data{transdate}    	= rpt_txt($ref->{transdate});
   	$column_data{tiporet_id}   	= rpt_txt($ref->{tiporet_id});
   	$column_data{porcret}    	= rpt_txt($ref->{porcret});
   	$column_data{base0}    		= rpt_txt($ref->{base0});
   	$column_data{based0}   		= rpt_txt($ref->{based0});
   	$column_data{baseni}   		= rpt_txt($ref->{baseni});
   	$column_data{valret}    	= rpt_int($ref->{valret});
   	$column_data{ordnumberret}		= rpt_txt($ref->{ordnumberret});
   	$column_data{estabret}		= rpt_txt($ref->{estabret});
   	$column_data{ptoemiret}         = rpt_txt($ref->{ptoemiret});
   	$column_data{secret}    	= rpt_txt($ref->{secret});
   	$column_data{transdateret}    	= rpt_txt($ref->{transdateret});
	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;
	$valret_total += $ref->{valret};
   }

   $column_data{no}   		= rpt_txt('&nbsp;');
   $column_data{ruc}     	= rpt_txt('&nbsp;');
   $column_data{anio}       	= rpt_txt('&nbsp;');
   $column_data{mes}       	= rpt_txt('&nbsp;');
   $column_data{tipoid_id}     	= rpt_txt('&nbsp;');
   $column_data{gifi_accno}    	= rpt_txt('&nbsp;');
   $column_data{tipodoc_id}     = rpt_txt('&nbsp;');
   $column_data{ordnumber}	= rpt_txt('&nbsp;');
   $column_data{estab}		= rpt_txt('&nbsp;');
   $column_data{ptoemi}         = rpt_txt('&nbsp;');
   $column_data{sec}           	= rpt_txt('&nbsp;');
   $column_data{transdate}    	= rpt_txt('&nbsp;');
   $column_data{tiporet_id}   	= rpt_txt('&nbsp;');
   $column_data{porcret}    	= rpt_txt('&nbsp;');
   $column_data{base0}    	= rpt_txt('&nbsp;');
   $column_data{based0}   	= rpt_txt('&nbsp;');
   $column_data{baseni}   	= rpt_txt('&nbsp;');
   $column_data{valret}    	= rpt_int($valret_total);
   $column_data{ordnumberret}	= rpt_txt('&nbsp;');
   $column_data{estabret}	= rpt_txt('&nbsp;');
   $column_data{ptoemiret}      = rpt_txt('&nbsp;');
   $column_data{secret}    	= rpt_txt('&nbsp;');
   $column_data{transdateret}   = rpt_txt('&nbsp;');

   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;

   $sth->finish;
   $dbh->disconnect;
}

