#!/bin/sh

set -e

CODE_DIR=/srv/code
DRUPAL_DIR=$CODE_DIR/drupal
CIVICRM_DIR=$CODE_DIR/civicrm

CURRENT=$(readlink $CIVICRM_DIR/current)
LATEST=$(curl -s "http://qa.debian.org/watch/sf.php/civicrm/" | grep drupal.tar.gz | head -1 | sed -r 's/^.*>([^<]+)<.*$/\1/' | cut -d "-" -f 2)

CURRENT_D=$(readlink $DRUPAL_DIR/current)
LATEST_D=$(curl -s "https://drupal.org/project/drupal" | grep "http://ftp.drupal.org/files/projects/" | head -1 | sed -r 's/^[^"]+href="([^"]*)".*/\1/' | sed -e 's/.*\///' -e 's/drupal-//g' -e 's/.tar.gz$//')

if [ "$CURRENT_D" != "$LATEST_D" ]; then
    echo "Upgrade from drupal $CURRENT_D to $LATEST_D is needed"
    echo " To download run:     $(dirname $(readlink -f $0))/download-drupal-version.sh ${LATEST_D}"
    echo " To install run:      rm $DRUPAL_DIR/current; ln -s ${LATEST_D} $DRUPAL_DIR/current"
    echo " To upgrade, go to:   http://civicrm/drupal/update.php"
fi

if [ "$CURRENT" != "$LATEST" ]; then
    echo "Upgrade from civicrm $CURRENT to $LATEST is needed"
    echo " To download run:     $(dirname $(readlink -f $0))/download-civicrm-version.sh ${LATEST}"
    echo " To install run:      rm $CIVICRM_DIR/current; ln -s ${LATEST} $CIVICRM_DIR/current"
    echo " To upgrade, go to:   http://civicrm/drupal/?q=civicrm/upgrade&reset=1"
fi
