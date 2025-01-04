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

int2ip() { printf ${2+-v} $2 "%d.%d.%d.%d" \
    $(($1>>24)) $(($1>>16&255)) $(($1>>8&255)) $(($1&255)) ;}
ip2int() { local _a=(${1//./ }) ; printf ${2+-v} $2 "%u" \
    $(( _a<<24 | ${_a[1]} << 16 | ${_a[2]} << 8 | ${_a[3]} )) ;}

while IFS=$' :\t\r\n' read a b c d; do
    [ "$a" = "0.0.0.0" ] && [ "$c" = "$a" ] && iFace=${d##* } gWay=$b
done < <(/sbin/route -n 2>&1)
ip2int $gWay gw
local_ip="$($(which ip) -j -4 -br addr | jq -r ". | map(select(.ifname == \"$iFace\")) | .[].addr_info.[0].local")"
ip2int $local_ip ip
mask="$($(which ipcalc) -n -b $local_ip | grep Netmask | awk '{print $2}')"
ip2int $mask mask
(( ( ip & mask ) == ( gw & mask ) )) &&
    int2ip $ip myIp && int2ip $mask netMask

echo "KADCAST_PUBLIC_ADDRESS=$PUBLIC_IP:9000"
if [ -z "$myIp" ]; then
    echo "KADCAST_LISTEN_ADDRESS=$PUBLIC_IP:9000"
else
    echo "KADCAST_LISTEN_ADDRESS=$myIp:9000"
fi
