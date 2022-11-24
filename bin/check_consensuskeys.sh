#!/bin/bash

CONSENSUS_KEYS=`grep keysfile /opt/dusk/conf/dusk.toml | sed 's|.* "||g' | sed 's|"||g'`
if test -f "$CONSENSUS_KEYS"; then
    echo "Using CONSENSUS_KEYS in $CONSENSUS_KEYS"
else 
    echo "CONSENSUS_KEYS file not found in $CONSENSUS_KEYS"
    exit 1
fi

if test -f "/opt/dusk/services/dusk.conf"; then
    exit 0
else 
    echo "CONSENSUS_KEYS password not found"
    exit 1
fi
