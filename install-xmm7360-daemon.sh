#!/bin/bash
# XMM7360 Daemon Installation Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== XMM7360 Daemon Installer ===${NC}\n"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (sudo)${NC}"
    exit 1
fi

# Check for required files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REQUIRED_FILES=(
    "xmm7360-daemon-full.py"
    "xmm7360.service"
    "10-xmm7360"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${RED}Error: Missing file: $file${NC}"
        exit 1
    fi
done

echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

# Check for device
if [ ! -e "/dev/wwan0xmmrpc0" ]; then
    echo -e "${RED}Error: /dev/wwan0xmmrpc0 not found!${NC}"
    echo "Please load the xmm7360 kernel driver first:"
    echo "  sudo modprobe iosm"
    exit 1
fi
echo "✓ XMM7360 device found"

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 not installed${NC}"
    exit 1
fi
echo "✓ Python 3 found"

echo -e "\n${YELLOW}[2/6] Installing daemon...${NC}"

# Install daemon script
install -m 755 "$SCRIPT_DIR/xmm7360-daemon-full.py" /usr/local/bin/xmm7360-daemon-full.py
echo "✓ Installed to /usr/local/bin/xmm7360-daemon.full.py"

echo -e "\n${YELLOW}[3/6] Installing systemd service...${NC}"

# Install service file
install -m 644 "$SCRIPT_DIR/xmm7360.service" /etc/systemd/system/xmm7360.service
systemctl daemon-reload
echo "✓ Installed to /etc/systemd/system/xmm7360.service"

echo -e "\n${YELLOW}[4/6] Installing NetworkManager dispatcher...${NC}"

# Install dispatcher script
mkdir -p /etc/NetworkManager/dispatcher.d
install -m 755 "$SCRIPT_DIR/10-xmm7360" /etc/NetworkManager/dispatcher.d/10-xmm7360
echo "✓ Installed to /etc/NetworkManager/dispatcher.d/10-xmm7360"

# Create log file
touch /var/log/xmm7360-daemon.log
chmod 644 /var/log/xmm7360-daemon.log
touch /var/log/xmm7360-nm-dispatcher.log
chmod 644 /var/log/xmm7360-nm-dispatcher.log
echo "✓ Created log files"

echo -e "\n${YELLOW}[5/6] Configuring services...${NC}"

# Enable service
systemctl enable xmm7360.service
echo "✓ Service enabled"

# Restart NetworkManager
systemctl restart NetworkManager
echo "✓ NetworkManager restarted"

echo -e "\n${YELLOW}[6/6] Starting daemon...${NC}"

# Start service
systemctl start xmm7360.service

# Wait a moment
sleep 3

# Check status
if systemctl is-active --quiet xmm7360.service; then
    echo -e "${GREEN}✓ Daemon started successfully${NC}"
else
    echo -e "${YELLOW}⚠ Daemon may still be connecting...${NC}"
fi

echo -e "\n${GREEN}=== Installation Complete! ===${NC}\n"

echo "Status commands:"
echo "  sudo systemctl status xmm7360       # Check daemon status"
echo "  sudo journalctl -u xmm7360 -f       # Live logs"
echo "  sudo tail -f /var/log/xmm7360-daemon.log  # Daemon log"
echo "  ip addr show wwan0                  # Check interface"
echo "  ip route                            # Check routing"
echo ""
echo "Control commands:"
echo "  sudo systemctl start xmm7360        # Start"
echo "  sudo systemctl stop xmm7360         # Stop"
echo "  sudo systemctl restart xmm7360      # Restart"
echo "  sudo systemctl disable xmm7360      # Disable auto-start"
echo ""
echo "Customize APN:"
echo "  sudo nano /etc/systemd/system/xmm7360.service"
echo "  # Change: --apn web.vodafone.de"
echo "  sudo systemctl daemon-reload"
echo "  sudo systemctl restart xmm7360"
echo ""
echo -e "${GREEN}Installation successful!${NC}"
