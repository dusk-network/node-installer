# ITN Installer

This repository contains an easy to use installer to run a Dusk Network node for our ITN program.

## Prerequisites

- Ubuntu 22.10 x64
- OpenSSL 3

This installer is specifically built for Ubuntu 22.10 x64. It might work on older or new version.

## Packages

The installer comes with the following packages:
- Dusk node service
- Rusk VM service
- Rusk wallet CLI

## Folder layout 

The configuration files, binaries, services and scripts can be found in `/opt/dusk/`. 

The log files can be found in `/var/logs/{d,r}usk.{err,log}`.

## Installation

:information_source: To run the **latest release** of the ITN installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/itn-installer/releases/download/v0.0.3/itn-installer.sh | sudo sh
```

:warning: **CAUTION** To run the **not release yet** unstable version of the ITN installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/dusk-network/itn-installer/main/itn-installer.sh | sudo sh
```

## Configuration

The installer comes with sane defaults, only requiring minimal configuration. Before the Dusk and Rusk service can be started, the `CONSENSUS_KEYS` and `DUSK_CONSENSUS_KEYS_PASS` need to be provided. 

The `CONSENSUS_KEYS` can be either moved to `/opt/dusk/conf/` from another system or generated on the node itself and moved there. 

### Set consensus keys

To generate the provisioner keys locally, run `rusk-wallet` and either create a new wallet or use a recovery phrase. Access your wallet and export your provisioner key-pair. 

The `.keys` file will be appended with the wallet address you have selected. Move this file to the Dusk node configuration folder and rename it. Copy the following command, replace it with your key and execute:
```sh
mv /root/.dusk/rusk-wallet/5YgmFvL5WKVbff9LtNwaY5VU17w93CXEs9ujPVRnEkcDko6Fsiv9moNBG1B2qxSh6F2m4qqDGvBFMThSii431BzN.keys /opt/dusk/conf/consensus.keys
```

### Set consensus password

Run the following command and it will prompt you to enter the password for the consensus keys file:
```sh
read -p "Consensus keys password:" ckp && echo "DUSK_CONSENSUS_KEYS_PASS=$ckp" > /opt/dusk/services/dusk.conf
```

### Start services

Everything should be configured now and the nodes ready to run. Use the following commands:
```sh
service rusk start
service dusk start
```

Check the status of the services by running:
```sh
service rusk status
service dusk status
```

## Diagnostics

Check if your node is syncing, processing and accepting new blocks:
```sh
tail -F /var/log/dusk.log | grep "accept_block"
```
Or
```sh
tail -F /var/log/dusk.log | grep "Accepted"
```

Check if your node is participating in consensus and trying to create blocks:
```sh
tail -F /var/log/rusk.log | grep "ExecuteStateTransition"
```

Or to check if it did so in the past:
```sh
 grep ExecuteStateTransition /var/log/rusk.log
```

To check for errors in the Dusk and Rusk log:
```sh
cat /var/log/{d,r}usk.err
```
