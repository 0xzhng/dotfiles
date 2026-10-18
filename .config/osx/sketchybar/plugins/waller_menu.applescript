-- Press Waller's original status item, without launching a closed app.
tell application "System Events"
  if not (exists process "Waller") then return
  tell process "Waller"
    repeat with statusBar in menu bars
      repeat with statusItem in menu bar items of statusBar
        if (description of statusItem) is "Live Wallpaper" then
          click statusItem
          return
        end if
      end repeat
    end repeat
  end tell
end tell
error "Waller's Live Wallpaper status menu is unavailable."
