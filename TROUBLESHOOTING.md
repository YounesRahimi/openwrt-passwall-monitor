# Troubleshooting Guide

Common issues and their solutions.

## Table of Contents
- [Installation Issues](#installation-issues)
- [Monitoring Issues](#monitoring-issues)
- [False Positives / Too Many Restarts](#false-positives--too-many-restarts)
- [Script Not Detecting Processes](#script-not-detecting-processes)
- [Performance Issues](#performance-issues)
- [Log Issues](#log-issues)

---

## Installation Issues

### Error: "command not found: wget"

**Problem:** Router doesn't have wget installed.

**Solution:**
```bash
# Install wget
opkg update
opkg install wget

# Or use curl instead (recommended)
opkg install curl

# Use the automatic installer
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/install.sh | sh
```

### Error: "crontab: command not found"

**Problem:** Cron isn't installed (rare on OpenWRT).

**Solution:**
```bash
opkg update
opkg install cron
/etc/init.d/cron enable
/etc/init.d/cron start
```

### Script downloads but won't execute

**Problem:** Not executable or wrong line endings.

**Solution:**
```bash
# Make executable
chmod +x /usr/bin/passwall-monitor.sh

# Fix line endings (if downloaded on Windows)
dos2unix /usr/bin/passwall-monitor.sh

# If dos2unix not available
sed -i 's/\r$//' /usr/bin/passwall-monitor.sh
```

---

## Monitoring Issues

### Monitor not running

**Diagnosis:**
```bash
# Check if cron is running
ps | grep cron

# Check cron jobs
crontab -l | grep passwall

# Check logs for errors
logread | grep cron
```

**Solutions:**

1. **Cron not running:**
```bash
/etc/init.d/cron start
/etc/init.d/cron enable
```

2. **Cron jobs missing:**
```bash
# Reinstall using install.sh or manually add cron jobs
crontab -e
# Add the 12 lines from README
```

3. **Script has errors:**
```bash
# Test script manually
sh -n /usr/bin/passwall-monitor.sh  # Syntax check
/usr/bin/passwall-monitor.sh         # Run once
```

### No logs being created

**Diagnosis:**
```bash
# Check if log directory exists
ls -la /var/log/

# Check permissions
ls -la /var/log/passwall_monitor.log

# Check disk space
df -h
```

**Solutions:**

1. **Directory doesn't exist:**
```bash
mkdir -p /tmp/log
touch /tmp/log/passwall_monitor.log
```

2. **Permission issues:**
```bash
chmod 644 /tmp/log/passwall_monitor.log
chown root:root /tmp/log/passwall_monitor.log
```

3. **Disk full:**
```bash
# Check what's using space
du -sh /tmp/* | sort -hr | head

# Clean old logs
rm /var/log/*.log.old
```

4. **Volatile /var/log (resets on reboot):**
```bash
# Move log to persistent storage
mkdir -p /root/logs
# Edit script and change LOG_FILE path
vi /usr/bin/passwall-monitor.sh
# Change: LOG_FILE="/tmp/log/passwall_monitor.log"
```

---

## False Positives / Too Many Restarts

### Restarts happening too frequently

**Diagnosis:**
```bash
# Check restart frequency
grep "HIGH CPU DETECTED" /tmp/log/passwall_monitor.log

# Check what's triggering restarts
grep -A 2 "HIGH CPU DETECTED" /tmp/log/passwall_monitor.log
```

**Solutions:**

1. **Increase thresholds:**
```bash
vi /usr/bin/passwall-monitor.sh

# For CPU issues - increase threshold
THRESHOLD=50  # If was 25

# For RAM issues - increase by 20-30MB
RAM_THRESHOLD_MB=100  # If was 80
```

2. **Increase duration before restart:**
```bash
vi /usr/bin/passwall-monitor.sh

# Wait longer before restart
HIGH_CPU_DURATION=30  # Was 15 seconds
```

# Or disable RAM check
ENABLE_RAM_CHECK=0
```

### Restarts during specific activities

**Example:** Restarts when streaming, downloading, etc.

**Solution:** This might be normal high usage. Consider:

1. **Increase thresholds during these activities**
2. **Use cooldown to prevent rapid restarts**
3. **Check if issue is actually with VPN server, not Passwall**

---

## Script Not Detecting Processes

### "Process not found" in logs

**Diagnosis:**
```bash
# Check what Passwall processes are actually running
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'

# Check process names
ps | grep passwall
```

**Solutions:**

1. **Process has different name:**
```bash
# Find the actual process name
ps | grep -v grep | grep -i passwall

# Edit script to add this process name
vi /root/passwall-monitor.sh
# Add to the process list in get_passwall_cpu() function
```

2. **Passwall not running:**
```bash
# Start Passwall
/etc/init.d/passwall start

# Check status
/etc/init.d/passwall status
```

### CPU/RAM always shows 0%

**Diagnosis:**
```bash
# Test CPU detection manually
top -bn1 | grep xray

# Check /proc access
ls -la /proc/$(pidof xray)/status
```

**Solutions:**

1. **Top command different on your router:**
```bash
# Try different top syntax
top -n 1  # Instead of top -bn1
top -b -n 1  # Separate flags

# Edit script to match your top version
vi /usr/bin/passwall-monitor.sh
```

2. **Process permission issues:**
```bash
# Run script as root
sudo /usr/bin/passwall-monitor.sh

# Check if Passwall runs as different user
ps aux | grep xray
```

---

## Performance Issues

### Router feels slow after installing monitor

**Diagnosis:**
```bash
# Check how much CPU monitor uses
top -n 1 | grep passwall-monitor

# Check cron frequency
crontab -l | grep passwall-monitor | wc -l
```

**Solutions:**

1. **Reduce check frequency:**
```bash
# Edit crontab
crontab -e

# Remove half the entries (check every 10s instead of 5s)
# Keep only these lines:
* * * * * /usr/bin/passwall-monitor.sh
* * * * * sleep 10; /usr/bin/passwall-monitor.sh
* * * * * sleep 20; /usr/bin/passwall-monitor.sh
* * * * * sleep 30; /usr/bin/passwall-monitor.sh
* * * * * sleep 40; /usr/bin/passwall-monitor.sh
* * * * * sleep 50; /usr/bin/passwall-monitor.sh
```

2. **Optimize script:**
```bash
# Check for resource-intensive operations
time /usr/bin/passwall-monitor.sh
# Should complete in <0.1 seconds
```

### Log file growing too large

**Diagnosis:**
```bash
# Check if log file exists and permissions
ls -la /tmp/log/passwall_monitor.log
```

**Solutions:**

Built-in rotation should handle this, but if not:

```bash
# Manually rotate
tail -n 500 /tmp/log/passwall_monitor.log > /tmp/log/passwall_monitor.log.tmp
mv /tmp/log/passwall_monitor.log.tmp /tmp/log/passwall_monitor.log

# Or reduce log verbosity in script
vi /usr/bin/passwall-monitor.sh
```

---

## Log Issues

### Logs show "High CPU" but Passwall seems fine

**This might be normal** if:
- Actively using VPN (downloading, streaming)
- Multiple devices connected
- Just started/restarted Passwall

**Check:**
```bash
# See current actual usage
top -n 1 | grep -E 'xray|sing-box'

# Monitor over time
watch -n 2 'top -n 1 | grep xray'
```

**If false alarms:**
- Increase CPU_THRESHOLD
- Increase HIGH_USAGE_DURATION

### Logs show restart but Passwall still broken

**Diagnosis:**
```bash
# Check if Passwall actually restarted
/etc/init.d/passwall status

# Check Passwall logs
logread | grep passwall

# Try manual restart
/etc/init.d/passwall restart
```

**Possible issues:**
1. Passwall configuration error
2. VPN server down
3. Network connectivity issue

**Solution:** Fix underlying Passwall issue, not monitoring script.

---

## Getting Help

If none of these solutions work:

1. **Collect diagnostic info:**
```bash
# Create diagnostic report
cat << 'EOF' > /tmp/diagnostic.txt
=== System Info ===
$(cat /etc/openwrt_release)

=== Router Specs ===
$(cat /proc/cpuinfo | grep -E 'model|cpu cores')
$(free -m)

=== Passwall Processes ===
$(ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan')

=== Current Usage ===
$(top -bn1 | head -20)

=== Cron Jobs ===
$(crontab -l)

=== Recent Logs ===
$(tail -50 /var/log/passwall_monitor.log)

=== Script Version ===
$(head -5 /usr/bin/passwall-monitor.sh)
EOF

cat /tmp/diagnostic.txt
```

2. **Create GitHub issue** with:
   - Your diagnostic report
   - Router model
   - What you've tried
   - Expected vs actual behavior

3. **Check existing issues:**
   - [GitHub Issues](https://github.com/YounesRahimi/openwrt-passwall-monitor/issues)

---

## Emergency: Disable Monitor Immediately

If monitor is causing problems:

```bash
# Quick disable
crontab -e
# Delete all passwall-monitor lines
# Save and exit

# Kill running instances
killall passwall-monitor.sh

# Or use uninstall script
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/uninstall.sh | sh
```
