#!/usr/bin/env sh

open_panel() {
  local process_name="$1"
  local keyword="$2"
  osascript <<EOF >/dev/null 2>&1
tell application "System Events"
  if not UI elements enabled then error "Accessibility disabled"
  tell process "$process_name"
    set targetItem to missing value
    repeat with mi in every menu bar item of menu bar 1
      set d to ""
      set n to ""
      try
        set d to description of mi
      end try
      try
        set n to name of mi
      end try
      if ((d contains "$keyword") or (n contains "$keyword")) then
        set targetItem to mi
        exit repeat
      end if
    end repeat
    if targetItem is not missing value then
      click targetItem
    else
      error "Menu item not found"
    end if
  end tell
end tell
EOF
}

toggle_notification_center() {
  osascript <<'EOF' >/dev/null 2>&1
tell application "System Events"
  if UI elements enabled then
    tell process "ControlCenter"
      set targetItem to missing value
      repeat with mi in every menu bar item of menu bar 1
        set d to ""
        try
          set d to description of mi
        end try
        if d contains "Clock" or d contains "Date" then
          set targetItem to mi
          exit repeat
        end if
      end repeat
      if targetItem is not missing value then
        click targetItem
        return
      end if
    end tell

    if exists process "NotificationCenter" then
      tell process "NotificationCenter"
        repeat with w in windows
          try
            click w
            return
          end try
        end repeat
      end tell
    end if
  end if
end tell
error "fallback"
EOF
}

case "$1" in
  wifi)
    open_panel "ControlCenter" "Wi-Fi" || open "x-apple.systempreferences:com.apple.wifi"
    ;;
  battery)
    open_panel "ControlCenter" "Battery" || open "x-apple.systempreferences:com.apple.preference.battery"
    ;;
  notification)
    toggle_notification_center \
      || open -a NotificationCenter \
      || open -b com.apple.notificationcenterui
    ;;
  sound)
    open_panel "ControlCenter" "Sound" || open "x-apple.systempreferences:com.apple.preference.sound"
    ;;
esac
