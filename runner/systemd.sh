#!/bin/bash


current_user() {
    echo "$(logname)"
}

current_home() {
    eval echo ~"$"
}

ensure_dusk_user_and_group_exist() {
    local CURRENT_USER=$(current_user)
    if ! id -u dusk >/dev/null 2>&1; then
        echo "Creating dusk system user and group."
        groupadd --system dusk
        useradd --system --create-home --shell /usr/sbin/nologin --gid dusk dusk
        echo "User 'dusk' and group 'dusk' created."
    fi

    echo "Adding current user to dusk group for access."
    if ! id -nG "$CURRENT_USER" | grep -qw "dusk"; then
        usermod -aG dusk "$CURRENT_USER"
        echo "User $CURRENT_USER has been added to the dusk group. Please log out and back in to apply changes."
    fi
}

stop_previous_services() {
    echo "Stopping previous services"
    if systemctl is-active --quiet rusk; then
        systemctl stop rusk
        echo "Stopped rusk service."
    else
        echo "Rusk service not running."
    fi
}

change_owner() {
    local user=$1
    local file_or_dir=$2
    chown -R "$user:dusk" "$file_or_dir"
}

setup_systemd() {
    # Set system parameters
    mv -f /opt/dusk/conf/dusk.conf /etc/sysctl.d/dusk.conf
    sysctl -p /etc/sysctl.d/dusk.conf

    echo "Installing services"
    # Overwrite previous service definitions
    mv -f /opt/dusk/services/rusk.service /etc/systemd/system/rusk.service

    # Configure logrotate (OS specific)
    configure_logrotate

    # Enable the Rusk service
    systemctl enable rusk
    systemctl daemon-reload
}

display_final_instructions() {
    cat /opt/dusk/installer/assets/finish.msg
}

link_download_state_bin() {
    local dest=$1
    ln -sf /opt/dusk/bin/systemd/download_state.sh $dest
}
