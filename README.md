# XMM7360 LTE Modem Daemon

Production-ready Python daemon for Intel XMM7360 LTE modems (Fibocom L850-GL) with automatic network configuration.

## Features

✅ Complete RPC protocol implementation  
✅ Automatic modem initialization  
✅ APN configuration  
✅ Network attachment  
✅ **Automatic network interface configuration** (IP, routes, DNS)  
✅ Systemd service integration  
✅ Auto-reconnect on connection loss  
✅ Simple on/off toggle script  
✅ Comprehensive logging  

## Quick Start

### Prerequisites

```bash
# Ensure kernel driver is loaded
sudo modprobe iosm

# Verify device exists
ls -la /dev/wwan0xmmrpc0
ls -la /sys/class/net/wwan0
```

### Installation

```bash
# 1. Install daemon
sudo cp xmm7360-daemon-full.py /usr/local/bin/xmm7360-daemon.py
sudo chmod +x /usr/local/bin/xmm7360-daemon.py

# 2. Install systemd service
sudo cp xmm7360.service /etc/systemd/system/
sudo systemctl daemon-reload

# 3. Install toggle script
sudo cp lte /usr/local/bin/lte
sudo chmod +x /usr/local/bin/lte

# 4. Disable auto-start (manual control)
sudo systemctl disable xmm7360
```

### Usage

```bash
# Connect to LTE
lte on

# Disconnect
lte off

# Check status
lte status

# View logs
lte logs
```

## What Happens When You Connect

```
lte on
  ↓
1. Daemon starts via systemd
2. Opens RPC device (/dev/wwan0xmmrpc0)
3. Initializes modem (7 RPC calls)
4. Checks FCC lock (auto-unlock if needed)
5. Disables airplane mode
6. Configures APN (web.vodafone.de)
7. Attaches to network
8. Gets IP address from carrier
9. Sets up data channel (RPC)
10. Configures network interface:
    - Brings wwan0 up
    - Adds IP address (e.g., 100.82.245.185/32)
    - Adds default route (metric 100)
    - Configures DNS servers
  ↓
✓ Internet connection active!
```

## Architecture

```
lte on/off command
    ↓
systemctl start/stop xmm7360
    ↓
xmm7360-daemon.py
    ├── RPC Communication (/dev/wwan0xmmrpc0)
    │   ├── Modem initialization
    │   ├── APN configuration
    │   ├── Network attachment
    │   └── Data channel setup
    └── Network Configuration
        ├── ip link set wwan0 up
        ├── ip addr add IP/32 dev wwan0
        ├── ip route add default dev wwan0
        └── Configure DNS in /etc/resolv.conf
```

## Configuration

### Change APN

```bash
# Edit service file
sudo nano /etc/systemd/system/xmm7360.service

# Modify ExecStart line:
ExecStart=/usr/bin/python3 /usr/local/bin/xmm7360-daemon.py --apn YOUR_APN

# Reload and restart
sudo systemctl daemon-reload
lte restart
```

### Adjust Route Metric

Edit the daemon code and change line with:
```python
subprocess.run(['ip', 'route', 'add', 'default', 'dev', 'wwan0', 'metric', '100'], check=True)
```

Change `'100'` to your preferred metric (higher = lower priority).

## Monitoring

### Live Logs

```bash
# Via lte script
lte logs

# Or directly
sudo journalctl -u xmm7360 -f

# Log file
sudo tail -f /var/log/xmm7360-daemon.log
```

### Connection Status

```bash
# Quick status
lte status

# Detailed interface info
ip addr show wwan0

# Routing table
ip route

# DNS configuration
cat /etc/resolv.conf | grep xmm7360

# Test connectivity
ping -c 4 8.8.8.8
curl https://ifconfig.me
```

## Troubleshooting

### Daemon Won't Start

```bash
# Check if device exists
ls -la /dev/wwan0xmmrpc0

# If not found, load driver
sudo modprobe iosm

# Check service status
sudo systemctl status xmm7360

# View errors
sudo journalctl -u xmm7360 -n 50
```

### No IP Address

```bash
# Check daemon logs for IP assignment
sudo journalctl -u xmm7360 | grep "IP address:"

# Manually verify interface
ip addr show wwan0

# If wwan0 has no IP, check if daemon completed successfully
lte logs | grep "Network interface configured"
```

### No Internet Access

```bash
# Check if interface is up
ip link show wwan0

# Check routing
ip route | grep wwan0

# Test DNS
nslookup google.com

# Check DNS configuration
cat /etc/resolv.conf | grep -A 2 "xmm7360"

# Ping test
ping -I wwan0 8.8.8.8
```

### Connection Drops

```bash
# Check logs for errors
lte logs | grep -i error

# Auto-reconnect is enabled by default
# Connection should restore automatically within 10 seconds

# Manual restart
lte restart
```

## Advanced Usage

### Manual Connection (Debug Mode)

```bash
# Run daemon in foreground with debug output
sudo systemctl stop xmm7360
sudo /usr/local/bin/xmm7360-daemon.py --debug

# Watch what happens during connection
# Ctrl+C to stop
```

### Disable Auto-Reconnect

