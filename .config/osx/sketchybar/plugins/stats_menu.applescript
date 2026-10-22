on run argv
  if (count of argv) is not 1 then error "Specify CPU, GPU, RAM, or Sensors."
  set moduleName to item 1 of argv
  if moduleName is not in {"CPU", "GPU", "RAM", "Sensors"} then error "Unknown Stats module."
  tell application "System Events"
    if not (exists process "Stats") then
      display notification "Open Stats first to use its menu." with title "SketchyBar"
      return
    end if
    tell process "Stats"
      repeat with statusBar in menu bars
        repeat with statusItem in menu bar items of statusBar
          set itemHelp to help of statusItem
          if itemHelp is not missing value then
            if itemHelp starts with (moduleName & ":") then
              click statusItem
              return
            end if
          end if
        end repeat
      end repeat
    end tell
  end tell
  display notification ("Enable the " & moduleName & " menu-bar widget in Stats.") with title "SketchyBar"
end run
