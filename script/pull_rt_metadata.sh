#!/bin/sh

set -e

TEMPF=$(mktemp)

sudo ssh -i /root/.ssh/wasp_key root@art /root/fgdb.rb/script/generate_rt_metadata.sh > $TEMPF
if [ -n "$(cat $TEMPF)" ]; then
    rm -f /var/www/fgdb.rb/config/rt_metadata.txt
    mv $TEMPF /var/www/fgdb.rb/config/rt_metadata.txt
    sudo fix-permissions
fi

