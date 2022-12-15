#!/bin/bash
echo "Consensus keys password: "
read ckp
echo "DUSK_CONSENSUS_KEYS_PASS=$ckp" > /opt/dusk/services/dusk.conf
