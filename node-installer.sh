#!/bin/bash
set -euo pipefail

declare -A VERSIONS
# Define versions per network, per component
VERSIONS=(
    ["mainnet-rusk"]="1.7.1"
    ["mainnet-rusk-wallet"]="0.3.0"
    ["testnet-rusk"]="1.7.1"
    ["testnet-rusk-wallet"]="0.4.0"
    ["devnet-rusk"]="1.7.0"
    ["devnet-rusk-wallet"]="0.4.0"
)

# Default network and feature (Provisioner node)
NETWORK="mainnet"
FEATURE="default"
TARGET_USER=""
DUSK_USER="dusk"
DUSK_GROUP="dusk"
INSTALLER_DIR="/opt/dusk/installer"
BUNDLE_DIR="$INSTALLER_DIR/bundle"
COMPONENTS_DIR="$INSTALLER_DIR/components"
STAGE_DIR="$INSTALLER_DIR/stage"
MAINNET_CONSENSUS_SPIN_TIME="1781175600"
TESTNET_CONSENSUS_SPIN_TIME="1779886800"

usage() {
    echo "Usage: $0 [--network mainnet|testnet|devnet] [--feature default|archive] [--user username]"
}

# Parse command-line arguments to check for network or feature flags
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --network)
            if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
                echo "Error: --network requires a value."
                usage
                exit 1
            fi
            NETWORK="$2"
            shift 2
            ;;
        --feature)
            if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
                echo "Error: --feature requires a value."
                usage
                exit 1
            fi
            FEATURE="$2"
            shift 2
            ;;
        --user)
            if [[ -z "${2:-}" || "${2:-}" == --* ]]; then
                echo "Error: --user requires a value."
                usage
                exit 1
            fi
            TARGET_USER="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ "$(id -u)" -ne 0 ]]; then
    echo "Error: The installer must be run as root, for example through sudo."
    exit 1
fi

if [[ -z "$TARGET_USER" && -n "${SUDO_USER:-}" && "${SUDO_USER:-}" != "root" ]]; then
    TARGET_USER="$SUDO_USER"
fi

if [[ -z "$TARGET_USER" ]]; then
    TARGET_USER="$(logname 2>/dev/null || true)"
fi

if [[ -z "$TARGET_USER" ]]; then
    TARGET_USER="$(id -un)"
fi

if ! id -u "$TARGET_USER" >/dev/null 2>&1; then
    echo "Error: Target user '$TARGET_USER' does not exist."
    exit 1
fi

CURRENT_USER="$TARGET_USER"
CURRENT_HOME="$(getent passwd "$CURRENT_USER" | cut -d: -f6)"

if [[ -z "$CURRENT_HOME" ]]; then
    echo "Error: Failed to determine home directory for target user '$CURRENT_USER'."
    exit 1
fi

echo "Selected target user: $CURRENT_USER"
echo "Home directory: $CURRENT_HOME"

# Validate passed network
case "$NETWORK" in
    mainnet|testnet|devnet)
        echo "Selected network: $NETWORK"
        ;;
    *)
        echo "Error: Unknown network $NETWORK. Use 'mainnet', 'testnet', or 'devnet'."
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

verify_component() {
    local component="$1"
    local version="$2"
    local bin_path="$3"
    local version_output

    if [[ ! -x "$bin_path" ]]; then
        echo "Error: Expected executable $bin_path was not found."
        exit 1
    fi

    version_output="$("$bin_path" --version 2>&1)" || {
        echo "Error: Failed to run $bin_path --version"
        echo "$version_output"
        exit 1
    }

    if [[ "$version_output" != *"$version"* ]]; then
        echo "Error: $component version check failed. Expected '$version', got '$version_output'."
        exit 1
    fi
}

