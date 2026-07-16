#!/usr/bin/env sh

# ── CPU (Waybar: cpu in group/mobo_drawer) ──────────────────
sketchybar --add item cpu right \
           --set cpu \
             icon="󰍛" \
             icon.font="$NERD_FONT:Bold:15.0" \
             icon.color=$SECONDARY \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              width=58 \
              update_freq=3 \
              script="$PLUGIN_DIR/cpu.sh"
