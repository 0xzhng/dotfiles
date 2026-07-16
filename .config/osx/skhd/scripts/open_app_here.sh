#!/usr/bin/env sh
# Open an app as a NEW instance on the CURRENT space.
# Usage: open_app_here.sh "AppName"
#
# Solves three problems:
#   1. Apps reopen in their last workspace instead of current
#   2. Apps don't create multiple instances
#   3. Focus jumps to another space when launching

APP_NAME="$1"
[ -z "$APP_NAME" ] && { echo "Usage: $0 AppName"; exit 1; }

# Capture current space BEFORE launching anything
CURRENT_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')

# Get window IDs for this app BEFORE launching
OLD_WINDOW_IDS=$(yabai -m query --windows 2>/dev/null | jq -r "[.[] | select(.app==\"$APP_NAME\")] | .[].id" | tr '\n' ' ')

# Launch a new instance. Different apps need different approaches:
case "$APP_NAME" in
  Zen|"Zen Browser")
    # Zen needs --new-window to actually create a separate window
    open -na "Zen" --args --new-window
    ;;
  Ghostty)
    # Ghostty respects -n for new instance
    open -na "Ghostty"
    ;;
  Finder)
    # Finder: open a new window via AppleScript
    osascript -e 'tell application "Finder" to make new Finder window' &
    ;;
  *)
    # Generic: try -n (new instance), fall back to AppleScript new window
    open -na "$APP_NAME" 2>/dev/null || \
    osascript -e "tell application \"$APP_NAME\" to activate" -e "tell application \"System Events\" to keystroke \"n\" using command down"
    ;;
esac

# Wait for the new window to appear
sleep 0.3

# Find the NEW window (one that wasn't in our old list)
NEW_WINDOW_ID=""
for _ in 1 2 3 4 5; do
  ALL_IDS=$(yabai -m query --windows 2>/dev/null | jq -r "[.[] | select(.app==\"$APP_NAME\")] | .[].id")
  for wid in $ALL_IDS; do
    # Check if this ID is new (not in OLD_WINDOW_IDS)
    case " $OLD_WINDOW_IDS " in
      *" $wid "*) ;;  # Already existed
      *) NEW_WINDOW_ID="$wid"; break 2 ;;
    esac
  done
  sleep 0.15
done

# If we found a new window, move it to the original space and focus
if [ -n "$NEW_WINDOW_ID" ] && [ -n "$CURRENT_SPACE" ]; then
  yabai -m window "$NEW_WINDOW_ID" --space "$CURRENT_SPACE" 2>/dev/null || true
  yabai -m space --focus "$CURRENT_SPACE" 2>/dev/null || true
  yabai -m window --focus "$NEW_WINDOW_ID" 2>/dev/null || true
fi
