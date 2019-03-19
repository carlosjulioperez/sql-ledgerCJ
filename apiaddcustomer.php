<?php
$module = './ct.pl';
$params = 'login=armaghan';
$params .= '&password=armaghan';
$params .= '&path=bin/mozilla';
$params .= '&db=customer';
$params .= '&action=save';
$params .= '&typeofcontact=company';
$params .= '&name=Ledger123';
$params .= '&firstname=Armaghan';
$params .= '&lastname=Saqib';
$params .= '&city=London';

$output = shell_exec("$module \"$params\"");
echo "<pre>$output</pre>";
?>

