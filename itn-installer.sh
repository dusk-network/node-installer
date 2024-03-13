#!/bin/sh
check_installed() {
    binary_name=$1
    package_name=$2
    which $binary_name >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "$binary_name missing"
        echo "Installing $package_name"  
        sudo NEEDRESTART_MODE=a apt install $package_name -y
    fi
}

echo "Stopping previous services"
service rusk stop || true;
rm -rf /opt/dusk/installer || true
rm -rf /opt/dusk/installer/installer.tar.gz || true

echo "Checking prerequisites"
check_installed unzip unzip
check_installed curl curl
check_installed jq jq
check_installed route net-tools
check_installed logrotate logrotate
check_installed dig dnsutils

echo "Creating rusk service user"
id -u dusk >/dev/null 2>&1 || useradd -r dusk

mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/rusk
mkdir -p /opt/dusk/services
mkdir -p /opt/dusk/installer
mkdir -p /root/.dusk/rusk-wallet

VERIFIER_KEYS_URL="https://nodes.dusk.network/keys"
INSTALLER_URL="https://github.com/dusk-network/itn-installer/tarball/main"
RUSK_URL=$(curl -s "https://api.github.com/repos/dusk-network/rusk/releases/latest" | jq -r  '.assets[].browser_download_url' | grep linux)
WALLET_URL=$(curl -s "https://api.github.com/repos/dusk-network/wallet-cli/releases/latest" | jq -r  '.assets[].browser_download_url' | grep libssl3)

echo "Downloading installer package for additional scripts and configurations"
curl -so /opt/dusk/installer/installer.tar.gz -L "$INSTALLER_URL"
tar xf /opt/dusk/installer/installer.tar.gz --strip-components 1 --directory /opt/dusk/installer

# Handle scripts, configs, and service definitions
mv -f /opt/dusk/installer/bin/* /opt/dusk/bin/
mv /opt/dusk/installer/conf/* /opt/dusk/conf/
mv -n /opt/dusk/installer/services/* /opt/dusk/services/

# Download, unpack and install wallet-cli
echo "Downloading the latest Rusk wallet..."
curl -so /opt/dusk/installer/wallet.tar.gz -L "$WALLET_URL"
mkdir -p /opt/dusk/installer/wallet
tar xf /opt/dusk/installer/wallet.tar.gz --strip-components 1 --directory /opt/dusk/installer/wallet
mv /opt/dusk/installer/wallet/rusk-wallet /opt/dusk/bin/
mv -f /opt/dusk/conf/wallet.toml /root/.dusk/rusk-wallet/config.toml

# Make bin folder scripts and bins executable, symlink to make available system-wide
chmod +x /opt/dusk/bin/*
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk
ln -sf /opt/dusk/bin/ruskquery /usr/bin/ruskquery
ln -sf /opt/dusk/bin/download_state /usr/bin/download_state
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet

echo "Downloading verifier keys"
curl -so /opt/dusk/installer/rusk-vd-keys.zip -L "$VERIFIER_KEYS_URL"
unzip -d /opt/dusk/rusk/ -o /opt/dusk/installer/rusk-vd-keys.zip
chown -R dusk:dusk /opt/dusk/

echo "Installing services"
# Overwrite previous service definitions
mv -f /opt/dusk/services/rusk.service /etc/systemd/system/rusk.service

# Configure logrotate with 644 permissions otherwise configuration is ignored
mv -f /opt/dusk/services/logrotate.conf /etc/logrotate.d/dusk.conf
chown root:root /etc/logrotate.d/dusk.conf
chmod 644 /etc/logrotate.d/dusk.conf

systemctl enable rusk
systemctl daemon-reload

echo "Setup local firewall"
ufw allow 8080/tcp
ufw allow 9000/udp

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

rm -rf /opt/dusk/installer
