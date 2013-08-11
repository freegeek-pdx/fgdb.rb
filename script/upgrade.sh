#!/bin/sh

BACKUP_DIR=/srv/backup-extras/

if ! test -f $BACKUP_DIR/I_AM_THE_BACKUPS; then
    echo "ERROR: $BACKUP_DIR isn't the backup dir"
    exit 1
fi

set -C
set -e
set -u

cd ~/fgdb.rb
git pull
./script/do_i_have_everything_installed_right

CUR=$(cat /var/www/fgdb.rb/.git/HEAD  | sed 's,ref: refs/heads/release_1.0.,,')
NEW=$(( $CUR + 1 ))

cd /var/www/fgdb.rb/
git fetch fg
git checkout db/schema.rb
git checkout -b release_1.0.$NEW fg/release_1.0.$NEW
env RAILS_ENV=production rake db:migrate
git checkout db/schema.rb
pg_dump fgdb_production > $BACKUP_DIR/post-sprint-$NEW.sql

#sudo invoke-rc.d thin start
rm tmp/release.txt
sudo restart-webserver
