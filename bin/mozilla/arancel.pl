require "$form->{path}/lib.pl";
require "$form->{path}/mylib.pl";

1;

#===================================
#
# DATASUR - IMPORTACIONES DESDE ENERO 2010
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
   $form->{title} = $locale->text('DATASUR - IMPORTACIONES DESDE ENERO 2010');
   &print_title;
   &start_form;
   &start_table;

  &print_form_text('Mes','mes', 2);
  &print_form_text('Partida','partida', 10);
  &print_form_text('Desc. Comercial','desc_comer', 20);
  &print_form_text('Importador','importador', 20);
  &print_form_text('Pais Origen','pais_origen', 20);
  &print_form_text('Embarcador','embarcador', 20);

   print qq|<tr><th align=right>| . $locale->text('Incluir en Reporte') . qq|</th><td>|;

   &print_checkbox('l_no', $locale->text('No.'), 'checked', '<br>');
   &print_checkbox('l_mes', $locale->text('Mes'), 'checked', '<br>');
   &print_checkbox('l_partida', $locale->text('Partida'), 'checked', '<br>');
   &print_checkbox('l_desc_comer', $locale->text('Desc. Comercial'), 'checked', '<br>');
   &print_checkbox('l_importador', $locale->text('Importador'), 'checked', '<br>');
   &print_checkbox('l_pais_origen', $locale->text('Pais Origen'), 'checked', '<br>');
   &print_checkbox('l_peso_neto', $locale->text('Peso Neto'), 'checked', '<br>');
   &print_checkbox('l_usd_fob', $locale->text('FOB'), 'checked', '<br>');
   &print_checkbox('l_embarcador', $locale->text('Embarcador'), 'checked', '<br>');
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

   my $mes = $form->{mes};
   my $partida = $form->{partida};
   my $desc_comer = $form->like(lc $form->{desc_comer});
   my $importador = $form->like(lc $form->{importador});
   my $pais_origen = $form->like(lc $form->{pais_origen});
   my $peso_neto = $form->{peso_neto};
   my $usd_fob = $form->{usd_fob};
   my $embarcador = $form->like(lc $form->{embarcador});

   my $where = qq| (1 = 1)|;
   $where .= qq| AND mes = $mes | if $form->{mes};
   $where .= qq| AND partida = '$partida' | if $form->{partida};
   $where .= qq| AND LOWER(desc_comer) LIKE '$desc_comer' | if $form->{desc_comer};
   $where .= qq| AND LOWER(importador) LIKE '$importador' | if $form->{importador};
   $where .= qq| AND LOWER(pais_origen) LIKE '$pais_origen' | if $form->{pais_origen };
   $where .= qq| AND peso_neto = $peso_neto | if $form->{peso_neto};
   $where .= qq| AND usd_fob = $usd_fob | if $form->{usd_fob};
   $where .= qq| AND LOWER(embarcador) LIKE '$embarcador' | if $form->{embarcador};

   @columns = qw(mes partida desc_comer importador pais_origen peso_neto usd_fob embarcador);
   # if this is first time we are running this report.
   $form->{sort} = 'partida' if !$form->{sort};
   $form->{oldsort} = 'none' if !$form->{oldsort};
   $form->{direction} = 'ASC' if !$form->{direction};
   @columns = $form->sort_columns(@columns);

   my %ordinal = (	
			mes => 1,
			partida => 2,
			desc_comer => 3,
			importador => 4,
			pais_origen => 5,
			peso_neto => 6,
			usd_fob => 7,
			embarcador => 8
   );

   my $sort_order = $form->sort_order(\@columns, \%ordinal);


   foreach (qw(l_subtotal mes partida desc_comer importador pais_origen peso_neto usd_fob embarcador)){
       $callback .= "&$_=$form->{$_}";
   }
   $callback .= "&vc=$form->{vc}";
   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);




   $query = qq|
      SELECT 	
              mes,
              partida,
              desc_comer,
              importador,
              pais_origen,
              peso_neto,
              usd_fob,
              embarcador
      FROM import_ec
      WHERE $where
      ORDER BY $sort_order
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

   foreach (qw(l_subtotal mes partida desc_comer importador pais_origen peso_neto usd_fob embarcador)){
       $callback .= "&$_=$form->{$_}";
   }

   my $href = $callback;
   $form->{callback} = $form->escape($callback,1);

   # store oldsort/direction information
   $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

   $column_header{no}   	= rpt_hdr('no', $locale->text('No.'));
   $column_header{mes} 		= rpt_hdr('mes', $locale->text('Mes'), $href);
   $column_header{partida} 	= rpt_hdr('partida', $locale->text('Partida'), $href);
   $column_header{desc_comer} 	= rpt_hdr('desc_comer', $locale->text('Desc. Comercial'), $href);
   $column_header{importador} 	= rpt_hdr('importador', $locale->text('Importador'), $href);
   $column_header{pais_origen}	= rpt_hdr('pais_origen', $locale->text('Pais Origen'), $href);
   $column_header{peso_neto}	= rpt_hdr('peso_neto', $locale->text('Peso Neto'), $href);
   $column_header{usd_fob} 	= rpt_hdr('usd_fob', $locale->text('FOB'), $href);
   $column_header{embarcador} 	= rpt_hdr('embarcador', $locale->text('Embarcador'), $href);



   $form->error($query) if $form->{l_sql};
   $dbh = $form->dbconnect(\%myconfig);
   my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
   for (keys %defaults) { $form->{$_} = $defaults{$_} }

   if ($form->{l_csv} eq 'Y'){
	&export_to_csv($dbh, $query, 'importaciones');
	exit;
   }
   $sth = $dbh->prepare($query);
   $sth->execute || $form->dberror($query);

   $form->{title} = $locale->text('DATASUR - IMPORTACIONES DESDE ENERO 2010');
   &print_title;
   &print_criteria('mes','Mes');
   &print_criteria('partida', 'Partida');
   &print_criteria('desc_comer', 'Desc. Comercial');
   &print_criteria('importador', 'Importador');
   &print_criteria('pais_origen', 'Pais Origen');
   &print_criteria('peso_neto', 'Peso Neto');
   &print_criteria('usd_fob', 'FOB');
   &print_criteria('embarcador', 'Embarcador');

   print qq|<table width=100%><tr class=listheading>|;
   # print header
   for (@column_index) { print "\n$column_header{$_}" }
   print qq|</tr>|;


   # Subtotal and total variables
   my $peso_neto_subtotal = 0;
   my $peso_neto_total = 0;

   my $usd_fob_subtotal = 0;
   my $usd_fob_total = 0;

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
                $column_data{no}   	= rpt_txt('&nbsp;');
                $column_data{mes} 	= rpt_txt('&nbsp;');
                $column_data{partida}	= rpt_txt('&nbsp;');
                $column_data{desc_comer}= rpt_txt('&nbsp;');
                $column_data{impotador} = rpt_txt('&nbsp;');
                $column_data{pais_origen} = rpt_txt('&nbsp;');
                $column_data{peso_neto} = rpt_dec($peso_neto_subtotal);
                $column_data{usd_fob}	= rpt_dec($usd_fob_subtotal);
                $column_data{embarcador} = rpt_txt('&nbsp;');



		# print footer
		print "<tr valign=top class=listsubtotal>";
		for (@column_index) { print "\n$column_data{$_}" }
		print "</tr>";

		$peso_neto_subtotal = 0;
		$usd_fob_subtotal = 0;
        	
	   }
	}

	$column_data{no}   		= rpt_txt($no);
   	$column_data{mes}	    	= rpt_int($ref->{mes});
   	$column_data{partida}    	= rpt_int($ref->{partida});
   	$column_data{desc_comer}	= rpt_txt($ref->{desc_comer});
   	$column_data{importador}	= rpt_txt($ref->{importador});
   	$column_data{pais_origen} 	= rpt_txt($ref->{pais_origen});
   	$column_data{peso_neto}   	= rpt_dec($ref->{peso_neto});
   	$column_data{usd_fob}    	= rpt_dec($ref->{usd_fob});
   	$column_data{embarcador}  	= rpt_txt($ref->{embarcador});


	print "<tr valign=top class=listrow$i>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
	$i++; $i %= 2; $no++;

	$peso_neto_subtotal += $ref->{peso_neto};
	$peso_neto_total += $ref->{peso_neto};

	$usd_fob_subtotal += $ref->{usd_fob};
	$usd_fob_total += $ref->{usd_fob};

   }

   $column_data{no}   	= rpt_txt('&nbsp;');
   $column_data{mes}    	= rpt_int('&nbsp;');
   $column_data{partida}  	= rpt_int('&nbsp;');
   $column_data{desc_comer}    	= rpt_int('&nbsp;');
   $column_data{importador}    	= rpt_int('&nbsp;');
   $column_data{pais_origen}    = rpt_int('&nbsp;');
   $column_data{peso_neto}	= rpt_dec($peso_neto_subtotal);
   $column_data{usd_fob}	= rpt_dec($usd_fob_subtotal);
   $column_data{embarcador} 	= rpt_int('&nbsp;');


   if ($form->{l_subtotal}){
	# print last subtotal
	print "<tr valign=top class=listsubtotal>";
	for (@column_index) { print "\n$column_data{$_}" }
	print "</tr>";
   }

   # grand total

   $column_data{peso_neto} 		= rpt_dec($peso_neto_total,2);
   $column_data{usd_fob}   		= rpt_dec($usd_fob_total,2);

   # print footer
   print "<tr valign=top class=listtotal>";
   for (@column_index) { print "\n$column_data{$_}" }
   print "</tr>";

   print qq|</table>|;

   $sth->finish;
   $dbh->disconnect;
}

