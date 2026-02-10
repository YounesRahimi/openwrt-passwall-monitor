#!/bin/sh
# Quick Installation Script for OpenWRT Passwall Monitor
# Author: Younes Rahimi
# Run this on your OpenWRT router

set -e  # Exit on error

SCRIPT_URL="https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/passwall-monitor.sh"
INSTALL_DIR="/usr/bin"
SCRIPT_NAME="passwall-monitor.sh"
SCRIPT_PATH="$INSTALL_DIR/$SCRIPT_NAME"

echo "================================================"
echo "  OpenWRT Passwall Monitor - Quick Installer"
echo "================================================"
echo ""

# Check if running on OpenWRT
if [ ! -f "/etc/openwrt_release" ]; then
    echo "ERROR: This doesn't appear to be an OpenWRT system"
    exit 1
fi

echo "[1/5] Checking prerequisites..."

# Check for required commands
for cmd in curl crontab; do
    if ! command -v $cmd >/dev/null 2>&1; then
        echo "ERROR: Required command '$cmd' not found"
        exit 1
    fi
done

# Ensure install directory exists
mkdir -p "$INSTALL_DIR"

echo "✓ Prerequisites OK"
echo ""

# Backup existing installation
if [ -f "$SCRIPT_PATH" ]; then
    echo "[2/5] Backing up existing installation..."
    cp "$SCRIPT_PATH" "$SCRIPT_PATH.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Backup created"
else
    echo "[2/5] No existing installation found"
fi
echo ""

# Download script
echo "[3/5] Downloading monitor script..."
if curl -sSL -o "$SCRIPT_PATH" "$SCRIPT_URL"; then
    chmod +x "$SCRIPT_PATH"
    echo "✓ Script downloaded and made executable"
else
    echo "ERROR: Failed to download script"
    echo "You can manually download from: $SCRIPT_URL"
    exit 1
fi
echo ""

# Test script
echo "[4/5] Testing script..."
if "$SCRIPT_PATH"; then
    echo "✓ Script test successful"
else
    echo "ERROR: Script test failed"
    exit 1
fi
echo ""

# Set up cron
echo "[5/5] Setting up automatic monitoring..."

# Check if already installed
if crontab -l 2>/dev/null | grep -q "$SCRIPT_NAME"; then
    echo "⚠ Cron jobs already exist. Skipping cron setup."
    echo "  To reinstall, remove existing cron jobs first:"
    echo "  crontab -e  # Then delete all $SCRIPT_NAME lines"
else
    # Add cron jobs
    (crontab -l 2>/dev/null || true; cat << EOF
# OpenWRT Passwall Monitor - runs every 5 seconds
* * * * * $SCRIPT_PATH
* * * * * sleep 5; $SCRIPT_PATH
* * * * * sleep 10; $SCRIPT_PATH
* * * * * sleep 15; $SCRIPT_PATH
* * * * * sleep 20; $SCRIPT_PATH
* * * * * sleep 25; $SCRIPT_PATH
* * * * * sleep 30; $SCRIPT_PATH
* * * * * sleep 35; $SCRIPT_PATH
* * * * * sleep 40; $SCRIPT_PATH
* * * * * sleep 45; $SCRIPT_PATH
* * * * * sleep 50; $SCRIPT_PATH
* * * * * sleep 55; $SCRIPT_PATH
EOF
) | crontab -
    
    echo "✓ Cron jobs installed"
    
    # Restart cron
    /etc/init.d/cron restart
    echo "✓ Cron service restarted"
fi
echo ""

echo "================================================"
echo "  Installation Complete! ✓"
echo "================================================"
echo ""
echo "What's Next:"
echo ""
echo "1. View logs:"
echo "   tail -f /tmp/log/passwall_monitor.log"
echo ""
echo "2. Check status:"
echo "   ps | grep passwall-monitor"
echo ""
echo "3. Customize thresholds (optional):"
echo "   vi $SCRIPT_PATH"
echo "   # Edit THRESHOLD and HIGH_CPU_DURATION"
echo ""
echo "4. View this installation:"
echo "   crontab -l"
echo ""
echo "Monitor is now active and will check every 5 seconds!"
echo ""
