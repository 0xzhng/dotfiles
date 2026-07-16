#!/usr/bin/env bash
# Strict 5-window limit per space - moves excess windows to other spaces

# Debug logging - check if env vars are set
{
echo "=== $(date) ==="
echo "YABAI_WINDOW_ID: ${YABAI_WINDOW_ID:-NOT SET}"
echo "YABAI_SPACE_ID: ${YABAI_SPACE_ID:-NOT SET}"
} >> /tmp/yabai_window_limit.log

# Get the window ID from yabai signal environment variable
WINDOW_ID="$YABAI_WINDOW_ID"

if [ -z "$WINDOW_ID" ]; then
    echo "ERROR: WINDOW_ID is empty" >> /tmp/yabai_window_limit.log
    exit 0
fi

# Small delay to ensure window is fully registered
sleep 0.1

# Get the space this window was created on
WINDOW_INFO=$(yabai -m query --windows --window "$WINDOW_ID" 2>/dev/null)
if [ -z "$WINDOW_INFO" ]; then
    echo "ERROR: Could not query window $WINDOW_ID" >> /tmp/yabai_window_limit.log
    exit 0
fi

CURRENT_SPACE=$(echo "$WINDOW_INFO" | jq -r '.space // empty')
if [ -z "$CURRENT_SPACE" ] || [ "$CURRENT_SPACE" = "null" ]; then
    echo "ERROR: Could not get space for window $WINDOW_ID" >> /tmp/yabai_window_limit.log
    exit 0
fi

# Count managed (non-floating, non-sticky) windows on current space
WINDOW_COUNT=$(yabai -m query --windows --space "$CURRENT_SPACE" 2>/dev/null | jq '[.[] | select(."is-floating" == false and ."is-sticky" == false and ."is-minimized" == false)] | length')

echo "Space $CURRENT_SPACE has $WINDOW_COUNT managed windows" >> /tmp/yabai_window_limit.log

# STRICT LIMIT: If MORE than 5 windows, move the newest one
if [ "$WINDOW_COUNT" -gt 5 ]; then
    echo "LIMIT EXCEEDED - moving window $WINDOW_ID" >> /tmp/yabai_window_limit.log

    # Find a space with fewer than 5 windows
    TOTAL_SPACES=$(yabai -m query --spaces 2>/dev/null | jq 'length')

    for ((i=1; i<=TOTAL_SPACES; i++)); do
        # Skip current space
        if [ "$i" -eq "$CURRENT_SPACE" ]; then
            continue
        fi

        # Count windows on this space
        SPACE_WINDOW_COUNT=$(yabai -m query --windows --space "$i" 2>/dev/null | jq '[.[] | select(."is-floating" == false and ."is-sticky" == false and ."is-minimized" == false)] | length')

        # If this space has room (less than 5), move the window there
        if [ "$SPACE_WINDOW_COUNT" -lt 5 ]; then
            echo "Moving window $WINDOW_ID to space $i (has $SPACE_WINDOW_COUNT windows)" >> /tmp/yabai_window_limit.log
            yabai -m window "$WINDOW_ID" --space "$i"
            # Focus the space we moved to
            yabai -m space --focus "$i" 2>/dev/null || true
            exit 0
        fi
    done

    # If no space has room, float the window instead
    echo "No space available - floating window $WINDOW_ID" >> /tmp/yabai_window_limit.log
    yabai -m window "$WINDOW_ID" --toggle float
else
    echo "Window count OK ($WINDOW_COUNT <= 5)" >> /tmp/yabai_window_limit.log
fi
