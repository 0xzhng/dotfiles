#!/bin/bash

# Check if external monitor is connected
if hyprctl monitors | grep -q "DP-1"; then
  # External monitor is connected → use only external
  hyprctl keyword monitor eDP-1,disable
  hyprctl keyword monitor DP-1,1920x1080@144,auto,1
else
  # No external monitor → fall back to laptop screen
  hyprctl keyword monitor eDP-1,1920x1080@60,auto,1
fi
