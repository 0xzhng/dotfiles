#!/usr/bin/env sh

sketchybar --add item gpu right \
           --set gpu \
             icon="󰢮" \
             icon.font="$NERD_FONT:Bold:15.0" \
             icon.color=$SECONDARY \
             label.font="$FONT:Medium:11.0" \
             label.color=$ON_BACKGROUND \
             background.drawing=off \
             width=58 \
             update_freq=1 \
             script="$PLUGIN_DIR/gpu.sh"
