-- Press CodexBar's actual status item, not a replacement popup.
tell application "System Events"
  if not (exists process "CodexBar") then
    display notification "Open CodexBar first to use its menu." with title "SketchyBar"
    return
  end if
  tell process "CodexBar"
    click menu bar item 1 of menu bar 2
  end tell
end tell
