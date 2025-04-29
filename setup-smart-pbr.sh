#!/bin/bash

# Smart Policy-Based Routing Setup for Raspberry Pi Kuwait (Pi Q8)
# Maintains Tailscale + LAN access when full tunnel VPN is active (e.g., WireGuard)
# Author: ChatGPT
# Date: 2025-04-29

set -e

echo "=== Starting Smart Policy-Based Routing Setup ==="

TAILSCALE_SUBNET="100.64.0.0/10"
LAN_SUBNET="192.168.0.0/16"
TAILSCALE_TABLE=100
LAN_TABLE=200

# Add routing tables if missing
echo "--- Ensuring custom routing tables are registered"
grep -q "^$TAILSCALE_TABLE tailscale" /etc/iproute2/rt_tables || echo "$TAILSCALE_TABLE tailscale" | sudo tee -a /etc/iproute2/rt_tables
grep -q "^$LAN_TABLE lan" /etc/iproute2/rt_tables || echo "$LAN_TABLE lan" | sudo tee -a /etc/iproute2/rt_tables

# Detect interfaces
TAILSCALE_IFACE=$(ip -o link show | grep tailscale | awk -F': ' '{print $2}' | head -n1)
LAN_IFACE=$(ip route | grep default | awk '{print $5}' | head -n1)

if [[ -z "$TAILSCALE_IFACE" || -z "$LAN_IFACE" ]]; then
  echo "!! ERROR: Unable to detect tailscale0 or LAN interface."
  exit 1
fi

echo "--- Detected Tailscale interface: $TAILSCALE_IFACE"
echo "--- Detected LAN interface: $LAN_IFACE"

# Apply IP rules only if not already applied
echo "--- Applying ip rules if missing"
sudo ip rule list | grep -q "$TAILSCALE_SUBNET" || sudo ip rule add to $TAILSCALE_SUBNET lookup tailscale
sudo ip rule list | grep -q "$LAN_SUBNET" || sudo ip rule add to $LAN_SUBNET lookup lan

# Apply routes to custom tables
echo "--- Adding routes to custom routing tables"
sudo ip route show table tailscale | grep -q "$TAILSCALE_SUBNET" || sudo ip route add $TAILSCALE_SUBNET dev $TAILSCALE_IFACE table tailscale
sudo ip route show table lan | grep -q "$LAN_SUBNET" || sudo ip route add $LAN_SUBNET dev $LAN_IFACE table lan

# Create boot-time persistence script
echo "--- Creating persistent route script at /etc/network/if-up.d/custom-routes"
sudo tee /etc/network/if-up.d/custom-routes > /dev/null <<EOF
#!/bin/sh
# Persistent route setup script

ip rule add to $TAILSCALE_SUBNET lookup tailscale 2>/dev/null
ip rule add to $LAN_SUBNET lookup lan 2>/dev/null
ip route add $TAILSCALE_SUBNET dev $TAILSCALE_IFACE table tailscale 2>/dev/null
ip route add $LAN_SUBNET dev $LAN_IFACE table lan 2>/dev/null
EOF

sudo chmod +x /etc/network/if-up.d/custom-routes

echo "=== Smart Policy-Based Routing Setup Complete! ✅"
