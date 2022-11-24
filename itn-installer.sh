#!/bin/sh
DUSK_BINARIES_URL="https://dusk-infra.ams3.digitaloceanspaces.com/rusk/itn-pack-binaries-linux.zip"
VERIFIER_KEYS_URL="https://dusk-infra.ams3.digitaloceanspaces.com/keys/vd-keys.zip"


check_installed() {
    binary_name=$1
    which $binary_name >/dev/null 2>&1
    if [ $? -eq 1 ]; then
        echo "Installing $binary_name"  
        apt install $binary_name -y
    fi
}


check_installed unzip
check_installed net-tools

mkdir -p /opt/dusk/installer

echo "Creating dusk service user"
id -u dusk >/dev/null 2>&1 || useradd -r dusk

curl -so /opt/dusk/installer/itn-pack-binaries-linux.zip "$DUSK_BINARIES_URL"
unzip -d /opt/dusk /opt/dusk/installer/itn-pack-binaries-linux.zip
chmod +x /opt/dusk/bin/detect_ips.sh

mkdir -p /opt/dusk/data/.rusk
mkdir -p /opt/dusk/data/chain

curl -so /opt/dusk/installer/vd-keys.zip "$VERIFIER_KEYS_URL"
unzip -d /opt/dusk/data/ /opt/dusk/installer/vd-keys.zip

mv /opt/dusk/services/dusk.service /etc/systemd/system/dusk.service
mv /opt/dusk/services/rusk.service /etc/systemd/system/rusk.service

systemctl enable dusk rusk
systemctl daemon-reload

echo "Dusk node installed"
echo "-----"
echo "To launch the node: "
echo "service rusk start;"
echo "service dusk start;"
echo "tail -F /var/log/{d,r}usk.{log,err}"

rm -rf /opt/dusk/installer