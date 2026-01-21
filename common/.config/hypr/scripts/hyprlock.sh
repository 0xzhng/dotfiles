#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
SYNC_SCRIPT="$SCRIPT_DIR/sync_sddm_to_hyprlock.py"

if [ -x "$SYNC_SCRIPT" ]; then
    "$SYNC_SCRIPT" || true
fi

if pgrep -x hyprlock >/dev/null 2>&1; then
    exit 0
fi

exec hyprlock "$@"
