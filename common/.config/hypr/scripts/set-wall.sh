#!/bin/bash
set -euo pipefail

MONITORS=("eDP-1" "DP-1")
WALL="$HOME/.config/hypr/bg1.png"
AUTOCONF="$HOME/.config/hypr/.hyprpaper-autoconfig.conf"

# Generate a minimal hyprpaper config on every run.
{
    printf 'preload=%s\n' "$WALL"
    for monitor in "${MONITORS[@]}"; do
        printf 'wallpaper=%s,%s\n' "$monitor" "$WALL"
    done
    printf 'splash=false\n'
} > "$AUTOCONF"

# Ensure old instances don't hold on to stale state.
pkill hyprpaper >/dev/null 2>&1 || true

# Start hyprpaper with the generated config.
hyprpaper -c "$AUTOCONF" >/dev/null 2>&1 &

# Ask hyprpaper to apply the wallpaper once it's ready.
for _ in {1..20}; do
    all_applied=true
    for monitor in "${MONITORS[@]}"; do
        if ! hyprctl hyprpaper wallpaper "$monitor,$WALL" >/dev/null 2>&1; then
            all_applied=false
            break
        fi
    done
    if [[ $all_applied == true ]]; then
        exit 0
    fi
    sleep 0.2
done

echo "Warning: hyprpaper could not be initialized" >&2
exit 1
