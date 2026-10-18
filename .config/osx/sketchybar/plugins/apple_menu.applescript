use framework "AppKit"
use scripting additions

-- The menu-bar owner can differ from the frontmost app (e.g. a Stats popup).
set menuOwner to current application's NSWorkspace's sharedWorkspace()'s menuBarOwningApplication()
set ownerPID to (menuOwner's processIdentifier()) as integer
tell application "System Events"
  tell (first application process whose unix id is ownerPID)
    click menu bar item 1 of menu bar 1
  end tell
end tell
return
