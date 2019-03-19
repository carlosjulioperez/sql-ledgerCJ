#!/usr/bin/perl

#///////////////////////////////////////////////
#===============================================
#--------- Table/Report Definition -------------
%header_table = (   
   name => { 
	prompt => 'Company Name',
	datatype => 'C',
	default => '',
	list => 'none',
	size => 20,
	subtotal => 0,
	total => 0
   },
   contact => { 
	prompt => 'Contact Person',
	datatype => 'C',
	default => '',
	list => 'none',
	size => 30,
	subtotal => 0,
	total => 0
   },
   phone => { 
	prompt => 'Phone',
	datatype => 'C',
	default => '',
	list => 'none',
	size => 10,
	subtotal => 0,
	total => 0
   },
   creditlimit => { 
	prompt => 'Credit Limit',
	datatype => 'N',
	default => '',
	list => 'none',
	size => 10,
	subtotal => 0,
	total => 0
   },
);

$header_form_cols = qw(name contact phone creditlimit);
$header_report_cols = qw(name contact phone creditlimit);

#===============================================
#///////////////////////////////////////////////

# Global variables
$indent = 0;

&beginpl;

&beginsub('search');
&endsub;

&beginsub('transactions');
&endsub;

&beginsub('add');
&endsub;

&beginsub('edit');
&endsub;

&beginsub('delete');
&endsub;

#-----------------------------------------
sub beginpl {
  pline('');
  pline('use SL::AA;');
  pline('require "$form->{path}/arap.pl";');
  pline('');
  pline('1;');
  pline('sub continue { &{form->{nextsub}} };');
  pline('');
}

#-----------------------------------------
sub beginsub {
  $subname = shift;
  $indent = 0;
  pline('');
  pline("sub $subname {");
  $indent += 3;
  pline('   # This is comment');
}

#-----------------------------------------
sub endsub {
  $indent = 0;
  pline("}");
}

#-----------------------------------------
sub pline {
  my $line = shift;
  print qq|$line\n|;
}

#-----------------------------------------
sub pword {
  my $word = shift;
  print qq|$word|;
}

######
# EOF
######

