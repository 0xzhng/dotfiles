#!/usr/bin/env sh

sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off

confirm=$(
  osascript <<'APPLESCRIPT'
tell application "System Events"
  activate
  set dialog_result to display dialog "Shut down your Mac now?" buttons {"Cancel", "Shut Down"} default button "Shut Down" with icon caution
  return button returned of dialog_result
end tell
APPLESCRIPT
)

[ "$confirm" = "Shut Down" ] || exit 0

# Disable macOS resume/restore behavior for next login.
defaults write -g ApplePersistence -bool false
defaults write com.apple.loginwindow TALLogoutSavesState -bool false
defaults write com.apple.loginwindow LoginwindowLaunchesRelaunchApps -bool false
killall cfprefsd >/dev/null 2>&1 || true

# Clear existing saved window state so reboot starts clean.
for state_dir in "$HOME"/Library/Saved\ Application\ State/*.savedState; do
  [ -e "$state_dir" ] || continue
  rm -rf "$state_dir"
done

osascript -e 'tell application "System Events" to shut down'
