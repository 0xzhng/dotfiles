#!/usr/bin/env sh

# Waybar pulseaudio format: {icon} {volume}%
# Icons: "󰕿" (low), "󰖀" (mid), "󰕾" (high)
# Muted: 󰖁

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

if [ "$SENDER" = "volume_change" ]; then
  VOL=$INFO
else
  VOL=$(osascript -e 'output volume of (get volume settings)')
fi

MUTED=$(osascript -e 'output muted of (get volume settings)')

OUTPUT_INFO=$(system_profiler SPAudioDataType 2>/dev/null | awk '/^[[:space:]]+[[:graph:]].*:$/{name=$0; sub(/^[[:space:]]+/,"",name); sub(/:$/, "", name)} /Transport:/{t=$0; sub(/.*Transport:[[:space:]]*/,"",t)} /Default Output Device: Yes/{print name "|" t; exit}')
OUTPUT_NAME=${OUTPUT_INFO%%|*}
OUTPUT_TRANSPORT=${OUTPUT_INFO##*|}

if [ "$MUTED" = "true" ] || [ "$VOL" -eq 0 ]; then
  ICON="󰖁"
  COLOR="0xff8f9099"  # outline (dimmed)
  LABEL=""
elif [ "$OUTPUT_TRANSPORT" = "Bluetooth" ] && [ -n "$OUTPUT_NAME" ]; then
  if printf '%s' "$OUTPUT_NAME" | grep -qi 'airpods\|earbuds\|beats'; then
    ICON="󰋋"
  else
    ICON="󰂯"
  fi
  COLOR="0xffb0c6ff"
  LABEL="${VOL}%"
elif [ "$VOL" -le 25 ]; then
  ICON="󰕿"
  COLOR="0xffb0c6ff"
  LABEL="${VOL}%"
elif [ "$VOL" -le 50 ]; then
  ICON="󰖀"
  COLOR="0xffb0c6ff"
  LABEL="${VOL}%"
elif [ "$VOL" -le 75 ]; then
  ICON="󰕾"
  COLOR="0xffb0c6ff"
  LABEL="${VOL}%"
else
  ICON="󰕾"
  COLOR="0xffb0c6ff"
  LABEL="${VOL}%"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="$COLOR" \
  label="$LABEL"

"$(cd "$(dirname "$0")" && pwd)/volume_airpods_mode.sh" status
