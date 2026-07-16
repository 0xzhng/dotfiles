#!/usr/bin/env sh

# ============================================================
# Secondary Display BSP Script
# Sets all spaces on non-primary displays to BSP layout so
# windows auto-tile. Yabai's BSP picks the split axis from
# the container's aspect ratio, so:
#   - landscape (horizontal) monitors → side-by-side splits
#   - portrait  (vertical)   monitors → stacked top/bottom splits
# Orientation is handled implicitly; no extra logic needed.
# ============================================================

DISPLAYS_JSON=$(yabai -m query --displays 2>/dev/null) || exit 0
DISPLAY_COUNT=$(printf '%s' "$DISPLAYS_JSON" | jq 'length')

[ "$DISPLAY_COUNT" -lt 2 ] && exit 0

PRIMARY=1

SECONDARY_DISPLAYS=$(printf '%s' "$DISPLAYS_JSON" | jq -r --arg p "$PRIMARY" '.[] | select(.index != ($p | tonumber)) | .index')

for disp_idx in $SECONDARY_DISPLAYS; do
    # Determine orientation from frame; portrait when h > w.
    FRAME=$(printf '%s' "$DISPLAYS_JSON" | jq -r --arg d "$disp_idx" '.[] | select(.index == ($d | tonumber)) | "\(.frame.w) \(.frame.h)"')
    W=$(echo "$FRAME" | awk '{print $1}')
    H=$(echo "$FRAME" | awk '{print $2}')

    SPACES=$(yabai -m query --spaces 2>/dev/null | jq -r --arg d "$disp_idx" '.[] | select(.display == ($d | tonumber)) | .index')
    for spc_idx in $SPACES; do
        yabai -m config --space "$spc_idx" layout bsp 2>/dev/null || true

        # Only seed split_type when the space has no tiled windows yet.
        # Re-seeding on an already-populated space doesn't reorder the
        # tree, but combined with the unfloat sweep below it can undo a
        # user's manual --swap. Skip both whenever windows are present.
        TILED_COUNT=$(yabai -m query --windows --space "$spc_idx" 2>/dev/null | jq '[.[] | select(."is-floating" == false and ."is-minimized" == false)] | length')
        [ "$TILED_COUNT" -gt 0 ] && continue

        # Bias initial split direction so the first split matches
        # the long axis of the display. BSP will continue to pick
        # axes from container aspect ratios after that.
        if awk -v w="$W" -v h="$H" 'BEGIN{exit !(h > w)}'; then
            yabai -m config --space "$spc_idx" split_type horizontal 2>/dev/null || true
        else
            yabai -m config --space "$spc_idx" split_type vertical 2>/dev/null || true
        fi
    done

    # Unfloat any windows currently floating on this display so they tile.
    # Re-tiling inserts at window_placement (second_child), which would
    # move windows around if a tiled window were briefly misreported as
    # floating. Guard with can-resize so only genuinely floating, movable
    # windows are toggled.
    WIN_IDS=$(yabai -m query --windows 2>/dev/null | jq -r --arg d "$disp_idx" '.[] | select(.display == ($d | tonumber) and ."is-floating" == true and ."can-move" == true and ."can-resize" == true) | .id')
    for win_id in $WIN_IDS; do
        yabai -m window "$win_id" --toggle float 2>/dev/null || true
    done
done
