#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
LOCK_CACHE_DIR="/tmp/hyprlock-wallpaper"
TARGET_BG="$LOCK_CACHE_DIR/bg1.png"
TARGET_BG_BAK="$LOCK_CACHE_DIR/bg1.png.bak"
WALLPAPER_DIR="$CONFIG_DIR/wallpapers"
CURRENT_WALL_SYMLINK="$CONFIG_DIR/current_wallpaper"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"
AUTOCONF="$CONFIG_DIR/.hyprpaper-autoconfig.conf"

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

resolve_wallpaper_path() {
    local candidate

    if [ -L "$CURRENT_WALL_SYMLINK" ] || [ -f "$CURRENT_WALL_SYMLINK" ]; then
        candidate=$(readlink -f "$CURRENT_WALL_SYMLINK" 2>/dev/null || true)
        if [ -n "$candidate" ] && [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    fi

    if [ -f "$TARGET_BG" ]; then
        printf '%s' "$TARGET_BG"
        return 0
    fi

    if [ -f "$TARGET_BG_BAK" ]; then
        printf '%s' "$TARGET_BG_BAK"
        return 0
    fi

    if [ -d "$WALLPAPER_DIR" ]; then
        candidate=$(find "$WALLPAPER_DIR" -maxdepth 1 -type f | head -n1 || true)
        if [ -n "$candidate" ] && [ -f "$candidate" ]; then
            printf '%s' "$candidate"
            return 0
        fi
    fi

    return 1
}

update_wallpaper_vars() {
    local source="$1"
    local lock_path="$2"

    mkdir -p "$CONFIG_DIR"
    {
        printf '$HyprWallpaper = "%s"\n' "$source"
        printf '$HyprLockWallpaper = "%s"\n' "$lock_path"
    } > "$WALLPAPER_VARS"
    printf '%s\n' "$lock_path" > "$WALLPAPER_DEBUG"
}

if ! SOURCE_WALL=$(resolve_wallpaper_path); then
    echo "No wallpaper asset found for hyprpaper" >&2
    exit 1
fi

LOCK_WALL="$SOURCE_WALL"
if convert_to_png_copy "$SOURCE_WALL" "$TARGET_BG"; then
    LOCK_WALL="$TARGET_BG"
else
    echo "Warning: failed to convert $SOURCE_WALL to PNG; falling back to original file" >&2
fi

update_wallpaper_vars "$SOURCE_WALL" "$LOCK_WALL"

WALL="$SOURCE_WALL"

# Build the monitor list dynamically so every active output gets a wallpaper.
if ! readarray -t MONITORS < <(hyprctl monitors | awk '/^Monitor / {print $2}'); then
    MONITORS=()
fi
# Fallback for situations where hyprctl isn't available (e.g., run from TTY).
if [[ ${#MONITORS[@]} -eq 0 ]]; then
    MONITORS=("eDP-1" "DP-1")
fi

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
