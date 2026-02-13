#!/bin/sh
# OpenWRT Passwall Resource Monitor - CONSERVATIVE VERSION
# Monitors CPU and RAM usage for Passwall and auto-restarts when thresholds exceeded
# Optimized for ASUS RT-AX59U (ARMv8, 4-core, 512MB RAM)

### CONFIGURATION - CONSERVATIVE DEFAULTS ###
# These are set VERY HIGH to avoid interfering with normal operation
# Only lower these if you understand the impact

CPU_THRESHOLD=200        # Percent (200% = TWO full cores stuck)
                        # CONSERVATIVE: Only restart on severe issues
                        # Normal operation: 5-30%
                        # Start here, lower to 150 or 100 only if needed

RAM_THRESHOLD_MB=150    # MB - Passwall processes combined  
                        # CONSERVATIVE: Only restart on major leak
                        # Normal: 20-50MB, This catches 3x normal usage
                        # Start here, lower to 120 or 100 only if needed

CHECK_INTERVAL=5        # Seconds between checks
HIGH_USAGE_DURATION=60  # CONSERVATIVE: Must be high for 60 seconds
                        # This means 12 consecutive high readings
                        # Prevents false positives during normal spikes

LOG_FILE="/var/log/passwall_monitor.log"
MAX_LOG_SIZE=102400     # 100KB - prevent log file from growing too large

### ADVANCED OPTIONS ###
ENABLE_CPU_CHECK=1      # 1=enabled, 0=disabled
ENABLE_RAM_CHECK=1      # 1=enabled, 0=disabled
RESTART_COOLDOWN=600    # 10 minutes - prevent restart loops
DRY_RUN=0              # 1=log only, don't restart (for testing)

### DO NOT EDIT BELOW THIS LINE ###
STATE_FILE="/tmp/passwall_monitor_state"
LAST_RESTART_FILE="/tmp/passwall_last_restart"

# Initialize counters
high_usage_count=0
required_checks=$((HIGH_USAGE_DURATION / CHECK_INTERVAL))

log_message() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "$timestamp - $1" >> "$LOG_FILE"
    
    # Rotate log if too large
    if [ -f "$LOG_FILE" ]; then
        local log_size=$(stat -c%s "$LOG_FILE" 2>/dev/null || echo 0)
        if [ "$log_size" -gt "$MAX_LOG_SIZE" ]; then
            tail -n 500 "$LOG_FILE" > "$LOG_FILE.tmp"
            mv "$LOG_FILE.tmp" "$LOG_FILE"
            log_message "Log rotated (size exceeded ${MAX_LOG_SIZE} bytes)"
        fi
    fi
}

get_passwall_cpu() {
    local total_cpu=0
    local process_found=0
    
    # Find Passwall-related processes
    for process in xray sing-box hysteria v2ray trojan; do
        local pids=$(pidof "$process" 2>/dev/null)
        
        for pid in $pids; do
            if [ -n "$pid" ]; then
                process_found=1
                # Get CPU usage using top
                local cpu=$(top -bn1 -p "$pid" 2>/dev/null | tail -n1 | awk '{print $7}' | sed 's/%//' | awk '{print int($1+0.5)}')
                
                if [ -n "$cpu" ] && [ "$cpu" != "CPU" ]; then
                    total_cpu=$((total_cpu + cpu))
                fi
            fi
        done
    done
    
    if [ $process_found -eq 0 ]; then
        echo "0"
    else
        echo "$total_cpu"
    fi
}

get_passwall_ram_mb() {
    local total_ram_kb=0
    local process_found=0
    
    # Find Passwall-related processes and sum their RAM usage
    for process in xray sing-box hysteria v2ray trojan; do
        local pids=$(pidof "$process" 2>/dev/null)
        
        for pid in $pids; do
            if [ -n "$pid" ] && [ -f "/proc/$pid/status" ]; then
                process_found=1
                # Get VmRSS (Resident Set Size) - actual physical RAM used
                local ram_kb=$(grep "^VmRSS:" "/proc/$pid/status" 2>/dev/null | awk '{print $2}')
                
                if [ -n "$ram_kb" ]; then
                    total_ram_kb=$((total_ram_kb + ram_kb))
                fi
            fi
        done
    done
    
    if [ $process_found -eq 0 ]; then
        echo "0"
    else
        # Convert KB to MB
        echo $((total_ram_kb / 1024))
    fi
}

