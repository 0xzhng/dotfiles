#!/usr/bin/env sh

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0x66b0c6ff \
    background.border_width=1 \
    background.border_color=0x99d9e2ff
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    background.border_width=0
fi
