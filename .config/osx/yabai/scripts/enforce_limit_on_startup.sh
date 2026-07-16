#!/usr/bin/env bash
# Enforce 5-window limit on all spaces at yabai startup
# This handles windows that were restored before yabai started

sleep 1  # Wait for yabai to fully initialize

TOTAL_SPACES=$(yabai -m query --spaces 2>/dev/null | jq 'length')

for ((space_idx=1; space_idx<=TOTAL_SPACES; space_idx++)); do
    # Get all managed windows on this space, sorted by ID (newest last)
    WINDOWS_JSON=$(yabai -m query --windows --space "$space_idx" 2>/dev/null | jq '[.[] | select(."is-floating" == false and ."is-sticky" == false and ."is-minimized" == false)] | sort_by(.id)')

    WINDOW_COUNT=$(echo "$WINDOWS_JSON" | jq 'length')

    # If more than 5 windows, move excess to other spaces
    if [ "$WINDOW_COUNT" -gt 5 ]; then
        # Get the excess windows (6th and beyond)
        EXCESS_WINDOWS=$(echo "$WINDOWS_JSON" | jq '.[5:] | .[].id')

        for window_id in $EXCESS_WINDOWS; do
            # Find a space with fewer than 5 windows
            MOVED=false
            for ((target_space=1; target_space<=TOTAL_SPACES; target_space++)); do
                # Skip current space
                if [ "$target_space" -eq "$space_idx" ]; then
                    continue
                fi

                # Count windows on target space
                TARGET_COUNT=$(yabai -m query --windows --space "$target_space" 2>/dev/null | jq '[.[] | select(."is-floating" == false and ."is-sticky" == false and ."is-minimized" == false)] | length')

                if [ "$TARGET_COUNT" -lt 5 ]; then
                    yabai -m window "$window_id" --space "$target_space" 2>/dev/null
                    MOVED=true
                    break
                fi
            done

            # If no space has room, float the window
            if [ "$MOVED" = false ]; then
                yabai -m window "$window_id" --toggle float 2>/dev/null
            fi
        done
    fi
done
