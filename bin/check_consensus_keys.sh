#!/bin/bash

CONSENSUS_KEYS=`grep consensus_keys_path /opt/dusk/conf/rusk.toml | sed -n "s/^[^=]*= *'\([^']*\)'/\1/p"`
if ! test -f "$CONSENSUS_KEYS"; then
    echo "CONSENSUS_KEYS file not found in $CONSENSUS_KEYS" 1>&2
    exit 1
fi

if ! test -f "/opt/dusk/services/dusk.conf"; then
    echo "CONSENSUS_KEYS password not set" 1>&2
    exit 1
fi
