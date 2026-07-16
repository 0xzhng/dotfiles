#!/usr/bin/env sh

STATE_DIR="$HOME/.cache/sketchybar"
EMA_FILE="$STATE_DIR/temp_estimate_ema"
mkdir -p "$STATE_DIR"

if [ "$SENDER" = "mouse.exited" ]; then
  sketchybar --set "$NAME" background.drawing=off background.border_width=0
  exit 0
fi

if [ "$SENDER" = "mouse.entered" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color=0x66b0c6ff \
    background.border_width=1 \
    background.border_color=0x99d9e2ff
fi

CPU_LOAD=$(top -l 2 -n 0 | awk '/CPU usage/ {line=$0} END {split(line,a,"[:,%]"); printf "%.0f", (a[2]+a[4])}')
[ -z "$CPU_LOAD" ] && CPU_LOAD=0

GPU_LOAD=$(ioreg -r -d 1 -c AGXAccelerator | awk -F'"Device Utilization %"=' '/"PerformanceStatistics"/ {print $2; exit}' | awk -F',' '{gsub(/[^0-9]/, "", $1); print $1}')
[ -z "$GPU_LOAD" ] && GPU_LOAD=0

BATTERY_DATA=$(ioreg -r -n AppleSmartBattery -w 0 -l)
RAW_BATTERY_TEMP=$(echo "$BATTERY_DATA" | awk -F'= ' '/"Temperature"/ {gsub(/[^0-9]/, "", $2); print $2; exit}')
[ -z "$RAW_BATTERY_TEMP" ] && RAW_BATTERY_TEMP=$(echo "$BATTERY_DATA" | awk -F'= ' '/"VirtualTemperature"/ {gsub(/[^0-9]/, "", $2); print $2; exit}')

BATTERY_TEMP=$(awk "BEGIN {
  raw=$RAW_BATTERY_TEMP
  if (raw >= 2000) c=(raw/10)-273.15
  else if (raw >= 500) c=raw/100
  else c=raw/10
  printf \"%.1f\", c
}")

THERM_OUT=$(pmset -g therm 2>/dev/null)
PRESSURE="Nominal"
OFFSET=0

if printf '%s' "$THERM_OUT" | grep -qi 'critical'; then
  PRESSURE="Critical"
  OFFSET=20
elif printf '%s' "$THERM_OUT" | grep -qi 'serious'; then
  PRESSURE="Serious"
  OFFSET=12
elif printf '%s' "$THERM_OUT" | grep -qi 'fair'; then
  PRESSURE="Fair"
  OFFSET=5
fi

RAW_ESTIMATE=$(awk "BEGIN {printf \"%.2f\", $BATTERY_TEMP + ($CPU_LOAD*0.10) + ($GPU_LOAD*0.08) + $OFFSET}")
CLAMPED_ESTIMATE=$(awk "BEGIN {x=$RAW_ESTIMATE; if (x < 30) x=30; if (x > 105) x=105; printf \"%.2f\", x}")

if [ -f "$EMA_FILE" ]; then
  PREV_EMA=$(cat "$EMA_FILE" 2>/dev/null)
else
  PREV_EMA="$CLAMPED_ESTIMATE"
fi

EMA_ESTIMATE=$(awk "BEGIN {printf \"%.2f\", (0.70*$PREV_EMA) + (0.30*$CLAMPED_ESTIMATE)}")
printf '%s' "$EMA_ESTIMATE" > "$EMA_FILE"

DISPLAY_TEMP=$(awk "BEGIN {printf \"%.0f\", $EMA_ESTIMATE}")

sketchybar --set "$NAME" label="~${DISPLAY_TEMP}C"

sketchybar --set temperature.inputs \
  label="B ${BATTERY_TEMP}C | CPU ${CPU_LOAD}% | GPU ${GPU_LOAD}% | P ${PRESSURE} (+${OFFSET})"

sketchybar --set temperature.detail \
  label="raw ${RAW_ESTIMATE}C -> ema ${EMA_ESTIMATE}C -> shown ~${DISPLAY_TEMP}C"
