#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$HOME/.config/hypr/scripts"
SET_WALL="$SCRIPT_DIR/set-wall.sh"
WB_RESTART="$SCRIPT_DIR/wbrestart.sh"

PROFILE="${1:-}"

log() {
    printf '[hotplug-refresh] %s\n' "$1" >&2
}

if [[ -n "$PROFILE" ]]; then
    log "profile switch detected: $PROFILE"
fi

case "$PROFILE" in
    docked|dual-right|dual-left)
        # Keep primary workspaces on external display.
        for ws in {1..10}; do
            hyprctl dispatch moveworkspacetomonitor "$ws DP-1" >/dev/null 2>&1 || true
        done

        # Keep laptop workspace on the secondary display in dual-monitor profiles.
        case "$PROFILE" in
            dual-right|dual-left)
                hyprctl dispatch moveworkspacetomonitor "11 eDP-1" >/dev/null 2>&1 || true
                ;;
        esac

        # Keep external display as the main focused output when available.
        hyprctl dispatch focusmonitor DP-1 >/dev/null 2>&1 || true
        hyprctl dispatch focusworkspaceoncurrentmonitor 1 >/dev/null 2>&1 || true
        ;;
esac

if [[ -x "$SET_WALL" ]]; then
    if ! "$SET_WALL"; then
        log "set-wall.sh failed"
    fi
else
    log "set-wall.sh not found at $SET_WALL"
fi

if [[ -x "$WB_RESTART" ]]; then
    "$WB_RESTART" >/dev/null 2>&1 &
fi