# Downloads and verifies a given component for a given network.
install_component() {
    local network="$1"
    local component="$2"
    local key="${network}-${component}"
    local version="${VERSIONS[$key]:-}"

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

    local component_dir="$COMPONENTS_DIR/${component}"
    rm -rf "$component_dir"
    mkdir -p "$component_dir"

    curl -fLso "$COMPONENTS_DIR/${component}.tar.gz" "$url" || {
        echo "Failed to download $component from $url"
        exit 1
    }
    tar xf "$COMPONENTS_DIR/${component}.tar.gz" --strip-components 1 --directory "$component_dir" || {
        echo "Failed to extract $component archive"
        exit 1
    }
    chmod +x "$component_dir/$component"
    verify_component "$component" "$version" "$component_dir/$component"
}

# Configure a staged installation based on the selected network.
configure_network() {
    local network="$1"
    local conf_dir="$2"
    local service_file="$3"
    local wallet_config="$4"
    local prover_url

    if [[ -f "$service_file" ]]; then
        sed -i '/^Environment="RUSK_CONSENSUS_SPIN_TIME=/d' "$service_file"
    fi

    case "$network" in
        mainnet)
            mv "$conf_dir/mainnet.genesis" "$conf_dir/genesis.toml"
            mv "$conf_dir/mainnet.toml" "$conf_dir/rusk.toml"
            rm -f "$conf_dir/testnet.genesis"
            rm -f "$conf_dir/testnet.toml"
            rm -f "$conf_dir/devnet.genesis"
            rm -f "$conf_dir/devnet.toml"
            if [[ -f "$service_file" ]]; then
                sed -i "/^Environment=\"RUSK_RECOVERY_INPUT=/a Environment=\"RUSK_CONSENSUS_SPIN_TIME=$MAINNET_CONSENSUS_SPIN_TIME\"" "$service_file"
            fi
            prover_url="https://provers.dusk.network"
            ;;
        testnet)
            mv "$conf_dir/testnet.genesis" "$conf_dir/genesis.toml"
            mv "$conf_dir/testnet.toml" "$conf_dir/rusk.toml"
            rm -f "$conf_dir/mainnet.genesis"
            rm -f "$conf_dir/mainnet.toml"
            rm -f "$conf_dir/devnet.genesis"
            rm -f "$conf_dir/devnet.toml"
            if [[ -f "$service_file" ]]; then
                sed -i "/^Environment=\"RUSK_RECOVERY_INPUT=/a Environment=\"RUSK_CONSENSUS_SPIN_TIME=$TESTNET_CONSENSUS_SPIN_TIME\"" "$service_file"
            fi
            prover_url="https://testnet.provers.dusk.network"
            ;;
        devnet)
            mv "$conf_dir/devnet.genesis" "$conf_dir/genesis.toml"
            mv "$conf_dir/devnet.toml" "$conf_dir/rusk.toml"
            rm -f "$conf_dir/mainnet.genesis"
            rm -f "$conf_dir/mainnet.toml"
            rm -f "$conf_dir/testnet.genesis"
            rm -f "$conf_dir/testnet.toml"
            prover_url="https://devnet.provers.dusk.network"
            ;;
        *)
            echo "Unknown network: $network. Defaulting to mainnet."
            configure_network "mainnet" "$conf_dir" "$service_file" "$wallet_config"
            return
            ;;
    esac

    sed -i "s|^prover = .*|prover = \"$prover_url\"|" "$wallet_config"
}

