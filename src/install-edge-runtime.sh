#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install edge runtime 1.2

# install Azure IoT Edge Runtime 1.2
install_edge_runtime() {
    apt-get install aziot-edge -y

    # create .toml from template
    log_info "create .toml from template."
    cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml

    SCOPE_ID=$1
    REGISTRATION_ID=$2
    SYMMETRIC_KEY=$3

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
}
