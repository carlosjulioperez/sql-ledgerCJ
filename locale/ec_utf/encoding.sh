#!/bin/bash
#enter input encoding here
#FROM_ENCODING="value_here"
FROM_ENCODING="ASCII"
#output encoding(UTF-8)
TO_ENCODING="UTF-8"
#convert
CONVERT=" iconv  -f   $FROM_ENCODING  -t   $TO_ENCODING"
#loop to convert multiple files 
#for  file  in  *.txt; do
for  file  in  *; do
    $CONVERT   "$file"   -o  "${file%.txt}.utf8.converted"
done
exit 0
