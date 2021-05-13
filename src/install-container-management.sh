#!/usr/bin/env bash

source utils.sh
ensure_sudo

prepare_apt $1

if [ -x "$(command -v docker)" ];
then
    echo "docker command is already available."
else
    log_info "Running install-container-management.sh"

    apt install moby-engine -y
fi
