#!/usr/bin/env sh

# ── Memory (Waybar: memory in group/mobo_drawer) ────────────
sketchybar --add item memory right \
           --set memory \
             icon="󰾆" \
             icon.font="$NERD_FONT:Bold:15.0" \
             icon.color=$SECONDARY \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              width=72 \
              update_freq=10 \
              script="$PLUGIN_DIR/memory.sh"
