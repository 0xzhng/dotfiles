#!/usr/bin/env sh

DEFAULT_TOP=2
DEFAULT_BOTTOM=17
DEFAULT_LEFT=17
DEFAULT_RIGHT=17
DEFAULT_GAP=4

WINDOW_JSON=$(yabai -m query --windows --window 2>/dev/null || printf '{}')
SPACE_JSON=$(yabai -m query --spaces --space 2>/dev/null) || exit 1

IS_FULLSCREEN=$(printf '%s' "$WINDOW_JSON" | jq -r '."has-fullscreen-zoom" // false')
SPACE_INDEX=$(printf '%s' "$SPACE_JSON" | jq -r '.index // 0')
STATE_FILE="/tmp/yabai_hypr_fullscreen_space_${SPACE_INDEX}.state"

if [ -f "$STATE_FILE" ]; then
  if [ "$IS_FULLSCREEN" = "true" ]; then
    yabai -m window --toggle zoom-fullscreen 2>/dev/null || true
  fi
  yabai -m space --padding abs:$DEFAULT_TOP:$DEFAULT_BOTTOM:$DEFAULT_LEFT:$DEFAULT_RIGHT
  yabai -m space --gap abs:$DEFAULT_GAP
  rm -f "$STATE_FILE"
  exit 0
fi

yabai -m space --padding abs:0:0:0:0
yabai -m space --gap abs:0
if [ "$IS_FULLSCREEN" != "true" ]; then
  yabai -m window --toggle zoom-fullscreen
fi
touch "$STATE_FILE"
