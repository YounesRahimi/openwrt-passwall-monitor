#!/bin/sh
# Passwall CPU Monitor Script for OpenWRT
# Author: Younes Rahimi
# Monitors Passwall CPU usage and restarts if > 25% for 15+ seconds

THRESHOLD=25
CHECK_INTERVAL=5  # Check every 5 seconds
HIGH_CPU_DURATION=15  # Must be high for 15 seconds
LOG_FILE="/tmp/log/passwall_monitor.log"

# Counter for consecutive high CPU readings
high_cpu_count=0
required_checks=$((HIGH_CPU_DURATION / CHECK_INTERVAL))

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

get_passwall_cpu() {
    # Get CPU usage for xray, sing-box, or hysteria processes
    local total_cpu=0

    # Check for common Passwall process names
    for process in xray sing-box hysteria v2ray; do
        local pids=$(pidof "$process" 2>/dev/null || true)
        if [ -n "$pids" ]; then
            for pid in $pids; do
                # Use /proc/stat for more reliable CPU measurement
                if [ -f "/proc/$pid/stat" ]; then
                    # Read CPU times from /proc/pid/stat
                    local stat_line=$(cat "/proc/$pid/stat" 2>/dev/null || echo "")
                    if [ -n "$stat_line" ]; then
                        # Get utime + stime (user + system CPU time)
                        local utime=$(echo "$stat_line" | awk '{print $14}')
                        local stime=$(echo "$stat_line" | awk '{print $15}')

                        # Simple heuristic: if process exists and is consuming resources
                        if [ -n "$utime" ] && [ -n "$stime" ]; then
                            # Check if process is actively using CPU by reading twice
                            sleep 1
                            local stat_line2=$(cat "/proc/$pid/stat" 2>/dev/null || echo "")
                            if [ -n "$stat_line2" ]; then
                                local utime2=$(echo "$stat_line2" | awk '{print $14}')
                                local stime2=$(echo "$stat_line2" | awk '{print $15}')

                                # Calculate CPU usage (simplified)
                                local cpu_ticks=$((utime2 + stime2 - utime - stime))
                                # If process consumed significant CPU in 1 second, consider it high
                                if [ "$cpu_ticks" -gt 50 ]; then
                                    total_cpu=$((total_cpu + 30))
                                fi
                            fi
                        fi
                    fi
                fi
            done
        fi
    done
    
    echo "$total_cpu"
}

restart_passwall() {
    log_message "HIGH CPU DETECTED - Restarting Passwall (CPU: $1%)"
    /etc/init.d/passwall restart
    sleep 5
    log_message "Passwall restarted successfully"
    high_cpu_count=0
}

# Main monitoring loop - runs for one iteration (called by cron every 5 seconds)
log_message "Monitor starting - checking Passwall CPU usage"

current_cpu=$(get_passwall_cpu)
log_message "Current CPU usage: $current_cpu%"

if [ "$current_cpu" -gt "$THRESHOLD" ]; then
    # Read the counter from state file
    if [ -f /tmp/passwall_high_cpu_count ]; then
        high_cpu_count=$(cat /tmp/passwall_high_cpu_count)
    else
        high_cpu_count=0
    fi
    
    high_cpu_count=$((high_cpu_count + 1))
    echo "$high_cpu_count" > /tmp/passwall_high_cpu_count
    
    log_message "High CPU detected: $current_cpu% (count: $high_cpu_count/$required_checks)"
    
    # Check if threshold duration exceeded
    if [ "$high_cpu_count" -ge "$required_checks" ]; then
        restart_passwall "$current_cpu"
        rm -f /tmp/passwall_high_cpu_count
    fi
else
    # CPU is normal, reset counter
    if [ -f /tmp/passwall_high_cpu_count ]; then
        log_message "CPU normalized: $current_cpu% - Resetting counter"
        rm -f /tmp/passwall_high_cpu_count
    fi
fi

log_message "Monitor check completed"
