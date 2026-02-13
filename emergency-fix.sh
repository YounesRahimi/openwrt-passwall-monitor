#!/bin/sh
# Emergency Diagnostic and Fix Script for Passwall Monitor Issues
# Run this if Passwall stopped working after installing the monitor

echo "=========================================="
echo "  Passwall Monitor Emergency Diagnostics"
echo "=========================================="
echo ""

# Step 1: Immediately disable the monitor
echo "[1/6] Disabling monitor..."
crontab -l 2>/dev/null | grep -v "passwall-monitor" | crontab -
echo "✓ Monitor cron jobs removed"
echo ""

# Step 2: Kill any running monitor instances
echo "[2/6] Stopping any running monitor processes..."
killall passwall-monitor.sh 2>/dev/null
echo "✓ Monitor processes stopped"
echo ""

# Step 3: Clean up state files
echo "[3/6] Cleaning up monitor state files..."
rm -f /tmp/passwall_monitor_state
rm -f /tmp/passwall_last_restart
echo "✓ State files cleaned"
echo ""

# Step 4: Check Passwall status
echo "[4/6] Checking Passwall status..."
echo ""

# Check if Passwall service exists
if [ -f "/etc/init.d/passwall" ]; then
    echo "Passwall service: Found"
    
    # Try to get status
    /etc/init.d/passwall status 2>/dev/null || echo "Status: Unknown"
    
    # Check for running processes
    echo ""
    echo "Passwall processes:"
    for proc in xray sing-box hysteria v2ray trojan; do
        pid=$(pidof $proc 2>/dev/null)
        if [ -n "$pid" ]; then
            echo "  ✓ $proc (PID: $pid)"
            # Show resource usage
            top -bn1 -p $pid 2>/dev/null | tail -n1 | awk '{printf "    CPU: %s%%, RAM: %s\n", $7, $8}'
        else
            echo "  ✗ $proc (not running)"
        fi
    done
else
    echo "ERROR: Passwall service not found at /etc/init.d/passwall"
fi
echo ""

# Step 5: Check system resources
echo "[5/6] System resource check..."
echo ""
free | awk '/Mem:/ {printf "RAM Usage: %d MB / %d MB (%.1f%% used)\n", ($3/1024), ($2/1024), ($3/$2*100)}'
echo "CPU Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo ""

# Step 6: Attempt restart
echo "[6/6] Attempting to restart Passwall..."
echo ""

if [ -f "/etc/init.d/passwall" ]; then
    echo "Stopping Passwall..."
    /etc/init.d/passwall stop
    sleep 3
    
    echo "Starting Passwall..."
    /etc/init.d/passwall start
    sleep 5
    
    echo ""
    echo "Checking if processes started..."
    success=0
    for proc in xray sing-box hysteria v2ray trojan; do
        if pidof $proc >/dev/null 2>&1; then
            echo "  ✓ $proc is running"
            success=1
        fi
    done
    
    if [ $success -eq 1 ]; then
        echo ""
        echo "✓ Passwall successfully restarted!"
    else
        echo ""
        echo "⚠ WARNING: No Passwall processes detected after restart"
        echo ""
        echo "Possible issues:"
        echo "1. Passwall configuration error"
        echo "2. VPN server unreachable"
        echo "3. Passwall needs manual reconfiguration"
    fi
else
    echo "ERROR: Cannot restart - Passwall service not found"
fi

echo ""
echo "=========================================="
echo "  Diagnostic Complete"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Check Passwall logs:"
echo "   logread | grep passwall"
echo ""
echo "2. Check system logs for errors:"
echo "   logread | tail -50"
echo ""
echo "3. Try manual restart via LuCI:"
echo "   Services → Passwall → Restart"
echo ""
echo "4. Check Passwall configuration:"
echo "   Services → Passwall → Basic Settings"
echo ""
echo "5. If still broken, check monitor logs:"
echo "   tail -50 /var/log/passwall_monitor.log"
echo ""
echo "Monitor has been DISABLED. Your router should work normally now."
echo "Only re-enable the monitor after Passwall is working properly."
echo ""
