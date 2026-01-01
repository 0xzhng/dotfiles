#!/bin/bash
set -euo pipefail

MONITOR="eDP-1"
WALL="$HOME/.config/hypr/bg1.png"
AUTOCONF="$HOME/.config/hypr/.hyprpaper-autoconfig.conf"

# Generate a minimal hyprpaper config on every run.
cat <<EOF > "$AUTOCONF"
preload=$WALL
wallpaper=$MONITOR,$WALL
splash=false
EOF

# Ensure old instances don't hold on to stale state.
pkill hyprpaper >/dev/null 2>&1 || true

# Start hyprpaper with the generated config.
hyprpaper -c "$AUTOCONF" >/dev/null 2>&1 &

# Ask hyprpaper to apply the wallpaper once it's ready.
for _ in {1..20}; do
    if hyprctl hyprpaper wallpaper "$MONITOR,$WALL" >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.2
done

echo "Warning: hyprpaper could not be initialized" >&2
exit 1
