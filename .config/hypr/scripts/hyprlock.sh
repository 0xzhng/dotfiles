#!/bin/bash

set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync_sddm_to_hyprlock.py"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"
CURRENT_WALL_SYMLINK="$CONFIG_DIR/current_wallpaper"
HYPRPAPER_AUTOCONF="$CONFIG_DIR/.hyprpaper-autoconfig.conf"
LOCK_CACHE_DIR="/tmp/hyprlock-wallpaper"
FALLBACK_WALL="$LOCK_CACHE_DIR/bg1.png"

strip_png_profiles() {
    local file="$1"
    python - "$file" <<'PY'
import os, struct, sys, tempfile
path = sys.argv[1]
with open(path, 'rb') as src:
    signature = src.read(8)
    if signature != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(0)
    fd, tmp_path = tempfile.mkstemp(prefix=os.path.basename(path)+'.', dir=os.path.dirname(path) or None)
    os.close(fd)
    with open(tmp_path, 'wb') as dst:
        dst.write(signature)
        while True:
            header = src.read(8)
            if len(header) < 8:
                break
            length, chunk_type = struct.unpack('>I4s', header)
            data = src.read(length)
            crc = src.read(4)
            if chunk_type == b'iCCP':
                continue
            dst.write(header)
            dst.write(data)
            dst.write(crc)
            if chunk_type == b'IEND':
                break
    os.replace(tmp_path, path)
PY
}

convert_to_png_copy() {
    local source="$1"
    local dest="$2"
    local dir
    dir=$(dirname "$dest")
    mkdir -p "$dir"
    chmod 755 "$dir" >/dev/null 2>&1 || true
    local tmp
    tmp=$(mktemp "${dest}.XXXXXX.png")

    if ! command -v ffmpeg >/dev/null 2>&1; then
        rm -f -- "$tmp"
        return 1
    fi

    local filters="scale='if(gt(iw,3840),3840,iw)':-1,format=rgb24"
    if ! ffmpeg -loglevel error -y -i "$source" -vf "$filters" -f image2 -c:v png "$tmp" >/dev/null 2>&1; then
        rm -f -- "$tmp"
        return 1
    fi

    strip_png_profiles "$tmp" || true
    mv -f -- "$tmp" "$dest"
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

get_recorded_wallpaper() {
    local key="$1"
    if [ ! -f "$WALLPAPER_VARS" ]; then
        return 1
    fi
    awk -F'"' -v search="$key" '$1 ~ search {print $2; exit}' "$WALLPAPER_VARS"
}

sync_wallpaper_var() {
    local path
    if ! path=$(resolve_wallpaper_source); then
        return
    fi

    local recorded_source recorded_lock
    recorded_source=$(get_recorded_wallpaper '\\$HyprWallpaper') || true
    recorded_lock=$(get_recorded_wallpaper '\\$HyprLockWallpaper') || true
    if [ -n "$recorded_source" ] && [ "$recorded_source" = "$path" ] && \
       [ -n "$recorded_lock" ] && [ -f "$recorded_lock" ]; then
        printf '%s\n' "$recorded_lock" > "$WALLPAPER_DEBUG"
        return
    fi

    mkdir -p "$CONFIG_DIR"
    local active="$path"
    if convert_to_png_copy "$path" "$FALLBACK_WALL"; then
        active="$FALLBACK_WALL"
    fi
    write_wallpaper_vars "$path" "$active"
}

if [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" || true
fi

sync_wallpaper_var

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

export GLYCIN_LOADERS_PATH="/usr/lib/glycin-loaders/2+"
exec hyprlock "$@"
