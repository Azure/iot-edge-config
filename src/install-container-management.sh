#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################
# install_container_management
#
#    installs moby-engine docker container management if needed.
# ARGUMENTS:
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

install_container_management() {
    if [ -x "$(command -v docker)" ];
    then
        log_info "docker command is already available."
    else
        log_info "Running install-container-management.sh"

        apt install moby-engine -y
    fi
}
