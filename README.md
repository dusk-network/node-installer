<h1 align="center">
<img height="90" src="assets/node_installer_light.svg#gh-dark-mode-only" alt="Dusk Docs">
<img height="90" src="assets/node_installer_dark.svg#gh-light-mode-only" alt="Dusk Docs">
</h1>

<p align="center">
  Official <img height="11" src="assets/dusk_circular_light.svg#gh-dark-mode-only"><img height="11" src="assets/dusk_circular_dark.svg#gh-light-mode-only"><a href="https://dusk.network/"> Dusk</a> Node installer, an easy-to-use installer for running a Dusk node on the Dusk mainnet, Nocturne testnet and the Lunare devnet.
</p>

<p align=center>
<a href="https://github.com/dusk-network/node-installer/releases">
<img alt="GitHub Downloads" src="https://img.shields.io/github/downloads/dusk-network/node-installer/total?style=flat-square&label=github%20downloads&color=71B1FF"></a>
&nbsp;
<a href="https://discord.gg/dusk-official">
<img src="https://img.shields.io/discord/847466263064346624?label=discord&style=flat-square&color=5a66f6" alt="Discord"></a>
&nbsp;
<a href="https://x.com/DuskFoundation/">
<img alt="X (formerly Twitter) Follow" src="https://img.shields.io/twitter/follow/DuskFoundation"></a>
&nbsp;
<a href="https://docs.dusk.network">
<img alt="Static Badge" src="https://img.shields.io/badge/read%20the%20docs-E2DFE9?style=flat-square&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB3aWR0aD0iMjAwIiBoZWlnaHQ9IjIwMCIgdmlld0JveD0iMCAwIDIwMCAyMDAiIGZpbGw9Im5vbmUiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyI%2BCjxwYXRoIGZpbGwtcnVsZT0iZXZlbm9kZCIgY2xpcC1ydWxlPSJldmVub2RkIiBkPSJNODEuMjk4IDEuNzM3OEM4OC4yMjI5IDAuNDM3NzI0IDk1LjQyMjcgLTAuMTYyMzEyIDEwMi43OTggMC4wMzc3QzE1NC45OTYgMS40Mzc3OSAxOTcuODQ1IDQzLjc0MDQgMTk5LjkyIDk1LjkxODZDMjAyLjE3IDE1Mi45OTcgMTU2LjU3MSAyMDAgOTkuOTk3NiAyMDBDOTMuNjIyNyAyMDAgODcuMzcyOSAxOTkuNCA4MS4zMjMgMTk4LjI1QzM1LjAyNDIgMTg5LjQ5OSAwIDE0OC44MjIgMCA5OS45OTM5QzAgNTEuMTY1OCAzNC45OTkyIDEwLjQ4ODMgODEuMjk4IDEuNzM3OFpNMTAyLjc3MyAxNzYuNjc0QzEwMS43MjMgMTc4LjAyNCAxMDIuODIyIDE3OS45NzQgMTA0LjUyMiAxNzkuODc0QzE0Ni42MjEgMTc3LjUyNCAxNzkuOTk2IDE0Mi42NzEgMTc5Ljk5NiA5OS45OTM5QzE3OS45OTYgNTcuMzE2MiAxNDYuNTk2IDIyLjQ2NDEgMTA0LjQ5NyAyMC4xMTM5QzEwMi43OTggMjAuMDEzOSAxMDEuNzIzIDIxLjk2NDEgMTAyLjc3MyAyMy4zMTQxQzExOS4yNDcgNDQuNDY1NCAxMjkuMDQ3IDcxLjA5MjEgMTI5LjA0NyA5OS45OTM5QzEyOS4wNDcgMTI4Ljg5NiAxMTkuMjIyIDE1NS40OTcgMTAyLjc3MyAxNzYuNjc0WiIgZmlsbD0iIzEwMTAxMCIvPgo8L3N2Zz4K"></a>
</p>

> For more information checkout the [node operator documentation](https://docs.dusk.network/operator/overview/) on our docs.

## 📋 Prerequisites

- Operating System: Ubuntu 24.04 LTS x64
- Dependencies: OpenSSL 3, GLibc 2.38+
- Environment: Any compatible Linux environment (VPS, local, cloud instance)

The installer officially supports 24.04 LTS x64. While it has also been tested successfully on Ubuntu 24.10, official support is limited to the LTS version listed above. Compatibility with other versions may vary.

## 📦 Packages

The installer comes with the following packages:
- [Rusk](https://github.com/dusk-network/rusk) service
- [Rusk wallet CLI](https://github.com/dusk-network/rusk/tree/master/rusk-wallet/src/bin)

## 📂 Folder layout 

The configuration files, binaries, services and scripts can be found in `/opt/dusk/`. 

The log files can be found in `/var/log/rusk.log` and `/var/log/rusk-recovery.log`.

## ⬇️ Installation

:information_source: To run the **latest release** of the Node Installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.5.0/node-installer.sh | sudo bash
```

:warning: **CAUTION** To run the **not release yet** unstable version of the Node Installer execute the following command:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/dusk-network/node-installer/main/node-installer.sh | sudo bash
```

### Networks

By default, the installer runs the node for our mainnet. If you'd like to run a node for the Nocturne testnet or Lunare devnet, you can pass `testnet` or `devnet` as an option during installation:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.5.0/node-installer.sh | sudo bash -s testnet
```

### Features

It is possible to run an archive node through the installer. By default, the installer will download a Provisioner node with proving capabilities. By setting a `FEATURE` variable to `archive`, it's possible to download an archive node binary:
```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/download/v0.5.0/node-installer.sh | FEATURE="archive" sudo bash
```

## ⚙️ Configuration

The installer comes with sane defaults, only requiring minimal configuration. Before the Rusk service can be started, the `CONSENSUS_KEYS` and `DUSK_CONSENSUS_KEYS_PASS` need to be provided. 

The `CONSENSUS_KEYS` can be either moved to `/opt/dusk/conf/` from another system or generated on the node itself and moved there. 

### 🔑 Set consensus keys

To generate the consensus keys locally, run `rusk-wallet` and either create a new wallet or use a recovery phrase with `rusk-wallet restore`. 

To generate and export the consensus key-pair and put the `.keys` file in the right directory with the right name, copy the following command:
```sh
rusk-wallet export -d /opt/dusk/conf -n consensus.keys
```

### 🔐 Set consensus password

Run the following command and it will prompt you to enter the password for the consensus keys file:
```sh
sh /opt/dusk/bin/setup_consensus_pwd.sh
```

### ↻ Reset Rusk state

To remove old Rusk state and the old wallet cache, simply run:
```sh
ruskreset
```

### ▶️ Start Rusk

Everything should be configured now and the node is ready to run. Use the following commands:
```sh
service rusk start
```

Check the status of the Rusk service by running:
```sh
service rusk status
```

## 🔢 Check the installer version

To check your installer version, run:
```sh
ruskquery version
```

If you're running an outdated version of the installer, it will warn you and ask you to upgrade.

## 🔄 Fast Syncing with Archival State Download

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

## 🔍 Diagnostics

Check if your node is syncing, processing and accepting new blocks:
```sh
tail -F /var/log/rusk.log | grep "block accepted"
```

To check the latest block height:
```sh
ruskquery block-height
```
