#!/usr/bin/env sh

TARGET="$1"
[ -z "$TARGET" ] && exit 0

STATE=$(sketchybar --query "$TARGET" 2>/dev/null | jq -r '.popup.drawing // "off"')

sketchybar --set apple_tray popup.drawing=off \
           --set battery popup.drawing=off \
           --set volume popup.drawing=off \
           --set temperature popup.drawing=off

if [ "$STATE" != "on" ]; then
  sketchybar --set "$TARGET" popup.drawing=on
fi
