#!/bin/bash

declare -A VERSIONS
# Define versions per network, per component
VERSIONS=(
    ["mainnet-rusk"]="1.0.0-rc.0"
    ["mainnet-rusk-wallet"]="0.1.0-rc.0"
    ["testnet-rusk"]="1.0.0-rc.0"
    ["testnet-rusk-wallet"]="0.1.0-rc.0"
    ["devnet-rusk"]="1.0.0-rc.0"
    ["devnet-rusk-wallet"]="0.1.0-rc.0"
)

# Select network (default to mainnet if no argument passed)
NETWORK="${1:-mainnet}"
case "$NETWORK" in
    mainnet|testnet|devnet)
        echo "Selected network: $NETWORK"
        ;;
    *)
        echo "Error: Unknown network $NETWORK. Use 'mainnet', 'testnet', or 'devnet'."
        exit 1
        ;;
esac

# Feature flag ("default" if not set, "archive" also possible)
FEATURE="${FEATURE:-default}"

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

if [ "$distro" != "ubuntu" ]; then
    echo "Unsupported Linux distribution: $distro. This installer only supports Ubuntu."
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
    if [[ "$component" == "rusk" ]]; then
        feature_suffix="-${FEATURE}"
    fi

    # Removes any RC version from the URL
    local sanitized_version="${version%-rc.*}" 
    # Construct the download URL
    local url="https://github.com/dusk-network/rusk/releases/download/${component}-${version}/${component}-${sanitized_version}-linux-${arch}${feature_suffix}.tar.gz"

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
    local kadcast_id
    local bootstrapping_nodes
    local genesis_timestamp

    case "$network" in
        mainnet)
            kadcast_id="0x1"
            bootstrapping_nodes="[]"
            genesis_timestamp="'2024-12-29T12:00:00Z'"
            ;;
        testnet)
            kadcast_id="0x2"
            bootstrapping_nodes="['134.122.62.88:9000','165.232.64.16:9000','137.184.118.43:9000']"
            genesis_timestamp="'2024-12-23T17:00:00Z'"
            ;;
        devnet)
            kadcast_id="0x3"
            bootstrapping_nodes="['128.199.32.54', '159.223.29.22', '143.198.225.158']"
            genesis_timestamp="'2024-12-23T12:00:00Z'"
            ;;
        *)
            echo "Unknown network: $network. Defaulting to testnet."
            configure_network "testnet"
            return
            ;;
    esac

    # Update the rusk.toml file with kadcast_id, bootstrapping_nodes & genesis_timestamp
    sed -i "s/^kadcast_id =.*/kadcast_id = $kadcast_id/" /opt/dusk/conf/rusk.toml
    sed -i "s/^bootstrapping_nodes =.*/bootstrapping_nodes = $bootstrapping_nodes/" /opt/dusk/conf/rusk.toml
    sed -i "s/^genesis_timestamp =.*/genesis_timestamp = $genesis_timestamp/" /opt/dusk/conf/rusk.toml
}

echo "Stopping previous services"
service rusk stop || true;
rm -rf /opt/dusk/installer || true
rm -rf /opt/dusk/installer/installer.tar.gz || true

echo "Checking prerequisites"
update_pkg_database
check_installed unzip unzip
check_installed curl curl
check_installed jq jq
check_installed route net-tools
check_installed logrotate logrotate
check_installed dig dnsutils
check_installed ufw ufw

echo "Creating rusk service user"
id -u dusk >/dev/null 2>&1 || useradd -r dusk

mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/rusk
mkdir -p /opt/dusk/services
mkdir -p /opt/dusk/installer
mkdir -p ~/.dusk/rusk-wallet

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
mv -f /opt/dusk/conf/wallet.toml ~/.dusk/rusk-wallet/config.toml

# Make bin folder scripts and bins executable, symlink to make available system-wide
chmod +x /opt/dusk/bin/*
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk
ln -sf /opt/dusk/bin/ruskquery /usr/bin/ruskquery
ln -sf /opt/dusk/bin/ruskreset /usr/bin/ruskreset
ln -sf /opt/dusk/bin/download_state.sh /usr/bin/download_state
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet

echo "Downloading verifier keys"

echo "Selected network: $NETWORK"
VERIFIER_KEYS_URL="https://testnet.nodes.dusk.network/keys"

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
        echo "Unknown network: $network. Defaulting to mainnet."
        return
        ;;
esac

rm -rf /opt/dusk/rusk/circuits || true
rm -rf /opt/dusk/rusk/keys || true

curl -so /opt/dusk/installer/rusk-vd-keys.zip -L "$VERIFIER_KEYS_URL"

unzip -d /opt/dusk/rusk/ -o /opt/dusk/installer/rusk-vd-keys.zip
chown -R dusk:dusk /opt/dusk/

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

configure_network "$NETWORK"

# Enable the Rusk service
systemctl enable rusk
systemctl daemon-reload

echo "Setup local firewall"
ufw allow ssh # SSH
ufw allow 8080/tcp # HTTP listener
ufw allow 9000/udp # Kadcast

if ! ufw status | grep -q "Status: active"; then
    echo "Enabling UFW"
    ufw --force enable
else
    echo "UFW is already enabled"
fi

echo "Dusk node installed"
echo "-----"
echo "Prerequisites for launching:"
echo "1. Provide CONSENSUS_KEYS file (default in /opt/dusk/conf/consensus.keys)"
echo "Run the following commands:"
echo "rusk-wallet restore"
echo "rusk-wallet export -d /opt/dusk/conf -n consensus.keys"
echo
echo "2. Set DUSK_CONSENSUS_KEYS_PASS (use /opt/dusk/bin/setup_consensus_pwd.sh)"
echo "Run the following command:"
echo "sh /opt/dusk/bin/setup_consensus_pwd.sh"
echo
echo "-----"
echo "To launch the node: "
echo "service rusk start"
echo
echo "To run the Rusk wallet:"
echo "rusk-wallet"
echo
echo "To check the logs:"
echo "tail -F /var/log/rusk.log"
echo
echo "The installer also adds a small Rusk querying utility called ruskquery."
echo "To see what you can query with it:"
echo "ruskquery"
echo
echo "To query the the node for the latest block height:"
echo "ruskquery block-height"
echo
echo "To check if your node installer is up to date:"
echo "ruskquery version"
echo
echo "To reset your Rusk state and wallet cache:"
echo "ruskreset"

rm -rf /opt/dusk/installer
