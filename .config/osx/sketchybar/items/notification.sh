#!/usr/bin/env sh

# ── Notification Bell (native Notification Center hybrid) ──
sketchybar --add item notification_bell right \
           --set notification_bell \
              icon="󰂚" \
              icon.font="$NERD_FONT:Bold:15.0" \
              icon.color=$SECONDARY \
              icon.padding_left=3 \
              icon.padding_right=3 \
              label.drawing=off \
              background.drawing=off \
              background.color=0x3344464f \
              background.corner_radius=8 \
              width=24 \
              click_script="$PLUGIN_DIR/native_panel.sh notification" \
              script="$PLUGIN_DIR/hover_highlight.sh" \
            --subscribe notification_bell mouse.entered mouse.exited
