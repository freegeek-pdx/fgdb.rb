#!/bin/sh

INSTALL=/var/www/fgdb.rb
MAILTO=$($INSTALL/script/runner "puts Default['management_mailing_list']")
SCRIPT=$INSTALL/script/find-self-signed-builder-tasks.sql

$SCRIPT | mail -s "Report of self-signed builder tasks in the DB" "$MAILTO"
