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
    if [ "x$(command -v docker)" != "x" ];
    then
        log_info "docker command is already available."
    else
        log_info "Installing moby-engine container management"

        apt-get install moby-engine -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
        long_running_command $!
        exit_code=$?
        if [[ $exit_code != 0 ]];
        then
            log_info "moby-engine installation failed with code: %d" $exit_code
            exit ${EXIT_CODES[8]}
        fi
        log_info "Installed moby-engine container management"
    fi
}
