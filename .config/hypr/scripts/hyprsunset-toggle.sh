#!/bin/bash

night_temp="${HYPRSUNSET_NIGHT_TEMP:-3400}"

notify() {
  local title="$1"
  local body="$2"

  if command -v notify-send >/dev/null 2>&1; then
    notify-send -e -u low -a hyprsunset "$title" "$body"
  elif command -v hyprctl >/dev/null 2>&1; then
    hyprctl notify 1 1500 "rgb(88c0d0)" "$title: $body" >/dev/null 2>&1
  fi
}

if pgrep -x hyprsunset >/dev/null; then
  pkill -x hyprsunset
  notify "Night mode" "Off"
else
  if command -v hyprsunset >/dev/null 2>&1; then
    hyprsunset -t "$night_temp" >/dev/null 2>&1 &
    notify "Night mode" "On (${night_temp}K)"
  else
    notify "Night mode" "hyprsunset not found"
  fi
fi
