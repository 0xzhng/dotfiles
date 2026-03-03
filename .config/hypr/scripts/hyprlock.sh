#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync_sddm_to_hyprlock.py"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"
CURRENT_WALL_SYMLINK="$CONFIG_DIR/current_wallpaper"
HYPRPAPER_AUTOCONF="$CONFIG_DIR/.hyprpaper-autoconfig.conf"
LOCK_CACHE_DIR="$HOME/.cache/hyprlock"
FALLBACK_WALL="$LOCK_CACHE_DIR/bg1.png"

convert_to_png_copy() {
    local source="$1"
    local dest="$2"
    local dir
    dir=$(dirname "$dest")
    mkdir -p "$dir"
    chmod 755 "$dir" >/dev/null 2>&1 || true
    local tmp
    tmp=$(mktemp "${dest}.XXXXXX.png")

    # Try ffmpeg conversion (scales down large images, normalises format)
    if command -v ffmpeg >/dev/null 2>&1; then
        local filters="scale='if(gt(iw,3840),3840,iw)':-1,format=rgb24"
        if ffmpeg -loglevel error -y -i "$source" -vf "$filters" -f image2 -c:v png "$tmp" >/dev/null 2>&1; then
            mv -f -- "$tmp" "$dest"
            chmod 644 "$dest" >/dev/null 2>&1 || true
            return 0
        fi
    fi

    # Fallback: try magick/convert to produce a real PNG
    if command -v magick >/dev/null 2>&1; then
        if magick "$source" "$tmp" >/dev/null 2>&1; then
            mv -f -- "$tmp" "$dest"
            chmod 644 "$dest" >/dev/null 2>&1 || true
            return 0
        fi
    elif command -v convert >/dev/null 2>&1; then
        if convert "$source" "$tmp" >/dev/null 2>&1; then
            mv -f -- "$tmp" "$dest"
            chmod 644 "$dest" >/dev/null 2>&1 || true
            return 0
        fi
    fi

    # Last resort: raw copy (may cause format mismatch but better than nothing)
    rm -f -- "$tmp"
    cp -f -- "$source" "$dest"
    chmod 644 "$dest" >/dev/null 2>&1 || true
}

write_wallpaper_vars() {
    local source="$1"
    local lock_path="$2"
    mkdir -p "$CONFIG_DIR"
    {
        printf '$HyprWallpaper = "%s"\n' "$source"
        printf '$HyprLockWallpaper = "%s"\n' "$lock_path"
    } > "$WALLPAPER_VARS"
    printf '%s\n' "$lock_path" > "$WALLPAPER_DEBUG"
}

resolve_wallpaper_source() {
    local target

    # 1. current_wallpaper symlink (set by wppicker)
    if [ -L "$CURRENT_WALL_SYMLINK" ] || [ -f "$CURRENT_WALL_SYMLINK" ]; then
        target=$(readlink -f "$CURRENT_WALL_SYMLINK" 2>/dev/null || true)
        if [ -n "$target" ] && [ -f "$target" ]; then
            printf '%s' "$target"
            return 0
        fi
    fi

    # 2. hyprpaper autoconfig (set by set-wall.sh)
    if [ -f "$HYPRPAPER_AUTOCONF" ]; then
        target=$(grep -m1 '^wallpaper=' "$HYPRPAPER_AUTOCONF" 2>/dev/null | cut -d',' -f2- || true)
        if [ -n "$target" ] && [ -f "$target" ]; then
            printf '%s' "$target"
            return 0
        fi
    fi

    # 3. already-cached lock wallpaper
    if [ -f "$FALLBACK_WALL" ]; then
        printf '%s' "$FALLBACK_WALL"
        return 0
    fi

    return 1
}

sync_wallpaper_var() {
    local path
    if ! path=$(resolve_wallpaper_source); then
        return
    fi

    # If the cached copy already matches the source, nothing to do
    local recorded_source recorded_lock
    recorded_source=$(awk -F'"' '/\$HyprWallpaper/ {print $2; exit}' "$WALLPAPER_VARS" 2>/dev/null) || true
    recorded_lock=$(awk -F'"' '/\$HyprLockWallpaper/ {print $2; exit}' "$WALLPAPER_VARS" 2>/dev/null) || true
    if [ -n "$recorded_source" ] && [ "$recorded_source" = "$path" ] && \
       [ -n "$recorded_lock" ] && [ -f "$recorded_lock" ]; then
        printf '%s\n' "$recorded_lock" > "$WALLPAPER_DEBUG"
        return
    fi

    # Convert/copy to persistent cache
    mkdir -p "$LOCK_CACHE_DIR"
    convert_to_png_copy "$path" "$FALLBACK_WALL"
    write_wallpaper_vars "$path" "$FALLBACK_WALL"
}

# Optionally sync SDDM theme -> hyprlock vars
if [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" || true
fi

sync_wallpaper_var

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

export GLYCIN_LOADERS_PATH="/usr/lib/glycin-loaders/2+"
exec hyprlock "$@"
