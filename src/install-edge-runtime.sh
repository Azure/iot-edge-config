#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install edge runtime 1.2

######################################
# install_edge_runtime
#
#    - installs Azure IoT Edge Runtime 1.2
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

function install_edge_runtime() {
    if [[ $# != 3 || "$1" == "" || "$2" == "" || "$3" == "" ]];
    then
        log_error "Scope ID, Registration ID, and the Symmetric Key are required"
        return
    fi

    if [ -x "$(command -v iotedge)" ];
    then
        log_error "Edge runtime is already available."
        return
    else
        log_info "install_edge_runtime..."
    fi

    apt-get install aziot-edge -y
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "'apt-get install aziot-edge' returned %d\n" $exit_code
        return
    fi

    # create .toml from template
    log_info "create .toml from template."
    cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "'cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml' returned %d\n" $exit_code
        return
    fi

    local SCOPE_ID=$1
    local REGISTRATION_ID=$2
    local SYMMETRIC_KEY=$3

    log_info "set '%s'; '%s'; '%s'" $SCOPE_ID $REGISTRATION_ID $SYMMETRIC_KEY
    sed -i '/## DPS provisioning with symmetric key/,/## DPS provisioning with X.509 certificate/c\
## DPS provisioning with symmetric key\
[provisioning]\
source = "dps"\
global_endpoint = "https://global.azure-devices-provisioning.net"\
id_scope = \"'$SCOPE_ID'\"\
\
[provisioning.attestation]\
method = "symmetric_key"\
registration_id = \"'$REGISTRATION_ID'\"\
\
symmetric_key = { value = \"'$SYMMETRIC_KEY'\" }                                                                         # inline key (base64), or...\
# symmetric_key = { uri = "file:///var/secrets/device-id.key" }                                                          # file URI, or...\
# symmetric_key = { uri = "pkcs11:slot-id=0;object=device%20id?pin-value=1234" }                                         # PKCS#11 URI\
\
## DPS provisioning with X.509 certificate\
    '  /etc/aziot/config.toml

    log_info "Apply settings - this will restart the edge"
    iotedge config apply

    OK_TO_CONTINUE=true
}
