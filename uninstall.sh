#!/bin/sh
# Uninstall Script for OpenWRT Passwall Monitor

set -e

SCRIPT_PATH="/root/passwall-monitor.sh"
LOG_FILE="/var/log/passwall_monitor.log"
STATE_FILE="/tmp/passwall_monitor_state"
RESTART_FILE="/tmp/passwall_last_restart"

echo "================================================"
echo "  OpenWRT Passwall Monitor - Uninstaller"
echo "================================================"
echo ""

# Confirmation
echo "This will remove:"
echo "  - Monitor script ($SCRIPT_PATH)"
echo "  - Cron jobs"
echo "  - Log files"
echo "  - Temporary files"
echo ""
echo -n "Continue? (y/N): "
read -r response

if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "[1/4] Removing cron jobs..."

# Remove cron jobs
if crontab -l 2>/dev/null | grep -q "passwall-monitor.sh"; then
    crontab -l 2>/dev/null | grep -v "passwall-monitor.sh" | crontab -
    echo "✓ Cron jobs removed"
else
    echo "⚠ No cron jobs found"
fi

echo ""
echo "[2/4] Stopping any running instances..."
# Kill any running instances (shouldn't be any with cron, but just in case)
killall passwall-monitor.sh 2>/dev/null || true
echo "✓ Stopped"

echo ""
echo "[3/4] Removing files..."

# Remove script
if [ -f "$SCRIPT_PATH" ]; then
    rm "$SCRIPT_PATH"
    echo "✓ Removed $SCRIPT_PATH"
else
    echo "⚠ Script not found: $SCRIPT_PATH"
fi

# Remove log file (ask first)
if [ -f "$LOG_FILE" ]; then
    echo -n "Remove log file? (y/N): "
    read -r log_response
    if [ "$log_response" = "y" ] || [ "$log_response" = "Y" ]; then
        rm "$LOG_FILE"
        echo "✓ Removed $LOG_FILE"
    else
        echo "⚠ Kept $LOG_FILE"
    fi
fi

# Remove state files
rm -f "$STATE_FILE" "$RESTART_FILE"
echo "✓ Removed temporary files"

echo ""
echo "[4/4] Restarting cron service..."
/etc/init.d/cron restart
echo "✓ Cron restarted"

echo ""
echo "================================================"
echo "  Uninstall Complete! ✓"
echo "================================================"
echo ""
echo "The Passwall monitor has been removed."
echo "Your Passwall service is still running normally."
echo ""
