#!/bin/sh
# Passwall CPU Monitor Script for OpenWRT
# Monitors Passwall CPU usage and restarts if > 25% for 15+ seconds

THRESHOLD=25
CHECK_INTERVAL=5  # Check every 5 seconds
HIGH_CPU_DURATION=15  # Must be high for 15 seconds
LOG_FILE="/var/log/passwall_monitor.log"

# Counter for consecutive high CPU readings
high_cpu_count=0
required_checks=$((HIGH_CPU_DURATION / CHECK_INTERVAL))

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

get_passwall_cpu() {
    # Get CPU usage for xray, sing-box, or hysteria processes
    # OpenWRT's top command outputs differently than standard Linux
    local cpu_usage=0
    
    # Check for common Passwall process names
    for process in xray sing-box hysteria v2ray; do
        local pid=$(pidof "$process" 2>/dev/null)
        if [ -n "$pid" ]; then
            # Use top to get CPU usage - sample for 1 second
            local proc_cpu=$(top -bn1 | grep -E "^\s*$pid" | awk '{print $7}' | sed 's/%//')
            if [ -n "$proc_cpu" ]; then
                # Handle decimal values
                proc_cpu=$(echo "$proc_cpu" | awk '{print int($1+0.5)}')
                cpu_usage=$((cpu_usage + proc_cpu))
            fi
        fi
    done
    
    echo "$cpu_usage"
}

restart_passwall() {
    log_message "HIGH CPU DETECTED - Restarting Passwall (CPU: $1%)"
    /etc/init.d/passwall restart
    sleep 5
    log_message "Passwall restarted successfully"
    high_cpu_count=0
}

# Main monitoring loop - runs for one iteration (called by cron every 5 seconds)
current_cpu=$(get_passwall_cpu)

if [ "$current_cpu" -gt "$THRESHOLD" ]; then
    # Read the counter from state file
    if [ -f /tmp/passwall_high_cpu_count ]; then
        high_cpu_count=$(cat /tmp/passwall_high_cpu_count)
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
