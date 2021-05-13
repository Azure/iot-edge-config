#!/usr/bin/env bash

source utils.sh
ensure_sudo

if [ -x "$(command -v docker)" ];
then
    echo "container is already installed"
else
    log_info "Running install-container-management.sh"

    prepare_apt
    apt install moby-engine -y
fi
