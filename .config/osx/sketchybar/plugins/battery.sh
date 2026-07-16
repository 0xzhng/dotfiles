#!/usr/bin/env sh

# Waybar battery format: {icon} {capacity}%
# Icons from Waybar: 󰂎 󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹
if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0x66b0c6ff \
    background.border_width=1 \
    background.border_color=0x99d9e2ff
  exit 0
fi

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" \
    background.drawing=off \
    background.border_width=0
  exit 0
fi

PERCENTAGE=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
CHARGING=$(pmset -g batt | grep 'AC Power')
POWER_SOURCE="Battery"
TIME_LEFT=$(pmset -g batt | awk -F';' '/InternalBattery/ {gsub(/^ +| +$/, "", $3); gsub(/ *present: true/, "", $3); print $3; exit}')

if [ -n "$CHARGING" ]; then
  POWER_SOURCE="AC Adapter"
fi

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" icon="󰂎" label="N/A"
  exit 0
fi

if [ -n "$CHARGING" ]; then
  ICON="󰂄"
  COLOR="0xffb0c6ff"  # primary
elif [ "$PERCENTAGE" -le 15 ]; then
  ICON="󰂎"
  COLOR="0xffffb4ab"  # error color for critical
elif [ "$PERCENTAGE" -le 25 ]; then
  ICON="󰁺"
  COLOR="0xffffb4ab"
elif [ "$PERCENTAGE" -le 35 ]; then
  ICON="󰁻"
  COLOR="0xffe0bbde"  # tertiary for warning zone
elif [ "$PERCENTAGE" -le 45 ]; then
  ICON="󰁼"
  COLOR="0xffc0c6dc"
elif [ "$PERCENTAGE" -le 55 ]; then
  ICON="󰁽"
  COLOR="0xffc0c6dc"
elif [ "$PERCENTAGE" -le 65 ]; then
  ICON="󰁾"
  COLOR="0xffb0c6ff"
elif [ "$PERCENTAGE" -le 75 ]; then
  ICON="󰁿"
  COLOR="0xffb0c6ff"
elif [ "$PERCENTAGE" -le 85 ]; then
  ICON="󰂀"
  COLOR="0xffb0c6ff"
elif [ "$PERCENTAGE" -le 95 ]; then
  ICON="󰂁"
  COLOR="0xffb0c6ff"
else
  ICON="󰁹"
  COLOR="0xffb0c6ff"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="${PERCENTAGE}%"

"$HOME/.config/sketchybar/plugins/battery_mode.sh" status >/dev/null 2>&1
