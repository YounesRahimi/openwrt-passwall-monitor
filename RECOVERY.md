# 🚨 PASSWALL NOT WORKING? - Quick Recovery Guide

If Passwall stopped working after installing the monitor, follow these steps:

## Immediate Fix (30 seconds)

### Step 1: Disable the Monitor
```bash
ssh root@192.168.1.1
crontab -e
```
Delete ALL lines containing `passwall-monitor`, then save and exit.

### Step 2: Restart Passwall
```bash
/etc/init.d/passwall restart
```

Wait 10 seconds, then test your VPN connection.

---

## Automatic Fix (Use Emergency Script)

```bash
ssh root@192.168.1.1
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/emergency-fix.sh | sh
```

This script will:
1. Disable all monitoring
2. Clean up state files  
3. Restart Passwall
4. Show diagnostic information

---

## Manual Diagnostic Steps

### Check if monitor is running:
```bash
crontab -l | grep passwall-monitor
ps | grep passwall-monitor
```

### Check Passwall processes:
```bash
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'
```

### Check monitor logs:
```bash
tail -50 /var/log/passwall_monitor.log
```

### Check system logs:
```bash
logread | grep passwall | tail -20
```

---

## Why Did This Happen?

The monitor may have restarted Passwall too aggressively if:

1. **Thresholds too low** - Default was 100% CPU / 80MB RAM
2. **Normal spike mistaken for problem** - Brief high usage is normal during:
   - VPN connection establishment
   - Heavy traffic (downloads, streaming)
   - DNS queries
3. **False positive** - The script restarted during normal operation

---

## Safe Re-Installation (After Passwall is Working)

The script has been updated with MUCH more conservative defaults:

- **CPU Threshold: 200%** (was 100%) - Only restart if TWO cores stuck
- **RAM Threshold: 150MB** (was 80MB) - Only restart on major leak  
- **Duration: 60 seconds** (was 15s) - Must be sustained much longer
- **Cooldown: 10 minutes** (was 5min) - Longer wait between restarts

### Test Mode First:
```bash
# Edit the script
vi /root/passwall-monitor.sh

# Enable dry-run mode (line ~26)
DRY_RUN=1              # 1=log only, don't restart

# This will log what it WOULD do without actually restarting
```

### Monitor in Real-Time:
```bash
# In one terminal, watch logs
tail -f /var/log/passwall_monitor.log

# In another, check actual usage
watch -n 2 'ps aux | grep -E "xray|sing-box" | grep -v grep'
```

### Gradual Threshold Tuning:

Start conservative, lower gradually:

1. **Week 1**: CPU=200%, RAM=150MB, Duration=60s
2. **Week 2**: If no issues, lower to CPU=150%, RAM=120MB, Duration=45s  
3. **Week 3**: If no issues, lower to CPU=100%, RAM=100MB, Duration=30s

**NEVER go below:**
- CPU: 50%
- RAM: 60MB
- Duration: 30 seconds

---

## Prevention Checklist

Before enabling the monitor:

- [ ] Passwall is working perfectly for 24+ hours
- [ ] You've tested with heavy usage (streaming, downloads)
- [ ] You understand your normal CPU/RAM usage
- [ ] You've enabled DRY_RUN mode first
- [ ] You can access router if VPN breaks (local network or backup access)

---

## Emergency Contacts

If you still can't fix it:

1. **OpenWRT Forum**: Post in Passwall thread
2. **GitHub Issues**: Create issue with logs
3. **Factory Reset**: Last resort - backup config first

---

## Key Takeaway

**The monitor should be a safety net, not an active participant.**

If it's restarting frequently, it's configured wrong. Normal operation should have:
- Zero restarts per week
- Or maybe 1 restart per month if there's an actual problem

If you're seeing daily restarts, the thresholds are TOO LOW.