check_restart_cooldown() {
    if [ -f "$LAST_RESTART_FILE" ]; then
        local last_restart=$(cat "$LAST_RESTART_FILE")
        local current_time=$(date +%s)
        local time_since_restart=$((current_time - last_restart))
        
        if [ "$time_since_restart" -lt "$RESTART_COOLDOWN" ]; then
            local remaining=$((RESTART_COOLDOWN - time_since_restart))
            log_message "Restart cooldown active - ${remaining}s remaining"
            return 1
        fi
    fi
    return 0
}

restart_passwall() {
    local reason=$1
    local cpu=$2
    local ram=$3
    
    if ! check_restart_cooldown; then
        return
    fi
    
    if [ "$DRY_RUN" -eq 1 ]; then
        log_message "===== DRY RUN - WOULD RESTART ====="
        log_message "Reason: $reason"
        log_message "CPU: ${cpu}% | RAM: ${ram}MB"
        log_message "==================================="
        return
    fi
    
    log_message "===== RESTART TRIGGERED ====="
    log_message "Reason: $reason"
    log_message "CPU: ${cpu}% | RAM: ${ram}MB"
    log_message "Restarting Passwall..."
    
    /etc/init.d/passwall restart
    
    # Record restart time
    date +%s > "$LAST_RESTART_FILE"
    
    sleep 3
    
    # Verify restart
    if pidof xray sing-box hysteria v2ray trojan >/dev/null 2>&1; then
        log_message "Passwall restarted successfully"
    else
        log_message "WARNING: Passwall may not have restarted properly"
    fi
    
    log_message "============================="
    
    # Reset counters
    high_usage_count=0
    rm -f "$STATE_FILE"
}

# Main monitoring logic
main() {
    # Get current resource usage
    local current_cpu=0
    local current_ram=0
    
    if [ "$ENABLE_CPU_CHECK" -eq 1 ]; then
        current_cpu=$(get_passwall_cpu)
    fi
    
    if [ "$ENABLE_RAM_CHECK" -eq 1 ]; then
        current_ram=$(get_passwall_ram_mb)
    fi
    
    # Check if any threshold exceeded
    local threshold_exceeded=0
    local reason=""
    
    if [ "$ENABLE_CPU_CHECK" -eq 1 ] && [ "$current_cpu" -gt "$CPU_THRESHOLD" ]; then
        threshold_exceeded=1
        reason="High CPU (${current_cpu}% > ${CPU_THRESHOLD}%)"
    fi
    
    if [ "$ENABLE_RAM_CHECK" -eq 1 ] && [ "$current_ram" -gt "$RAM_THRESHOLD_MB" ]; then
        threshold_exceeded=1
        if [ -n "$reason" ]; then
            reason="$reason + High RAM (${current_ram}MB > ${RAM_THRESHOLD_MB}MB)"
        else
            reason="High RAM (${current_ram}MB > ${RAM_THRESHOLD_MB}MB)"
        fi
    fi
    
    # Handle threshold state
    if [ "$threshold_exceeded" -eq 1 ]; then
        # Load previous count
        if [ -f "$STATE_FILE" ]; then
            high_usage_count=$(cat "$STATE_FILE")
        fi
        
        high_usage_count=$((high_usage_count + 1))
        echo "$high_usage_count" > "$STATE_FILE"
        
        log_message "$reason (count: ${high_usage_count}/${required_checks})"
        
        # Check if sustained long enough
        if [ "$high_usage_count" -ge "$required_checks" ]; then
            restart_passwall "$reason" "$current_cpu" "$current_ram"
        fi
    else
        # Usage is normal
        if [ -f "$STATE_FILE" ]; then
            local prev_count=$(cat "$STATE_FILE")
            if [ "$prev_count" -gt 0 ]; then
                log_message "Resources normalized - CPU: ${current_cpu}% RAM: ${current_ram}MB (counter reset)"
            fi
            rm -f "$STATE_FILE"
        fi
        high_usage_count=0
    fi
}

# Execute main function
main
