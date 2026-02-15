#!/bin/bash

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"
SINK="@DEFAULT_AUDIO_SINK@"
SOURCE="@DEFAULT_AUDIO_SOURCE@"

if command -v pamixer >/dev/null 2>&1; then
  AUDIO_BACKEND="pamixer"
elif command -v wpctl >/dev/null 2>&1; then
  AUDIO_BACKEND="wpctl"
else
  echo "Error: either pamixer or wpctl is required for $0" >&2
  exit 1
fi

wpctl_get_raw() {
  wpctl get-volume "$1" 2>/dev/null
}

wpctl_percent_from_raw() {
  local level
  level=$(awk '{print $2}' <<<"$1")
  if [[ -z "$level" ]]; then
    echo 0
  else
    awk -v vol="$level" 'BEGIN { printf "%.0f", vol * 100 }'
  fi
}

wpctl_is_muted_from_raw() {
  [[ "$1" == *"[MUTED]"* ]]
}

get_sink_volume_value() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    pamixer --get-volume 2>/dev/null || echo 0
  else
    local raw
    raw=$(wpctl_get_raw "$SINK")
    wpctl_percent_from_raw "$raw"
  fi
}

get_source_volume_value() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    pamixer --default-source --get-volume 2>/dev/null || echo 0
  else
    local raw
    raw=$(wpctl_get_raw "$SOURCE")
    wpctl_percent_from_raw "$raw"
  fi
}

is_sink_muted() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    [[ "$(pamixer --get-mute 2>/dev/null)" == "true" ]]
  else
    local raw
    raw=$(wpctl_get_raw "$SINK")
    wpctl_is_muted_from_raw "$raw"
  fi
}

is_source_muted() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    [[ "$(pamixer --default-source --get-mute 2>/dev/null)" == "true" ]]
  else
    local raw
    raw=$(wpctl_get_raw "$SOURCE")
    wpctl_is_muted_from_raw "$raw"
  fi
}

# Get Volume
get_volume() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    volume=$(pamixer --get-volume 2>/dev/null || echo 0)
    if [[ "$(pamixer --get-mute 2>/dev/null)" == "true" || "$volume" -eq 0 ]]; then
      echo "Muted"
    else
      echo "$volume %"
    fi
  else
    local raw
    raw=$(wpctl_get_raw "$SINK")
    local percent
    percent=$(wpctl_percent_from_raw "$raw")
    if wpctl_is_muted_from_raw "$raw" || [[ "$percent" -eq 0 ]]; then
      echo "Muted"
    else
      echo "$percent %"
    fi
  fi
}

# Get icons
get_icon() {
  current=$(get_volume)
  if [[ "$current" == "Muted" ]]; then
    echo "$iDIR/volume-mute.png"
  elif [[ "${current%\%}" -le 30 ]]; then
    echo "$iDIR/volume-low.png"
  elif [[ "${current%\%}" -le 60 ]]; then
    echo "$iDIR/volume-mid.png"
  else
    echo "$iDIR/volume-high.png"
  fi
}

# Notify
notify_user() {
  if [[ "$(get_volume)" == "Muted" ]]; then
    notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume:" " Muted"
  else
    notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" &&
      "$sDIR/Sounds.sh" --volume
  fi
}

# Increase Volume
inc_volume() {
  if is_sink_muted; then
    toggle_mute
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer -i 5 --allow-boost --set-limit 150 && notify_user
    else
      wpctl set-volume "$SINK" 5%+ --limit 1.5 && notify_user
    fi
  fi
}

# Decrease Volume
dec_volume() {
  if is_sink_muted; then
    toggle_mute
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer -d 5 && notify_user
    else
      wpctl set-volume "$SINK" 5%- && notify_user
    fi
  fi
}

# Toggle Mute
toggle_mute() {
  if is_sink_muted; then
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer -u && notify-send -e -u low -i "$(get_icon)" " Volume:" " Switched ON"
    else
      wpctl set-mute "$SINK" toggle
      notify-send -e -u low -i "$(get_icon)" " Volume:" " Switched ON"
    fi
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer -m && notify-send -e -u low -i "$iDIR/volume-mute.png" " Mute"
    else
      wpctl set-mute "$SINK" toggle
      notify-send -e -u low -i "$iDIR/volume-mute.png" " Mute"
    fi
  fi
}

# Toggle Mic
toggle_mic() {
  if is_source_muted; then
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer --default-source -u && notify-send -e -u low -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
    else
      wpctl set-mute "$SOURCE" toggle
      notify-send -e -u low -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
    fi
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer --default-source -m && notify-send -e -u low -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
    else
      wpctl set-mute "$SOURCE" toggle
      notify-send -e -u low -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
    fi
  fi
}
# Get Mic Icon
get_mic_icon() {
  current=$(get_mic_volume)
  if [[ "$current" == "Muted" ]]; then
    echo "$iDIR/microphone-mute.png"
  else
    echo "$iDIR/microphone.png"
  fi
}

# Get Microphone Volume
get_mic_volume() {
  if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
    volume=$(pamixer --default-source --get-volume 2>/dev/null || echo 0)
    if [[ "$(pamixer --default-source --get-mute 2>/dev/null)" == "true" || "$volume" -eq 0 ]]; then
      echo "Muted"
    else
      echo "$volume %"
    fi
  else
    local raw
    raw=$(wpctl_get_raw "$SOURCE")
    local percent
    percent=$(wpctl_percent_from_raw "$raw")
    if wpctl_is_muted_from_raw "$raw" || [[ "$percent" -eq 0 ]]; then
      echo "Muted"
    else
      echo "$percent %"
    fi
  fi
}

# Notify for Microphone
notify_mic_user() {
  local icon volume_value
  icon=$(get_mic_icon)
  volume_value=$(get_source_volume_value)
  notify-send -e -h int:value:"$volume_value" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon" " Mic Level:" " ${volume_value} %"
}

# Increase MIC Volume
inc_mic_volume() {
  if is_source_muted; then
    toggle_mic
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer --default-source -i 5 && notify_mic_user
    else
      wpctl set-volume "$SOURCE" 5%+ && notify_mic_user
    fi
  fi
}

# Decrease MIC Volume
dec_mic_volume() {
  if is_source_muted; then
    toggle_mic
  else
    if [[ "$AUDIO_BACKEND" == "pamixer" ]]; then
      pamixer --default-source -d 5 && notify_mic_user
    else
      wpctl set-volume "$SOURCE" 5%- && notify_mic_user
    fi
  fi
}

# Execute accordingly
if [[ "$1" == "--get" ]]; then
  get_volume
elif [[ "$1" == "--inc" ]]; then
  inc_volume
elif [[ "$1" == "--dec" ]]; then
  dec_volume
elif [[ "$1" == "--toggle" ]]; then
  toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
  toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
  get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
  get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
  inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
  dec_mic_volume
else
  get_volume
fi
