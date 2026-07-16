#!/usr/bin/env sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

ICON=$(sketchybar --query volume 2>/dev/null | jq -r '.icon.value // ""')

if [ "$ICON" = "󰋋" ] || [ "$ICON" = "󰂯" ]; then
  "$SCRIPT_DIR/toggle_popup.sh" volume
else
  "$SCRIPT_DIR/native_panel.sh" sound
fi
