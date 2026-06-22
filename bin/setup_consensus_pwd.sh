#!/bin/sh
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Run this command as root, for example: sudo sh /opt/dusk/bin/setup_consensus_pwd.sh" 1>&2
    exit 1
fi

printf "Consensus keys password: "
IFS= read -r ckp

install -o root -g root -m 600 /dev/null /opt/dusk/services/dusk.conf
escaped_ckp=$(printf "%s" "$ckp" | sed "s/'/'\\\\''/g")
printf "DUSK_CONSENSUS_KEYS_PASS='%s'\n" "$escaped_ckp" > /opt/dusk/services/dusk.conf
