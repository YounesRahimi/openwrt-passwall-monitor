#!/bin/sh
# Passwall Monitor Script for OpenWRT
# Author: Younes Rahimi
# Monitors Passwall CPU usage and network connectivity
# Restarts Passwall if CPU > threshold for 15+ seconds or network fails for 1 minute

# CPU Monitoring Configuration
CPU_THRESHOLD=25
CHECK_INTERVAL=5  # Check every 5 seconds
HIGH_CPU_DURATION=15  # Must be high for 15 seconds

# Network Connectivity Configuration
ENABLE_CONNECTIVITY_CHECK=1  # Set to 0 to disable network checking
CONNECTIVITY_TIMEOUT=10  # Timeout for connectivity test in seconds
CONNECTIVITY_FAILURE_DURATION=60  # Must fail for 60 seconds before restart
CONNECTIVITY_URL="https://www.google.com/generate_204"

# Restart and Cooldown Configuration
RESTART_COOLDOWN=300  # Wait 5 minutes after restart before monitoring again (seconds)

# Logging Configuration
LOG_FILE="/tmp/log/passwall_monitor.log"
LOG_LEVEL="INFO"  # Options: DEBUG, INFO, WARNING, ERROR (DEBUG shows everything)

# Counter for consecutive high CPU readings
high_cpu_count=0
required_cpu_checks=$((HIGH_CPU_DURATION / CHECK_INTERVAL))

# Counter for consecutive connectivity failures
connectivity_failure_count=0
required_connectivity_checks=$((CONNECTIVITY_FAILURE_DURATION / CHECK_INTERVAL))

