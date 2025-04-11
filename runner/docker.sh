#!/bin/bash

current_user() {
    # In the Docker container, the root user is always used.
    echo "root"
}

current_home() {
    echo "/root"
}

ensure_dusk_user_and_group_exist() {
    # This is a no-op because in the Docker container, no dusk user
    # or group is created.
    true
}

stop_previous_services() {
    # No-op because we can't determine which name the user may have
    # run a container with previously.
    true
}

change_owner() {
    # No-op because the root is the only user
    # and already has all required permissions.
    true
}

setup_systemd() {
    # No-op since Docker is already being used.
    true
}

display_final_instructions() {
    # Since the node-installer is run during Docker build, the instructions
    # to be taken next will be in the README instead.
    true
}

link_download_state_bin() {
    local dest=$1
    ln -sf /opt/dusk/bin/docker/download_state.sh $dest
}
