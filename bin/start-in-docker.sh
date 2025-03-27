#!/bin/bash

set -e

cd /opt/dusk

export RUST_BACKTRACE=full 
export RUSK_PROFILE_PATH=/opt/dusk/rusk
export RUSK_RECOVERY_INPUT=/opt/dusk/conf/genesis.toml

/opt/dusk/bin/rusk recovery state
if [ -z "$DUSK_CONSENSUS_KEYS_PASS" ]; then
    echo "DUSK_CONSENSUS_KEYS_PASS is not set"
    exit 1
fi

if [ ! -f /opt/dusk/conf/consensus.keys ]; then
    echo "Consensus keys file was not found. Mount it on /opt/dusk/conf/consensus.keys"
    exit 1
fi

detect_ips_output=$(/opt/dusk/bin/detect_ips_inner.sh)
export KADCAST_PUBLIC_ADDRESS=$(echo "$detect_ips_output" | sed -n '1p')
export KADCAST_LISTEN_ADDRESS=$(echo "$detect_ips_output" | sed -n '2p')

/opt/dusk/bin/rusk --config /opt/dusk/conf/rusk.toml
