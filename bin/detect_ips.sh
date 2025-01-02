#!/bin/bash

# Fetch IPv4 WAN address using ifconfig.me, fallback to ipinfo.io
PUBLIC_IP=$(curl -4 -s https://ifconfig.me)
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=$(curl -4 -s https://ipinfo.io/ip)
fi

# Validate IPv4 address
if [[ -z "$PUBLIC_IP" || ! "$PUBLIC_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Unable to retrieve a valid WAN IPv4 address"
    exit 1
fi

# Detect the local IP (for machines behind NAT or in internal networks)
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Validate Local IPv4 address
if [[ -z "$LOCAL_IP" || ! "$LOCAL_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Unable to retrieve a valid local IPv4 address"
    exit 1
fi

# Set the KADCAST addresses conditionally
echo "KADCAST_PUBLIC_ADDRESS=${PUBLIC_IP}:9000"
if [ -z "$LOCAL_IP" ]; then
    echo "KADCAST_LISTEN_ADDRESS=$PUBLIC_IP:9000"
else
    echo "KADCAST_LISTEN_ADDRESS=$LOCAL_IP:9000"
fi