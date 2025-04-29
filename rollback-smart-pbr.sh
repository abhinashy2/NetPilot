#!/bin/bash

# Rollback Script: Revert Smart Policy-Based Routing Setup
# Author: ChatGPT
# Date: 2025-04-29

set -e

TAILSCALE_SUBNET="100.64.0.0/10"
LAN_SUBNET="192.168.0.0/16"
TAILSCALE_TABLE=100
LAN_TABLE=200

echo "=== Rolling back Policy-Based Routing configuration ==="

# Remove IP rules (if exist)
echo "--- Removing IP rules"
sudo ip rule del to $TAILSCALE_SUBNET lookup tailscale 2>/dev/null || true
sudo ip rule del to $LAN_SUBNET lookup lan 2>/dev/null || true

# Remove routes (if exist)
echo "--- Removing routes from custom tables"
sudo ip route flush table tailscale 2>/dev/null || true
sudo ip route flush table lan 2>/dev/null || true

# Optional: Remove custom routing tables from rt_tables
echo "--- Cleaning up /etc/iproute2/rt_tables entries (optional)"
sudo sed -i '/^100 tailscale$/d' /etc/iproute2/rt_tables
sudo sed -i '/^200 lan$/d' /etc/iproute2/rt_tables

# Remove persistent route script
echo "--- Removing /etc/network/if-up.d/custom-routes"
sudo rm -f /etc/network/if-up.d/custom-routes

echo "=== Rollback complete. System is back to original network state. ✅"
