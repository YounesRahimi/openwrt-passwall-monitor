# OpenWRT Passwall Monitor 🛡️

> Automated resource monitoring and auto-restart for Passwall on OpenWRT routers

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenWRT](https://img.shields.io/badge/OpenWRT-24.10-blue.svg)](https://openwrt.org/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## ⚠️ IMPORTANT - Read Before Installing

**This monitor is designed to be a safety net for rare issues, not an active manager.**

- **Conservative defaults**: Won't restart unless usage is VERY high for 60+ seconds
- **Test mode available**: Enable `DRY_RUN=1` to see what it would do without actually restarting
- **Easy disable**: If anything goes wrong, just remove the cron jobs

**🚨 Passwall stopped working?** See [RECOVERY.md](docs/RECOVERY.md) for immediate fix.

## 🎯 What Does This Do?

Automatically monitors your Passwall VPN processes (xray, sing-box, hysteria, v2ray, trojan) and restarts them when:

- **CPU usage** exceeds thresholds (default: 200% = 2 full cores stuck)
- **RAM usage** exceeds thresholds (default: 150MB)  
- High usage **persists for 60+ seconds** (prevents false positives)

Perfect for fixing those rare situations where Passwall gets stuck - **but won't interfere with normal operation**.

## ✨ Features

- ✅ **Dual Monitoring**: CPU + RAM usage tracking
- ✅ **Smart Thresholds**: Auto-tuned for your router's specs
- ✅ **False Positive Prevention**: Only restarts after sustained high usage
- ✅ **Restart Protection**: 5-minute cooldown prevents restart loops
- ✅ **Detailed Logging**: Track all events with automatic log rotation
- ✅ **Easy Installation**: Copy, paste, done! (3 commands)
- ✅ **Zero Dependencies**: Pure POSIX shell script
- ✅ **Multiple Cores Supported**: Works with xray, sing-box, hysteria, v2ray, trojan

## 📊 Default Thresholds (CONSERVATIVE)

These values are set VERY HIGH to avoid false positives:

| Resource | Threshold | Reasoning |
|----------|-----------|-----------|
| **CPU** | 200% | TWO full cores stuck - indicates severe problem |
| **RAM** | 150MB | 3x normal usage - indicates major leak |
| **Duration** | 60 seconds | Must be sustained - prevents false positives |
| **Cooldown** | 10 minutes | Long wait between restarts |

### Why These Conservative Values?

**These thresholds are intentionally HIGH** to ensure the monitor doesn't interfere with normal operation:

- **Normal Passwall usage**: 5-30% CPU, 20-50MB RAM
- **During heavy use**: 50-80% CPU, 60-80MB RAM  
- **Monitor triggers**: 200%+ CPU, 150MB+ RAM for 60+ seconds

**You can lower these** after observing your router's behavior, but start conservative!

## 🚀 Quick Start (3 Steps)

### 1. Download the Script

**Option A - Direct download:**
```bash
ssh root@192.168.1.1
cd /root
curl -o passwall-monitor.sh https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/passwall-monitor.sh
chmod +x passwall-monitor.sh
```

**Option B - Copy/paste:**
```bash
ssh root@192.168.1.1
cd /root
# Copy the contents of passwall-monitor.sh
vi passwall-monitor.sh  # Paste the script
chmod +x passwall-monitor.sh
```

### 2. Test It

```bash
/root/passwall-monitor.sh
tail -f /var/log/passwall_monitor.log
```

**Recommended: Enable Test Mode First**

```bash
# Edit script
vi /root/passwall-monitor.sh

# Find and change this line (around line 26):
DRY_RUN=1              # 1=log only, don't restart (TEST MODE)

# Save and exit
```

In test mode, the script logs what it *would* do without actually restarting Passwall. Monitor for 24-48 hours to ensure it won't trigger false positives.

### 3. Set Up Auto-Run (Cron)

```bash
crontab -e
```

Add these lines to run every 5 seconds:

```cron
* * * * * /root/passwall-monitor.sh
* * * * * sleep 5; /root/passwall-monitor.sh
* * * * * sleep 10; /root/passwall-monitor.sh
* * * * * sleep 15; /root/passwall-monitor.sh
* * * * * sleep 20; /root/passwall-monitor.sh
* * * * * sleep 25; /root/passwall-monitor.sh
* * * * * sleep 30; /root/passwall-monitor.sh
* * * * * sleep 35; /root/passwall-monitor.sh
* * * * * sleep 40; /root/passwall-monitor.sh
* * * * * sleep 45; /root/passwall-monitor.sh
* * * * * sleep 50; /root/passwall-monitor.sh
* * * * * sleep 55; /root/passwall-monitor.sh
```

Save and exit, then restart cron:

```bash
/etc/init.d/cron restart
```

**Done!** 🎉 The monitor is now running.

## 📝 Usage

### View Real-Time Logs

```bash
# Follow live logs
tail -f /var/log/passwall_monitor.log

# View recent logs
tail -n 50 /var/log/passwall_monitor.log

# Search for restarts
grep "RESTART TRIGGERED" /var/log/passwall_monitor.log
```

### Check Current Status

```bash
# Check if monitor is running
ps | grep passwall-monitor

# Check Passwall processes
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'

# Check current resource usage
top -n 1 | grep -E 'xray|sing-box|hysteria|v2ray|trojan'
```

### Manual Commands

```bash
# Manual restart
/etc/init.d/passwall restart

# Test monitor once
/root/passwall-monitor.sh

# Stop monitoring (remove cron jobs)
crontab -e  # Delete all passwall-monitor lines
```

## ⚙️ Configuration

Edit `/root/passwall-monitor.sh` to customize:

### Adjust Thresholds

```bash
# For 2-core routers, lower CPU threshold:
CPU_THRESHOLD=50        # 50% = one full core on 2-core system

# For 256MB RAM routers:
RAM_THRESHOLD_MB=40     # Lower threshold for less RAM

# For 1GB+ RAM routers:
RAM_THRESHOLD_MB=150    # Higher threshold for more RAM
```

### Timing Configuration

```bash
CHECK_INTERVAL=5        # How often to check (seconds)
HIGH_USAGE_DURATION=15  # How long to wait before restart (seconds)
RESTART_COOLDOWN=300    # Cooldown between restarts (seconds)
```

### Enable/Disable Checks

```bash
ENABLE_CPU_CHECK=1      # 1=enabled, 0=disabled
ENABLE_RAM_CHECK=1      # 1=enabled, 0=disabled
```

## 🔍 Troubleshooting

### Monitor Not Running?

```bash
# Check if cron is running
ps | grep cron
/etc/init.d/cron status

# Check cron jobs
crontab -l

# Check for errors
logread | grep cron
```

### Script Not Detecting Processes?

```bash
# Verify process names
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'

# Test CPU detection manually
top -bn1 | grep xray

# Test RAM detection
cat /proc/$(pidof xray)/status | grep VmRSS
```

### Logs Not Appearing?

```bash
# Create log directory
mkdir -p /var/log
touch /var/log/passwall_monitor.log

# Check permissions
ls -la /var/log/passwall_monitor.log

# Test logging
/root/passwall-monitor.sh
cat /var/log/passwall_monitor.log
```

### Too Many Restarts?

```bash
# Increase thresholds or duration
vi /root/passwall-monitor.sh

# Increase CPU_THRESHOLD to 150
# Or increase HIGH_USAGE_DURATION to 30
```

## 📋 Recommended Thresholds by Router

| Router Model | CPU Cores | RAM | CPU Threshold | RAM Threshold |
|--------------|-----------|-----|---------------|---------------|
| ASUS RT-AX59U | 4 | 512MB | 100% | 80MB |
| Xiaomi AX3600 | 4 | 512MB | 100% | 80MB |
| GL.iNet AR300M | 1 | 128MB | 80% | 30MB |
| Netgear R7800 | 2 | 512MB | 75% | 80MB |
| Linksys WRT3200ACM | 2 | 512MB | 75% | 80MB |

**Don't see your router?** Use these rules:
- **CPU**: `100% ÷ number_of_cores` (minimum 50%)
- **RAM**: `15-20% of available RAM` after OS overhead

## 🗂️ File Locations

```
/root/passwall-monitor.sh           # Main script
/var/log/passwall_monitor.log       # Activity log (auto-rotates at 100KB)
/tmp/passwall_monitor_state         # Temporary counter state
/tmp/passwall_last_restart          # Last restart timestamp
```

## 🧪 Testing

### Simulate High CPU

```bash
# Run this on your router to test
yes > /dev/null &
# Monitor should NOT restart (process name doesn't match)

# Kill it after testing
killall yes
```

### View Statistics

```bash
# Check how often restarts occur
grep "RESTART TRIGGERED" /var/log/passwall_monitor.log | wc -l

# See average uptime between restarts
grep "RESTART TRIGGERED" /var/log/passwall_monitor.log
```

## 🔄 Updating

```bash
cd /root
# Backup current config
cp passwall-monitor.sh passwall-monitor.sh.backup

# Download new version
curl -o passwall-monitor.sh https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/passwall-monitor.sh
chmod +x passwall-monitor.sh

# Restore your custom settings
vi passwall-monitor.sh
```

## 🗑️ Uninstallation

```bash
# Remove cron jobs
crontab -e
# Delete all passwall-monitor lines

# Remove files
rm /root/passwall-monitor.sh
rm /var/log/passwall_monitor.log
rm /tmp/passwall_monitor_state
rm /tmp/passwall_last_restart

# Restart cron
/etc/init.d/cron restart
```

## ❓ FAQ

**Q: Will this work with other Passwall cores?**  
A: Yes! Supports xray, sing-box, hysteria, v2ray, and trojan.

**Q: Does it work on other routers?**  
A: Yes! Works on any OpenWRT router. Just adjust thresholds for your specs.

**Q: Will it cause connection drops?**  
A: Brief 3-5 second reconnection during restart. Only happens when truly needed.

**Q: How much overhead does monitoring add?**  
A: Minimal - script runs for <0.1 seconds every 5 seconds.

**Q: Can I monitor other services?**  
A: Yes! Edit the script's process detection section to add other services.

## 🤝 Contributing

Contributions welcome! Feel free to:
- Report bugs
- Suggest features
- Submit pull requests
- Share your custom configurations

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🙏 Acknowledgments

- OpenWRT community
- Passwall developers
- All contributors and testers

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/YounesRahimi/openwrt-passwall-monitor/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/YounesRahimi/openwrt-passwall-monitor/discussions)
- 📖 **Wiki**: [Documentation](https://github.com/YounesRahimi/openwrt-passwall-monitor/wiki)

---

**Made with ❤️ for the OpenWRT community**

*If this helped you, consider giving it a ⭐ star!*