install_staged_files() {
    install -d -o root -g "$DUSK_GROUP" -m 751 /opt/dusk
    install -d -o root -g root -m 755 /opt/dusk/bin
    install -d -o root -g "$DUSK_GROUP" -m 750 /opt/dusk/conf
    install -d -o root -g "$DUSK_GROUP" -m 750 /opt/dusk/services
    install -d -o "$DUSK_USER" -g "$DUSK_GROUP" -m 770 /opt/dusk/rusk

    for bin_file in "$STAGE_DIR/bin"/*; do
        install -o root -g root -m 755 "$bin_file" "/opt/dusk/bin/$(basename "$bin_file")"
    done

    install -o root -g root -m 755 "$COMPONENTS_DIR/rusk/rusk" /opt/dusk/bin/rusk
    install -o root -g root -m 755 "$COMPONENTS_DIR/rusk-wallet/rusk-wallet" /opt/dusk/bin/rusk-wallet

    for conf_file in "$STAGE_DIR/conf"/*; do
        case "$(basename "$conf_file")" in
            dusk.conf|wallet.toml)
                continue
                ;;
        esac
        install -o root -g "$DUSK_GROUP" -m 660 "$conf_file" "/opt/dusk/conf/$(basename "$conf_file")"
    done

    for service_file in "$STAGE_DIR/services"/*; do
        case "$(basename "$service_file")" in
            rusk.conf.user)
                if [[ ! -f /opt/dusk/services/rusk.conf.user ]]; then
                    install -o root -g root -m 600 "$service_file" /opt/dusk/services/rusk.conf.user
                else
                    chown root:root /opt/dusk/services/rusk.conf.user
                    chmod 600 /opt/dusk/services/rusk.conf.user
                fi
                ;;
            rusk.conf.default)
                install -o root -g root -m 600 "$service_file" /opt/dusk/services/rusk.conf.default
                ;;
            rusk.service)
                install -o root -g root -m 644 "$service_file" /opt/dusk/services/rusk.service
                install -o root -g root -m 644 "$service_file" /etc/systemd/system/rusk.service
                ;;
            logrotate.conf)
                install -o root -g root -m 644 "$service_file" /opt/dusk/services/logrotate.conf
                ;;
            *)
                install -o root -g "$DUSK_GROUP" -m 660 "$service_file" "/opt/dusk/services/$(basename "$service_file")"
                ;;
        esac
    done

    if [[ ! -f /opt/dusk/services/dusk.conf ]]; then
        install -o root -g root -m 600 /dev/null /opt/dusk/services/dusk.conf
    else
        chown root:root /opt/dusk/services/dusk.conf
        chmod 600 /opt/dusk/services/dusk.conf
    fi

    install -d -o "$CURRENT_USER" -g "$DUSK_GROUP" -m 770 "$CURRENT_HOME/.dusk"
    install -d -o "$CURRENT_USER" -g "$DUSK_GROUP" -m 770 "$CURRENT_HOME/.dusk/rusk-wallet"
    install -o "$CURRENT_USER" -g "$DUSK_GROUP" -m 660 "$STAGE_DIR/conf/wallet.toml" "$CURRENT_HOME/.dusk/rusk-wallet/config.toml"

    install -o root -g root -m 644 "$STAGE_DIR/conf/dusk.conf" /etc/sysctl.d/dusk.conf
    chown -R "$DUSK_USER:$DUSK_GROUP" /opt/dusk/rusk
    chmod -R u+rwX,g+rwX,o-rwx /opt/dusk/rusk
}

# Check for OpenSSL 3 or higher
if ! command -v openssl >/dev/null 2>&1 || [[ "$(openssl version | awk '{print $2}' | cut -d. -f1)" -lt 3 ]]; then
    echo "The required OpenSSL version is not available. Please install OpenSSL 3 or higher"
    echo "You likely need to upgrade your OS or install a newer OS"
    exit 1
fi

# Ensure Dusk service group and user exist before setting file ownership
if ! getent group "$DUSK_GROUP" >/dev/null 2>&1; then
    echo "Creating $DUSK_GROUP system group."
    groupadd --system "$DUSK_GROUP"
fi

if ! id -u "$DUSK_USER" >/dev/null 2>&1; then
    echo "Creating $DUSK_USER system user."
    useradd --system --create-home --shell /usr/sbin/nologin --gid "$DUSK_GROUP" "$DUSK_USER"
    echo "User '$DUSK_USER' created."
fi

# Cleanup previous installer just in case
rm -rf "$INSTALLER_DIR" || true
install -d -o root -g root -m 700 "$BUNDLE_DIR"
install -d -o root -g root -m 700 "$COMPONENTS_DIR"
install -d -o root -g root -m 700 "$STAGE_DIR"

# Download and extract installer files before touching the live installation.
INSTALLER_URL="https://github.com/dusk-network/node-installer/archive/refs/tags/v0.5.22.tar.gz"
echo "Downloading installer package for additional scripts and configurations"
curl -fLso "$INSTALLER_DIR/installer.tar.gz" "$INSTALLER_URL" || {
    echo "Failed to download installer package from $INSTALLER_URL"
    exit 1
}
tar xf "$INSTALLER_DIR/installer.tar.gz" --strip-components 1 --directory "$BUNDLE_DIR" || {
    echo "Failed to extract installer package"
    exit 1
}

# Detect and source OS logic
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    distro="$(echo "$ID" | tr '[:upper:]' '[:lower:]')"
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

OS_SCRIPT="$BUNDLE_DIR/os/$distro.sh"
if [[ -f "$OS_SCRIPT" ]]; then
    echo "Using OS support script: $OS_SCRIPT"
    # shellcheck source=/dev/null
    source "$OS_SCRIPT"
else
    echo "No support script found for '$distro'"
    echo "Want to add support? See: https://github.com/dusk-network/node-installer#contributing-os-support"
    exit 1
fi

echo "Update package db and install prerequisites."
install_deps

echo "Adding target user to $DUSK_GROUP group for access."
if ! id -nG "$CURRENT_USER" | grep -qw "$DUSK_GROUP"; then
    usermod -aG "$DUSK_GROUP" "$CURRENT_USER"
    echo "User $CURRENT_USER has been added to the $DUSK_GROUP group. Please log out and back in to apply changes."
fi

# Download, unpack, and verify binaries before changing the live install.
install_component "$NETWORK" "rusk"
install_component "$NETWORK" "rusk-wallet"

install -d -o root -g root -m 700 "$STAGE_DIR/bin"
install -d -o root -g root -m 700 "$STAGE_DIR/conf"
install -d -o root -g root -m 700 "$STAGE_DIR/services"
cp -a "$BUNDLE_DIR/bin/." "$STAGE_DIR/bin/"
cp -a "$BUNDLE_DIR/conf/." "$STAGE_DIR/conf/"
cp -a "$BUNDLE_DIR/services/." "$STAGE_DIR/services/"

echo "Selected network: $NETWORK"
configure_network "$NETWORK" "$STAGE_DIR/conf" "$STAGE_DIR/services/rusk.service" "$STAGE_DIR/conf/wallet.toml"

echo "Stopping previous services"
if systemctl is-active --quiet rusk; then
    systemctl stop rusk
    echo "Stopped rusk service."
else
    echo "Rusk service not running."
fi

install_staged_files

# Symlink to make available system-wide
ln -sf /opt/dusk/bin/rusk /usr/bin/rusk
ln -sf /opt/dusk/bin/ruskquery /usr/bin/ruskquery
ln -sf /opt/dusk/bin/ruskreset /usr/bin/ruskreset
ln -sf /opt/dusk/bin/rusk-wallet /usr/bin/rusk-wallet
if [[ "$NETWORK" == "devnet" ]]; then
    if [[ -L /usr/bin/download_state && "$(readlink /usr/bin/download_state)" == "/opt/dusk/bin/download_state.sh" ]]; then
        rm -f /usr/bin/download_state
    elif [[ -e /usr/bin/download_state ]]; then
        echo "Leaving unmanaged /usr/bin/download_state in place; devnet fast sync is not available."
    fi
fi
if [[ "$NETWORK" == "mainnet" || "$NETWORK" == "testnet" ]]; then
    ln -sf /opt/dusk/bin/download_state.sh /usr/bin/download_state
fi

# Set system parameters
sysctl -p /etc/sysctl.d/dusk.conf

# Configure logrotate (OS specific)
configure_logrotate

# Enable the Rusk service
systemctl enable rusk
systemctl daemon-reload

# Display final instructions
cat "$BUNDLE_DIR/assets/finish.msg"

rm -rf "$INSTALLER_DIR"
