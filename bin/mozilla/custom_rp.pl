1; 
sub export { &{ $form->{nextsub} } };

sub save_report {
  $form->save_form('report');
}

# (3) Run 'perl locales.pl' in your locale folder if you are not using Default English language

# (4) Add following code to bin/mozilla/custom_rp.pl for each new report.
sub sri_search {
  $form->{title} = $locale->text('SRI');

  $form->all_vc(\%myconfig, 'vendor', 'AP');
  delete $form->{all_employee}; # Prevent duplicate list
  $form->all_vc(\%myconfig, 'customer', 'AR');
  if (@{ $form->{all_years} }) {
    # accounting years
    $selectaccountingyear = "<option>\n";
    for (@{ $form->{all_years} }) { $selectaccountingyear .= qq|<option>$_\n| }
    $selectaccountingmonth = "<option>\n";
    for (sort keys %{ $form->{all_month} }) { $selectaccountingmonth .= qq|<option value=$_>|.$locale->text($form->{all_month}{$_}).qq|\n| }

    $selectfrom = qq|
        <tr>
	<th align=right>|.$locale->text('Period').qq|</th>
	<td>
	<select name=month>$selectaccountingmonth</select>
	<select name=year>$selectaccountingyear</select>
	<input name=interval class=radio type=radio value=0 checked>&nbsp;|.$locale->text('Current').qq|
	<input name=interval class=radio type=radio value=1>&nbsp;|.$locale->text('Month').qq|
	<input name=interval class=radio type=radio value=3>&nbsp;|.$locale->text('Quarter').qq|
	<input name=interval class=radio type=radio value=12>&nbsp;|.$locale->text('Year').qq|
	</td>
      </tr>
|;
  }
  # Month/Year widget if needed

  @a = ();
  push @a, (qq|<input name="l_no" class=checkbox type=checkbox value=Y>|.$locale->text('No.'));

  push @a, (qq|<input name="l_numeroruc" class=checkbox type=checkbox value=Y checked>|.$locale->text('Numeroruc'));
  push @a, (qq|<input name="l_anio" class=checkbox type=checkbox value=Y checked>|.$locale->text('Anio'));
  push @a, (qq|<input name="l_mes" class=checkbox type=checkbox value=Y checked>|.$locale->text('Mes'));
  push @a, (qq|<input name="l_tipoid_id" class=checkbox type=checkbox value=Y checked>|.$locale->text('Tipoid id'));
  push @a, (qq|<input name="l_idprov" class=checkbox type=checkbox value=Y checked>|.$locale->text('Idprov'));
  push @a, (qq|<input name="l_tipodoc_id" class=checkbox type=checkbox value=Y checked>|.$locale->text('Tipodoc id'));
  push @a, (qq|<input name="l_ordnumber" class=checkbox type=checkbox value=Y checked>|.$locale->text('Ordnumber'));
  push @a, (qq|<input name="l_estab" class=checkbox type=checkbox value=Y checked>|.$locale->text('Estab'));
  push @a, (qq|<input name="l_ptoemi" class=checkbox type=checkbox value=Y checked>|.$locale->text('Ptoemi'));
  push @a, (qq|<input name="l_sec" class=checkbox type=checkbox value=Y checked>|.$locale->text('Sec'));
  push @a, (qq|<input name="l_transdate" class=checkbox type=checkbox value=Y checked>|.$locale->text('Transdate'));
  push @a, (qq|<input name="l_tiporet_id" class=checkbox type=checkbox value=Y checked>|.$locale->text('Tiporet id'));
  push @a, (qq|<input name="l_porcret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Porcret'));
  push @a, (qq|<input name="l_base0" class=checkbox type=checkbox value=Y checked>|.$locale->text('Base0'));
  push @a, (qq|<input name="l_based0" class=checkbox type=checkbox value=Y checked>|.$locale->text('Based0'));
  push @a, (qq|<input name="l_baseni" class=checkbox type=checkbox value=Y checked>|.$locale->text('Baseni'));
  push @a, (qq|<input name="l_valret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Valret'));
  push @a, (qq|<input name="l_ordnumberret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Ordnumberret'));
  push @a, (qq|<input name="l_estabret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Estabret'));
  push @a, (qq|<input name="l_ptoemiret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Ptoemiret'));
  push @a, (qq|<input name="l_secret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Secret'));
  push @a, (qq|<input name="l_transdateret" class=checkbox type=checkbox value=Y checked>|.$locale->text('Transdateret'));
  $form->header;

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
	  <td>
	    <table>
$customer
$vendor
$department
$warehouse
$employee
$project
$partsgroup		<tr>
		  <th align=right>|.$locale->text('Numeroruc').qq|</th>
		  <td><input name=numeroruc size=25 value="$form->{numeroruc}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Anio').qq|</th>
		  <td><input name=anio size=25 value="$form->{anio}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Mes').qq|</th>
		  <td><input name=mes size=25 value="$form->{mes}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Tipoid id').qq|</th>
		  <td><input name=tipoid_id size=6 value="$form->{tipoid_id}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Idprov').qq|</th>
		  <td><input name=idprov size=25 value="$form->{idprov}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Tipodoc id').qq|</th>
		  <td><input name=tipodoc_id size=4 value="$form->{tipodoc_id}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Ordnumber').qq|</th>
		  <td><input name=ordnumber size=25 value="$form->{ordnumber}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Estab').qq|</th>
		  <td><input name=estab size=7 value="$form->{estab}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Ptoemi').qq|</th>
		  <td><input name=ptoemi size=7 value="$form->{ptoemi}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Sec').qq|</th>
		  <td><input name=sec size=11 value="$form->{sec}"></td>
		</tr>
             </table>
	   </td>
	   <td>
	     <table>		<tr>
		  <th align=right>|.$locale->text('Transdate').qq|</th>
		  <td>
		     <input name=transdate1 size=11 value="$form->{transdate1}" title="$myconfig{dateformat}"> - 
		     <input name=transdate2 size=11 value="$form->{transdate1}" title="$myconfig{dateformat}">
		  </td>
		</tr>
$selectfrom
		<tr>
		  <th align=right>|.$locale->text('Tiporet id').qq|</th>
		  <td><input name=tiporet_id size=4 value="$form->{tiporet_id}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Porcret').qq|</th>
		  <td><input name=porcret size=4 value="$form->{porcret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Base0').qq|</th>
		  <td>
		     <input name=base01 size=8 value="$form->{base01}" title="$myconfig{dateformat}"> - 
		     <input name=base02 size=8 value="$form->{base02}" title="$myconfig{dateformat}">
		  </td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Based0').qq|</th>
		  <td>
		     <input name=based01 size=8 value="$form->{based01}" title="$myconfig{dateformat}"> - 
		     <input name=based02 size=8 value="$form->{based02}" title="$myconfig{dateformat}">
		  </td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Baseni').qq|</th>
		  <td>
		     <input name=baseni1 size=8 value="$form->{baseni1}" title="$myconfig{dateformat}"> - 
		     <input name=baseni2 size=8 value="$form->{baseni2}" title="$myconfig{dateformat}">
		  </td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Valret').qq|</th>
		  <td><input name=valret size=6 value="$form->{valret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Ordnumberret').qq|</th>
		  <td><input name=ordnumberret size=25 value="$form->{ordnumberret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Estabret').qq|</th>
		  <td><input name=estabret size=7 value="$form->{estabret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Ptoemiret').qq|</th>
		  <td><input name=ptoemiret size=7 value="$form->{ptoemiret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Secret').qq|</th>
		  <td><input name=secret size=11 value="$form->{secret}"></td>
		</tr>
		<tr>
		  <th align=right>|.$locale->text('Transdateret').qq|</th>
		  <td>
		     <input name=transdateret1 size=11 value="$form->{transdateret1}" title="$myconfig{dateformat}"> - 
		     <input name=transdateret2 size=11 value="$form->{transdateret1}" title="$myconfig{dateformat}">
		  </td>
		</tr>

             </table>
	   </td>
	   <td>
	     <table>
	     </table>
	   </td>
	</tr>
	<tr>
	  <table>
	    <tr>
	      <th align=right>|.$locale->text('Include in Report').qq|</th>
	      <td>
		<table>

|;
  while (@a) {
    print qq|<tr>\n|;
    for (1 .. 6) {
      print qq|<td nowrap>|. shift @a;
      print qq|</td>\n|;
    }
    print qq|</tr>\n|;
  }

  print qq|
	   	    <tr>
		      <td><input name="l_subtotal" class=checkbox type=checkbox value=Y checked> |.$locale->text('Subtotal').qq|</td>
		    </tr>
		  </table>
	        </td>
	      </tr>
	    </table>
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<input type=hidden name=nextsub value=sri_report>
|;

  $form->hide_form(qw(path login));
  
  print qq|
<br>
<input class=submit type=submit name=action value="|.$locale->text('Continue').qq|">
</form>
|;

  print qq|

</body>
</html>
|;
}

sub sri_report {

  my @columns = qw( numeroruc anio mes tipoid_id idprov tipodoc_id ordnumber estab ptoemi sec transdate tiporet_id porcret base0 based0 baseni valret ordnumberret estabret ptoemiret secret transdateret);
  my %ordinal = (
  numeroruc => 1,
    anio => 2,
    mes => 3,
    tipoid_id => 4,
    idprov => 5,
    tipodoc_id => 6,
    ordnumber => 7,
    estab => 8,
    ptoemi => 9,
    sec => 10,
    transdate => 11,
    tiporet_id => 12,
    porcret => 13,
    base0 => 14,
    based0 => 15,
    baseni => 16,
    valret => 17,
    ordnumberret => 18,
    estabret => 19,
    ptoemiret => 20,
    secret => 21,
    transdateret => 22,
  );

  $form->{sort} = "idprov" unless $form->{sort};
  $form->{direction} = 'ASC' if !$form->{direction};
  $form->{direction} = ($form->{direction} eq 'ASC') ? "ASC" : "DESC";

  $href = "$form->{script}?action=sri_report";
  for (qw(path login l_subtotal summary)) { $href .= "&$_=$form->{$_}" }
  @columns = $form->sort_columns(@columns);
  my $sort_order = $form->sort_order(@columns, \%ordinal);
  splice @columns, 0, 0, 'no';
  $href .= "&direction=$form->{direction}&oldsort=$form->{sort}";

  for (qw(customer vendor department warhouse project employee partsgroup)){
     if ($form->{$_}){
       ($form->{$_}, $form->{"${_}_id"}) = split(/--/, $form->{$_});
       $form->{"${_}_id"} *= 1;
       $href .= "&$_=".$form->escape($form->{$_});
     }
  }
  for (qw(department warehouse project employee partsgroup)) { $form->{"l_$_"} = '' if $form->{$_} }

  $form->{title} = $locale->text('SRI') . " / $form->{company}";

  my $dbh = $form->dbconnect(\%myconfig);
  my %defaults = $form->get_defaults($dbh, \@{['precision', 'company']});
  for (keys %defaults) { $form->{$_} = $defaults{$_} }

  my $where = " (1 = 1) ";
  ($form->{transdate1}, $form->{transdate2}) = $form->from_to($form->{year}, $form->{month}, $form->{interval}) if $form->{year} && $form->{month};

  if ($form->{numeroruc}){
     $href .= "&numeroruc=".$form->escape($form->{numeroruc});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Numeroruc') . " : $form->{numeroruc}";
     $var = $form->like(lc $form->{numeroruc});
     $where .= " AND lower(numeroruc) LIKE '$var'";
  }

  if ($form->{anio}){
     $href .= "&anio=".$form->escape($form->{anio});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Anio') . " : $form->{anio}";
     $var = $form->like(lc $form->{anio});
     $where .= " AND lower(anio) LIKE '$var'";
  }

  if ($form->{mes}){
     $href .= "&mes=".$form->escape($form->{mes});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Mes') . " : $form->{mes}";
     $var = $form->like(lc $form->{mes});
     $where .= " AND lower(mes) LIKE '$var'";
  }

  if ($form->{tipoid_id}){
     $href .= "&tipoid_id=".$form->escape($form->{tipoid_id});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Tipoid id') . " : $form->{tipoid_id}";
     $var = $form->like(lc $form->{tipoid_id});
     $where .= " AND lower(tipoid_id) LIKE '$var'";
  }

  if ($form->{idprov}){
     $href .= "&idprov=".$form->escape($form->{idprov});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Idprov') . " : $form->{idprov}";
     $var = $form->like(lc $form->{idprov});
     $where .= " AND lower(idprov) LIKE '$var'";
  }


  if ($form->{ordnumber}){
     $href .= "&ordnumber=".$form->escape($form->{ordnumber});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Ordnumber') . " : $form->{ordnumber}";
     $var = $form->like(lc $form->{ordnumber});
     $where .= " AND lower(ordnumber) LIKE '$var'";
  }

  if ($form->{estab}){
     $href .= "&estab=".$form->escape($form->{estab});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Estab') . " : $form->{estab}";
     $var = $form->like(lc $form->{estab});
     $where .= " AND lower(estab) LIKE '$var'";
  }

  if ($form->{ptoemi}){
     $href .= "&ptoemi=".$form->escape($form->{ptoemi});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Ptoemi') . " : $form->{ptoemi}";
     $var = $form->like(lc $form->{ptoemi});
     $where .= " AND lower(ptoemi) LIKE '$var'";
  }

  if ($form->{sec}){
     $href .= "&sec=".$form->escape($form->{sec});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Sec') . " : $form->{sec}";
     $var = $form->like(lc $form->{sec});
     $where .= " AND lower(sec) LIKE '$var'";
  }

  if ($form->{transdate1} or $form->{transdate2}){
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Transdate') . " :".$locale->date(\%myconfig, $form->{transdate1}, 1) . ' - ' .$locale->date(\%myconfig, $form->{transdate2}, 1);

     if ($form->{transdate1}){
       $href .= "&transdate1=".$form->escape($form->{transdate1});
       $datevar = $dbh->quote( $form->{transdate1} );
       $where .= " AND transdate >= $datevar";
     }
     if ($form->{transdate2}){
       $href .= "&transdate2=".$form->escape($form->{transdate2});
       $datevar = $dbh->quote( $form->{transdate2} );
       $where .= " AND transdate <= $datevar";
     }
  }



  if ($form->{base01} or $form->{base02}){
     $option .= "\n<br>" if $option;
     if ($form->{base01}){
       $form->{base01} *= 1;
       $href .= "&base01=".$form->escape($form->{base01});
       $where .= " AND base0 >= $form->{base01}";
     }
     if ($form->{base02}){
       $form->{base02} *= 1;
       $href .= "&base02=".$form->escape($form->{base02});
       $where .= " AND base0 <= $form->{base02}";
     }
     $option .= $locale->text('Base0') . " : $form->{base01} - $form->{base02}";
  }
  if ($form->{based01} or $form->{based02}){
     $option .= "\n<br>" if $option;
     if ($form->{based01}){
       $form->{based01} *= 1;
       $href .= "&based01=".$form->escape($form->{based01});
       $where .= " AND based0 >= $form->{based01}";
     }
     if ($form->{based02}){
       $form->{based02} *= 1;
       $href .= "&based02=".$form->escape($form->{based02});
       $where .= " AND based0 <= $form->{based02}";
     }
     $option .= $locale->text('Based0') . " : $form->{based01} - $form->{based02}";
  }
  if ($form->{baseni1} or $form->{baseni2}){
     $option .= "\n<br>" if $option;
     if ($form->{baseni1}){
       $form->{baseni1} *= 1;
       $href .= "&baseni1=".$form->escape($form->{baseni1});
       $where .= " AND baseni >= $form->{baseni1}";
     }
     if ($form->{baseni2}){
       $form->{baseni2} *= 1;
       $href .= "&baseni2=".$form->escape($form->{baseni2});
       $where .= " AND baseni <= $form->{baseni2}";
     }
     $option .= $locale->text('Baseni') . " : $form->{baseni1} - $form->{baseni2}";
  }

  if ($form->{ordnumberret}){
     $href .= "&ordnumberret=".$form->escape($form->{ordnumberret});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Ordnumberret') . " : $form->{ordnumberret}";
     $var = $form->like(lc $form->{ordnumberret});
     $where .= " AND lower(ordnumberret) LIKE '$var'";
  }

  if ($form->{estabret}){
     $href .= "&estabret=".$form->escape($form->{estabret});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Estabret') . " : $form->{estabret}";
     $var = $form->like(lc $form->{estabret});
     $where .= " AND lower(estabret) LIKE '$var'";
  }

  if ($form->{ptoemiret}){
     $href .= "&ptoemiret=".$form->escape($form->{ptoemiret});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Ptoemiret') . " : $form->{ptoemiret}";
     $var = $form->like(lc $form->{ptoemiret});
     $where .= " AND lower(ptoemiret) LIKE '$var'";
  }

  if ($form->{secret}){
     $href .= "&secret=".$form->escape($form->{secret});
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Secret') . " : $form->{secret}";
     $var = $form->like(lc $form->{secret});
     $where .= " AND lower(secret) LIKE '$var'";
  }

  if ($form->{transdateret1} or $form->{transdateret2}){
     $option .= "\n<br>" if $option;
     $option .= $locale->text('Transdateret') . " : $form->{'transdateret1'} - $form->{transdateret2}";
     if ($form->{transdateret1}){
       $href .= "&transdateret1=".$form->escape($form->{transdateret1});
       $datevar = $dbh->quote( $form->{transdateret1} );
       $where .= " AND transdateret >= $datevar";
     }
     if ($form->{transdateret2}){
       $href .= "&transdateret2=".$form->escape($form->{transdateret2});
       $datevar = $dbh->quote( $form->{transdateret2} );
       $where .= " AND transdateret <= $datevar";
     }
  }


  my $query;

  $query = qq|
SELECT 
   (SELECT fldvalue FROM defaults WHERE fldname='businessnumber') AS numeroRuc,
   TO_CHAR(retenc.transdate, 'YYYY') AS anio,
   TO_CHAR(retenc.transdate, 'MM') AS mes,
   retenc.tipoid_id,
   retenc.idprov,
   retenc.tipodoc_id,
   retenc.ordnumber,
   retenc.estab,
   retenc.ptoemi,
   retenc.sec,
   retenc.transdate,
   retenc.tiporet_id,
   retenc.porcret,
   retenc.base0,
   retenc.based0,
   retenc.baseni,
   retenc.valret,
   retenc.ordnumberret,
   retenc.estabret,
   retenc.ptoemiret,
   retenc.secret,
   retenc.transdateret
FROM retenc

WHERE $where
ORDER BY $form->{sort} $form->{direction}
|;  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  @column_index = ();
  foreach $item (@columns) {
    if ($form->{"l_$item"} eq "Y") {
      push @column_index, $item;
      $href .= "&l_$item=Y";
    }
  }
  $callback = $form->escape($href,1);

  $column_header{no} = "<th>".$locale->text('No.')."</th>";
  $column_header{numeroruc} = "<th><a class=listheading href=$href&sort=numeroruc>".$locale->text('Numeroruc')."</a></th>";  $column_header{anio} = "<th><a class=listheading href=$href&sort=anio>".$locale->text('Anio')."</a></th>";  $column_header{mes} = "<th><a class=listheading href=$href&sort=mes>".$locale->text('Mes')."</a></th>";  $column_header{tipoid_id} = "<th><a class=listheading href=$href&sort=tipoid_id>".$locale->text('Tipoid id')."</a></th>";  $column_header{idprov} = "<th><a class=listheading href=$href&sort=idprov>".$locale->text('Idprov')."</a></th>";  $column_header{tipodoc_id} = "<th><a class=listheading href=$href&sort=tipodoc_id>".$locale->text('Tipodoc id')."</a></th>";  $column_header{ordnumber} = "<th><a class=listheading href=$href&sort=ordnumber>".$locale->text('Ordnumber')."</a></th>";  $column_header{estab} = "<th><a class=listheading href=$href&sort=estab>".$locale->text('Estab')."</a></th>";  $column_header{ptoemi} = "<th><a class=listheading href=$href&sort=ptoemi>".$locale->text('Ptoemi')."</a></th>";  $column_header{sec} = "<th><a class=listheading href=$href&sort=sec>".$locale->text('Sec')."</a></th>";  $column_header{transdate} = "<th><a class=listheading href=$href&sort=transdate>".$locale->text('Transdate')."</a></th>";  $column_header{tiporet_id} = "<th><a class=listheading href=$href&sort=tiporet_id>".$locale->text('Tiporet id')."</a></th>";  $column_header{porcret} = "<th><a class=listheading href=$href&sort=porcret>".$locale->text('Porcret')."</a></th>";  $column_header{base0} = "<th><a class=listheading href=$href&sort=base0>".$locale->text('Base0')."</a></th>";  $column_header{based0} = "<th><a class=listheading href=$href&sort=based0>".$locale->text('Based0')."</a></th>";  $column_header{baseni} = "<th><a class=listheading href=$href&sort=baseni>".$locale->text('Baseni')."</a></th>";  $column_header{valret} = "<th><a class=listheading href=$href&sort=valret>".$locale->text('Valret')."</a></th>";  $column_header{ordnumberret} = "<th><a class=listheading href=$href&sort=ordnumberret>".$locale->text('Ordnumberret')."</a></th>";  $column_header{estabret} = "<th><a class=listheading href=$href&sort=estabret>".$locale->text('Estabret')."</a></th>";  $column_header{ptoemiret} = "<th><a class=listheading href=$href&sort=ptoemiret>".$locale->text('Ptoemiret')."</a></th>";  $column_header{secret} = "<th><a class=listheading href=$href&sort=secret>".$locale->text('Secret')."</a></th>";  $column_header{transdateret} = "<th><a class=listheading href=$href&sort=transdateret>".$locale->text('Transdateret')."</a></th>";

  $form->header;

  print qq|
<body>

<table width=100%>
  <tr>
    <th class=listtop>$form->{title}</th>
  </tr>
  <tr height="5"></tr>
  <tr>
    <td>$option</td>
  </tr>
  <tr>
    <td>
      <table width=100%>
	<tr class=listheading>
|;

  for (@column_index) { print "$column_header{$_}\n" }

  print "
        </tr>
";
  
  my $base0_total = 0; my $base0_subtotal = 0;
  my $based0_total = 0; my $based0_subtotal = 0;
  my $baseni_total = 0; my $baseni_subtotal = 0;

  my $i = 1; my $no = 1;
  my $groupbreak = 'none';
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
    # You can use the link below to goto any form (and come back too)
    $form->{link} = qq|$form->{script}?action=edit&id=$ref->{id}&path=$form->{path}&login=$form->{login}&callback=$callback|;
    $groupbreak = $ref->{$form->{sort}} if $groupbreak eq 'none';
    if ($form->{l_subtotal}){
       if ($groupbreak ne $ref->{$form->{sort}}){
 	  $groupbreak = $ref->{$form->{sort}};
	  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
	  $column_data{base0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $base0_subtotal, $form->{precision}) . qq|</th>|;
	  $base0_subtotal = 0;
	  $column_data{based0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $based0_subtotal, $form->{precision}) . qq|</th>|;
	  $based0_subtotal = 0;
	  $column_data{baseni} = qq|<th align=right>|.$form->format_amount(\%myconfig, $baseni_subtotal, $form->{precision}) . qq|</th>|;
	  $baseni_subtotal = 0;
	  print "<tr valign=top class=listsubtotal>";
	  for (@column_index) { print "\n$column_data{$_}" }
	  print "</tr>";
       }
    }
    $column_data{no} = qq|<td align=right>$no</td>|;
    $column_data{numeroruc} = qq|<td nowrap>$ref->{numeroruc}</td>|;
    $column_data{anio} = qq|<td nowrap>$ref->{anio}</td>|;
    $column_data{mes} = qq|<td nowrap>$ref->{mes}</td>|;
    $column_data{tipoid_id} = qq|<td nowrap>$ref->{tipoid_id}</td>|;
    $column_data{idprov} = qq|<td nowrap>$ref->{idprov}</td>|;
    $column_data{tipodoc_id} = qq|<td align=right>$ref->{tipodoc_id}</td>|;
    $column_data{ordnumber} = qq|<td nowrap>$ref->{ordnumber}</td>|;
    $column_data{estab} = qq|<td nowrap>$ref->{estab}</td>|;
    $column_data{ptoemi} = qq|<td nowrap>$ref->{ptoemi}</td>|;
    $column_data{sec} = qq|<td nowrap>$ref->{sec}</td>|;
    $column_data{transdate} = qq|<td align=right>$ref->{transdate}</td>|;
    $column_data{tiporet_id} = qq|<td align=right>$ref->{tiporet_id}</td>|;
    $column_data{porcret} = qq|<td align=right>$ref->{porcret}</td>|;
    $column_data{base0} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{base0}, $form->{precision}).qq|</td>|;
    $column_data{based0} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{based0}, $form->{precision}).qq|</td>|;
    $column_data{baseni} = qq|<td align=right>|.$form->format_amount(\%myconfig, $ref->{baseni}, $form->{precision}).qq|</td>|;
    $column_data{valret} = qq|<td nowrap>$ref->{valret}</td>|;
    $column_data{ordnumberret} = qq|<td nowrap>$ref->{ordnumberret}</td>|;
    $column_data{estabret} = qq|<td nowrap>$ref->{estabret}</td>|;
    $column_data{ptoemiret} = qq|<td nowrap>$ref->{ptoemiret}</td>|;
    $column_data{secret} = qq|<td nowrap>$ref->{secret}</td>|;
    $column_data{transdateret} = qq|<td align=right>$ref->{transdateret}</td>|;

    print qq|
	<tr class=listrow$i>
|;
    for (@column_index) { print "$column_data{$_}\n" }
    $i++; $i %= 2; $no++;

    print qq|
        </tr>
|;

    $base0_subtotal += $ref->{base0}; $base0_total += $ref->{base0};    $based0_subtotal += $ref->{based0}; $based0_total += $ref->{based0};    $baseni_subtotal += $ref->{baseni}; $baseni_total += $ref->{baseni};

  }

  # Print subtotals of last group
  if ($form->{l_subtotal}){
     for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
     $column_data{base0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $base0_subtotal, $form->{precision}) . qq|</th>|;
     $column_data{based0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $based0_subtotal, $form->{precision}) . qq|</th>|;
     $column_data{baseni} = qq|<th align=right>|.$form->format_amount(\%myconfig, $baseni_subtotal, $form->{precision}) . qq|</th>|;
     print "<tr valign=top class=listsubtotal>";
     for (@column_index) { print "\n$column_data{$_}" }
     print "</tr>";
  }

  # Now print grand totals
  print qq|
	<tr class=listtotal>
|;
  for (@column_index) { $column_data{$_} = "<td>&nbsp;</td>" }
  $column_data{base0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $base0_total, $form->{precision}) . qq|</th>|;
  $column_data{based0} = qq|<th align=right>|.$form->format_amount(\%myconfig, $based0_total, $form->{precision}) . qq|</th>|;
  $column_data{baseni} = qq|<th align=right>|.$form->format_amount(\%myconfig, $baseni_total, $form->{precision}) . qq|</th>|;
  for (@column_index) { print "\n$column_data{$_}" }

  print qq|
	</tr>
      </table>
    </td>
  </tr>
  <tr>
    <td><hr size=3 noshade></td>
  </tr>
</table>

<form method=post action=$form->{script}>
|;

  $form->{actionname} = 'test_report';
  $form->{nextsub} = 'sri_export';
  $form->hide_form;
  
  print qq|
<br>
<select name=filetype><option value=csv>csv<option value=tsv>tsv<option value=xml selected>xml</select>
<input class=submit type=submit name=action value="|.$locale->text('Export').qq|">
&nbsp;&nbsp;
<input name=reportname type=text size=20>
<input class=submit type=submit name=action value="|.$locale->text('Save Report').qq|">
</form>

</body>
</html>
|;

}

sub sri_export {

  $form->{file} = 'sri';
  #my @columns = qw( numeroruc anio mes tipoid_id idprov tipodoc_id ordnumber estab ptoemi sec transdate tiporet_id porcret base0 based0 baseni valret ordnumberret estabret ptoemiret secret transdateret);
  my @groupcolumns = qw(tipoid_id idprov tipodoc_id ordnumber estab ptoemi sec transdate);
  my @detailcolumns = qw(tiporet_id porcret base0 based0 baseni valret);
  my @groupcolumns2 = qw(ordnumberret estabret ptoemiret secret transdateret);

  @column_index = ();
  foreach $item (@columns) {
    push @column_index, $item if ($form->{"l_$item"} eq "Y")
  }

  $form->{includeheader} = 1;

  for (qw(customer vendor department warhouse project employee partsgroup)){
     if ($form->{$_}){
       ($form->{$_}, $form->{"${_}_id"}) = split(/--/, $form->{$_});
       $form->{"${_}_id"} *= 1;
     }
  }
  for (qw(department warehouse project employee partsgroup)) { $form->{"l_$_"} = '' if $form->{$_} }

  my $dbh = $form->dbconnect(\%myconfig);

  my $where = " (1 = 1) ";


  if ($form->{numeroruc}){
     $var = $form->like(lc $form->{numeroruc});
     $where .= " AND lower(numeroruc) LIKE '$var'";
  }
  if ($form->{anio}){
     $var = $form->like(lc $form->{anio});
     $where .= " AND lower(anio) LIKE '$var'";
  }
  if ($form->{mes}){
     $var = $form->like(lc $form->{mes});
     $where .= " AND lower(mes) LIKE '$var'";
  }
  if ($form->{tipoid_id}){
     $var = $form->like(lc $form->{tipoid_id});
     $where .= " AND lower(tipoid_id) LIKE '$var'";
  }
  if ($form->{idprov}){
     $var = $form->like(lc $form->{idprov});
     $where .= " AND lower(idprov) LIKE '$var'";
  }
  if ($form->{ordnumber}){
     $var = $form->like(lc $form->{ordnumber});
     $where .= " AND lower(ordnumber) LIKE '$var'";
  }
  if ($form->{estab}){
     $var = $form->like(lc $form->{estab});
     $where .= " AND lower(estab) LIKE '$var'";
  }
  if ($form->{ptoemi}){
     $var = $form->like(lc $form->{ptoemi});
     $where .= " AND lower(ptoemi) LIKE '$var'";
  }
  if ($form->{sec}){
     $var = $form->like(lc $form->{sec});
     $where .= " AND lower(sec) LIKE '$var'";
  }
  if ($form->{transdate1} or $form->{transdate2}){
     if ($form->{transdate1}){
       $where .= " AND transdate >= '$form->{transdate1}'";
     }
     if ($form->{transdate2}){
       $where .= " AND transdate <= '$form->{transdate2}'";
     }
  }
  if ($form->{base01} or $form->{base02}){
     if ($form->{base01}){
       $where .= " AND base0 >= $form->{base01}";
     }
     if ($form->{base02}){
       $where .= " AND base0 <= $form->{base02}";
     }
  }
  if ($form->{based01} or $form->{based02}){
     if ($form->{based01}){
       $where .= " AND based0 >= $form->{based01}";
     }
     if ($form->{based02}){
       $where .= " AND based0 <= $form->{based02}";
     }
  }
  if ($form->{baseni1} or $form->{baseni2}){
     if ($form->{baseni1}){
       $where .= " AND baseni >= $form->{baseni1}";
     }
     if ($form->{baseni2}){
       $where .= " AND baseni <= $form->{baseni2}";
     }
  }
  if ($form->{ordnumberret}){
     $var = $form->like(lc $form->{ordnumberret});
     $where .= " AND lower(ordnumberret) LIKE '$var'";
  }
  if ($form->{estabret}){
     $var = $form->like(lc $form->{estabret});
     $where .= " AND lower(estabret) LIKE '$var'";
  }
  if ($form->{ptoemiret}){
     $var = $form->like(lc $form->{ptoemiret});
     $where .= " AND lower(ptoemiret) LIKE '$var'";
  }
  if ($form->{secret}){
     $var = $form->like(lc $form->{secret});
     $where .= " AND lower(secret) LIKE '$var'";
  }
  if ($form->{transdateret1} or $form->{transdateret2}){
     if ($form->{transdateret1}){
       $where .= " AND transdateret >= '$form->{transdateret1}'";
     }
     if ($form->{transdateret2}){
       $where .= " AND transdateret <= '$form->{transdateret2}'";
     }
  }

  my $query = qq|
SELECT 
   (SELECT fldvalue FROM defaults WHERE fldname='businessnumber') AS numeroRuc,
   TO_CHAR(retenc.transdate, 'YYYY') AS anio,
   TO_CHAR(retenc.transdate, 'MM') AS mes,
   retenc.tipoid_id,
   retenc.idprov,
   retenc.tipodoc_id,
   retenc.ordnumber,
   retenc.estab,
   retenc.ptoemi,
   retenc.sec,
   retenc.transdate,
   retenc.tiporet_id,
   retenc.porcret,
   retenc.base0,
   retenc.based0,
   retenc.baseni,
   retenc.valret,
   retenc.ordnumberret,
   retenc.estabret,
   retenc.ptoemiret,
   retenc.secret,
   retenc.transdateret
FROM retenc

WHERE $where
ORDER BY numeroruc
|;
  my $sth = $dbh->prepare($query) || $form->dberror($query);
  $sth->execute || $form->dberror($query);

  $column_header{numeroruc} = $locale->text('numeroRuc');
  $column_header{anio} = $locale->text('anio');
  $column_header{mes} = $locale->text('mes');
  $column_header{tipoid_id} = $locale->text('tpldProv');
  $column_header{idprov} = $locale->text('idProv');
  $column_header{tipodoc_id} = $locale->text('tipoComp');
  $column_header{ordnumber} = $locale->text('aut');
  $column_header{estab} = $locale->text('estab');
  $column_header{ptoemi} = $locale->text('ptoEmi');
  $column_header{sec} = $locale->text('sec');
  $column_header{transdate} = $locale->text('fechaEmiCom');
  $column_header{tiporet_id} = $locale->text('codRetAir');
  $column_header{porcret} = $locale->text('porcentaje');
  $column_header{base0} = $locale->text('base0');
  $column_header{based0} = $locale->text('baseGrav');
  $column_header{baseni} = $locale->text('baseNoGrav');
  $column_header{valret} = $locale->text('valRetAir');
  $column_header{ordnumberret} = $locale->text('autRet');
  $column_header{estabret} = $locale->text('estabRet');
  $column_header{ptoemiret} = $locale->text('ptoEmiRet');
  $column_header{secret} = $locale->text('secRet');
  $column_header{transdateret} = $locale->text('fechaEmiRet');


  open(OUT, ">-") or $form->error("STDOUT : $!");
  binmode(OUT);
  print qq|Content-Type: application/file;
Content-Disposition: attachment; filename="$form->{file}.$form->{filetype}"\n|;

  print OUT qq|
<?xml version="1.0" encoding="ISO-8859-1" standalone="yes"?>
<reoc>
    <numeroRuc>0992179155001</numeroRuc>
    <anio>2010</anio>
    <mes>01</mes>
<compras>\n|;

  $line = "";
  $form->{sort} = 'idprov';
  $groupbreak = 'none';
  while ($ref = $sth->fetchrow_hashref(NAME_lc)){
      $line = '';
      if ($form->{l_subtotal}){
        if ($groupbreak eq 'none'){
          $line .= qq|<detalleCompras>\n|;
          $groupbreak = $ref->{$form->{sort}};
          for (@groupcolumns){
            $line .= qq|  <$column_header{$_}>$ref->{$_}</$column_header{$_}>\n|;
	  }
          for (@groupcolumns2){ $form->{$_} = $ref->{$_} } # Save for later use
          $line .= qq|  <air>\n|;
        }
        if ($groupbreak ne $ref->{$form->{sort}}){
           $line .= qq|  </air>\n|;
           for (@groupcolumns2){
             $line .= qq|  <$column_header{$_}>$form->{$_}</$column_header{$_}>\n|;
	   }
           $line .= qq|</detalleCompras>\n|;
 	   $groupbreak = $ref->{$form->{sort}};
           $line .= qq|<detalleCompras>\n|;
           for (@groupcolumns){
             $line .= qq|  <$column_header{$_}>$ref->{$_}</$column_header{$_}>\n|;
	   }
           for (@groupcolumns2){ $form->{$_} = $ref->{$_} } # Save for later use
           $line .= qq|  <air>\n|;
        }
      }
      $line .= qq|    <detalleAir>\n|;
      for (@detailcolumns) {
         $line .= qq|    <$column_header{$_}>$ref->{$_}</$column_header{$_}>\n|;
      }
      $line .= qq|    </detalleAir>\n|;
      print OUT "$line\n";
  }

  print qq|  </air>\n|;
  for (@groupcolumns2){
      print qq|  <$column_header{$_}>$form->{$_}</$column_header{$_}>\n|;
  }
  print qq|  </detalleCompras>\n|;
  print qq|</compras>\n</reoc>\n|;
  close(OUT);
}
# End of sri

