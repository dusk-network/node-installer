Dusk node installed
-----
Prerequisites for launching:
1. Provide CONSENSUS_KEYS file (default in /opt/dusk/conf/consensus.keys)
Run the following commands:
rusk-wallet restore
rusk-wallet export -d /opt/dusk/conf -n consensus.keys

2. Set DUSK_CONSENSUS_KEYS_PASS (use /opt/dusk/bin/setup_consensus_pwd.sh)
Run the following command:
sh /opt/dusk/bin/setup_consensus_pwd.sh

-----
To launch the node: 
service rusk start

To run the Rusk wallet:
rusk-wallet

To check the logs:
tail -F /var/log/rusk.log

The installer also adds a small Rusk querying utility called ruskquery.
To see what you can query with it:
ruskquery

To query the node for the latest block height:
ruskquery block-height

To check if your node installer is up to date:
ruskquery version

To reset your Rusk state and wallet cache:
ruskreset
