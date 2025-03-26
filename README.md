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

> For more information checkout the
> [node operator documentation](https://docs.dusk.network/operator/overview/) on
> our docs.

# 📃 Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#-prerequisites)
- [Packages](#-packages)
- [Folder Layout](#-folder-layout)
- [Pre-Installation Setup](#-pre-installation-setup)
  - [Step 1: Create a Dedicated Group & User](#step-1-create-a-dedicated-group--user)
  - [Step 2: Set Up SSH Access](#step-2-set-up-ssh-access)
  - [Step 3: Add `duskadmin` to the `sudo` Group](#step-3-add-duskadmin-to-the-sudo-group)
  - [Step 4: Verify Access](#step-4-verify-access)
  - [Step 5: Firewall](#step-5-firewall)
    - [Configure with `ufw`](#configure-with-ufw)
- [Installation](#⬇️-installation)
  - [Networks](#networks)
  - [Features](#features)
- [Configuration](#⚙️-configuration)
  - [Set Consensus Keys](#-set-consensus-keys)
  - [Set Consensus Password](#-set-consensus-password)
  - [Reset Rusk State](#↻-reset-rusk-state)
  - [Start Rusk](#▶️-start-rusk)
- [Check the Installer Version](#-check-the-installer-version)
- [Diagnostics](#-diagnostics)
- [Fast Syncing with Archival State Download](#-fast-syncing-with-archival-state-download)
  - [Using the Fast Sync Command](#using-the-fast-sync-command)
- [Using Docker](#-using-docker)
  - [Download Node Installer Code](#download-node-installer-code)
  - [Building Node Image](#building-node-image)
  - [Running](#running)
  - [Running Query Commands](#running-query-commands)
  - [Fast Syncing](#fast-syncing)

## 📋 Prerequisites

- Operating System: Ubuntu 24.04 LTS x64
- Dependencies: OpenSSL 3, GLibc 2.38+
- Environment: Any compatible Linux environment (VPS, local, cloud instance)

The installer officially supports 24.04 LTS x64. While it has also been tested
successfully on Ubuntu 24.10, official support is limited to the LTS version
listed above. Compatibility with other versions may vary.

If you don't have a system that meets the requirements, you may use the Docker setup instead.

## 📦 Packages

The installer comes with the following packages:

- [Rusk](https://github.com/dusk-network/rusk) service
- [Rusk wallet CLI](https://github.com/dusk-network/rusk/tree/master/rusk-wallet/src/bin)

## 📂 Folder layout

The configuration files, binaries, services and scripts can be found in
`/opt/dusk/`.

The log files can be found in `/var/log/rusk.log` and
`/var/log/rusk-recovery.log`.

## 🔑 Pre-Installation Setup

To securely manage your node, it's highly recommended to use a dedicated
non-root user (e.g., `duskadmin`). Before running the Node Installer, ensure you
have set up a dedicated user for managing your node and configured SSH access.
This user should be part of the `dusk` group to access node files and
configurations.

### Step 1: Create a Dedicated Group & User

Create a new non-root user (e.g., `duskadmin`), add them to the `dusk` group and
set a password for the new user:

```sh
sudo groupadd --system dusk
sudo useradd -m -G dusk -s /bin/bash duskadmin
sudo passwd duskadmin
```

### Step 2: Set Up SSH Access

Ensure the new user has access to your SSH keys for secure login. Add your
public key directly to the new user's `authorized_keys` file:

1. Edit or create the `authorized_keys` file for the new user:

```sh
mkdir -p /home/duskadmin/.ssh
sudo nano /home/duskadmin/.ssh/authorized_keys
```

2. Paste your public SSH key (e.g., starting with `ssh-rsa` or `ssh-ed25519`)
3. Save and set proper permissions:

```sh
sudo chmod 700 /home/duskadmin/.ssh
sudo chmod 600 /home/duskadmin/.ssh/authorized_keys
sudo chown -R duskadmin:dusk /home/duskadmin/.ssh
```

### Step 3: Add `duskadmin` to the `sudo` Group

If not already done, log in as `root` or a user with sufficient privileges and
add `duskadmin` to the `sudo` group:

```sh
sudo usermod -aG sudo duskadmin
```

Log out from you node for the group changes to take effect.

### Step 4: Verify Access

Test SSH access to the new user account by connecting to the node with the new
account:

```sh
ssh duskadmin@<your-server-ip>
```

### Step 5: Firewall

It's important to setup a firewall. A firewall controls incoming and outgoing
traffic and ensures your system is protected.

You can use common tools like `ufw`, `iptables`, or `firewalld`. At a minimum,
the following ports should be open:

- The port you use for SSH (default: `22`)
- `9000/udp` for Kadcast (used for consensus messages)

If you're running an archive node or want to expose the HTTP server, you can
also open the corresponding TCP port (default: `8080`).

#### Configure with `ufw`

If you're using `ufw`, you can configure it with these commands:

```sh
# Allow SSH (default port 22)
sudo ufw limit ssh
# Allow Kadcast UDP traffic
sudo ufw allow 9000/udp
# Enable the firewall
sudo ufw enable
```

For non-default SSH ports or other firewall tools, adjust the commands
accordingly.

## ⬇️ Installation

:information_source: To run the **latest release** of the Node Installer execute
the following command:

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/latest/download/node-installer.sh | sudo bash
```

:warning: **CAUTION** To run the **not release yet** unstable version of the
Node Installer execute the following command:

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://raw.githubusercontent.com/dusk-network/node-installer/main/node-installer.sh | sudo bash
```

### Networks

By default, the installer runs the node for our mainnet. If you'd like to run a
node for the Nocturne testnet or Lunare devnet, you can specify the network
using the `--network` flag:

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/latest/download/node-installer.sh | sudo bash -s -- --network testnet
```

Available network options:

- `mainnet` (default)
- `testnet`
- `devnet`

### Features

The installer defaults to downloading a Provisioner node. To install an archive
node, you can use the `--feature` flag:

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/latest/download/node-installer.sh | sudo bash -s -- --feature archive
```

You can combine both flags to install a specific network and feature. For
example:

```sh
curl --proto '=https' --tlsv1.2 -sSfL https://github.com/dusk-network/node-installer/releases/latest/download/node-installer.sh | sudo bash -s -- --network devnet --feature archive
```

Available feature options:

- `default` (Provisioner node, default)
- `archive` (Archive node)

## ⚙️ Configuration

The installer comes with sane defaults, only requiring minimal configuration.
Before the Rusk service can be started, the `CONSENSUS_KEYS` and
`DUSK_CONSENSUS_KEYS_PASS` need to be provided.

The `CONSENSUS_KEYS` can be either moved to `/opt/dusk/conf/` from another
system or generated on the node itself and moved there.

### 🔑 Set consensus keys

To generate the consensus keys locally, run `rusk-wallet` and either create a
new wallet or use a recovery phrase with `rusk-wallet restore`.

To generate and export the consensus key-pair and put the `.keys` file in the
right directory with the right name, copy the following command:

```sh
rusk-wallet export -d /opt/dusk/conf -n consensus.keys
```

### 🔐 Set consensus password

Run the following command and it will prompt you to enter the password for the
consensus keys file:

```sh
sh /opt/dusk/bin/setup_consensus_pwd.sh
```

### ↻ Reset Rusk state

To remove old Rusk state and the old wallet cache, simply run:

```sh
ruskreset
```

### ▶️ Start Rusk

Everything should be configured now and the node is ready to run. Use the
following commands:

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

If you're running an outdated version of the installer, it will warn you and ask
you to upgrade.

## 🔍 Diagnostics

Check if your node is syncing, processing and accepting new blocks:

```sh
tail -F /var/log/rusk.log | grep "block accepted"
```

To check the latest block height:

```sh
ruskquery block-height
```

## 🔄 Fast Syncing with Archival State Download

To significantly reduce the time required to sync your node to the latest
published state, you can use the `download_state` command. This command stops
your node and replaces its current state with the latest published state from
one of Dusk's archival nodes. Currently this is only available for mainnet.

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

   If you want to sync up with a specific state instead of the default one, you
   need to pass the block height of the state you want to syncup with.
   ```sh
   download_state 369876
   ```

   Follow the prompts to confirm the operation.

3. Restart your node:
   ```sh
   service rusk restart
   ```

This process will ensure your node is up-to-date with the latest blockchain
state, allowing you to sync faster and get back to participating in the network
in less time.

> [!NOTE]
> If you are experiencing errors in downloading the state, it might be due to
> some remnants of previous state syncing. Try to clean up with
> `sudo rm /tmp/state.tar.gz`

## 🐳 Using Docker

If you don't have a system that meets the prerequisites to run a node, you may run with
Docker instead.

First, if you don't have Docker installed, follow the [official guide](https://docs.docker.com/desktop/)
to install it.

### Download Node Installer Code

To build the Docker image for a node, you first need to download the code for the version of the
node installer you're going to use.

```sh
wget https://github.com/dusk-network/node-installer/archive/refs/tags/<version>.zip
```

For example, if you're using version v0.5.6, then you'll run:

```sh
wget https://github.com/dusk-network/node-installer/archive/refs/tags/v0.5.6.zip
```

Ensure that the version you select is a version that supports Docker.

After downloading the code, unzip it and change your working directory:

```sh
unzip node-installer-<version>
cd node-installer-<version>
```

Or if you want to use the latest unreleased code:

```sh
git clone https://github.com/dusk-network/node-installer.git
cd node-installer
```

### Building Node Image

To build the image:

```sh
docker build -t node-installer .
```

This will build a Docker image with all the prerequisites and binaries to run a node.
By default, the dependencies installed will be for provisioner nodes on mainnet.

To change that, you need to specify build args to indicate which network you want to run on and
which feature to use.

```sh
docker build -t node-installer --build-arg NETWORK=<mainnet|testnet> --build-arg FEATURE=<default|archive> .
```

Building the image without specifying any build args is equivalent to:

```sh
docker build -t node-installer --build-arg NETWORK=mainnet --build-arg FEATURE=default .
```

You can combine args to build for a specific network and feature. For example, if you want to run
an archive node on testnet:

```sh
docker build -t node-installer --build-arg NETWORK=testnet --build-arg FEATURE=archive .
```

### Running

Before running, you need to get your consensus keys. You can create them by following
[Set Consensus Keys](#-set-consensus-keys).

To start a node:

```sh
docker run -d \
  --name rusk \
  -e DUSK_CONSENSUS_KEYS_PASS=<consensus-keys-password> \
  -v /path/to/consensus.keys:/opt/dusk/conf/consensus.keys \
  -v /path/to/rusk-profile:/opt/dusk/rusk \
  -p 9000:9000/udp \
  node-installer
```

Replacing:
- `<consensus-keys-password>` with your actual consensus keys password. This will set the environment variable
`DUSK_CONSENSUS_KEYS_PASS`.
- `/path/to/consensus.keys` with the actual path to where your consensus keys are located. This will enabled rusk to
access them from within the container.
- `/path/to/rusk-profile` with the path to the rusk profile, a directory where the state will be stored. This will allow
rusk to save its current state outside the container so that the state will persist between runs.

This will run a container named rusk in the background.

To check the logs:

```sh
docker logs rusk
```

To stop a node:

```sh
docker stop rusk
```

To restart a previously stopped node:

```sh
docker start rusk
```

### Running Query Commands

You can run any `ruskquery` command to check diagnostics or the installer version:

Checking the block height:

```sh
docker exec rusk ruskquery block-height
```

Checking the installer version:

```sh
docker exec rusk ruskquery version
```

### Fast Syncing

If you built the image with the `NETWORK` arg set to mainnet, then you can also run the `download_state`
command for fast archival state syncing.

1. If you've already run the container, stop it and remove it:
   ```sh
   docker stop rusk
   docker rm rusk
   ```

2. Execute the fast sync command
   ```sh
   docker run --rm -it -v /path/to/rusk-profile:/opt/dusk/rusk node-installer download_state
   ```
   This will execute the command within a temporary container but the state is saved in
   `/path/to/rusk-profile`.

   Or syncing up to a specific height.
   ```sh
   docker run --rm -it -v /path/to/rusk-profile:/opt/dusk/rusk node-installer download_state 369876
   ```

   Follow the prompts to confirm the operation.

3. Restart your node:
   Follow the [Running](#running) guide to start a node.
