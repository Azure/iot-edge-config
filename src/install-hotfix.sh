#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install hotfix for percept related functions

######################################
# install_defender_hotfix
#
#    - Fix the system hang issue caused by Defender for IoT (defender-iot-micro-agent-edge)
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function install_defender_hotfix() {
    log_info "Installing defender hotfix ..."
    dpkg -i ${VERSION_ID}/dmidecode_3.3-4_arm64.deb 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "dmidecode_3.3-4: installation failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Installed defender hotfix"
}
