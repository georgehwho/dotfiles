#!/bin/bash
# Keep the Mac awake so herdr sessions and remote Claude sessions keep running;
# sleep only on purpose (the "Lock and Sleep" Raycast command).
# Needs sudo. Safe to re-run. Undo: sudo pmset restoredefaults
set -e

# Never idle-sleep, on the charger or on battery. The display still turns off.
sudo pmset -a sleep 0
sudo pmset -c displaysleep 10
sudo pmset -b displaysleep 5

# Require the password the moment the display sleeps or the Mac sleeps,
# so sleeping also locks (was a 5 minute grace period)
sysadminctl -screenLock immediate -password -

echo "Power settings now:"
pmset -g custom | grep -E 'Power:| sleep |displaysleep'
sysadminctl -screenLock status
