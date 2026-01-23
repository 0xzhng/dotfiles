#!/bin/bash
# Minimal helper that keeps wallpapers and Waybar in sync with kanshi output switches.
set -uo pipefail

profile_name="${1:-}"
wallpaper_script="$HOME/.config/hypr/scripts/set-wall.sh"
waybar_script="$HOME/.config/hypr/scripts/wbrestart.sh"

# Let Hyprland settle after kanshi applies the new layout so hyprctl queries succeed.
sleep 0.35

if [[ -x "$wallpaper_script" ]]; then
    if ! "$wallpaper_script"; then
        echo "hotplug-refresh: wallpaper refresh failed for profile ${profile_name:-unknown}" >&2
    fi
else
    echo "hotplug-refresh: missing $wallpaper_script" >&2
fi

if [[ -x "$waybar_script" ]]; then
    if ! "$waybar_script"; then
        echo "hotplug-refresh: Waybar restart failed for profile ${profile_name:-unknown}" >&2
    fi
else
    pkill -9 waybar >/dev/null 2>&1 || true
    waybar >/dev/null 2>&1 &
fi

exit 0
