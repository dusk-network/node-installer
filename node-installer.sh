#!/bin/bash

# When this script is run depends on the tool that's used to run it.
#
# If a user runs this script directly, the node software is installed
# in /opt/dusk and the rusk-wallet, in ~/.dusk with the dusk user and
# group having permissions to access it.
#
# If the user decides to use Docker instead, then this script will be
# run during the Docker build. In that case, all installs are done
# within the container and no additional user or groups are created;
# the root user within the container is used for everything.

declare -A VERSIONS
# Define versions per network, per component
VERSIONS=(
    ["mainnet-rusk"]="1.2.0"
    ["mainnet-rusk-wallet"]="0.1.0-rc.0"
    ["testnet-rusk"]="1.2.0"
    ["testnet-rusk-wallet"]="0.1.0-rc.0"
)

# Default network and feature (Provisioner node)
NETWORK="mainnet"
FEATURE="default"

# Parse command-line arguments to check for network or feature flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --feature)
            FEATURE="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--network mainnet|testnet] [--feature default|archive]"
            exit 1
            ;;
    esac
done

# Validate passed network
case "$NETWORK" in
    mainnet|testnet)
        echo "Selected network: $NETWORK"
        ;;
    *)
        echo "Error: Unknown network $NETWORK. Use 'mainnet' or 'testnet'."
        exit 1
        ;;
esac

# Validate passed feature
case "$FEATURE" in
    default|archive)
        echo "Selected feature: $FEATURE"
        ;;
    *)
        echo "Error: Unknown feature $FEATURE. Use 'default' (Provisioner node) or 'archive'."
        exit 1
        ;;
esac

# Retrieve architecture
arch=""
case "$(uname -m)" in
    x86_64) arch="x64";;
    aarch64) arch="arm64";;
    *) echo "Unsupported architecture: $(uname -m). Only x64 and arm64 are supported."; exit 1;;
esac

# Installs a given component for a given network
install_component() {
    local network="$1"
    local component="$2"
    local key="${network}-${component}"
    local version="${VERSIONS[$key]}"

    if [[ -z "$version" ]]; then
        echo "Error: Version not found for $key"
        exit 1
    fi

    # Apply the FEATURE suffix only for Rusk
    local feature_suffix=""
    local release_tag="${component}"
    if [[ "$component" == "rusk" ]]; then
        feature_suffix="-${FEATURE}"
        # rusk tag name changed after 1.0.0
        release_tag="dusk-rusk"
    fi

    # Removes any RC version from the URL
    local sanitized_version="${version%-rc.*}" 
    # Construct the download URL
    local url="https://github.com/dusk-network/rusk/releases/download/${release_tag}-${version}/${component}-${sanitized_version}-linux-${arch}${feature_suffix}.tar.gz"

    echo "Installing $component version $version for $network ($arch${feature_suffix})"
    echo "Downloading from $url"

    local component_dir="/opt/dusk/installer/${component}"
    mkdir -p "$component_dir"

    curl -so /opt/dusk/installer/${component}.tar.gz -L "$url" || { echo "Failed to download $component"; exit 1; }
    tar xf /opt/dusk/installer/${component}.tar.gz --strip-components 1 --directory "$component_dir"
}

# Configure your local installation based on the selected network
configure_network() {
    local network=$1
    local prover_url

    case "$network" in
        mainnet)
            mv /opt/dusk/conf/mainnet.genesis /opt/dusk/conf/genesis.toml
            mv /opt/dusk/conf/mainnet.toml /opt/dusk/conf/rusk.toml
            rm /opt/dusk/conf/testnet.genesis
            rm /opt/dusk/conf/testnet.toml
            prover_url="https://provers.dusk.network"
            ;;
        testnet)
            mv /opt/dusk/conf/testnet.genesis /opt/dusk/conf/genesis.toml
            mv /opt/dusk/conf/testnet.toml /opt/dusk/conf/rusk.toml
            rm /opt/dusk/conf/mainnet.genesis
            rm /opt/dusk/conf/mainnet.toml
            prover_url="https://testnet.provers.dusk.network"
            ;;
        *)
            echo "Unknown network: $network. Defaulting to mainnet."
            configure_network "mainnet"
            return
            ;;
    esac

    # Update the wallet.toml with the appropriate prover URL for the given network
    sed -i "s|^prover = .*|prover = \"$prover_url\"|" $CURRENT_HOME/.dusk/rusk-wallet/config.toml
}

