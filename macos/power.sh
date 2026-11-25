#!/bin/bash
# Give herdr and remote Claude sessions room to keep running through short breaks:
# idle sleep after 10 min on battery, 30 min on the charger (Apple's setting here was 1 min).
# Display sleep, lid-close sleep, Power Nap and hibernation stay as Apple ships them.
# Needs sudo. Safe to re-run. Undo: sudo pmset restoredefaults
set -e

sudo pmset -b sleep 10
sudo pmset -c sleep 30

# Require the password the moment the display sleeps or the Mac sleeps,
# so sleeping also locks (was a 5 minute grace period)
sysadminctl -screenLock immediate -password -

echo "Power settings now:"
pmset -g custom | grep -E 'Power:| sleep |displaysleep'
sysadminctl -screenLock status
