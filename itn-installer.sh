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

echo "Creating rusk service user"
id -u dusk >/dev/null 2>&1 || useradd -r dusk

mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/rusk
mkdir -p /opt/dusk/services
mkdir -p /opt/dusk/installer
mkdir -p /root/.dusk/rusk-wallet

VERIFIER_KEYS_URL="https://nodes.dusk.network/keys"
LAST_STATE_URL="https://nodes.dusk.network/state/86920"
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

chmod +x /opt/dusk/bin/*

#echo "Downloading the latest Rusk binary..."
#curl -so /opt/dusk/installer/rusk.tar.gz -L "$RUSK_URL"
#mkdir -p /opt/dusk/installer/rusk
#tar xf /opt/dusk/installer/rusk.tar.gz --directory /opt/dusk/installer/rusk
#mv /opt/dusk/installer/rusk/rusk /opt/dusk/bin/
chmod +x /opt/dusk/bin/rusk
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk

echo "Downloading the latest Rusk wallet..."
curl -so /opt/dusk/installer/wallet.tar.gz -L "$WALLET_URL"
mkdir -p /opt/dusk/installer/wallet
tar xf /opt/dusk/installer/wallet.tar.gz --strip-components 1 --directory /opt/dusk/installer/wallet
mv /opt/dusk/installer/wallet/rusk-wallet /opt/dusk/bin/
chmod +x /opt/dusk/bin/rusk-wallet
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet
mv -f /opt/dusk/conf/wallet.toml /root/.dusk/rusk-wallet/config.toml

echo "Downloading verifier keys"
curl -so /opt/dusk/installer/rusk-vd-keys.zip -L "$VERIFIER_KEYS_URL"
unzip -d /opt/dusk/rusk/ -o /opt/dusk/installer/rusk-vd-keys.zip
chown -R dusk:dusk /opt/dusk/

echo "Downloading state"
rm -rf /opt/dusk/rusk/state
rm -rf /opt/dusk/rusk/chain.db
curl -so  /opt/dusk/installer/86920.tar.gz -L "$LAST_STATE_URL"
tar -xvf /opt/dusk/installer/86920.tar.gz -C /opt/dusk/rusk/
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
ufw allow 9000:9005/udp

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
echo "To check the logs"
echo "tail -F /var/log/rusk.log"

rm -f /opt/dusk/installer/rusk.tar.gz
rm -f /opt/dusk/installer/installer.tar.gz
rm -f /opt/dusk/installer/wallet.tar.gz
rm -rf /opt/dusk/installer
