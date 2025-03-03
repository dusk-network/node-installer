#!/bin/bash

# Detect the user running the script
CURRENT_USER=$(logname)
CURRENT_HOME=$(eval echo ~"$CURRENT_USER")
echo "Detected current user: $CURRENT_USER"
echo "Home directory: $CURRENT_HOME"

declare -A VERSIONS
# Define versions per network, per component
VERSIONS=(
    ["mainnet-rusk"]="1.1.1"
    ["mainnet-rusk-wallet"]="0.1.0-rc.0"
    ["testnet-rusk"]="1.1.1"
    ["testnet-rusk-wallet"]="0.1.0-rc.0"
)

# Default network and feature (Provisioner node)
NETWORK="devnet"
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
            echo "Usage: $0 [--network mainnet|testnet|devnet] [--feature default|archive]"
            exit 1
            ;;
    esac
done

# Validate passed network
case "$NETWORK" in
    mainnet|testnet|devnet)
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

# Platform validation
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "This installer only supports macOS."
    exit 1
fi

# Retrieve architecture
arch=""
case "$(uname -m)" in
    x86_64) arch="x64" ;;
    arm64) arch="arm64" ;;
    *) echo "Unsupported architecture: $(uname -m). Only x64 and arm64 are supported."; exit 1 ;;
esac

# Check required macOS tools
for pkg in curl unzip jq; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo "$pkg is required. Install it using Homebrew: brew install $pkg"
        exit 1
    fi
done

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
    local url="https://github.com/dusk-network/rusk/releases/download/${release_tag}-${version}/${component}-${sanitized_version}-macos-arm64${feature_suffix}.tar.gz"

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
            rm /opt/dusk/conf/devnet.genesis
            rm /opt/dusk/conf/devnet.toml
            prover_url="https://provers.dusk.network"
            ;;
        testnet)
            mv /opt/dusk/conf/testnet.genesis /opt/dusk/conf/genesis.toml
            mv /opt/dusk/conf/testnet.toml /opt/dusk/conf/rusk.toml
            rm /opt/dusk/conf/mainnet.genesis
            rm /opt/dusk/conf/mainnet.toml
            rm /opt/dusk/conf/devnet.genesis
            rm /opt/dusk/conf/devnet.toml
            prover_url="https://testnet.provers.dusk.network"
            ;;
        devnet)
            mv /opt/dusk/conf/devnet.genesis /opt/dusk/conf/genesis.toml
            mv /opt/dusk/conf/devnet.toml /opt/dusk/conf/rusk.toml
            rm /opt/dusk/conf/mainnet.genesis
            rm /opt/dusk/conf/mainnet.toml
            rm /opt/dusk/conf/testnet.genesis
            rm /opt/dusk/conf/testnet.toml
            prover_url="https://devnet.provers.dusk.network"
            ;;
        *)
            echo "Unknown network: $network. Defaulting to devnet."
            configure_network "devnet"
            return
            ;;
    esac

    # Update the wallet.toml with the appropriate prover URL for the given network
    sed -i "s|^prover = .*|prover = \"$prover_url\"|" $CURRENT_HOME/.dusk/rusk-wallet/config.toml
}

rm -rf /opt/dusk/installer || true
rm -rf /opt/dusk/installer/installer.tar.gz || true

mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/rusk
mkdir -p /opt/dusk/services
mkdir -p /opt/dusk/installer
mkdir -p $CURRENT_HOME/.dusk/rusk-wallet
chown -R "$CURRENT_USER:dusk" "$CURRENT_HOME/.dusk"
chmod -R 770 "$CURRENT_HOME/.dusk"

INSTALLER_URL="https://github.com/dusk-network/node-installer/tarball/main"

echo "Downloading installer package for additional scripts and configurations"
curl -so /opt/dusk/installer/installer.tar.gz -L "$INSTALLER_URL"
tar xf /opt/dusk/installer/installer.tar.gz --strip-components 1 --directory /opt/dusk/installer

# Handle scripts, configs, and service definitions
mv -f /opt/dusk/installer/bin/* /opt/dusk/bin/
mv /opt/dusk/installer/conf/* /opt/dusk/conf/

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
    ln -sf /opt/dusk/bin/download_state.sh /usr/bin/download_state
fi

echo "Downloading verifier keys"

echo "Selected network: $NETWORK"
VERIFIER_KEYS_URL="https://devnet.nodes.dusk.network/keys"

case "$NETWORK" in
    mainnet)
        VERIFIER_KEYS_URL="https://nodes.dusk.network/keys"
        ;;
    testnet)
        VERIFIER_KEYS_URL="https://testnet.nodes.dusk.network/keys"
        ;;
    devnet)
        VERIFIER_KEYS_URL="https://devnet.nodes.dusk.network/keys"
        ;;
    *)
        echo "Unknown network: $network. Defaulting to devnet."
        return
        ;;
esac

rm -rf /opt/dusk/rusk/circuits || true
rm -rf /opt/dusk/rusk/keys || true

curl -so /opt/dusk/installer/rusk-vd-keys.zip -L "$VERIFIER_KEYS_URL"
unzip -d /opt/dusk/rusk/ -o /opt/dusk/installer/rusk-vd-keys.zip

configure_network "$NETWORK"

# Set permissions for dusk user and group
chown -R dusk:dusk /opt/dusk
chmod -R 660 /opt/dusk
# Directory listing needs execution
find /opt/dusk -type d -exec chmod +x {} \;
chmod +x /opt/dusk/bin/*

# Display final instructions
cat /opt/dusk/installer/assets/finish.msg

rm -rf /opt/dusk/installer
