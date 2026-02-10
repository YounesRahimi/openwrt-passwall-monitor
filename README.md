# OpenWRT Passwall Monitor 🛡️

> Automated resource monitoring and auto-restart for Passwall on OpenWRT routers

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenWRT](https://img.shields.io/badge/OpenWRT-24.10-blue.svg)](https://openwrt.org/)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

## 🎯 What Does This Do?

Automatically monitors your Passwall VPN processes (xray, sing-box, hysteria, v2ray, trojan) and restarts them when:

- **CPU usage** exceeds thresholds (default: 100% = 1 full core)
- **RAM usage** exceeds thresholds (default: 80MB)
- **Network connectivity** fails through VPN (default: 1 minute of failures)
- High usage **persists for 15+ seconds** (prevents false positives)

Perfect for fixing those frustrating situations where Passwall gets stuck consuming resources or loses network connectivity!

## ✨ Features

- ✅ **Triple Monitoring**: CPU + RAM + Network connectivity tracking
- ✅ **Smart Connectivity Checks**: Tests actual internet access via Google's 204 endpoint
- ✅ **Smart Thresholds**: Auto-tuned for your router's specs
- ✅ **False Positive Prevention**: Only restarts after sustained issues
- ✅ **Restart Protection**: 5-minute cooldown prevents restart loops
- ✅ **Detailed Logging**: Track all events with automatic log rotation
- ✅ **Easy Installation**: Copy, paste, done! (3 commands)
- ✅ **Zero Dependencies**: Pure POSIX shell script
- ✅ **Multiple Cores Supported**: Works with xray, sing-box, hysteria, v2ray, trojan

## 📊 Default Thresholds (ASUS RT-AX59U)

These values are pre-configured for the **ASUS RT-AX59U** router:

| Resource | Threshold | Reasoning |
|----------|-----------|-----------|
| **CPU** | 100% | One full core (out of 4) - indicates stuck thread |
| **RAM** | 80MB | Normal usage: 20-50MB, 80MB+ indicates leak |
| **Network** | 1 minute | Failed connectivity checks before restart |
| **Duration** | 15 seconds | Sustained high usage before restart |
| **Cooldown** | 5 minutes | Prevents rapid restart loops |

### Why These Values?

- **ARMv8 4-core CPU** (400% total available)
  - Single process using >100% = spinning/stuck thread
  - 100% = 25% of total CPU capacity
  
- **512MB RAM** (~350MB available after OS)
  - Normal Passwall: 20-50MB
  - Memory leak threshold: 80MB (15% of available RAM)

- **Network Connectivity**
  - Tests actual internet access via `https://www.google.com/generate_204`
  - Only monitors when VPN processes are active
  - 60-second failure threshold prevents false positives from temporary network issues

## 🚀 Quick Start (2 Steps)

### 1. Download and Install

**Option A - Automatic Installation (Recommended):**
```bash
ssh root@192.168.1.1
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/install.sh | sh
```

**Option B - Manual Download and Install:**
```bash
ssh root@192.168.1.1
curl -o install.sh https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/install.sh
chmod +x install.sh
./install.sh
```

### 2. Verify Installation

```bash
# Check if monitor is running
ps | grep passwall-monitor

# View real-time logs
tail -f /tmp/log/passwall_monitor.log
```

**Done!** 🎉 The monitor is now running automatically every 5 seconds.

## 📝 Usage

### View Real-Time Logs

```bash
# Follow live logs
tail -f /tmp/log/passwall_monitor.log

# View recent logs
tail -n 50 /tmp/log/passwall_monitor.log

# Search for restarts
grep "HIGH CPU DETECTED" /tmp/log/passwall_monitor.log
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
/usr/bin/passwall-monitor.sh

# Stop monitoring (remove cron jobs)
crontab -e  # Then delete all passwall-monitor lines
```

## ⚙️ Configuration

Edit `/usr/bin/passwall-monitor.sh` to customize:

### Adjust CPU/RAM Thresholds

```bash
# For more sensitive detection:
CPU_THRESHOLD=15       # Lower threshold (15% CPU)

# For less sensitive detection:
CPU_THRESHOLD=50       # Higher threshold (50% CPU)

# Adjust timing:
HIGH_CPU_DURATION=30   # Wait 30 seconds before restart
CHECK_INTERVAL=10      # Check every 10 seconds instead of 5
```

### Configure Network Connectivity Monitoring

```bash
# Disable network checking entirely
ENABLE_CONNECTIVITY_CHECK=0

# Customize connectivity settings
CONNECTIVITY_TIMEOUT=15                    # Timeout for connectivity test
CONNECTIVITY_FAILURE_DURATION=120         # Wait 2 minutes before restart
CONNECTIVITY_URL="https://httpbin.org/status/200"  # Alternative test endpoint
```

### Supported Test Endpoints

- `https://www.google.com/generate_204` (default) - Google's standard no-content endpoint
- `https://httpbin.org/status/200` - Alternative testing service
- `https://1.1.1.1/` - Cloudflare DNS endpoint
- `https://8.8.8.8/` - Google DNS endpoint

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

### Network Connectivity Issues?

```bash
# Test connectivity manually
curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 "https://www.google.com/generate_204"
# Should return: 204

# Test with wget (alternative)
wget --spider --timeout=10 --tries=1 "https://www.google.com/generate_204"

# Check if VPN processes are running
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'

# Disable connectivity check temporarily
vi /usr/bin/passwall-monitor.sh  
# Set ENABLE_CONNECTIVITY_CHECK=0
```

### Logs Not Appearing?

```bash
# Create log directory
mkdir -p /tmp/log
touch /tmp/log/passwall_monitor.log

# Check permissions
ls -la /tmp/log/passwall_monitor.log

# Test logging manually
/usr/bin/passwall-monitor.sh
cat /tmp/log/passwall_monitor.log
```

### Too Many Restarts?

```bash
# Increase threshold or duration
vi /usr/bin/passwall-monitor.sh

# Increase THRESHOLD to 50
# Or increase HIGH_CPU_DURATION to 30
```

## 📋 Recommended Thresholds by Router

| Router Model | CPU Cores | RAM | CPU Threshold | Notes |
|--------------|-----------|-----|---------------|-------|
| ASUS RT-AX59U | 4 | 512MB | 25% | Default setting |
| Xiaomi AX3600 | 4 | 512MB | 25% | Good for high-end routers |
| GL.iNet AR300M | 1 | 128MB | 50% | Single core, higher threshold |
| Netgear R7800 | 2 | 512MB | 35% | Dual core compromise |
| Linksys WRT3200ACM | 2 | 512MB | 35% | Dual core compromise |

**Don't see your router?** Use these rules:
- **Single core**: Start with 50-80%
- **Dual core**: Start with 35-50% 
- **Quad core+**: Start with 25-35%

## 🗂️ File Locations

```
/usr/bin/passwall-monitor.sh           # Main script
/tmp/log/passwall_monitor.log          # Activity log
/tmp/passwall_high_cpu_count           # Temporary counter state
```

## 🧪 Testing

### Test Manual Execution

```bash
# Run the monitor once manually
/usr/bin/passwall-monitor.sh

# Check the log for output
tail /tmp/log/passwall_monitor.log
```

### View Statistics

```bash
# Check how often restarts occur
grep "HIGH CPU DETECTED" /tmp/log/passwall_monitor.log | wc -l

# See recent activity
tail -20 /tmp/log/passwall_monitor.log
```

## 🔄 Updating

```bash
# Easy update using install script (preserves settings)
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/install.sh | sh
```

## 🗑️ Uninstallation

```bash
# Easy uninstallation
curl -sSL https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/uninstall.sh | sh
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
