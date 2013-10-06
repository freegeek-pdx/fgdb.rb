#!/bin/sh

INSTALL=/var/www/fgdb.rb
MAILTO=cprevatte@freegeek.org
SCRIPT=$INSTALL/script/find-self-signed-builder-tasks.sql

$SCRIPT | mail -s "Report of self-signed builder tasks in the DB" "$MAILTO"
