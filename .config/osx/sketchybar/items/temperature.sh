#!/usr/bin/env sh

sketchybar --add item temperature right \
           --set temperature \
             icon="󰔏" \
             icon.font="$NERD_FONT:Bold:15.0" \
             icon.color=$SECONDARY \
             label.font="$FONT:Medium:11.0" \
             label.color=$ON_BACKGROUND \
             background.drawing=off \
             popup.background.color=$GLASS \
             popup.background.corner_radius=10 \
             popup.background.border_width=1 \
             popup.background.border_color=$GLASS_BORDER \
             popup.align=right \
             width=62 \
             update_freq=2 \
              script="$PLUGIN_DIR/temperature.sh" \
              click_script="$PLUGIN_DIR/toggle_popup.sh temperature" \
           --subscribe temperature mouse.clicked mouse.entered mouse.exited system_woke

sketchybar --add item temperature.formula popup.temperature \
           --set temperature.formula \
             icon="􀅴" \
             icon.font="$NERD_FONT:Regular:12.0" \
             icon.color=$ON_BACKGROUND \
             label="~T = B + 0.10*CPU + 0.08*GPU + offset" \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              width=360 \
              background.drawing=off

sketchybar --add item temperature.inputs popup.temperature \
           --set temperature.inputs \
             icon="􀐫" \
             icon.font="$NERD_FONT:Regular:12.0" \
             icon.color=$ON_BACKGROUND \
             label="B --C | CPU --% | GPU --% | P Nominal (+0)" \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              width=360 \
              background.drawing=off

sketchybar --add item temperature.detail popup.temperature \
           --set temperature.detail \
             icon="􀐬" \
             icon.font="$NERD_FONT:Regular:12.0" \
             icon.color=$ON_BACKGROUND \
             label="raw --C -> ema --C -> shown ~--C" \
              label.font="$FONT:Medium:11.0" \
              label.color=$ON_BACKGROUND \
              width=360 \
              background.drawing=off
