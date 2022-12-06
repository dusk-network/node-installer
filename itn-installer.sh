#!/bin/sh
PACKER_SOURCE_URL="https://github.com/dusk-network/itn-installer/archive/refs/tags/v0.0.3.tar.gz"
VERIFIER_KEYS_URL="https://dusk-infra.ams3.digitaloceanspaces.com/keys/vd-keys.zip"
WALLET_URL="https://github.com/dusk-network/wallet-cli/releases/download/v0.13.0/ruskwallet0.13.0-linux-x64-libssl3.tar.gz"


check_installed() {
    binary_name=$1
    package_name=$2
    which $binary_name >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "$binary_name missing"
        echo "Installing $package_name"  
        apt install $package_name -y
    fi
}

echo "Checking prerequisites"
check_installed unzip unzip
check_installed route net-tools
check_installed logrotate logrotate

echo "Creating dusk service user"
id -u dusk >/dev/null 2>&1 || useradd -r dusk


mkdir -p /opt/dusk/bin
mkdir -p /opt/dusk/conf
mkdir -p /opt/dusk/data
mkdir -p /opt/dusk/services
mkdir -p /opt/dusk/installer

echo "Downloading packages"
curl -so /opt/dusk/installer.tar.gz -L "$PACKER_SOURCE_URL"
tar xf /opt/dusk/installer.tar.gz --strip-components 1 --directory /opt/dusk/installer

# Overwrite previous binary
mv -f /opt/dusk/installer/bin/* /opt/dusk/bin/
# Don't overwrite previous binary conf
mv -n /opt/dusk/installer/conf/* /opt/dusk/conf/
# Don't overwrite previous services conf
mv -n /opt/dusk/installer/services/* /opt/dusk/services/

chmod +x /opt/dusk/bin/detect_ips.sh
chmod +x /opt/dusk/bin/check_consensuskeys.sh

mkdir -p /opt/dusk/data/.rusk
mkdir -p /opt/dusk/data/chain

echo "Downloading verifier keys"
curl -so /opt/dusk/installer/vd-keys.zip -L "$VERIFIER_KEYS_URL"
unzip -d /opt/dusk/data/ -o /opt/dusk/installer/vd-keys.zip


echo "Installing services"
# Overwrite previous service definitions
mv -f /opt/dusk/services/dusk.service /etc/systemd/system/dusk.service
mv -f /opt/dusk/services/rusk.service /etc/systemd/system/rusk.service
mv -f /opt/dusk/services/logrotate.conf /etc/logrotate.d/dusk.conf

systemctl enable dusk rusk
systemctl daemon-reload

echo "Installing wallet"

curl -so /opt/dusk/installer/wallet.tar.gz -L "$WALLET_URL"
mkdir -p /opt/dusk/installer/wallet
tar xf  /opt/dusk/installer/wallet.tar.gz --strip-components 1 --directory /opt/dusk/installer/wallet
mv /opt/dusk/installer/wallet/rusk-wallet /opt/dusk/bin/
chmod +x /opt/dusk/bin/rusk-wallet
ln -s /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet

mkdir -p ~/.dusk/rusk-wallet/
mv /opt/dusk/conf/wallet.toml ~/.dusk/rusk-wallet/config.toml

echo "Setup local firewall"
ufw allow 9000:9005/udp

echo "Dusk node installed"
echo "-----"
echo "Prerequisites for launching:"
echo "1. Provide CONSENSUS_KEYS file"
echo "2. Set DUSK_CONSENSUS_KEYS_PASS"
echo
echo "-----"
echo "To launch the node: "
echo "service rusk start;"
echo "service dusk start;"
echo
echo "To run the Rusk wallet:"
echo "rusk-wallet;"
echo 
echo "To check the logs"
echo "tail -F /var/log/{d,r}usk.{log,err}"

rm -f /opt/dusk/installer.tar.gz
rm -rf /opt/dusk/installer
