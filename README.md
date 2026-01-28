# XMM7360 LTE Modem Daemon

Production-ready Python daemon for Intel XMM7360 LTE modems (Fibocom L850-GL) with NetworkManager integration.

## Features

✅ Automatic modem initialization and connection

✅ Systemd service integration 

✅ NetworkManager dispatcher support 

✅ Auto-reconnect on connection loss 

✅ Comprehensive logging 

✅ Configurable APN 

## Quick Start

### 1. Prerequisites

```bash
# Ensure kernel driver is loaded
sudo modprobe iosm

# Verify device exists
ls -la /dev/wwan0xmmrpc0
ls -la /sys/class/net/wwan0
```

### 2. Installation

```bash
# Make installer executable
chmod +x install-xmm7360-daemon.sh

# Run installer
sudo ./install-xmm7360-daemon.sh
```

### 3. Verify Connection

```bash
# Check daemon status
sudo systemctl status xmm7360

# Watch logs in real-time
sudo journalctl -u xmm7360 -f

# Check network interface
ip addr show wwan0

# Test connectivity
ping -I wwan0 8.8.8.8
```

## Architecture

```
┌─────────────────────────────────────┐
│      NetworkManager / nmcli         │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   NetworkManager Dispatcher         │
│   /etc/NetworkManager/dispatcher.d/ │
│   10-xmm7360                        │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   xmm7360.service (systemd)         │
│   /usr/local/bin/xmm7360-daemon.py  │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   RPC Protocol Handler              │
│   /dev/wwan0xmmrpc0                 │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│   Intel XMM7360 Modem Hardware      │
│   Network Interface: wwan0          │
└─────────────────────────────────────┘
```

## Configuration

### Change APN

```bash
# Edit service file
sudo nano /etc/systemd/system/xmm7360.service

# Modify ExecStart line:
ExecStart=/usr/local/bin/xmm7360-daemon.py --apn YOUR_APN_HERE

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart xmm7360
```

### Disable Auto-Reconnect

```bash
# Edit service file
sudo nano /etc/systemd/system/xmm7360.service

# Add --no-reconnect flag:
ExecStart=/usr/local/bin/xmm7360-daemon.py --apn web.vodafone.de --no-reconnect

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart xmm7360
```

### Enable Debug Logging

```bash
# Edit service file
sudo nano /etc/systemd/system/xmm7360.service

# Add --debug flag:
ExecStart=/usr/local/bin/xmm7360-daemon.py --apn web.vodafone.de --debug

# Reload and restart
sudo systemctl daemon-reload
sudo systemctl restart xmm7360
```

## Usage

### Manual Connection

```bash
# Start daemon
sudo systemctl start xmm7360

# Stop daemon
sudo systemctl stop xmm7360

# Restart daemon
sudo systemctl restart xmm7360

# View status
sudo systemctl status xmm7360
```

### Automatic Connection on Boot

```bash
# Enable auto-start
sudo systemctl enable xmm7360

# Disable auto-start
sudo systemctl disable xmm7360
```

### NetworkManager Integration

The daemon automatically integrates with NetworkManager:

```bash
# List connections
nmcli connection show

# Bring up wwan0
nmcli connection up wwan0

# Bring down wwan0
nmcli connection down wwan0
```

## Monitoring

### Live Logs

```bash
# Daemon logs (systemd journal)
sudo journalctl -u xmm7360 -f

# Daemon log file
sudo tail -f /var/log/xmm7360-daemon.log

# NetworkManager dispatcher logs
sudo tail -f /var/log/xmm7360-nm-dispatcher.log
```

### Connection Status

```bash
# Check interface status
ip addr show wwan0

# Check routing
ip route

# Test connectivity
ping -I wwan0 8.8.8.8

# Check DNS
nslookup google.com

# Speed test
speedtest-cli --source wwan0
```

### Modem Information

```bash
# Kernel driver info
dmesg | grep -i iosm

# Device info
udevadm info /sys/class/net/wwan0

# Interface statistics
ip -s link show wwan0
```

## Troubleshooting

### Daemon Won't Start

