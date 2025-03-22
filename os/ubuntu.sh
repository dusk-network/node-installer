#!/bin/bash

install_deps() {
    echo "Updating package database..."
    apt update

    declare -a packages=("unzip" "curl" "net-tools" "ipcalc" "jq" "logrotate")
    for pkg in "${packages[@]}"; do
        if ! command -v "$pkg" >/dev/null 2>&1; then
            echo "Installing missing dependency: $pkg"
            NEEDRESTART_MODE=a apt install -y "$pkg"
        else
            echo "$pkg is already installed."
        fi
    done
}

configure_logrotate() {
    echo "Configuring logrotate for Dusk"
    cp -f /opt/dusk/services/logrotate.conf /etc/logrotate.d/dusk.conf
    chown root:root /etc/logrotate.d/dusk.conf
    chmod 644 /etc/logrotate.d/dusk.conf
}
