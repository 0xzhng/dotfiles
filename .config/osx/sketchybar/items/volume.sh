#!/usr/bin/env sh

# ── Volume (Waybar: pulseaudio in group/audio) ──────────────
sketchybar --add item volume right \
           --set volume \
              icon.font="$NERD_FONT:Bold:15.0" \
              icon.color=$PRIMARY \
              icon.padding_left=0 \
              icon.padding_right=2 \
                label.font="$FONT:Medium:11.0" \
                label.color=$ON_BACKGROUND \
                background.drawing=off \
               width=64 \
               popup.background.color=$GLASS \
               popup.background.corner_radius=10 \
               popup.background.border_width=1 \
               popup.background.border_color=$GLASS_BORDER \
               update_freq=5 \
               script="$PLUGIN_DIR/volume.sh" \
               click_script="$PLUGIN_DIR/volume_click.sh" \
               right_click_script="$PLUGIN_DIR/volume_mute_toggle.sh" \
            --subscribe volume volume_change system_woke mouse.entered mouse.exited

sketchybar --add item volume.airpods.transparency popup.volume \
           --set volume.airpods.transparency \
              icon="󰒳" \
              label="Transparency" \
              label.font="$FONT:Medium:11.0" \
              icon.color=$ON_BACKGROUND \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              background.color=0x66b0c6ff \
              background.corner_radius=6 \
              script="$PLUGIN_DIR/popup_row_hover.sh" \
              click_script="$PLUGIN_DIR/volume_airpods_mode.sh transparency; sketchybar --set volume popup.drawing=off" \
           --subscribe volume.airpods.transparency mouse.entered.global mouse.exited.global

sketchybar --add item volume.airpods.cancel popup.volume \
           --set volume.airpods.cancel \
              icon="󰍳" \
              label="Noise Cancellation" \
              label.font="$FONT:Medium:11.0" \
              icon.color=$ON_BACKGROUND \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              background.color=0x66b0c6ff \
              background.corner_radius=6 \
              script="$PLUGIN_DIR/popup_row_hover.sh" \
              click_script="$PLUGIN_DIR/volume_airpods_mode.sh cancel; sketchybar --set volume popup.drawing=off" \
           --subscribe volume.airpods.cancel mouse.entered.global mouse.exited.global

sketchybar --add item volume.airpods.off popup.volume \
           --set volume.airpods.off \
              icon="󰈈" \
              label="Noise Control Off" \
              label.font="$FONT:Medium:11.0" \
              icon.color=$ON_BACKGROUND \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              background.color=0x66b0c6ff \
              background.corner_radius=6 \
              script="$PLUGIN_DIR/popup_row_hover.sh" \
              click_script="$PLUGIN_DIR/volume_airpods_mode.sh off; sketchybar --set volume popup.drawing=off" \
           --subscribe volume.airpods.off mouse.entered.global mouse.exited.global

sketchybar --add item volume.airpods.settings popup.volume \
           --set volume.airpods.settings \
              icon="􀍟" \
              label="Sound Settings" \
              label.font="$FONT:Medium:11.0" \
              icon.color=$ON_BACKGROUND \
              label.color=$ON_BACKGROUND \
              background.drawing=off \
              background.color=0x66b0c6ff \
              background.corner_radius=6 \
              script="$PLUGIN_DIR/popup_row_hover.sh" \
              click_script="$PLUGIN_DIR/native_panel.sh sound; sketchybar --set volume popup.drawing=off" \
           --subscribe volume.airpods.settings mouse.entered.global mouse.exited.global
