#!/usr/bin/env sh

# ── Clock (Waybar: modules-left, format: %I:%M %p) ─────────
sketchybar --add item clock left \
           --set clock \
             icon.drawing=off \
             label.font="$FONT:Semibold:12.0" \
             label.color=$ON_BACKGROUND \
             label.padding_left=10 \
             label.padding_right=10 \
             update_freq=30 \
             script="$PLUGIN_DIR/clock.sh" \
             background.drawing=off
