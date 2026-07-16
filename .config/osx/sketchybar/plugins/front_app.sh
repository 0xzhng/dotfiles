#!/usr/bin/env sh

# Window indicator: focused app plus current space index.
APP_NAME=""
SPACE_INDEX=""

if [ "$SENDER" = "front_app_switched" ] && [ -n "$INFO" ]; then
  APP_NAME="$INFO"
fi

if command -v yabai >/dev/null 2>&1; then
  APP_NAME_YABAI=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty')
  [ -n "$APP_NAME_YABAI" ] && APP_NAME="$APP_NAME_YABAI"

  SPACE_INDEX_YABAI=$(yabai -m query --spaces --space 2>/dev/null | jq -r '.index // empty')
  [ -n "$SPACE_INDEX_YABAI" ] && SPACE_INDEX="$SPACE_INDEX_YABAI"
fi

if [ -z "$APP_NAME" ]; then
  APP_NAME=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
fi

APP_NAME=$(echo "$APP_NAME" | cut -c1-26)

if [ -n "$SPACE_INDEX" ]; then
  LABEL="$APP_NAME • $SPACE_INDEX"
else
  LABEL="$APP_NAME"
fi

sketchybar --set "$NAME" label="$LABEL"
