#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install edge runtime 1.2

######################################
# apply_config_changes
#
#    - apply changes and restart
#
# ARGUMENTS:
# OUTPUTS:
#    Write output to stdout
# RETURN:
######################################

function apply_config_changes() {
    log_info "Apply settings - this will restart Azure IoTEdge"
    iotedge config apply 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
    exit_code=$?
    if [[ $exit_code == 0 ]];
    then
        log_info "IoTEdge has been configured successfully"
    fi
}

######################################
# install_common
#
#    - install the runtime
#
# ARGUMENTS:
# OUTPUTS:
#    Write output to stdout
# RETURN:
######################################

function install_common() {
    log_info "Installing edge runtime..."

    apt-get install aziot-edge -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "aziot-edged installation failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Installed edge runtime..."
}

######################################
# install_edge_runtime_dps
#
#    - installs Azure IoT Edge Runtime 1.2, DPS provisioning
#    - generates the edge's configuration file from template and
#      fills in the DPS provisioning section from provided parameters
#
# ARGUMENTS:
#    SCOPE_ID
#    REGISTRATION_ID
#    SYMMETRIC_KEY
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function install_edge_runtime_dps() {
    if [[ $# != 3 || "$1" == "" || "$2" == "" || "$3" == "" ]];
    then
        log_error "Scope ID, Registration ID, and the Symmetric Key are required"
        exit ${EXIT_CODES[2]}
    fi

    if [ -x "$(command -v iotedge)" ];
    then
        out=$(which docker)
        log_error "Edge runtime is already available at %s." $out
        exit ${EXIT_CODES[9]}
    fi

    install_common

    # create config.toml
    log_info "Create instance configuration 'config.toml'."

    local SCOPE_ID=$1
    local REGISTRATION_ID=$2
    local SYMMETRIC_KEY=$3

    log_info "Set DPS provisioning parameters."

    local FILE_NAME="/etc/aziot/config.toml"

    # create a config.toml - will replace existing
    echo 'hostname = "'`hostname`'"' > $FILE_NAME
    echo '' >> $FILE_NAME
    echo '## DPS provisioning with symmetric key' >> $FILE_NAME
    echo '[provisioning]' >> $FILE_NAME
    echo 'source = "dps"' >> $FILE_NAME
    echo 'global_endpoint = "https://global.azure-devices-provisioning.net"' >> $FILE_NAME
    echo 'id_scope = "'$SCOPE_ID'"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo '[provisioning.attestation]' >> $FILE_NAME
    echo 'method = "symmetric_key"' >> $FILE_NAME
    echo 'registration_id = "'$REGISTRATION_ID'"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo 'symmetric_key = { value = "'$SYMMETRIC_KEY'" }' >> $FILE_NAME
    echo '' >> $FILE_NAME

    apply_config_changes
}

######################################
# install_edge_runtime_cs
#
#    - installs Azure IoT Edge Runtime 1.2
#    - generates the edge's configuration file from template and
#      fills in the manual provisioning section from provided parameters
#
# ARGUMENTS:
#    CONNECTION_STRING
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function install_edge_runtime_cs() {
    if [[ $# != 1 || "$1" == "" ]];
    then
        log_error "IoTEdge Device Connection string is required"
        exit ${EXIT_CODES[2]}
    fi

    if [ "x$(command -v iotedge)" != "x" ];
    then
        log_error "Edge runtime is already available at ${BOLD}'%s'${DEFAULT}." $(which iotedge)
        exit ${EXIT_CODES[9]}
    fi

    install_common

    # create config.toml
    log_info "Create instance configuration 'config.toml'."

    local CONNECTION_STRING=$1

    log_info "Set manual provisioning parameters."

    local FILE_NAME="/etc/aziot/config.toml"

    # create a config.toml - will replace existing
    echo 'hostname = "'`hostname`'"' > $FILE_NAME
    echo '' >> $FILE_NAME
    echo '## Manual provisioning configuration' >> $FILE_NAME
    echo '[provisioning]' >> $FILE_NAME
    echo 'source = "manual"' >> $FILE_NAME
    echo 'connection_string = "'$CONNECTION_STRING'"' >> $FILE_NAME
    echo '' >> $FILE_NAME

    apply_config_changes
}
