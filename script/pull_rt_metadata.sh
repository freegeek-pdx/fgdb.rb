#!/bin/sh

set -e

TEMPF=$(mktemp)

sudo ssh -i /root/.ssh/wasp_key root@art /root/fgdb.rb/script/generate_rt_metadata.sh > $TEMPF
sudo chown www-data:www-data "$TEMPF"
sudo chmod 644 "$TEMPF"
if [ -n "$(cat $TEMPF)" ]; then
    mv $TEMPF /var/www/fgdb.rb/config/rt_metadata.txt
fi

