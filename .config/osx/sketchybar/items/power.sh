#!/usr/bin/env sh

# ── Power Button (Waybar: custom/power in group/status) ─────
sketchybar --add item power_btn right \
           --set power_btn \
             icon="⏻" \
             icon.font="$NERD_FONT:Bold:15.0" \
             icon.color=$ERROR \
             icon.padding_left=6 \
             icon.padding_right=10 \
             label.drawing=off \
             background.drawing=off \
             click_script="$PLUGIN_DIR/power.sh"
