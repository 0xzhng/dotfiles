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
