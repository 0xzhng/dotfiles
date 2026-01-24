#!/bin/bash
set -euo pipefail

CANDIDATES=(
    dolphin
    thunar
    nautilus
    nemo
    pcmanfm-qt
    pcmanfm
    caja
    doublecmd
)

for fm in "${CANDIDATES[@]}"; do
    if command -v "$fm" >/dev/null 2>&1; then
        exec "$fm"
    fi
done

if command -v xdg-open >/dev/null 2>&1; then
    exec xdg-open "$HOME"
fi

notify-send "Hyprland" "No graphical file manager is installed." || true
exit 0
