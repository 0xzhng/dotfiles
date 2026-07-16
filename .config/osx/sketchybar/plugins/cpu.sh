#!/usr/bin/env sh

# More stable CPU sampling: use second sample from top -l 2
CPU_LINE=$(top -l 2 -n 0 | awk '/CPU usage/ {line=$0} END {print line}')
CPU=$(echo "$CPU_LINE" | awk -F'[:,%]' '{u=$2+0; s=$4+0; printf("%.0f", u+s)}')
[ -z "$CPU" ] && CPU=0
sketchybar --set "$NAME" label="${CPU}%"
