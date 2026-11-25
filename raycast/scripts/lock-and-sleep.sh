#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Lock and Sleep
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🌙
# @raycast.packageName System
# @raycast.description Lock the screen and put the Mac to sleep (it otherwise stays awake for herdr/Claude sessions)

# With the screen lock set to "immediate" (macos/power.sh), sleeping also locks.
pmset sleepnow
