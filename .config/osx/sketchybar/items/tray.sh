#!/usr/bin/env sh

# ── Apple/Tray indicator (Waybar: tray in modules-left) ─────
sketchybar --add item apple_tray left \
           --set apple_tray \
              icon="􀣺" \
              icon.font="$FONT:Semibold:13.0" \
              icon.color=$SECONDARY \
              icon.padding_left=6 \
              icon.padding_right=6 \
              padding_left=0 \
              padding_right=0 \
              label.drawing=off \
              background.drawing=off \
              background.color=0x3344464f \
              background.corner_radius=8 \
              popup.background.color=$GLASS \
              popup.background.corner_radius=10 \
              popup.background.border_width=1 \
              popup.background.border_color=$GLASS_BORDER \
              click_script="$PLUGIN_DIR/toggle_popup.sh apple_tray" \
              script="$PLUGIN_DIR/hover_highlight.sh" \
            --subscribe apple_tray mouse.entered mouse.exited

sketchybar --add item apple.system_settings popup.apple_tray \
           --set apple.system_settings \
              icon="􀍟" \
              label="System Settings" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                 click_script="open -a 'System Settings'; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.system_settings mouse.entered.global mouse.exited.global

sketchybar --add item apple.finder popup.apple_tray \
           --set apple.finder \
              icon="􀈕" \
              label="Launch New Finder" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="open -n -a Finder; osascript -e 'tell application \"Finder\" to make new Finder window'; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.finder mouse.entered.global mouse.exited.global

sketchybar --add item apple.lock popup.apple_tray \
           --set apple.lock \
              icon="􀎡" \
              label="Lock Screen" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="pmset displaysleepnow; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.lock mouse.entered.global mouse.exited.global

sketchybar --add item apple.sleep popup.apple_tray \
           --set apple.sleep \
              icon="􀙧" \
              label="Sleep" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="pmset sleepnow; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.sleep mouse.entered.global mouse.exited.global

sketchybar --add item apple.restart popup.apple_tray \
           --set apple.restart \
              icon="􀚁" \
              label="Restart" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="osascript -e 'tell app \"System Events\" to restart'; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.restart mouse.entered.global mouse.exited.global

sketchybar --add item apple.shutdown popup.apple_tray \
           --set apple.shutdown \
              icon="􀆨" \
              label="Shut Down" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="$PLUGIN_DIR/shutdown_confirm.sh"
           --subscribe apple.shutdown mouse.entered.global mouse.exited.global

sketchybar --add item apple.logout popup.apple_tray \
           --set apple.logout \
              icon="􀍠" \
              label="Log Out" \
              label.font="$FONT:Medium:12.0" \
              icon.color=$ON_BACKGROUND \
               label.color=$ON_BACKGROUND \
               background.drawing=off \
               background.color=0x66b0c6ff \
               background.corner_radius=6 \
               script="$PLUGIN_DIR/popup_row_hover.sh" \
                click_script="osascript -e 'tell app \"System Events\" to log out'; sketchybar --set apple_tray popup.drawing=off --set battery popup.drawing=off"
           --subscribe apple.logout mouse.entered.global mouse.exited.global
