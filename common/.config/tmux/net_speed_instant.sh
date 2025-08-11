#!/bin/bash
# Fastest possible implementation - direct sampling with moving average

interface=$(ip route | grep default | awk '{print $5}' | head -n1)
[ -z "$interface" ] && interface="eth0"

# Use arrays for moving average (last 3 samples)
SAMPLE_FILE="/tmp/tmux_net_samples"
LOCK_FILE="/tmp/tmux_net.lock"

# Prevent concurrent access
exec 200>"$LOCK_FILE"
flock -n 200 || { cat "/tmp/tmux_net_last" 2>/dev/null || echo "0.0M↓ 0.0M↑"; exit 0; }

# Read current stats
rx_now=$(cat /sys/class/net/$interface/statistics/rx_bytes 2>/dev/null || echo 0)
tx_now=$(cat /sys/class/net/$interface/statistics/tx_bytes 2>/dev/null || echo 0)
time_now=$(date +%s%3N)  # milliseconds

# Read samples history
if [ -f "$SAMPLE_FILE" ]; then
    samples=$(tail -3 "$SAMPLE_FILE")
    
    # Get oldest sample for average calculation
    oldest=$(echo "$samples" | head -1)
    if [ -n "$oldest" ]; then
        IFS=' ' read rx_old tx_old time_old <<< "$oldest"
        
        time_diff=$(( time_now - time_old ))
        if [ $time_diff -gt 0 ]; then
            # Calculate average speed over samples
            rx_speed=$(echo "scale=1; ($rx_now - $rx_old) * 1000 / $time_diff / 1048576" | bc -l 2>/dev/null || echo "0")
            tx_speed=$(echo "scale=1; ($tx_now - $tx_old) * 1000 / $time_diff / 1048576" | bc -l 2>/dev/null || echo "0")
            
            result="${rx_speed}M↓ ${tx_speed}M↑"
            echo "$result" > /tmp/tmux_net_last
            echo "$result"
        else
            cat /tmp/tmux_net_last 2>/dev/null || echo "0.0M↓ 0.0M↑"
        fi
    else
        echo "0.0Mb↓ 0.0Mb↑"
    fi
else
    echo "0.0Mb↓ 0.0Mb↑"
fi

# Append new sample and keep only last 5
echo "$rx_now $tx_now $time_now" >> "$SAMPLE_FILE"
tail -5 "$SAMPLE_FILE" > "$SAMPLE_FILE.tmp" && mv "$SAMPLE_FILE.tmp" "$SAMPLE_FILE"

flock -u 200
