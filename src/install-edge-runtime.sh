#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install edge runtime 1.2

######################################
# remove_packages
#
#    - Remove the installed packages including of
#      * IoTEdge
#      * OSConfig
#      * Defender for IoT
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function remove_packages() {
    log_info "Removing installed packages..."

    apt-get remove --purge ${percept_packages[@]} -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "apt remove failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Removed all packages"
}

######################################
# install_edge_runtime
#
#    - installs Azure IoT Edge Runtime 1.2
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function install_edge_runtime() {
    if [ "x$(command -v iotedge)" != "x" ];
    then
        log_warn "Edge runtime is already available."

        if [[ "${parsed_cmds["FORCE_RUN"]}" == "" ]];
        then
            read -p "Do you want to install again? [Y/n] " ans
            if [ ${ans^} == 'Y' ];
            then
                remove_packages
            else
                exit ${EXIT_CODES[9]}
            fi
        else
            log_info "Force to run the installation!"
            remove_packages
        fi
    fi

    log_info "Installing edge runtime..."

    apt-get install -o Dpkg::Options::="--force-confdef" aziot-identity-service="${package_versions[0]}" aziot-edge="${package_versions[1]}" -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "aziot-edged installation failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Installed edge runtime..."
}
