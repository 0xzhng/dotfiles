#!/usr/bin/env sh

CURRENT_SPACE=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')

# Ask Zen for a new window
open -a "Zen"
sleep 0.20
osascript -e 'tell application "System Events" to keystroke "n" using command down'
sleep 0.35

# Try to keep the new Zen window on the original space
if [ -n "$CURRENT_SPACE" ]; then
  ZEN_WINDOW_ID=$(yabai -m query --windows 2>/dev/null | jq -r '[.[] | select(.app=="Zen")] | sort_by(.id) | last | .id // empty')
  if [ -n "$ZEN_WINDOW_ID" ]; then
    yabai -m window "$ZEN_WINDOW_ID" --space "$CURRENT_SPACE" 2>/dev/null || true
    yabai -m space --focus "$CURRENT_SPACE" 2>/dev/null || true
    yabai -m window --focus "$ZEN_WINDOW_ID" 2>/dev/null || true
  fi
fi
