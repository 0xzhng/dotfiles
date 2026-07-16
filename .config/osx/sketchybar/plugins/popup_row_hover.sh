#!/usr/bin/env sh

ITEM_JSON=$(sketchybar --query "$NAME" 2>/dev/null) || exit 0

X=$(printf '%s' "$INFO" | jq -r '.x // empty' 2>/dev/null)
Y=$(printf '%s' "$INFO" | jq -r '.y // empty' 2>/dev/null)

if [ -z "$X" ] || [ -z "$Y" ]; then
  sketchybar --set "$NAME" background.drawing=off background.border_width=0
  exit 0
fi

OX=$(printf '%s' "$ITEM_JSON" | jq -r '.bounding_rects | to_entries[0].value.origin[0] // -9999')
OY=$(printf '%s' "$ITEM_JSON" | jq -r '.bounding_rects | to_entries[0].value.origin[1] // -9999')
W=$(printf '%s' "$ITEM_JSON" | jq -r '.bounding_rects | to_entries[0].value.size[0] // 0')
H=$(printf '%s' "$ITEM_JSON" | jq -r '.bounding_rects | to_entries[0].value.size[1] // 0')

if [ "$OX" = "-9999" ] || [ "$W" = "0" ] || [ "$H" = "0" ]; then
  sketchybar --set "$NAME" background.drawing=off background.border_width=0
  exit 0
fi

X_MAX=$(awk "BEGIN {print $OX + $W}")
Y_MAX=$(awk "BEGIN {print $OY + $H}")

INSIDE=$(awk "BEGIN {if ($X >= $OX && $X <= $X_MAX && $Y >= $OY && $Y <= $Y_MAX) print 1; else print 0}")

if [ "$INSIDE" = "1" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0x66b0c6ff \
    background.border_width=1 \
    background.border_color=0x99d9e2ff
else
  sketchybar --set "$NAME" background.drawing=off background.border_width=0
fi
