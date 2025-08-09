#!/bin/bash
interface="eth0"
cache_file="/tmp/tmux_net_cache"

# Get current stats
if [ -f /sys/class/net/$interface/statistics/rx_bytes ]; then
    rx_now=$(cat /sys/class/net/$interface/statistics/rx_bytes)
    tx_now=$(cat /sys/class/net/$interface/statistics/tx_bytes)
    time_now=$(date +%s)
    
    if [ -f "$cache_file" ]; then
        # Read previous values
        read rx_prev tx_prev time_prev < "$cache_file"
        
        # Calculate time difference
        time_diff=$((time_now - time_prev))
        
        if [ $time_diff -gt 0 ]; then
            # Calculate speeds in KB/s
            rx_speed=$(( (rx_now - rx_prev) / time_diff / 1024 ))
            tx_speed=$(( (tx_now - tx_prev) / time_diff / 1024 ))
            echo "${rx_speed}K↓ ${tx_speed}K↑"
        else
            echo "0K↓ 0K↑"
        fi
    else
        echo "0K↓ 0K↑"
    fi
    
    # Save current values
    echo "$rx_now $tx_now $time_now" > "$cache_file"
else
    echo "NO-NET"
fi
