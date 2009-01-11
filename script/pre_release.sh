#!/bin/sh

set -C
set -e
set -u

CUR=$(cat /var/www/fgdb.rb/.git/HEAD  | sed 's,ref: refs/heads/release_1.0.,,')
NEW=$(( $CUR + 1 ))

cd /var/www/fgdb.rb/
sudo mv public/_release.html public/release.html
sudo invoke-rc.d thin stop

pg_dump fgdb_production > ~/pre-sprint-$NEW.sql

echo "Check ~/pre-sprint-$NEW.sql"
