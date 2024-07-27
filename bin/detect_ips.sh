#!/bin/bash

PUBLIC_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
## Fallback to a different dns provider
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=`dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's|"||g'`
fi

runOnMac=false
int2ip() { printf ${2+-v} $2 "%d.%d.%d.%d" \
        $(($1>>24)) $(($1>>16&255)) $(($1>>8&255)) $(($1&255)) ;}
ip2int() { local _a=(${1//./ }) ; printf ${2+-v} $2 "%u" $(( _a<<24 |
                  ${_a[1]} << 16 | ${_a[2]} << 8 | ${_a[3]} )) ;}

get_ip() {
    while IFS=$' :\t\r\n' read iface state rhs; do
        [ "$iface" = "$iFace" ] && {
            ip2int "$(echo $rhs | cut -d '/' -f1)" ip
            while IFS=$' :\t\r\n' read before netmask after; do
                mask=$netmask
            done < <(/usr/bin/ipcalc -n -b $rhs | grep Netmask)
            ip2int $mask mask
            (( ( ip & mask ) == ( gw & mask ) )) &&
                int2ip $ip myIp && int2ip $mask netMask
        }
    done < <(ip -4 -br addr)
}

get_ip_macos() {
    while read lhs rhs; do
        [ "$lhs" ] && {
            [ -z "${lhs#*:}" ] && iface=${lhs%:}
            [ "$lhs" = "inet" ] && [ "$iface" = "$iFace" ] && {
                mask=${rhs#*netmask }
                mask=${mask%% *}
                [ "$mask" ] && [ -z "${mask%0x*}" ] &&
                    printf -v mask %u $mask ||
                    ip2int $mask mask
                ip2int ${rhs%% *} ip
                (( ( ip & mask ) == ( gw & mask ) )) &&
                    int2ip $ip myIp && int2ip $mask netMask
            }
        }
    done < <(/sbin/ifconfig)
}

while IFS=$' :\t\r\n' read a b c d; do
    [ "$a" = "usage" ] && [ "$b" = "route" ] && runOnMac=true
    if $runOnMac; then
        case $a in
            gateway )    gWay=$b  ;;
            interface )  iFace=$b ;;
        esac
    else
        [ "$a" = "0.0.0.0" ] && [ "$c" = "$a" ] && iFace=${d##* } gWay=$b
    fi
done < <(/sbin/route -n 2>&1 || /sbin/route -n get 0.0.0.0/0)
ip2int $gWay gw
[ $runOnMac ] && get_ip_macos || get_ip

echo "KADCAST_PUBLIC_ADDRESS=$PUBLIC_IP:9000"
if [ -z "$myIp" ]; then
    echo "KADCAST_LISTEN_ADDRESS=$PUBLIC_IP:9000"
else
    echo "KADCAST_LISTEN_ADDRESS=$myIp:9000"
fi

