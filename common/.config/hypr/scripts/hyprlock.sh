#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync_sddm_to_hyprlock.py"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"
CURRENT_WALL_SYMLINK="$CONFIG_DIR/current_wallpaper"
HYPRPAPER_AUTOCONF="$CONFIG_DIR/.hyprpaper-autoconfig.conf"
FALLBACK_WALL="$CONFIG_DIR/bg1.png"

write_wallpaper_var() {
    local path="$1"
    mkdir -p "$CONFIG_DIR"
    printf '$HyprWallpaper = "%s"\n' "$path" > "$WALLPAPER_VARS"
    printf '%s\n' "$path" > "$WALLPAPER_DEBUG"
}

resolve_wallpaper_path() {
    local target

    if [ -L "$CURRENT_WALL_SYMLINK" ] || [ -f "$CURRENT_WALL_SYMLINK" ]; then
        target=$(readlink -f "$CURRENT_WALL_SYMLINK" 2>/dev/null || true)
        if [ -n "$target" ] && [ -f "$target" ]; then
            printf '%s' "$target"
            return 0
        fi
    fi

    if [ -f "$HYPRPAPER_AUTOCONF" ]; then
        target=$(grep -m1 '^wallpaper=' "$HYPRPAPER_AUTOCONF" 2>/dev/null | cut -d',' -f2- || true)
        if [ -n "$target" ] && [ -f "$target" ]; then
            printf '%s' "$target"
            return 0
        fi
    fi

    if [ -f "$FALLBACK_WALL" ]; then
        printf '%s' "$FALLBACK_WALL"
        return 0
    fi

    return 1
}

sync_wallpaper_var() {
    local path
    if path=$(resolve_wallpaper_path); then
        mkdir -p "$CONFIG_DIR"
        # Ensure the lockscreen wallpaper is a real file, not a dangling symlink.
        if [ -L "$FALLBACK_WALL" ]; then
            rm -f "$FALLBACK_WALL"
        fi
        if [ ! -f "$FALLBACK_WALL" ] || ! cmp -s "$path" "$FALLBACK_WALL" 2>/dev/null; then
            cp -f -- "$path" "$FALLBACK_WALL"
        fi
        write_wallpaper_var "$FALLBACK_WALL"
    fi
}

if [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" || true
fi

sync_wallpaper_var

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

exec hyprlock "$@"
