#!/bin/bash

BACKUP_DIR=/srv/backup-extras/

#if [ ! -d $BACKUP_DIR ]; then
#    mkdir -p $BACKUP_DIR
#fi

#if ! test -f $BACKUP_DIR/I_AM_THE_BACKUPS; then
#    sshfs $BACKUP_SERVER:$REMOTE_DIR $BACKUP_DIR
    if ! test -f $BACKUP_DIR/I_AM_THE_BACKUPS; then
	echo "ERROR: $BACKUP_DIR isn't the backup dir"
	exit 1
    fi
#fi

set -C
set -e
set -u

CUR=$(cat /var/www/fgdb.rb/.git/HEAD  | sed 's,ref: refs/heads/release_1.0.,,')
NEW=$(( $CUR + 1 ))

checkit(){
    return 1
    NUM=$1
    if [ ! -f $BACKUP_DIR/post-sprint-$CUR.sql -o ! -f $BACKUP_DIR/pre-sprint-$CUR.sql ]; then
	return 0
    fi
    [ $(( ( $NUM * 15 * $(du -sc $BACKUP_DIR/{pre,post}-sprint-$CUR.sql | tail -1 | awk '{print $1}') ) / 10 )) -gt $(df  | grep " /$" | awk '{print $4}') ]
}

boldit(){
    echo -ne "\033[1;31m"
}

clearit(){
    echo -ne "\033[0m"
}

pressenter(){
    echo -n "Press enter to continue..."
    read "ENTER"
}

if checkit 1; then
    boldit
    echo "====================================================================="
    echo "ERROR: There is not enough space on the disk to perform this upgrade."
    echo "You will have to fix this and try the upgrade again."
    echo "====================================================================="
    clearit
    pressenter
    exit 1
fi

if checkit 2; then
    boldit
    echo "============================================================================================"
    echo "WARNING: This is the last release you can perform."
    echo "After this release, you will have to increase the disk size or delete some old backup files."
    echo "You should make a ticket or add this to your todo list."
    echo "============================================================================================"
    clearit
    pressenter
fi

cd /var/www/fgdb.rb/
touch tmp/release.txt

pg_dump fgdb_production > $BACKUP_DIR/pre-sprint-$NEW.sql

echo "Check $BACKUP_DIR/pre-sprint-$NEW.sql"
