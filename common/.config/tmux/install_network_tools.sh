#!/bin/bash

# Quick installer for network monitoring tools

echo "=== Network Monitoring Tools Setup ==="
echo "This will help you install tools to verify accuracy"
echo ""

# Detect package manager
if command -v apt &> /dev/null; then
    PKG_MGR="apt"
    INSTALL_CMD="sudo apt install -y"
elif command -v dnf &> /dev/null; then
    PKG_MGR="dnf"
    INSTALL_CMD="sudo dnf install -y"
elif command -v pacman &> /dev/null; then
    PKG_MGR="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
else
    echo "Unsupported package manager"
    exit 1
fi

echo "Detected: $PKG_MGR"
echo ""

# Essential tools
echo "1. Essential monitoring tools:"
echo "   - nload: Visual bandwidth monitor"
echo "   - bmon: Bandwidth monitor with graphs"
echo "   - iftop: Shows bandwidth usage per connection"
echo "   - vnstat: Network statistics"
echo ""

echo -n "Install essential tools? [y/N]: "
read response
if [[ "$response" =~ ^[Yy]$ ]]; then
    $INSTALL_CMD nload bmon iftop vnstat
fi

# Testing tools
echo ""
echo "2. Speed testing tools:"
echo "   - speedtest-cli: Command line speedtest"
echo "   - iperf3: Network performance testing"
echo "   - curl: For download tests"
echo ""

echo -n "Install testing tools? [y/N]: "
read response
if [[ "$response" =~ ^[Yy]$ ]]; then
    $INSTALL_CMD speedtest-cli iperf3 curl
fi

# Advanced tools
echo ""
echo "3. Advanced analysis tools:"
echo "   - nethogs: Per-process bandwidth usage"
echo "   - wondershaper: Bandwidth limiting (for testing)"
echo ""

echo -n "Install advanced tools? [y/N]: "
read response
if [[ "$response" =~ ^[Yy]$ ]]; then
    $INSTALL_CMD nethogs wondershaper
fi

echo ""
echo "=== Quick Usage Guide ==="
echo ""
echo "Compare with your tmux monitor using:"
echo "  nload              - Press Tab to switch interfaces"
echo "  bmon               - Real-time graphs"
echo "  sudo iftop         - Per-connection bandwidth"
echo "  vnstat -l          - Live traffic monitor"
echo "  sudo nethogs       - See which process uses bandwidth"
echo "  speedtest-cli      - Internet speed test"
echo "  iperf3 -c iperf.he.net  - Test to public server"
echo ""
echo "To limit bandwidth for testing accuracy:"
echo "  sudo wondershaper [interface] 1024 1024  # Limit to 1MB/s"
echo "  sudo wondershaper clear [interface]      # Remove limit"
