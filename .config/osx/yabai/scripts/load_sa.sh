#!/usr/bin/env sh

# Load the yabai scripting-addition without triggering a password prompt at login.
# This relies on a sudoers NOPASSWD rule bound to the current yabai binary hash.
# If the rule is stale (after upgrade/reinstall), this exits quietly.

if sudo -n /opt/homebrew/bin/yabai --load-sa >/dev/null 2>&1; then
  exit 0
fi

exit 0
