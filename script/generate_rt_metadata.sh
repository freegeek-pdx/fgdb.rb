#!/bin/sh

set -e

get_customvalue_list() {
    NAME="$1"
    echo "SELECT name FROM customfieldvalues WHERE customfield = (SELECT id FROM customfields WHERE name ILIKE '$NAME') ORDER BY sortorder;" | sudo su - postgres -c 'psql -U postgres rtdb' | sed -r -e 's/,/%%%/g' -e '/^ / !d' -e 's/\|/,/g'  -e 's/[ ]*,[ ]*/","/g' -e 's/$/"/' -e 's/^[ ]+/"/' -e 's/%%%/,/g' -e '1 d'
}

for i in "OS" "Type of Box" "Tech Support Issue" "Ticket Source" "Box source" "Warranty"; do
    echo "== $i =="
    get_customvalue_list "$i"
done
