# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-02-11

### Added
- **Network Connectivity Monitoring**: Automatically tests internet access when VPN processes are active
- HTTP connectivity check via `https://www.google.com/generate_204`
- Configurable connectivity failure duration (default: 60 seconds)
- Support for both curl and wget as fallback
- Optional connectivity monitoring (can be disabled via `ENABLE_CONNECTIVITY_CHECK=0`)
- Customizable test endpoints and timeouts

### Enhanced
- Updated restart function to handle both CPU and connectivity restart reasons
- Improved logging with detailed restart reasons
- Enhanced documentation with connectivity monitoring examples
- Added troubleshooting section for connectivity issues

### Configuration
- `ENABLE_CONNECTIVITY_CHECK`: Enable/disable connectivity monitoring (default: 1)
- `CONNECTIVITY_TIMEOUT`: Timeout for connectivity tests (default: 10 seconds)
- `CONNECTIVITY_FAILURE_DURATION`: Time to wait before restart (default: 60 seconds)  
- `CONNECTIVITY_URL`: Test endpoint (default: Google's generate_204)

## [1.0.0] - 2026-02-10

### Added
- Initial release
- CPU usage monitoring with configurable threshold
- RAM usage monitoring with configurable threshold
- Automatic Passwall restart when thresholds exceeded
- False positive prevention (requires sustained high usage)
- Restart cooldown protection (5-minute default)
- Automatic log rotation at 100KB
- Support for multiple Passwall cores (xray, sing-box, hysteria, v2ray, trojan)
- Detailed event logging
- Auto-tuned defaults for ASUS RT-AX59U (4-core, 512MB RAM)
- Configurable enable/disable for CPU and RAM checks
- State persistence across cron executions
- Comprehensive README with installation guide
- MIT License

### Configuration Defaults
- CPU Threshold: 100% (one full core)
- RAM Threshold: 80MB
- Check Interval: 5 seconds
- High Usage Duration: 15 seconds
- Restart Cooldown: 300 seconds (5 minutes)
- Max Log Size: 100KB

### Supported Routers
- Optimized for ASUS RT-AX59U
- Compatible with any OpenWRT router (with threshold adjustment)

[1.1.0]: https://github.com/YounesRahimi/openwrt-passwall-monitor/releases/tag/v1.1.0
[1.0.0]: https://github.com/YounesRahimi/openwrt-passwall-monitor/releases/tag/v1.0.0
