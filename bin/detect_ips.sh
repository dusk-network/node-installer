#!/bin/bash

PUBLIC_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
## Fallback to a different dns provider
if [ -z "$PUBLIC_IP" ]; then
    PUBLIC_IP=`dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | sed 's|"||g'`
fi

int2ip() { printf ${2+-v} $2 "%d.%d.%d.%d" \
        $(($1>>24)) $(($1>>16&255)) $(($1>>8&255)) $(($1&255)) ;}
ip2int() { local _a=(${1//./ }) ; printf ${2+-v} $2 "%u" $(( _a<<24 |
                  ${_a[1]} << 16 | ${_a[2]} << 8 | ${_a[3]} )) ;}

case "$(uname -s)" in
    Darwin*)  runOnMac=true  ;;
    *)        runOnMac=false ;;
esac

if $runOnMac; then
    while IFS=$' :\t\r\n' read a b c d; do
        case $a in
            gateway )    gWay=$b  ;;
            interface )  iFace=$b ;;
        esac
    done < <(/sbin/route -n get 0.0.0.0/0)
    ip2int $gWay gw

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
else
    while IFS=$' :\t\r\n' read a b c d e rest; do
        gWay=$c
        iFace=$e
    done < <(ip -4 -c=never route show default)
    ip2int $gWay gw

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
fi

echo "KADCAST_PUBLIC_ADDRESS=$PUBLIC_IP:9000"
if [ -z "$myIp" ]; then
    echo "KADCAST_LISTEN_ADDRESS=$PUBLIC_IP:9000"
else
    echo "KADCAST_LISTEN_ADDRESS=$myIp:9000"
fi

