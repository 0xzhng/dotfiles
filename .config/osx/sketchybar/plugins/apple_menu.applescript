use scripting additions

on run argv
  if (count of argv) is not 1 then error "Expected one Apple menu action."
  set menuAction to item 1 of argv

  if menuAction is "about" then
    do shell script "/usr/bin/open '/System/Library/CoreServices/Applications/About This Mac.app'"
  else if menuAction is "settings" then
    do shell script "/usr/bin/open -a 'System Settings'"
  else if menuAction is "lock" then
    -- Control-Command-Q locks the session; display sleep alone does not.
    tell application "System Events" to keystroke "q" using {control down, command down}
  else if menuAction is "sleep" then
    do shell script "/usr/bin/pmset sleepnow"
  else if menuAction is "restart" then
    display dialog "Are you sure you want to restart this Mac? Save your work before continuing." with title "Restart" with icon caution buttons {"Cancel", "Restart"} default button "Cancel" cancel button "Cancel"
    tell application "System Events" to restart
  else if menuAction is "shutdown" then
    display dialog "Are you sure you want to shut down this Mac? Save your work before continuing." with title "Shut Down" with icon caution buttons {"Cancel", "Shut Down"} default button "Cancel" cancel button "Cancel"
    tell application "System Events" to shut down
  else
    error "Unknown Apple menu action."
  end if
end run
