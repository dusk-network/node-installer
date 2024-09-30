# Node Installer

This repository contains an easy to use installer to run a Dusk node for our Nocturne testnet and our Lunare devnet. For more information on how to participate, see the [node running guide](https://docs.dusk.network/nocturne/node-running-guide/) on our wiki.

## Prerequisites

- Ubuntu 22.04 LTS x64
- OpenSSL 3

This installer is specifically built for Ubuntu 22.04 x64. It might work on older or newer versions.

## Packages

The installer comes with the following packages:
- [Rusk](https://github.com/dusk-network/rusk) service
- [Rusk wallet CLI](https://github.com/dusk-network/rusk/tree/master/rusk-wallet/src/bin)

## Folder layout 

The configuration files, binaries, services and scripts can be found in `/opt/dusk/`. 

The log files can be found in `/var/log/rusk.log` and `/var/log/rusk-recovery.log`.

## Installation

:information_source: To run the **latest release** of the Node Installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.2.0/node-installer.sh | sudo sh
```

By default, the installer runs the node for our Nocturne testnet. If you'd like to run a node for the Lunare devnet or mainnet, you can pass `devnet` or `mainnet` as an option during installation:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.2.0/node-installer.sh | sudo sh -s devnet
```

:warning: **CAUTION** To run the **not release yet** unstable version of the Node Installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/dusk-network/node-installer/main/node-installer.sh | sudo sh
```

## Configuration

The installer comes with sane defaults, only requiring minimal configuration. Before the Rusk service can be started, the `CONSENSUS_KEYS` and `DUSK_CONSENSUS_KEYS_PASS` need to be provided. 

The `CONSENSUS_KEYS` can be either moved to `/opt/dusk/conf/` from another system or generated on the node itself and moved there. 

### Set consensus keys

To generate the provisioner keys locally, run `rusk-wallet` and either create a new wallet or use a recovery phrase with `rusk-wallet restore`. 

To generate and export the provisioner key-pair and put the `.keys` file in the right directory with the right name, copy the following command:
```sh
rusk-wallet export -d /opt/dusk/conf -n consensus.keys
```

### Set consensus password

Run the following command and it will prompt you to enter the password for the consensus keys file:
```sh
sh /opt/dusk/bin/setup_consensus_pwd.sh
```

### Reset Rusk state

To remove old Rusk state and the old wallet cache, simply run:
```sh
ruskreset
```

### Start Rusk

Everything should be configured now and the node is ready to run. Use the following commands:
```sh
service rusk start
```

Check the status of the Rusk service by running:
```sh
service rusk status
```

## Check the installer version

To check your installer version, run:
```sh
ruskquery version
```

If you're running an outdated version of the installer, it will warn you and ask you to upgrade.

## Fast Syncing with Archival State Download

To significantly reduce the time required to sync your node to the latest published state, you can use the `download_state` command. This command stops your node and replaces its current state with the latest published state from one of Dusk's archival nodes. 

To see the available published states, run:
```sh
download_state --list
```

### Using the Fast Sync Command

1. Stop your node (if it's running):
   ```sh
   service rusk stop
   ```

2. Execute the fast sync command.
   ```sh
   download_state
   ```
   
   If you want to sync up with a specific state instead of the default one, you need to pass the block height of the state you want to syncup with.
   ```sh
   download_state 369876
   ```

   Follow the prompts to confirm the operation.

3. Restart your node:
   ```sh
   service rusk restart
   ```

This process will ensure your node is up-to-date with the latest blockchain state, allowing you to sync faster and get back to participating in the network in less time.

> [!NOTE]
> If you are experiencing errors in downloading the state, it might be due to some remnants of previous state syncing. Try to clean up with `sudo rm /tmp/state.tar.gz`

## Diagnostics

Check if your node is syncing, processing and accepting new blocks:
```sh
tail -F /var/log/rusk.log | grep "block accepted"
```

To check the latest block height:
```sh
ruskquery block-height
```
