#!/usr/bin/env sh

# Highlight active workspace, dim inactive
# Uses yabai to detect which space is focused
if [ "$SELECTED" = "true" ]; then
  sketchybar --set "$NAME" \
    icon.highlight=on \
    background.drawing=on
else
  sketchybar --set "$NAME" \
    icon.highlight=off \
    background.drawing=off
fi
