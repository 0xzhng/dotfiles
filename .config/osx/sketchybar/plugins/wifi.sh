#!/usr/bin/env sh

STATE_DIR="$HOME/.cache/sketchybar"
STATE_FILE="$STATE_DIR/wifi_mode"
STATS_FILE="$STATE_DIR/wifi_stats"
SSID_CACHE_FILE="$STATE_DIR/wifi_ssid"
mkdir -p "$STATE_DIR"

format_rate() {
  BYTES_PER_SEC="$1"
  awk -v b="$BYTES_PER_SEC" 'BEGIN {
    split("B K M G T", u, " ")
    i = 1
    while (b >= 1024 && i < 5) {
      b = b / 1024
      i++
    }
    if (i == 1 || b >= 100) {
      printf "%.0f%s", b, u[i]
    } else {
      printf "%.1f%s", b, u[i]
    }
  }'
}

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

if [ "$SENDER" = "mouse.clicked" ] || [ "$1" = "toggle" ]; then
  MODE="ssid"
  [ -f "$STATE_FILE" ] && MODE=$(cat "$STATE_FILE")
  if [ "$MODE" = "ssid" ]; then
    MODE="speed"
  else
    MODE="ssid"
  fi
  printf "%s" "$MODE" > "$STATE_FILE"
fi

MODE="ssid"
[ -f "$STATE_FILE" ] && MODE=$(cat "$STATE_FILE")

WIFI_DEV=$(networksetup -listallhardwareports 2>/dev/null | awk '/Hardware Port: (Wi-Fi|AirPort)/ {getline; print $2; exit}')
[ -z "$WIFI_DEV" ] && WIFI_DEV="en0"

RAW_NETWORK=$(networksetup -getairportnetwork "$WIFI_DEV" 2>/dev/null)
SSID=$(printf '%s' "$RAW_NETWORK" | awk -F': ' '/Current Wi-Fi Network/ {print $2}')
SUMMARY=$(ipconfig getsummary "$WIFI_DEV" 2>/dev/null)

if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
  # Try alternative method
  SSID=$(printf '%s' "$SUMMARY" | awk -F ' SSID : ' '/ SSID : / {print $2}')
fi

if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
  # Newer macOS summaries may expose NetworkID instead of SSID
  SSID=$(printf '%s' "$SUMMARY" | awk -F ' NetworkID : ' '/ NetworkID : / {print $2; exit}')
fi

if [ -z "$SSID" ] || [ "$SSID" = "<redacted>" ]; then
  AIRPORT_BIN="/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport"
  if [ -x "$AIRPORT_BIN" ]; then
    SSID=$($AIRPORT_BIN -I 2>/dev/null | awk -F': ' '/^[[:space:]]*SSID:/ {print $2; exit}')
  fi
fi

POWER_ON=$(networksetup -getairportpower "$WIFI_DEV" 2>/dev/null | awk '{print tolower($NF)}')
LINK_ACTIVE=$(printf '%s' "$SUMMARY" | awk -F' : ' '/LinkStatusActive/ {print tolower($2); exit}')

if [ "$POWER_ON" = "off" ] || [ "$LINK_ACTIVE" = "false" ]; then
  sketchybar --set "$NAME" icon="󰌙" icon.color="0xff8f9099" label="Off" label.width=0
  exit 0
fi

case "$SSID" in
  *"<redacted>"*|*"[redacted]"*)
    SSID=""
    ;;
esac

if [ -n "$SSID" ] && [ "$SSID" != "Connected" ]; then
  printf "%s" "$SSID" > "$SSID_CACHE_FILE"
fi

if [ -z "$SSID" ]; then
  SSID=$(networksetup -listpreferredwirelessnetworks "$WIFI_DEV" 2>/dev/null | awk 'NR==2 {sub(/^[[:space:]]+/, ""); print; exit}')
fi

if [ -z "$SSID" ]; then
  SSID="Connected"
fi

# Get signal strength (RSSI)
RSSI=$(printf '%s' "$SUMMARY" | awk -F' / ' '/Signal \/ Noise/ {gsub(" dBm","",$1); print $1; exit}')

if [ -z "$RSSI" ]; then
  ICON="󰤨"
elif [ "$RSSI" -ge -50 ]; then
  ICON="󰤨"
elif [ "$RSSI" -ge -60 ]; then
  ICON="󰤥"
elif [ "$RSSI" -ge -70 ]; then
  ICON="󰤢"
elif [ "$RSSI" -ge -80 ]; then
  ICON="󰤟"
else
  ICON="󰤯"
fi

sketchybar --set "$NAME" \
  icon="$ICON" \
  icon.color="0xffc0c6dc"

if [ "$MODE" = "ssid" ]; then
  SSID_DISPLAY=$(echo "$SSID" | cut -c1-14)
  LEN=$(printf "%s" "$SSID_DISPLAY" | awk '{print length}')
  WIDTH=$((LEN * 7 + 10))
  [ "$WIDTH" -lt 40 ] && WIDTH=40
  [ "$WIDTH" -gt 96 ] && WIDTH=96
  sketchybar --set "$NAME" label="$SSID_DISPLAY" label.width=$WIDTH
  exit 0
fi

IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2; exit}')
[ -z "$IFACE" ] && IFACE="$WIFI_DEV"

NOW=$(date +%s)
BYTES_IN=$(netstat -bI "$IFACE" 2>/dev/null | awk 'NR==2 {print $7}')
BYTES_OUT=$(netstat -bI "$IFACE" 2>/dev/null | awk 'NR==2 {print $10}')

if [ -z "$BYTES_IN" ] || [ -z "$BYTES_OUT" ]; then
  SSID_DISPLAY=$(echo "$SSID" | cut -c1-14)
  LEN=$(printf "%s" "$SSID_DISPLAY" | awk '{print length}')
  WIDTH=$((LEN * 7 + 10))
  [ "$WIDTH" -lt 40 ] && WIDTH=40
  [ "$WIDTH" -gt 96 ] && WIDTH=96
  sketchybar --set "$NAME" label="$SSID_DISPLAY" label.width=$WIDTH
  exit 0
fi

if [ ! -f "$STATS_FILE" ]; then
  printf "%s %s %s\n" "$NOW" "$BYTES_IN" "$BYTES_OUT" > "$STATS_FILE"
  sketchybar --set "$NAME" label="↑0K↓0K" label.width=84
  exit 0
fi

read -r LAST_TS LAST_IN LAST_OUT < "$STATS_FILE"
DT=$((NOW - LAST_TS))
[ "$DT" -le 0 ] && DT=1

DIN=$((BYTES_IN - LAST_IN))
DOUT=$((BYTES_OUT - LAST_OUT))
[ "$DIN" -lt 0 ] && DIN=0
[ "$DOUT" -lt 0 ] && DOUT=0

UP_BPS=$((DOUT / DT))
DOWN_BPS=$((DIN / DT))

UP_VAL=$(format_rate "$UP_BPS")
DOWN_VAL=$(format_rate "$DOWN_BPS")

printf "%s %s %s\n" "$NOW" "$BYTES_IN" "$BYTES_OUT" > "$STATS_FILE"
  sketchybar --set "$NAME" label="↑${UP_VAL}↓${DOWN_VAL}" label.width=84
