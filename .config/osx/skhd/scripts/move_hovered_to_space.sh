#!/usr/bin/env sh

SPACE_ID="$1"
[ -z "$SPACE_ID" ] && exit 1

CURRENT=$(yabai -m query --spaces 2>/dev/null | jq 'length' 2>/dev/null || echo 0)
if [ "$CURRENT" -lt "$SPACE_ID" ]; then
  for i in $(seq $((CURRENT + 1)) "$SPACE_ID"); do
    yabai -m space --create 2>/dev/null || true
  done
fi

# Hyprland-like behavior: use window under cursor as active target.
yabai -m window --focus mouse 2>/dev/null || true

# Move focused/hovered window to requested space.
yabai -m window --space "$SPACE_ID" 2>/dev/null || exit 1

# Follow the moved window to that space.
if [ "$SPACE_ID" = "10" ]; then
  KEY="0"
else
  KEY="$SPACE_ID"
fi

yabai -m space --focus "$SPACE_ID" 2>/dev/null || skhd -k "ctrl - $KEY"
