#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Github Formatter Markdown (before-after-comparison)
# @raycast.mode silent

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

# Read the clipboard and split on newlines
IFS=$'\n' read -d '' -r -a images < <(pbpaste)

# Start with the header
result="| Before | After |
| :---: | :---: |"

# Loop over the array two items at a time
for ((i=0; i<${#images[@]}; i+=2))
do
  # Add a row for each pair of images
  result="$result
| ${images[$i]} | ${images[$i+1]} |"
done

# Display the result inline
echo -n "$result" | pbcopy

echo -n "Copied output to clipboard!"
