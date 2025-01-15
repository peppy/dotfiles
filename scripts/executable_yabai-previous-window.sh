#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Focus previous window
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.author ppy
# @raycast.authorURL https://raycast.com/ppy

yabai -m window --focus west || yabai -m window --focus stack.prev || yabai -m window --focus stack.last
