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
#    updates the global variable OK_TO_CONTINUE in case of failure to false.
######################################

install_container_management() {
    if [ -x "$(command -v docker)" ];
    then
        log_info "docker command is already available."
    else
        log_info "Running install-container-management.sh"

        apt-get install moby-engine -y
        exit_code=$?
        if [[ $exit_code != 0 ]];
        then
            OK_TO_CONTINUE=false
            log_info "'apt-get install moby-engine' returned %d\n" $exit_code
        fi
    fi
}
