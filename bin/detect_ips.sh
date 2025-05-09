#!/bin/bash
set -euo pipefail

# Fetch IPv4 WAN address using ifconfig.me, fallback to ipinfo.io
PUBLIC_IP=$(curl -4 -s https://ifconfig.me || curl -4 -s https://ipinfo.io/ip || true)

# Validate IPv4 address
if [[ ! "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Unable to retrieve a valid WAN IPv4 address" >&2
    exit 1
fi

# Detect the local IP via route table (for machines behind NAT or in internal networks)
# We query 1.1.1.1 here to get the primary outbound interface
LOCAL_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')

# Validate Local IPv4 address
if [[ ! "$LOCAL_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Unable to retrieve a valid local IPv4 address" >&2
    exit 1
fi

# Output the KADCAST addresses
echo "KADCAST_PUBLIC_ADDRESS=${PUBLIC_IP}:9000"
echo "KADCAST_LISTEN_ADDRESS=${LOCAL_IP}:9000"
