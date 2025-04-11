#!/bin/bash

detect_ips_output=$(/opt/dusk/bin/detect_ips_inner.sh)
PUBLIC_IP=$(echo "$detect_ips_output" | sed -n '1p')
LISTEN_IP=$(echo "$detect_ips_output" | sed -n '2p')

echo "KADCAST_PUBLIC_ADDRESS=$PUBLIC_IP"
echo "KADCAST_LISTEN_ADDRESS=$LISTEN_IP"
