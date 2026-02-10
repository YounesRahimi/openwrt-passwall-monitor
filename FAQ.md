# Frequently Asked Questions (FAQ)

## General Questions

### What is this tool for?

This tool automatically monitors your OpenWRT router's Passwall VPN processes and restarts them if they consume excessive CPU or RAM for an extended period. This helps maintain stable VPN performance.

### Why would Passwall need to be restarted?

Common reasons:
- Memory leaks in VPN cores (especially with long uptimes)
- Stuck threads consuming CPU
- Connection pool exhaustion
- DNS resolution issues causing CPU spikes

### Will this work on my router?

Yes! It works on any OpenWRT router. The default configuration is optimized for ASUS RT-AX59U, but you can adjust thresholds for your specific router. See [Router Configs](examples/ROUTER_CONFIGS.md).

### Do I need technical knowledge to use this?

Basic knowledge needed:
- How to SSH into your router
- Copy/paste commands
- Edit text files (optional, for customization)

The installation is just 3 commands!

## Installation Questions

### How do I install this?

**Easiest way:**
```bash
ssh root@192.168.1.1
wget -O - https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/install.sh | sh
```

**Manual way:** See [Quick Start in README](README.md#-quick-start-3-steps)

### Can I use this with the LuCI web interface?

Yes! You can add the cron jobs through:
1. LuCI → System → Scheduled Tasks
2. Paste the cron entries
3. Save & Apply

### Do I need to keep my computer on?

No! Once installed, it runs entirely on your router. Your computer can be off.

### Where should I install the script?

Default location is `/root/passwall-monitor.sh`. This is recommended as `/root` is typically persistent across reboots.

## Configuration Questions

### What are the default thresholds?

```bash
CPU_THRESHOLD=100        # 100% = one full core
RAM_THRESHOLD_MB=80      # 80MB of RAM
HIGH_USAGE_DURATION=15   # 15 seconds sustained
```

These are optimized for a 4-core router with 512MB RAM.

### How do I know what thresholds to use?

See the [Threshold Calculation Guide](examples/ROUTER_CONFIGS.md#how-to-calculate-thresholds-for-your-router).

**Quick formula:**
- **CPU:** 100% ÷ (number of cores) = threshold per core
- **RAM:** (Available RAM) × 15-20% = reasonable threshold

### Can I monitor only CPU or only RAM?

Yes! Set these in the script:
```bash
ENABLE_CPU_CHECK=0  # Disable CPU monitoring
ENABLE_RAM_CHECK=0  # Disable RAM monitoring
```

### How often does it check?

Default: Every 5 seconds

You can change this by modifying the cron jobs or editing `CHECK_INTERVAL` in the script.

## Operational Questions

### Will it interrupt my VPN connection?

Yes, but briefly. Passwall restart takes 3-5 seconds. Active connections will need to reconnect.

**However:** This only happens when thresholds are exceeded for 15+ seconds, which indicates an actual problem.

### How do I know if it's working?

```bash
# Check logs
tail -f /var/log/passwall_monitor.log

# Check if monitoring
ps | grep passwall-monitor

# Verify cron jobs
crontab -l
```

### How often does it restart Passwall?

**Ideally: Never or very rarely**

If you see frequent restarts (multiple times per day), your thresholds may be too low or there's an underlying issue with:
- Your VPN server
- Your Passwall configuration
- Your router resources

### What's the cooldown period?

Default: 5 minutes (300 seconds)

This prevents rapid restart loops. After a restart, the monitor waits 5 minutes before allowing another restart.

### Can I disable the monitor temporarily?

```bash
# Remove cron jobs temporarily
crontab -l > /tmp/cron.backup
crontab -r

# To restore
crontab /tmp/cron.backup
```

## Troubleshooting Questions

### It's not creating logs

**Check:**
```bash
# Does directory exist?
ls -la /var/log/

# Create if needed
mkdir -p /var/log
touch /var/log/passwall_monitor.log
```

See [Log Issues](docs/TROUBLESHOOTING.md#log-issues) for more.

### It's restarting Passwall too often

**Possible causes:**
1. Thresholds too low
2. VPN server issues
3. High traffic usage is normal

**Solutions:**
- Increase thresholds by 25-50%
- Increase `HIGH_USAGE_DURATION`
- Check your VPN server status

See [False Positives](docs/TROUBLESHOOTING.md#false-positives--too-many-restarts).

### It's not detecting Passwall processes

**Check:**
```bash
# What processes are running?
ps | grep -E 'xray|sing-box|hysteria|v2ray|trojan'

# If different name, add to script
vi /root/passwall-monitor.sh
# Edit get_passwall_cpu() function
```

### How do I check current CPU/RAM usage?

```bash
# Real-time monitoring
top -n 1 | grep -E 'xray|sing-box'

# Specific process
top -n 1 -p $(pidof xray)

# RAM usage
cat /proc/$(pidof xray)/status | grep VmRSS
```

### Script syntax errors

**Fix:**
```bash
# Check syntax
sh -n /root/passwall-monitor.sh

# Common fix: line endings
sed -i 's/\r$//' /root/passwall-monitor.sh
```

## Performance Questions

### Does it slow down my router?

No, not noticeably. The script:
- Runs for <0.1 seconds
- Checks every 5 seconds (12 times per minute)
- Uses minimal memory

### Can I reduce the check frequency?

Yes! Edit crontab and remove half the entries to check every 10 seconds instead of 5.

### Will it use a lot of disk space?

No. Log file auto-rotates at 100KB. Typical usage: 20-50KB for weeks of logs.

## Compatibility Questions

### Which Passwall cores are supported?

All major cores:
- ✅ xray
- ✅ sing-box
- ✅ hysteria
- ✅ v2ray
- ✅ trojan

### Does it work with Passwall2?

Should work! Passwall2 uses similar cores. Test and report back!

### What OpenWRT versions are supported?

Tested on:
- OpenWRT 24.10+
- OpenWRT 23.05

Should work on older versions too (22.03+) as it uses basic POSIX shell.

### Does it work on other firmware?

Should work on OpenWRT-based firmware:
- ✅ GL.iNet firmware
- ✅ Turris OS
- Possibly: DD-WRT, Tomato (untested)

## Advanced Questions

### Can I monitor other services?

Yes! Edit the script's process detection functions to add other service names. See [CONTRIBUTING.md](CONTRIBUTING.md).

### Can I send notifications?

Not built-in, but you can add to the `restart_passwall()` function:
```bash
# Example: Send to webhook
curl -X POST https://your-webhook-url \
  -d "Passwall restarted: CPU=$cpu% RAM=${ram}MB"
```

### Can I run this on multiple routers?

Yes! Each router runs independently. Just install on each one.

### How do I backup my configuration?

```bash
# Backup script with your custom settings
scp root@192.168.1.1:/root/passwall-monitor.sh ./my-router-config.sh

# Backup cron jobs
ssh root@192.168.1.1 'crontab -l' > my-cron.backup
```

### Can I monitor from a remote location?

The monitor runs locally on the router. For remote monitoring, you could:
1. Set up log forwarding to remote server
2. Add webhook notifications (see above)
3. Use OpenWRT's monitoring tools (vnStat, etc.)

## Uninstallation Questions

### How do I remove it?

```bash
# Quick method
wget -O - https://raw.githubusercontent.com/YounesRahimi/openwrt-passwall-monitor/main/uninstall.sh | sh

# Manual method
crontab -e  # Remove all passwall-monitor lines
rm /root/passwall-monitor.sh
rm /var/log/passwall_monitor.log
```

### Will uninstalling affect my Passwall?

No! Uninstalling only removes the monitoring. Passwall continues working normally.

### Can I reinstall later?

Yes! Just run the install script again.

## Support Questions

### Where can I get help?

1. Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Search [existing issues](https://github.com/YounesRahimi/openwrt-passwall-monitor/issues)
3. Create a new issue with details

### How do I report a bug?

Use the [Bug Report template](.github/ISSUE_TEMPLATE/bug_report.md) and include:
- Router model & specs
- Your configuration
- Logs
- Steps to reproduce

### Can I contribute?

Yes! See [CONTRIBUTING.md](CONTRIBUTING.md). We especially need:
- Testing on different routers
- Configuration examples
- Documentation improvements
- Translations

### Is there a Discord/Telegram group?

Not yet! Create a GitHub Discussion if interested in starting one.

---

## Still have questions?

- 💬 [GitHub Discussions](https://github.com/YounesRahimi/openwrt-passwall-monitor/discussions)
- 🐛 [Report an Issue](https://github.com/YounesRahimi/openwrt-passwall-monitor/issues/new/choose)
- 📖 [Read the Docs](docs/)
