#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title GHFM before-after
# @raycast.mode inline

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

# Read the clipboard and split on newlines
IFS=$'\n' read -d '' -r -a images < <(pbpaste)

# Generate the GHFM table and copy to clipboard
result="| Before | After |
| :---: | :---: |
| ${images[0]} | ${images[1]} |"
echo -n "$result" | pbcopy

echo -n "Copied to clipboard!"
