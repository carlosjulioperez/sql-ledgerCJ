#!/usr/local/bin/bash

./ar.pl "path=bin/mozilla&login=armaghan&password=armaghan&action=continue&nextsub=transactions&summarY=1&open=Y&l_amount=Y&l_description=Y&l_invnumber=Y&l_name=Y&l_paid=Y&l_transdate=Y&vc=customer&ARAP=AR&outstanding=1" > /tmp/outstanding.html
mutt -a /tmp/outstanding.html -s 'Outstanding report' saqib@ledger123.com < /dev/null

