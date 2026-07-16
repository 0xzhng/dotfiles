#!/usr/bin/env sh

set_row_off() {
  sketchybar --set "$1" background.drawing=off background.border_width=0
}

set_row_on() {
  sketchybar --set "$1" \
    background.drawing=on \
    background.color=0x66b0c6ff \
    background.border_width=1 \
    background.border_color=0x99d9e2ff
}

clear_all_rows() {
  for item in \
    apple.system_settings apple.finder apple.lock apple.sleep apple.restart apple.shutdown apple.logout \
    battery.mode.low battery.mode.auto battery.mode.high battery.mode.setup battery.settings \
    volume.airpods.transparency volume.airpods.cancel volume.airpods.off volume.airpods.settings
  do
    set_row_off "$item"
  done
}

highlight_rows_for_popup() {
  popup_owner="$1"
  shift

  popup_state=$(sketchybar --query "$popup_owner" 2>/dev/null | jq -r '.popup.drawing // "off"')
  if [ "$popup_state" != "on" ]; then
    for item in "$@"; do
      set_row_off "$item"
    done
    return
  fi

  x=$(printf '%s' "$INFO" | jq -r '.x // empty' 2>/dev/null)
  y=$(printf '%s' "$INFO" | jq -r '.y // empty' 2>/dev/null)
  if [ -z "$x" ] || [ -z "$y" ]; then
    return
  fi

  for item in "$@"; do
    item_json=$(sketchybar --query "$item" 2>/dev/null)
    ox=$(printf '%s' "$item_json" | jq -r '.bounding_rects | to_entries[0].value.origin[0] // -9999')
    oy=$(printf '%s' "$item_json" | jq -r '.bounding_rects | to_entries[0].value.origin[1] // -9999')
    w=$(printf '%s' "$item_json" | jq -r '.bounding_rects | to_entries[0].value.size[0] // 0')
    h=$(printf '%s' "$item_json" | jq -r '.bounding_rects | to_entries[0].value.size[1] // 0')

    if [ "$ox" = "-9999" ] || [ "$w" = "0" ] || [ "$h" = "0" ]; then
      set_row_off "$item"
      continue
    fi

    inside=$(awk "BEGIN {if ($x >= $ox && $x <= ($ox + $w) && $y >= $oy && $y <= ($oy + $h)) print 1; else print 0}")
    if [ "$inside" = "1" ]; then
      set_row_on "$item"
    else
      set_row_off "$item"
    fi
  done
}

case "$SENDER" in
  mouse.entered.global)
    highlight_rows_for_popup apple_tray apple.system_settings apple.finder apple.lock apple.sleep apple.restart apple.shutdown apple.logout
    highlight_rows_for_popup battery battery.mode.low battery.mode.auto battery.mode.high battery.mode.setup battery.settings
    highlight_rows_for_popup volume volume.airpods.transparency volume.airpods.cancel volume.airpods.off volume.airpods.settings
    ;;
  mouse.exited.global|front_app_switched|space_change)
    clear_all_rows
    sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off --set volume popup.drawing=off --set temperature popup.drawing=off
    ;;
  *)
    ;;
esac