# Check for OpenSSL 3 or higher
if ! command -v openssl >/dev/null 2>&1 || [ "$(openssl version | awk '{print $2}' | cut -d. -f1)" -lt 3 ]; then
    echo "The required OpenSSL version is not available. Please install OpenSSL 3 or higher"
    echo "You likely need to upgrade your OS or install a newer OS"
    exit 1
fi

# Cleanup previous installer just in case
rm -rf /opt/dusk/installer || true
rm -rf /opt/dusk/installer/installer.tar.gz || true

mkdir -p /opt/dusk/installer

# Download and extract installer files
INSTALLER_URL="https://github.com/dusk-network/node-installer/tarball/docker-support"
echo "Downloading installer package for additional scripts and configurations"
curl -so /opt/dusk/installer/installer.tar.gz -L "$INSTALLER_URL"
tar xf /opt/dusk/installer/installer.tar.gz --strip-components 1 --directory /opt/dusk/installer

RUNNER_SCRIPT_DIR=/opt/dusk/installer/runner
if [ "$BUILDING_DOCKER_IMAGE" == "true" ]; then
    echo "Using runner script: $RUNNER_SCRIPT_DIR/docker.sh"
    source "$RUNNER_SCRIPT_DIR/docker.sh"
else
    echo "Using runner script: $RUNNER_SCRIPT_DIR/systemd.sh"
    source "$RUNNER_SCRIPT_DIR/systemd.sh"
fi

# Detect and source OS logic
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
else
    echo "Unable to detect OS. /etc/os-release not found."
    exit 1
fi

# Normalize distro ID for compatible derivatives
case "$distro" in
    linuxmint*) distro="ubuntu" ;;
esac

echo "Detected OS ID: $ID"
echo "Normalized OS target: $distro"

OS_SCRIPT="/opt/dusk/installer/os/$distro.sh"
if [ -f "$OS_SCRIPT" ]; then
    echo "Using OS support script: $OS_SCRIPT"
    source "$OS_SCRIPT"
else
    echo "No support script found for '$distro'"
    echo "Want to add support? See: https://github.com/dusk-network/node-installer#contributing-os-support"
    exit 1
fi

# Detect the user running the script
CURRENT_USER=$(current_user)
CURRENT_HOME=$(current_home)
echo "Detected current user: $CURRENT_USER"
echo "Home directory: $CURRENT_HOME"

echo "Update package db and install prerequisites."
install_deps

ensure_dusk_user_and_group_exist
stop_previous_services

mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/rusk
mkdir -p /opt/dusk/services
mkdir -p $CURRENT_HOME/.dusk/rusk-wallet
change_owner "$CURRENT_USER" "$CURRENT_HOME/.dusk"
chmod -R 770 "$CURRENT_HOME/.dusk"

# Handle scripts, configs, and service definitions
mv -f /opt/dusk/installer/bin/* /opt/dusk/bin/
mv /opt/dusk/installer/conf/* /opt/dusk/conf/
mv -n /opt/dusk/installer/services/* /opt/dusk/services/

# Download, unpack and install Rusk
install_component "$NETWORK" "rusk"
mv /opt/dusk/installer/rusk/rusk /opt/dusk/bin/

# Download, unpack and install Rusk wallet
install_component "$NETWORK" "rusk-wallet"
mv /opt/dusk/installer/rusk-wallet/rusk-wallet /opt/dusk/bin/
mv -f /opt/dusk/conf/wallet.toml $CURRENT_HOME/.dusk/rusk-wallet/config.toml

# Symlink to make available system-wide
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk
ln -sf /opt/dusk/bin/ruskquery /usr/bin/ruskquery
ln -sf /opt/dusk/bin/ruskreset /usr/bin/ruskreset
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet
if [ "$NETWORK" == "mainnet" ]; then
    link_download_state_bin /usr/bin/download_state
fi

echo "Selected network: $NETWORK"
configure_network "$NETWORK"

# Set permissions for dusk user and group
change_owner dusk /opt/dusk
chmod -R 660 /opt/dusk

# Directory listing needs execution
find /opt/dusk -type d -exec chmod +x {} \;
chmod -R +x /opt/dusk/bin/*

setup_systemd

display_final_instructions

rm -rf /opt/dusk/installer