```bash
# Check device exists
ls -la /dev/wwan0xmmrpc0
# If not found: sudo modprobe iosm

# Check permissions
sudo -u nobody ls -la /dev/wwan0xmmrpc0
# Should be readable

# Check for conflicts
ps aux | grep xmm7360
# Kill any orphaned processes

# Try manual start
sudo /usr/local/bin/xmm7360-daemon.py --debug
```

### No IP Address

```bash
# Check daemon logs
sudo journalctl -u xmm7360 | grep "IP address"

# Manually request DHCP
sudo dhclient -v wwan0

# Check APN configuration
sudo journalctl -u xmm7360 | grep "APN"

# Verify modem initialization
sudo journalctl -u xmm7360 | grep "initialized"
```

### Connection Drops

```bash
# Check for errors in logs
sudo journalctl -u xmm7360 | grep -i error

# Monitor connection
watch -n 1 'ip addr show wwan0; ip route'

# Check signal quality (if available)
# TODO: Implement signal monitoring

# Increase restart delay
sudo nano /etc/systemd/system/xmm7360.service
# Change: RestartSec=30s
```

### Network Manager Conflicts

```bash
# Check NetworkManager status
systemctl status NetworkManager

# Restart NetworkManager
sudo systemctl restart NetworkManager

# Check dispatcher
ls -la /etc/NetworkManager/dispatcher.d/10-xmm7360

# Test dispatcher manually
sudo /etc/NetworkManager/dispatcher.d/10-xmm7360 wwan0 up
```

## Advanced

### Manual RPC Commands

```bash
# Run daemon in foreground with debug
sudo /usr/local/bin/xmm7360-daemon.py --debug

# Test individual RPC functions
sudo python3 -c "
from xmm7360_daemon import RPC
rpc = RPC('/dev/wwan0xmmrpc0')
rpc.open()
rpc.execute(0x30)  # UtaMsSmsInit
rpc.close()
"
```

### Integration with Other Tools

```bash
# Use with custom routing
sudo ip rule add from 192.168.1.0/24 lookup 100
sudo ip route add default dev wwan0 table 100

# Use specific DNS
sudo resolvectl dns wwan0 8.8.8.8 8.8.4.4

# Monitor traffic
sudo iftop -i wwan0
```

### Performance Tuning

```bash
# Increase interface MTU (if supported)
sudo ip link set wwan0 mtu 1500

# Enable TCP optimizations
sudo sysctl -w net.ipv4.tcp_congestion_control=bbr

# Monitor performance
iperf3 -c speedtest.example.com --bind wwan0
```

## Files

- `/usr/local/bin/xmm7360-daemon.py` - Main daemon
- `/etc/systemd/system/xmm7360.service` - Systemd service
- `/etc/NetworkManager/dispatcher.d/10-xmm7360` - NM dispatcher
- `/var/log/xmm7360-daemon.log` - Daemon log
- `/var/log/xmm7360-nm-dispatcher.log` - Dispatcher log

## Uninstallation

```bash
# Stop and disable service
sudo systemctl stop xmm7360
sudo systemctl disable xmm7360

# Remove files
sudo rm /usr/local/bin/xmm7360-daemon-full.py
sudo rm /etc/systemd/system/xmm7360.service
sudo rm /etc/NetworkManager/dispatcher.d/10-xmm7360
sudo rm /var/log/xmm7360-*.log

# Reload systemd
sudo systemctl daemon-reload

# Restart NetworkManager
sudo systemctl restart NetworkManager
```

## Known Limitations

- APN configuration uses simplified encoding (works for most APNs)
- No signal strength monitoring
- No SMS support
- IPv6 may require additional configuration
- No GUI integration (command-line only)

## Future Enhancements

- [ ] Signal strength monitoring
- [ ] SMS support
- [ ] GUI status indicator
- [ ] IPv6 support
- [ ] Connection quality metrics
- [ ] ModemManager integration via Plugin-API

## References

- [xmm7360-pci GitHub](https://github.com/xmm7360/xmm7360-pci)
- [iosm Kernel Driver](https://docs.kernel.org/networking/device_drivers/wwan/iosm.html)
- [NetworkManager Dispatcher](https://networkmanager.dev/docs/api/latest/NetworkManager-dispatcher.html)

## License

GPL v2+ (same as xmm7360-pci project)

## Credits

Based on the RPC implementation from the xmm7360-pci project.
Used Claude.AI for fast coding...

