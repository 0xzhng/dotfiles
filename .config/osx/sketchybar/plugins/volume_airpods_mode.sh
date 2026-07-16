#!/usr/bin/env sh

STATE_DIR="$HOME/.cache/sketchybar"
STATE_FILE="$STATE_DIR/airpods_noise_mode"
mkdir -p "$STATE_DIR"

MODE="$1"

run_shortcut() {
  NAME="$1"
  shortcuts run "$NAME" >/dev/null 2>&1
}

apply_mode_via_ui() {
  case "$1" in
    cancel) IDX=4 ;;
    off) IDX=5 ;;
    transparency) IDX=6 ;;
    *) return 1 ;;
  esac

  osascript <<EOF >/dev/null 2>&1
tell application "System Events"
  if not UI elements enabled then error "AX disabled"

  tell process "ControlCenter"
    set soundItem to missing value
    repeat with mi in every menu bar item of menu bar 1
      set d to ""
      try
        set d to description of mi
      end try
      if d contains "Sound" or d contains "Volume" then
        set soundItem to mi
        exit repeat
      end if
    end repeat
    if soundItem is missing value then error "Sound item not found"

    click soundItem

    set opened to false
    repeat 20 times
      delay 0.05
      if (count of windows) > 0 then
        set opened to true
        exit repeat
      end if
    end repeat
    if not opened then error "Sound panel not opened"

    set boxes to {}
    repeat with e in entire contents of window 1
      try
        if class of e is checkbox then set end of boxes to e
      end try
    end repeat

    if (count of boxes) < ${IDX} then error "Noise mode controls not found"
    click item ${IDX} of boxes
    delay 0.08

    key code 53
  end tell
end tell
EOF
}

apply_mode_backend() {
  case "$1" in
    transparency)
      run_shortcut "AirPods Transparency" || run_shortcut "AirPods: Transparency" || apply_mode_via_ui transparency
      ;;
    cancel)
      run_shortcut "AirPods Noise Cancellation" || run_shortcut "AirPods: Noise Cancellation" || apply_mode_via_ui cancel
      ;;
    off)
      run_shortcut "AirPods Noise Off" || run_shortcut "AirPods: Noise Off" || apply_mode_via_ui off
      ;;
    *)
      return 1
      ;;
  esac
}

if [ "$MODE" = "status" ]; then
  :
elif [ "$MODE" = "transparency" ] || [ "$MODE" = "cancel" ] || [ "$MODE" = "off" ]; then
  if apply_mode_backend "$MODE"; then
    printf "%s" "$MODE" > "$STATE_FILE"
  else
    osascript -e 'display notification "Create Shortcuts: AirPods Transparency / AirPods Noise Cancellation / AirPods Noise Off" with title "AirPods Backend Not Configured"' >/dev/null 2>&1 || true
  fi
else
  exit 0
fi

CURRENT="off"
[ -f "$STATE_FILE" ] && CURRENT=$(cat "$STATE_FILE")

TP_LABEL="Transparency"
NC_LABEL="Noise Cancellation"
OF_LABEL="Noise Control Off"

[ "$CURRENT" = "transparency" ] && TP_LABEL="✓ Transparency"
[ "$CURRENT" = "cancel" ] && NC_LABEL="✓ Noise Cancellation"
[ "$CURRENT" = "off" ] && OF_LABEL="✓ Noise Control Off"

sketchybar --set volume.airpods.transparency label="$TP_LABEL" \
           --set volume.airpods.cancel label="$NC_LABEL" \
           --set volume.airpods.off label="$OF_LABEL"
