#!/usr/bin/env sh

# Mimic clicking the macOS green button (zoom/fullscreen behavior).
# Ghostty requires window decorations enabled for native fullscreen.
APP=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // ""')
APP_LC=$(printf "%s" "$APP" | tr '[:upper:]' '[:lower:]')

if [ "$APP_LC" = "ghostty" ]; then
  osascript -e 'tell application "Ghostty" to activate' \
            -e 'tell application "System Events" to keystroke "f" using {control down, command down}'
  exit 0
fi

osascript <<'EOF'
tell application "System Events"
  set frontApp to name of first application process whose frontmost is true
  tell process frontApp
    try
      tell front window
        set zoomButton to first button whose subrole is "AXZoomButton"
        click zoomButton
      end tell
    on error
      try
        click menu item "Toggle Full Screen" of menu 1 of menu bar item "Window" of menu bar 1
      on error
        try
          click menu item "Enter Full Screen" of menu 1 of menu bar item "View" of menu bar 1
        on error
          try
            click menu item "Zoom" of menu 1 of menu bar item "Window" of menu bar 1
          end try
        end try
      end try
    end try
  end tell
end tell
EOF
