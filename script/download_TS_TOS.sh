#!/bin/sh

set -e

cd $(dirname $(readlink -f $0))/..

curl -s "http://wiki.freegeek.org/index.php?title=Tech_Support_Intake_Blurb&action=raw" | \
  sed -r -e 's/==(.+)==/<center><h3>\1<\/h3><\/center>/g' \
  -e 's/=(.+)=/<center><h2>\1<\/h2><\/center>/g' \
  -e 's/^\*\*(.+)$/<ul type="none"><li><ul><li>\1<\/li><\/ul><\/li><\/ul >/g' \
  -e 's/^\*(.+)$/<ul><li>\1<\/li><\/ul>/g' \
  -e 's/^$/<br\/><br\/>/g' \
  -e 's/^    (.+)$/<ul><li>\1<\/li><\/ul>/g' | \
  tr '\n' ' ' | \
  sed -e 's/<\/ul> <ul>//g' \
  -e 's/<\/ul><\/li><\/ul > <ul type="none"><li><ul>//g' \
  -e 's/<\/ul > <ul>//g' \
  -e 's/<\/ul> <ul type="none">//g' \
  -e 's/<\/li><li><ul>/<ul>/g' | \
  sed -e 's/$/\n/g' \
  -e 's/<li>/<li style="font-size: 10px;">/g' \
  -e 's/>/>\n/g' > config/TS_TOS.html
