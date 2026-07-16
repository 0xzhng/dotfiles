#!/usr/bin/env sh

GPU_LOAD=$(ioreg -r -d 1 -c AGXAccelerator | awk -F'"Device Utilization %"=' '/"PerformanceStatistics"/ {print $2; exit}' | awk -F',' '{gsub(/[^0-9]/, "", $1); print $1}')

if [ -n "$GPU_LOAD" ]; then
  sketchybar --set "$NAME" label="${GPU_LOAD}%"
else
  sketchybar --set "$NAME" label="--"
fi
