#!/usr/bin/env sh

# ── Workspaces (Waybar: hyprland/workspaces#kanji) ──────────
# Kanji characters: 一二三四五六七八九十
SPACE_ICONS=("一" "二" "三" "四" "五" "六" "七" "八" "九" "十")

# Query actual number of spaces from yabai/macOS
SPACES=$(yabai -m query --spaces 2>/dev/null | jq '.[].index' 2>/dev/null)
if [ -z "$SPACES" ]; then
  # Fallback: create indicators for spaces 1-5
  SPACES="1 2 3 4 5"
fi

for SID in $SPACES; do
  IDX=$((SID - 1))
  if [ $IDX -ge 0 ] && [ $IDX -lt 10 ]; then
    KANJI_CHAR="${SPACE_ICONS[$IDX]}"
  else
    KANJI_CHAR="$SID"
  fi

  sketchybar --add space space.$SID center \
             --set space.$SID \
               space=$SID \
               icon="$KANJI_CHAR" \
               icon.font="$FONT:Bold:13.0" \
               icon.color=$OUTLINE \
               icon.highlight_color=$PRIMARY \
               icon.padding_left=8 \
               icon.padding_right=8 \
               label.drawing=off \
               background.drawing=off \
               background.color=$PRIMARY_CONTAINER \
               background.corner_radius=6 \
               background.height=22 \
               script="$PLUGIN_DIR/space.sh" \
               click_script="yabai -m space --focus $SID 2>/dev/null || skhd -k 'ctrl - $SID'"
done

# Separator dot-line after workspaces (before notification bell)
sketchybar --add item space_sep_r center \
           --set space_sep_r \
             icon="·" \
             icon.font="$FONT:Heavy:18.0" \
             icon.color=$OUTLINE_VARIANT \
             icon.padding_left=6 \
             icon.padding_right=6 \
             label.drawing=off \
             background.drawing=off
