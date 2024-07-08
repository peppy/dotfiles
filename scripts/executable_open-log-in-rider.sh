#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Open most recent downloaded log file in rider
# @raycast.mode silent

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

FILE=`ls -tp ~/Downloads/*.log | grep -v /\$ | head -1`

echo -n "Opening $FILE in rider"
~/scripts/rider $FILE
