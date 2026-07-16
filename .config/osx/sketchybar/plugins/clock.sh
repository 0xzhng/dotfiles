#!/usr/bin/env sh

# Show date + time like: Mon Mar 23 • 03:15 PM
DATE=$(date "+%a %b %-d")
TIME=$(date "+%I:%M %p")
sketchybar --set clock label="$DATE • $TIME"
