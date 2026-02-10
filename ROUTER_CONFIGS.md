# Configuration Examples

This directory contains tested configurations for various router models.

## How to Use These Examples

1. Find your router model below
2. Copy the recommended threshold values
3. Edit `/root/passwall-monitor.sh` on your router
4. Replace the default values with the recommended ones
5. Restart the monitor (it will use new values on next run)

---

## ASUS RT-AX59U (Default)

**Specs:**
- CPU: MediaTek MT7986A, ARMv8, 4 cores @ 2.0 GHz
- RAM: 512 MB
- OpenWRT: 24.10+

**Configuration:**
```bash
CPU_THRESHOLD=100        # One full core
RAM_THRESHOLD_MB=80      # ~15% of available RAM
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Tested by:** Original author  
**Status:** ✅ Tested and working

---

## Xiaomi Mi Router 3G / 4A Gigabit

**Specs:**
- CPU: MediaTek MT7621, MIPS, 2 cores @ 880 MHz
- RAM: 128 MB
- OpenWRT: 23.05+

**Configuration:**
```bash
CPU_THRESHOLD=75         # Higher % due to fewer cores
RAM_THRESHOLD_MB=30      # Much lower due to limited RAM
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=20   # Slightly longer to avoid false positives
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## GL.iNet GL-AX1800

**Specs:**
- CPU: MediaTek MT7981B, ARMv8, 2 cores @ 1.3 GHz  
- RAM: 256 MB
- OpenWRT: GL.iNet firmware (based on OpenWRT)

**Configuration:**
```bash
CPU_THRESHOLD=75         # One core = 50%, set higher for safety
RAM_THRESHOLD_MB=50      # ~20% of available RAM
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## Netgear R7800

**Specs:**
- CPU: Qualcomm IPQ8065, ARMv7, 2 cores @ 1.7 GHz
- RAM: 512 MB
- OpenWRT: 23.05+

**Configuration:**
```bash
CPU_THRESHOLD=75         # Higher for dual-core
RAM_THRESHOLD_MB=80      # Similar to RT-AX59U
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## Linksys WRT3200ACM

**Specs:**
- CPU: Marvell 88F6820, ARMv7, 2 cores @ 1.3 GHz
- RAM: 512 MB
- OpenWRT: 23.05+

**Configuration:**
```bash
CPU_THRESHOLD=75
RAM_THRESHOLD_MB=80
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## Raspberry Pi 4 (as router)

**Specs:**
- CPU: Broadcom BCM2711, ARMv8, 4 cores @ 1.5 GHz
- RAM: 1 GB / 2 GB / 4 GB / 8 GB
- OpenWRT: 23.05+

**Configuration (for 1GB model):**
```bash
CPU_THRESHOLD=100        # One full core
RAM_THRESHOLD_MB=150     # More generous due to more RAM
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Configuration (for 4GB+ model):**
```bash
CPU_THRESHOLD=100
RAM_THRESHOLD_MB=200     # Even more generous
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## TP-Link Archer C7 v2/v5

**Specs:**
- CPU: Qualcomm Atheros QCA9558, MIPS, 1 core @ 720 MHz
- RAM: 128 MB
- OpenWRT: 23.05+

**Configuration:**
```bash
CPU_THRESHOLD=80         # Single core, set conservatively
RAM_THRESHOLD_MB=30      # Limited RAM
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=20   # Longer duration
RESTART_COOLDOWN=300
```

**Tested by:** Community contribution needed  
**Status:** ⚠️ Needs testing

---

## How to Calculate Thresholds for Your Router

### CPU Threshold

**Formula:**
```
CPU_THRESHOLD = (100% ÷ number_of_cores) × safety_factor

Where safety_factor is typically 1.0 to 1.5
```

**Examples:**
- 4 cores: 100% ÷ 4 × 1.0 = 25% (but we use 100% as one full core is concerning)
- 2 cores: 100% ÷ 2 × 1.0 = 50% (use 75% with safety margin)
- 1 core: 100% × 0.8 = 80% (leave some headroom)

### RAM Threshold

**Formula:**
```
Available_RAM = Total_RAM - OS_overhead
OS_overhead ≈ 100-150 MB (depends on OpenWRT version)

RAM_THRESHOLD_MB = Available_RAM × 15-20%
```

**Examples:**
- 512 MB total: (512 - 140) × 20% ≈ 75 MB → use 80 MB
- 256 MB total: (256 - 120) × 20% ≈ 27 MB → use 30 MB
- 128 MB total: (128 - 100) × 20% ≈ 6 MB → use 25-30 MB (critical!)
- 1024 MB total: (1024 - 140) × 15% ≈ 132 MB → use 150 MB

---

## Contributing Your Configuration

If you've tested this on your router, please contribute!

**Create an issue or PR with:**
1. Router model and exact specs
2. Your working configuration
3. How long you've been running it
4. Any observations (restart frequency, issues, etc.)

**Template:**
```markdown
## Router Model: YOUR_ROUTER_MODEL

**Specs:**
- CPU: [model, architecture, cores, speed]
- RAM: [size]
- OpenWRT: [version]

**Configuration:**
```bash
CPU_THRESHOLD=XX
RAM_THRESHOLD_MB=XX
CHECK_INTERVAL=5
HIGH_USAGE_DURATION=15
RESTART_COOLDOWN=300
```

**Testing Notes:**
- Duration tested: X days/weeks
- Restart frequency: Once every X hours/days (or never)
- Issues: None / [describe]
- Special notes: [anything unusual]

**Tested by:** [GitHub username]
**Status:** ✅ Tested and working
```

Your contribution helps others with the same router! 🙏
