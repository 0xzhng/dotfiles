#!/usr/bin/env sh

# More realistic RAM usage: active + wired + compressed pages
VM=$(vm_stat)
PAGE_SIZE=$(echo "$VM" | awk '/page size of/ {gsub("[^0-9]", "", $8); print $8; exit}')
[ -z "$PAGE_SIZE" ] && PAGE_SIZE=16384

ACTIVE=$(echo "$VM" | awk '/Pages active/ {gsub("\\.", "", $3); print $3; exit}')
WIRED=$(echo "$VM" | awk '/Pages wired down/ {gsub("\\.", "", $4); print $4; exit}')
COMPRESSED=$(echo "$VM" | awk '/Pages occupied by compressor/ {gsub("\\.", "", $5); print $5; exit}')

[ -z "$ACTIVE" ] && ACTIVE=0
[ -z "$WIRED" ] && WIRED=0
[ -z "$COMPRESSED" ] && COMPRESSED=0

USED_PAGES=$((ACTIVE + WIRED + COMPRESSED))
USED_BYTES=$((USED_PAGES * PAGE_SIZE))
USED_GB=$(awk "BEGIN {printf \"%.1f\", $USED_BYTES/1073741824}")

sketchybar --set "$NAME" label="${USED_GB}G"
