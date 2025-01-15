#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus next window
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

yabai -m window --focus east || yabai -m window --focus stack.next || yabai -m window --focus stack.first
