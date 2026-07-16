#!/usr/bin/env sh
# Smart focus: tries window focus first, falls back to display focus.
# Usage: focus_window.sh <west|east|north|south>
# Enables hjkl binds to cross display boundaries.

dir="$1"

# Try focusing a window in the given direction (same display)
yabai -m window --focus "$dir" 2>/dev/null && exit 0

# No window in that direction — switch to the adjacent display instead.
# yabai will auto-focus the last active window on the target display.
yabai -m display --focus "$dir" 2>/dev/null
