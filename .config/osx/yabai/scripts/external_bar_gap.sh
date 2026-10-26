#!/usr/bin/env sh

# Reserve SketchyBar's 40px height plus the existing 17px gap only on
# the LG and Samsung externals. Display indices change in laptop mode.
DISPLAYS=$(yabai -m query --displays) || exit 1
SPACES=$(yabai -m query --spaces) || exit 1
DEFAULT_PADDING=$(yabai -m config top_padding) || exit 1

printf '%s' "$SPACES" | jq -r --argjson displays "$DISPLAYS" \
    --argjson default "$DEFAULT_PADDING" '
    .[] as $space |
    $displays[] | select(.index == $space.display) |
    (if .uuid == "CB448690-E0D9-4B35-97C5-93713D5290AC" or
        .uuid == "A339F5FA-A1D6-4413-B3C7-3ACFBE0CE389"
     then $default + 40 else $default end) as $padding |
    "\($space.index) \($padding)"
' | while read -r space padding; do
    current=$(yabai -m config --space "$space" top_padding) || continue
    # Avoid reflowing unchanged spaces, including the laptop display.
    [ "$current" = "$padding" ] ||
        yabai -m config --space "$space" top_padding "$padding"
done
