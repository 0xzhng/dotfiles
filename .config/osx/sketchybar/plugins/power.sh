#!/usr/bin/env sh

# Waybar on-click: wlogout → macOS equivalent: present power options
osascript -e 'tell application "loginwindow" to «event aevtrlgo»'
