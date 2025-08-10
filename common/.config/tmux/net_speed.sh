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
            # Calculate speeds in MB/s (with decimal precision)
            rx_bytes=$(( rx_now - rx_prev ))
            tx_bytes=$(( tx_now - tx_prev ))
            rx_speed=$(echo "scale=1; $rx_bytes / $time_diff / 1048576" | bc 2>/dev/null || echo "0")
            tx_speed=$(echo "scale=1; $tx_bytes / $time_diff / 1048576" | bc 2>/dev/null || echo "0")
            echo "${rx_speed}M↓ ${tx_speed}M↑"
        else
            echo "0.0M↓ 0.0M↑"
        fi
    else
        echo "0.0M↓ 0.0M↑"
    fi
    
    # Save current values
    echo "$rx_now $tx_now $time_now" > "$cache_file"
else
    echo "NO-NET"
fi
