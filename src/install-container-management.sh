#!/usr/bin/env bash

source utils.sh
ensure_sudo

if [ -x "$(command -v docker)" ];
then
    echo "docker command is already available."
else
    log_info "Running install-container-management.sh"
        
    prepare_apt $1
    apt install moby-engine -y
fi
