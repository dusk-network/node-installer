#!/bin/bash

# Detect the user running the script
CURRENT_USER=$(logname)
CURRENT_HOME=$(eval echo ~"$CURRENT_USER")
echo "Detected current user: $CURRENT_USER"
echo "Home directory: $CURRENT_HOME"

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

# Check for Linux
if [ "$(uname -s | tr '[:upper:]' '[:lower:]')" != "linux" ]; then
    echo "Unsupported platform: $(uname -s). This installer only supports Linux."
    exit 1
fi

# Detect the Linux distribution
distro="unknown"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    distro=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
else
    echo "Unable to detect the Linux distribution. Ensure this is an Ubuntu-based system."
    exit 1
fi

if [ "$distro" != "ubuntu" ] && [ "$distro" != "linuxmint" ]; then
    echo "Unsupported Linux distribution: $distro. This installer only supports Ubuntu and Linux Mint." # Ubuntu based
    exit 1
fi


echo "Detected supported distro: $distro ($arch)"

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

# Check for OpenSSL 3 or higher
if ! command -v openssl >/dev/null 2>&1 || [ "$(openssl version | awk '{print $2}' | cut -d. -f1)" -lt 3 ]; then
    echo "The required OpenSSL version is not available. Please install OpenSSL 3 or higher"
    echo "You likely need to upgrade your OS or install a newer OS"
    exit 1
fi

update_pkg_database() {
    echo "Updating package database..."
    apt update
}

check_installed() {
    binary_name=$1
    package_name=$2

    if ! which $binary_name >/dev/null 2>&1; then
        echo "$binary_name missing"
        echo "Installing $package_name"
        NEEDRESTART_MODE=a apt install $package_name -y
    else
        echo "$binary_name is already installed."
    fi
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

echo "Stopping previous services"
if systemctl is-active --quiet rusk; then
    systemctl stop rusk
    echo "Stopped rusk service."
else
    echo "Rusk service not running."
fi

rm -rf /opt/dusk/installer || true
rm -rf /opt/dusk/installer/installer.tar.gz || true

echo "Checking prerequisites"
update_pkg_database
check_installed unzip unzip
check_installed curl curl
check_installed route net-tools
check_installed ipcalc ipcalc
check_installed jq jq
check_installed logrotate logrotate

# Ensure dusk group and user exist
if ! id -u dusk >/dev/null 2>&1; then
    echo "Creating dusk system user and group."
    groupadd --system dusk
    useradd --system --create-home --shell /usr/sbin/nologin --gid dusk dusk
    echo "User 'dusk' and group 'dusk' created."
else
    echo "User 'dusk' and group 'dusk' already exist."
fi

# Add the current user to the dusk group for access
echo "Adding current user to dusk group for access."
if ! id -nG "$CURRENT_USER" | grep -qw "dusk"; then
    usermod -aG dusk "$CURRENT_USER"
    echo "User $CURRENT_USER has been added to the dusk group. Please log out and back in to apply changes."
fi

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
    ln -sf /opt/dusk/bin/download_state.sh /usr/bin/download_state
fi

echo "Selected network: $NETWORK"

configure_network "$NETWORK"

# Set permissions for dusk user and group
chown -R dusk:dusk /opt/dusk
chmod -R 660 /opt/dusk
# Directory listing needs execution
find /opt/dusk -type d -exec chmod +x {} \;
chmod +x /opt/dusk/bin/*

# Set system parameters
mv -f /opt/dusk/conf/dusk.conf /etc/sysctl.d/dusk.conf
sysctl -p /etc/sysctl.d/dusk.conf

echo "Installing services"
# Overwrite previous service definitions
mv -f /opt/dusk/services/rusk.service /etc/systemd/system/rusk.service

# Configure logrotate with 644 permissions otherwise configuration is ignored
mv -f /opt/dusk/services/logrotate.conf /etc/logrotate.d/dusk.conf
chown root:root /etc/logrotate.d/dusk.conf
chmod 644 /etc/logrotate.d/dusk.conf

# Enable the Rusk service
systemctl enable rusk
systemctl daemon-reload

# Display final instructions
cat /opt/dusk/installer/assets/finish.msg

rm -rf /opt/dusk/installer
