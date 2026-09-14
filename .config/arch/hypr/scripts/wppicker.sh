#!/bin/bash
set -euo pipefail
shopt -s nullglob

# Toggle off if wallpaper picker rofi is already up (mirrors main rofi toggle behavior).
if pgrep -x rofi >/dev/null 2>&1; then
    pkill rofi
    exit 0
fi

# === CONFIG ===
CONFIG_DIR="$HOME/.config/hypr"
WALLPAPER_DIR="$CONFIG_DIR/wallpapers"
SYMLINK_PATH="$CONFIG_DIR/current_wallpaper"
TARGET_BG="$CONFIG_DIR/bg1.png"
SET_WALL_SCRIPT="$CONFIG_DIR/scripts/set-wall.sh"
WALLPAPER_VARS="$CONFIG_DIR/wallpaper-vars.conf"
WALLPAPER_DEBUG="$CONFIG_DIR/.hyprlock-wallpaper.path"

# === COLLECT CANDIDATES ===
mkdir -p "$WALLPAPER_DIR"
cd "$WALLPAPER_DIR" || exit 1
FILES=( *.jpg *.jpeg *.png *.gif )
if [[ ${#FILES[@]} -eq 0 ]]; then
    exit 0
fi
mapfile -t SORTED < <(ls -1 -t -- "${FILES[@]}")

# === ICON-PREVIEW SELECTION WITH ROFI ===
set +o pipefail
SELECTED_WALL=$(
    for a in "${SORTED[@]}"; do
        printf '%s\0icon\x1f%s\n' "$a" "$a"
    done | rofi -dmenu -p ""
)
ROFI_STATUS=$?
set -o pipefail
if [[ $ROFI_STATUS -ne 0 || -z "$SELECTED_WALL" ]]; then
    exit 0
fi
SELECTED_PATH="$WALLPAPER_DIR/$SELECTED_WALL"

# === SET WALLPAPER COLORS ===
if command -v matugen >/dev/null 2>&1; then
    matugen image "$SELECTED_PATH"
fi

# === UPDATE WALLPAPER FILES ===
mkdir -p "$CONFIG_DIR"
ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"
# Replace any symlink with a real copy so hyprlock can always read the pixels.
if [ -L "$TARGET_BG" ]; then
    rm -f "$TARGET_BG"
fi
cp -f -- "$SELECTED_PATH" "$TARGET_BG"

# === UPDATE HYPRPAPER ===
if [[ -x "$SET_WALL_SCRIPT" ]]; then
    "$SET_WALL_SCRIPT"
else
    if ! readarray -t MONITORS < <(hyprctl monitors | awk '/^Monitor / {print $2}'); then
        MONITORS=()
    fi
    if [[ ${#MONITORS[@]} -eq 0 ]]; then
        MONITORS=("eDP-1")
    fi
    for monitor in "${MONITORS[@]}"; do
        hyprctl hyprpaper wallpaper "$monitor,$TARGET_BG" >/dev/null 2>&1 || true
    done
fi
