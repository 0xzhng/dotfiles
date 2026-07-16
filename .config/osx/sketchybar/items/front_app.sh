#!/usr/bin/env sh

# ── Front App (Waybar: group/app_drawer + hyprland/window) ──
sketchybar --add item front_app left \
           --set front_app \
              icon.drawing=off \
              label.font="$FONT:Semibold:12.0" \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              update_freq=2 \
              script="$PLUGIN_DIR/front_app.sh" \
            --subscribe front_app front_app_switched space_change
