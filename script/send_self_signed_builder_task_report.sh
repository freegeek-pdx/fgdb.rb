#!/bin/sh

INSTALL=/var/www/fgdb.rb
MAILTO=$($INSTALL/script/runner "puts Default['production_manager_email']")
SCRIPT=$INSTALL/script/find-self-signed-builder-tasks.sql

$SCRIPT | mail -s "Report of self-signed builder tasks in the DB" "$MAILTO" database