# Cooldown state file
COOLDOWN_FILE="/tmp/passwall_cooldown_until"

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Logging functions with level filtering
log_debug() {
    if [ "$LOG_LEVEL" = "DEBUG" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [DEBUG] $1" >> "$LOG_FILE"
    fi
}

log_info() {
    if [ "$LOG_LEVEL" = "DEBUG" ] || [ "$LOG_LEVEL" = "INFO" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [INFO] $1" >> "$LOG_FILE"
    fi
}

log_warning() {
    if [ "$LOG_LEVEL" = "DEBUG" ] || [ "$LOG_LEVEL" = "INFO" ] || [ "$LOG_LEVEL" = "WARNING" ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - [WARNING] $1" >> "$LOG_FILE"
    fi
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - [ERROR] $1" >> "$LOG_FILE"
}

# Check if system is in cooldown period after restart
is_in_cooldown() {
    if [ -f "$COOLDOWN_FILE" ]; then
        local cooldown_until=$(cat "$COOLDOWN_FILE" 2>/dev/null || echo "0")
        local current_time=$(date +%s)

        if [ "$current_time" -lt "$cooldown_until" ]; then
            local remaining=$((cooldown_until - current_time))
            log_debug "In cooldown period - $remaining seconds remaining"
            return 0  # Still in cooldown
        else
            # Cooldown period expired
            log_info "Cooldown period expired - resuming normal monitoring"
            rm -f "$COOLDOWN_FILE"
            return 1  # Not in cooldown
        fi
    fi
    return 1  # No cooldown file, not in cooldown
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

check_network_connectivity() {
    if [ "$ENABLE_CONNECTIVITY_CHECK" -ne 1 ]; then
        return 0  # Connectivity check disabled, assume OK
    fi

    # Check if any Passwall process is running
    local passwall_running=0
    for process in xray sing-box hysteria v2ray trojan; do
        if pidof "$process" >/dev/null 2>&1; then
            passwall_running=1
            break
        fi
    done

    if [ "$passwall_running" -eq 0 ]; then
        return 0  # No VPN process running, skip connectivity check
    fi

    # Test connectivity using curl with timeout
    if command -v curl >/dev/null 2>&1; then
        response_code=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout "$CONNECTIVITY_TIMEOUT" --max-time "$CONNECTIVITY_TIMEOUT" "$CONNECTIVITY_URL" 2>/dev/null)
        if [ "$response_code" = "204" ]; then
            return 0  # Success
        else
            return 1  # Failure
        fi
    elif command -v wget >/dev/null 2>&1; then
        if wget --spider --timeout="$CONNECTIVITY_TIMEOUT" --tries=1 "$CONNECTIVITY_URL" >/dev/null 2>&1; then
            return 0  # Success
        else
            return 1  # Failure
        fi
    else
        log_warning "Neither curl nor wget available for connectivity check"
        return 0  # Can't test, assume OK
    fi
}

restart_passwall() {
    local reason="$1"
    if [ "$reason" = "cpu" ]; then
        log_error "HIGH CPU DETECTED - Restarting Passwall (CPU: $2%)"
    elif [ "$reason" = "connectivity" ]; then
        log_error "NETWORK CONNECTIVITY FAILURE - Restarting Passwall"
    else
        log_error "Restarting Passwall (Reason: $reason)"
    fi

    /etc/init.d/passwall restart
    sleep 5
    log_info "Passwall restarted successfully"

    # Set cooldown period
    local cooldown_until=$(($(date +%s) + RESTART_COOLDOWN))
    echo "$cooldown_until" > "$COOLDOWN_FILE"
    log_info "Entering cooldown period for $RESTART_COOLDOWN seconds"

    # Reset counters
    high_cpu_count=0
    connectivity_failure_count=0
    rm -f /tmp/passwall_high_cpu_count
    rm -f /tmp/passwall_connectivity_failure_count
}

# Main monitoring loop - runs for one iteration (called by cron every 5 seconds)
log_debug "Monitor starting - checking Passwall CPU and connectivity"

# Check if we're in cooldown period
if is_in_cooldown; then
    log_debug "Skipping monitoring checks during cooldown period"
    exit 0
fi

# Check CPU usage
current_cpu=$(get_passwall_cpu)
log_debug "Current CPU usage: $current_cpu%"

cpu_restart_needed=0
if [ "$current_cpu" -gt "$CPU_THRESHOLD" ]; then
    # Read the counter from state file
    if [ -f /tmp/passwall_high_cpu_count ]; then
        high_cpu_count=$(cat /tmp/passwall_high_cpu_count)
    else
        high_cpu_count=0
    fi

    high_cpu_count=$((high_cpu_count + 1))
    echo "$high_cpu_count" > /tmp/passwall_high_cpu_count

    log_warning "High CPU detected: $current_cpu% (count: $high_cpu_count/$required_cpu_checks)"

    # Check if threshold duration exceeded
    if [ "$high_cpu_count" -ge "$required_cpu_checks" ]; then
        cpu_restart_needed=1
    fi
else
    # CPU is normal, reset counter
    if [ -f /tmp/passwall_high_cpu_count ]; then
        log_info "CPU normalized: $current_cpu% - Resetting counter"
        rm -f /tmp/passwall_high_cpu_count
    fi
fi

# Check network connectivity
connectivity_restart_needed=0
if [ "$ENABLE_CONNECTIVITY_CHECK" -eq 1 ]; then
    if ! check_network_connectivity; then
        # Read the counter from state file
        if [ -f /tmp/passwall_connectivity_failure_count ]; then
            connectivity_failure_count=$(cat /tmp/passwall_connectivity_failure_count)
        else
            connectivity_failure_count=0
        fi

        connectivity_failure_count=$((connectivity_failure_count + 1))
        echo "$connectivity_failure_count" > /tmp/passwall_connectivity_failure_count

        log_warning "Network connectivity failure detected (count: $connectivity_failure_count/$required_connectivity_checks)"

        # Check if threshold duration exceeded
        if [ "$connectivity_failure_count" -ge "$required_connectivity_checks" ]; then
            connectivity_restart_needed=1
        fi
    else
        # Connectivity is OK, reset counter
        if [ -f /tmp/passwall_connectivity_failure_count ]; then
            log_info "Network connectivity restored - Resetting counter"
            rm -f /tmp/passwall_connectivity_failure_count
        fi
    fi
fi

# Restart if needed
if [ "$cpu_restart_needed" -eq 1 ]; then
    restart_passwall "cpu" "$current_cpu"
elif [ "$connectivity_restart_needed" -eq 1 ]; then
    restart_passwall "connectivity"
fi

log_debug "Monitor check completed"
