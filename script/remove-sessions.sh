#!/bin/bash

if [ "--help" = "$1" ]
then
    echo "Remove old session files older than HOURS (default 24)"
    echo
    echo "Usage: RAILS_ROOT='/path' remove_sessions.sh [HOURS]"
    echo "       script/remove_sessions.sh [HOURS] (will use current directory)"
    echo
    exit
fi


# Default to 24 hours if not set
if [ -z $1 ]
then
    TIME=$(expr 24 \* 60)
else
    TIME=$(expr $1 \* 60)
fi

# Use the current directory for the RAILS_ROOT if it was not set
if [ -z $RAILS_ROOT ]
then
    RAILS_ROOT=$(dirname $(readlink -f $0))/..
fi

if [ ! -d $RAILS_ROOT ]; then
    echo "RAILS_ROOT does not exist."
    exit 1
fi

find $RAILS_ROOT/tmp/sessions -mmin +$TIME -iname 'ruby_sess.*' -exec rm -v {} \;