```bash
# Edit service file
sudo nano /etc/systemd/system/xmm7360.service

# Add --no-reconnect flag
ExecStart=/usr/bin/python3 /usr/local/bin/xmm7360-daemon.py --apn web.vodafone.de --no-reconnect

# Reload
sudo systemctl daemon-reload
```

### Custom DNS Servers

The daemon automatically uses DNS servers provided by the carrier. To override:

```bash
# After connection, manually set DNS
sudo nano /etc/resolv.conf

# Replace xmm7360 entries with:
nameserver 8.8.8.8
nameserver 8.8.4.4
```

Or modify the daemon code to use specific DNS servers.

### Integration with VPN

LTE connection works alongside VPN. Example with OpenVPN:

```bash
# Connect LTE first
lte on

# Then connect VPN
sudo openvpn --config myvpn.ovpn

# VPN traffic will route through LTE if it has lower metric
```

## Comparison with Other Solutions

### vs. ModemManager

| Feature | This Daemon | ModemManager |
|---------|-------------|--------------|
| XMM7360 Support | ✅ Full RPC | ❌ No RPC support |
| Setup Complexity | 🟢 Simple | 🔴 Complex plugin needed |
| Control | ✅ Direct (lte on/off) | 🟡 Via nmcli |
| Auto-start | ❌ Manual only | ✅ Automatic |
| Dependencies | 🟢 Python only | 🟡 Full MM stack |

### vs. open_xdatachannel.py (original)

| Feature | This Daemon | Original Script |
|---------|-------------|-----------------|
| Network Config | ✅ Automatic | ⚠️ Manual (pyroute2) |
| Systemd | ✅ Yes | ❌ No |
| Auto-reconnect | ✅ Yes | ❌ No |
| Easy control | ✅ lte on/off | ❌ Need to run manually |
| Logging | ✅ Full | 🟡 Basic |

## Files

- `/usr/local/bin/xmm7360-daemon.py` - Main daemon (770 lines)
- `/usr/local/bin/lte` - Toggle script
- `/etc/systemd/system/xmm7360.service` - Systemd service
- `/var/log/xmm7360-daemon.log` - Log file

## Uninstallation

```bash
# Stop and disable service
lte off
sudo systemctl disable xmm7360

# Remove files
sudo rm /usr/local/bin/xmm7360-daemon.py
sudo rm /usr/local/bin/lte
sudo rm /etc/systemd/system/xmm7360.service
sudo rm /var/log/xmm7360-daemon.log

# Clean up DNS
sudo nano /etc/resolv.conf
# Remove lines with "# Added by xmm7360"

# Reload systemd
sudo systemctl daemon-reload
```

## Technical Details

### RPC Protocol

Based on the xmm7360-pci project's RPC implementation. The daemon implements:

- ASN.1 encoding/decoding
- RPC message framing
- Synchronous and asynchronous RPC calls
- Unsolicited message handling

Key RPC functions used:
- `UtaMsSmsInit` (0x30) - SMS initialization
- `UtaMsNetOpen` (0x53) - Network subsystem
- `UtaMsNetAttachReq` (0x5C) - Network registration
- `UtaMsCallPsAttachApnConfigReq` (0x1AF) - APN configuration
- `UtaMsCallPsConnectReq` (0x51) - Data connection
- `UtaRPCPSConnectSetupReq` (0x7D) - Data channel setup

### Network Configuration

The daemon configures the network interface using standard `ip` commands:

```python
subprocess.run(['ip', 'link', 'set', 'wwan0', 'up'])
subprocess.run(['ip', 'addr', 'add', f'{ip_address}/32', 'dev', 'wwan0'])
subprocess.run(['ip', 'route', 'add', 'default', 'dev', 'wwan0', 'metric', '100'])
```

DNS is configured by modifying `/etc/resolv.conf` with markers for cleanup.

### FCC Unlock

The daemon automatically performs FCC unlock if required using the challenge-response mechanism with the hardware-specific key.

## Known Limitations

- Requires root privileges (for network configuration)
- No GUI integration (command-line only)
- No signal strength monitoring
- No SMS support
- IPv6 configuration is automatic (SLAAC) but not explicitly managed
- Single APN configuration (no multi-profile support)

## Future Enhancements

- [ ] Signal strength monitoring via RPC
- [ ] SMS send/receive support
- [ ] GUI status indicator (system tray)
- [ ] Multiple APN profiles
- [ ] Automatic carrier detection
- [ ] Network quality metrics
- [ ] ModemManager plugin (long-term goal)

## Credits

Based on the RPC implementation from:
- [xmm7360-pci project](https://github.com/xmm7360/xmm7360-pci)

Network configuration inspired by:
- Original `open_xdatachannel.py` script

## License

GPL v2+ (same as xmm7360-pci project)

## Support

For issues or questions:
1. Check logs: `lte logs`
2. Run in debug mode: `sudo /usr/local/bin/xmm7360-daemon.py --debug`
3. Check kernel driver: `dmesg | grep -i iosm`
4. Verify device: `ls -la /dev/wwan0xmmrpc0`

## Changelog

### v2.0 (Current)
- ✅ Automatic network interface configuration
- ✅ DNS management in /etc/resolv.conf
- ✅ Cleanup on disconnect
- ✅ Simple lte on/off toggle script

### v1.0
- Initial release with RPC implementation
- Manual network configuration required
