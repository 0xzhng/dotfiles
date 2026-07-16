#!/usr/bin/env sh

# ── Battery (Waybar: battery in group/laptop) ───────────────
sketchybar --add item battery right \
           --set battery \
              icon.font="$NERD_FONT:Bold:16.0" \
              icon.color=$PRIMARY \
              icon.padding_left=1 \
              icon.padding_right=2 \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              background.color=0x3344464f \
              background.corner_radius=8 \
              width=68 \
              update_freq=120 \
              popup.background.color=$GLASS \
              popup.background.corner_radius=10 \
              popup.background.border_width=1 \
              popup.background.border_color=$GLASS_BORDER \
              click_script="$PLUGIN_DIR/battery_mode.sh status; $PLUGIN_DIR/toggle_popup.sh battery" \
              script="$PLUGIN_DIR/battery.sh" \
            --subscribe battery system_woke power_source_change mouse.entered mouse.exited

sketchybar --add item battery.mode.low popup.battery \
           --set battery.mode.low \
              icon="󰂎" \
              icon.font="$NERD_FONT:Regular:13.0" \
              icon.color=$ON_BACKGROUND \
             icon.padding_left=6 \
             icon.padding_right=4 \
             label="Low Power" \
              label.font="$FONT:Medium:11.0" \
              label.padding_left=6 \
              label.padding_right=6 \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                 click_script="$PLUGIN_DIR/battery_mode.sh set low; sketchybar --set battery popup.drawing=off"
           --subscribe battery.mode.low mouse.entered.global mouse.exited.global

sketchybar --add item battery.mode.auto popup.battery \
           --set battery.mode.auto \
              icon="󰁿" \
              icon.font="$NERD_FONT:Regular:13.0" \
              icon.color=$ON_BACKGROUND \
             icon.padding_left=6 \
             icon.padding_right=4 \
             label="Automatic" \
              label.font="$FONT:Medium:11.0" \
              label.padding_left=6 \
              label.padding_right=6 \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                 click_script="$PLUGIN_DIR/battery_mode.sh set auto; sketchybar --set battery popup.drawing=off"
           --subscribe battery.mode.auto mouse.entered.global mouse.exited.global

sketchybar --add item battery.mode.high popup.battery \
           --set battery.mode.high \
              icon="󰂄" \
              icon.font="$NERD_FONT:Regular:13.0" \
              icon.color=$ON_BACKGROUND \
             icon.padding_left=6 \
             icon.padding_right=4 \
             label="High Power" \
              label.font="$FONT:Medium:11.0" \
              label.padding_left=6 \
              label.padding_right=6 \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                 click_script="$PLUGIN_DIR/battery_mode.sh set high; sketchybar --set battery popup.drawing=off"
           --subscribe battery.mode.high mouse.entered.global mouse.exited.global

sketchybar --add item battery.mode.setup popup.battery \
           --set battery.mode.setup \
              icon="􀎞" \
              label="Enable Mode Control" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
               click_script="$PLUGIN_DIR/battery_mode.sh setup; sketchybar --set battery popup.drawing=off"
           --subscribe battery.mode.setup mouse.entered.global mouse.exited.global

sketchybar --add item battery.settings popup.battery \
           --set battery.settings \
              icon="􀍟" \
              label="Battery Settings" \
             label.font="$FONT:Medium:11.0" \
              label.padding_left=6 \
              label.padding_right=6 \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
               click_script="open 'x-apple.systempreferences:com.apple.preference.battery'; sketchybar --set battery popup.drawing=off"
           --subscribe battery.settings mouse.entered.global mouse.exited.global
