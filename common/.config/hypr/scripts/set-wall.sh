#!/bin/bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/hypr"
TARGET_BG="$CONFIG_DIR/bg1.png"
TARGET_BG_BAK="$CONFIG_DIR/bg1.png.bak"
WALLPAPER_DIR="$CONFIG_DIR/wallpapers"
CURRENT_WALL_SYMLINK="$CONFIG_DIR/current_wallpaper"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"
AUTOCONF="$CONFIG_DIR/.hyprpaper-autoconfig.conf"

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

sync_wallpaper_assets() {
    local source="$1"

    mkdir -p "$CONFIG_DIR"

    if [ "$source" != "$TARGET_BG" ]; then
        if [ -L "$TARGET_BG" ]; then
            rm -f "$TARGET_BG"
        fi
        if [ ! -f "$TARGET_BG" ] || ! cmp -s "$source" "$TARGET_BG" 2>/dev/null; then
            cp -f -- "$source" "$TARGET_BG"
        fi
    elif [ ! -f "$TARGET_BG" ]; then
        cp -f -- "$source" "$TARGET_BG"
    fi

    printf '$HyprWallpaper = "%s"\n' "$TARGET_BG" > "$WALLPAPER_VARS"
    printf '%s\n' "$TARGET_BG" > "$WALLPAPER_DEBUG"
}

if ! SOURCE_WALL=$(resolve_wallpaper_path); then
    echo "No wallpaper asset found for hyprpaper" >&2
    exit 1
fi

sync_wallpaper_assets "$SOURCE_WALL"
WALL="$TARGET_BG"

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
