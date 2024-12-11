#!/bin/sh

# Retrieve OS & distro
os=$(uname -s)
distro="unknown"

get_linux_distro() {
    if [ -f /etc/os-release ]; then 
        # systemd users should have os-release available
        . /etc/os-release
        distro=$(echo "$NAME" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
    elif type lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    else
        distro="unknown"
    fi
}

if [ "$os" = "Linux" ]; then
    get_linux_distro
fi

# Retrieve architecture
case "$(uname -m)" in
    x86_64*)    arch=x86_64;;
    arm*)       arch=ARM;;
    aarch64*)   arch=ARM64;;
    *)          arch="unknown:$(uname -m)"
esac

# Check for Debian or Ubuntu on x86_64 architecture
if [ "$distro" != "debian" ] && [ "$distro" != "ubuntu" ] || [ "$arch" != "x86_64" ]; then
    echo "Unsupported OS or architecture. This installer only supports Debian/Ubuntu-based systems with the x86_64 architecture."
    exit 1
fi

update_pkg_database() {
    echo "Updating package database..."
    case "$distro" in
        debian|ubuntu)
            apt update
            ;;
    *)
        echo "Unsupported distribution for package database updates: $distro"
        exit 1
        ;;
    esac
}

check_installed() {
    binary_name=$1
    package_name=$2
    which $binary_name >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "$binary_name missing"
        echo "Installing $package_name"

        case "$distro" in
            debian|ubuntu)
                NEEDRESTART_MODE=a apt install $package_name -y
                ;;
            # arch|manjaro)
            #   pacman -S "$package_name" --noconfirm
            #   ;;
            *)
                # This path shouldn't happen on Linux OSes
                echo "Unsupported distro: $distro"
                exit 1
                ;;
        esac
    else
        echo "$binary_name is already installed."
    fi
}

# Fetch all Rusk tags once and store them in a variable
ALL_TAGS=$(curl -s "https://api.github.com/repos/dusk-network/rusk/tags" | jq -r '.[].name')

# Grab the latest version tag for a given tag pattern
get_latest_tag() {
    local tag_pattern=$1

    # We sort on version, and grab the tail (highest version). If we grab the head,
    # we might run into consistency issues
    echo "$ALL_TAGS" \
        | grep -E "^${tag_pattern}-[0-9]+\.[0-9]+\.[0-9]+$" \
        | sort -V | tail -n 1
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
            bootstrapping_nodes="['mainnet-node:9000']"
            genesis_timestamp="'2024-10-15T12:30:00Z'"
            ;;
        testnet)
            kadcast_id="0x2"
            bootstrapping_nodes="['104.248.194.214:9000','164.92.247.97:9000','146.190.56.220:9000']"
            genesis_timestamp="'2024-12-11T09:00:00Z'"
            ;;
        devnet)
            kadcast_id="0x3"
            bootstrapping_nodes="['']"
            genesis_timestamp="'2024-10-01T12:30:00Z'"
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
# RUSK_TAG=$(get_latest_tag "rusk")
# RUSK_URL=$(curl -s "https://api.github.com/repos/dusk-network/rusk/releases/tags/${RUSK_TAG}" | jq -r  '.assets[].browser_download_url' | grep linux)
# WALLET_TAG=$(get_latest_tag "rusk-wallet")
# WALLET_URL=$(curl -s "https://api.github.com/repos/dusk-network/wallet-cli/releases/tags/${WALLET_TAG}" | jq -r  '.assets[].browser_download_url' | grep libssl3)

echo "Downloading installer package for additional scripts and configurations"
curl -so /opt/dusk/installer/installer.tar.gz -L "$INSTALLER_URL"
tar xf /opt/dusk/installer/installer.tar.gz --strip-components 1 --directory /opt/dusk/installer

# Handle scripts, configs, and service definitions
mv -f /opt/dusk/installer/bin/* /opt/dusk/bin/
mv /opt/dusk/installer/conf/* /opt/dusk/conf/
mv -n /opt/dusk/installer/services/* /opt/dusk/services/

# Download, unpack and install wallet-cli
# echo "Downloading the latest Rusk wallet..."
# curl -so /opt/dusk/installer/wallet.tar.gz -L "$WALLET_URL"
# mkdir -p /opt/dusk/installer/wallet
# tar xf /opt/dusk/installer/wallet.tar.gz --strip-components 1 --directory /opt/dusk/installer/wallet
# mv /opt/dusk/installer/wallet/rusk-wallet /opt/dusk/bin/
mv -f /opt/dusk/conf/wallet.toml ~/.dusk/rusk-wallet/config.toml

# Make bin folder scripts and bins executable, symlink to make available system-wide
chmod +x /opt/dusk/bin/*
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk
ln -sf /opt/dusk/bin/ruskquery /usr/bin/ruskquery
ln -sf /opt/dusk/bin/ruskreset /usr/bin/ruskreset
ln -sf /opt/dusk/bin/download_state.sh /usr/bin/download_state
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet

echo "Downloading verifier keys"
# Select network (default to testnet if no argument passed)
NETWORK="${1:-testnet}"
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
        echo "Unknown network: $network. Defaulting to testnet."
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
