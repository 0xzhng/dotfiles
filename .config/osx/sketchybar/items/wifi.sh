#!/usr/bin/env sh

# ── WiFi (Waybar: network in group/connections) ─────────────
sketchybar --add item wifi_icon right \
           --set wifi_icon \
              icon.font="$NERD_FONT:Bold:15.0" \
              icon.color=$SECONDARY \
              icon.padding_left=0 \
              icon.padding_right=2 \
                label.font="$FONT:Medium:11.0" \
                label.color=$ON_BACKGROUND \
                label.drawing=on \
                label.width=0 \
               label.align=left \
               background.drawing=off \
               background.color=0x3344464f \
               background.corner_radius=8 \
               update_freq=2 \
               right_click_script="$PLUGIN_DIR/native_panel.sh wifi" \
               script="$PLUGIN_DIR/wifi.sh" \
             --subscribe wifi_icon wifi_change mouse.entered mouse.exited mouse.clicked
