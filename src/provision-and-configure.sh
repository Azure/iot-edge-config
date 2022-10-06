#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to provision & configure

######################################
# setup_product_info
#
#    - Write OS Variant, Manufacturer & Product Name into /etc/product-info.toml
#    - If the file exists AND the key name os_variant exists, do nothing
#    - Add additional_info into /etc/aziot/config.toml.edge.template
#
# ARGUMENTS:
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function setup_product_info() {
    local PRODUCT_INFO_FILE="/etc/product-info.toml"
    local os_varient="operating_system_variant"
    local varient_mark="eai_installer"
    local existing_item=""

    if [ ! -f $PRODUCT_INFO_FILE ];
    then
        log_info "Create $PRODUCT_INFO_FILE"
        touch $PRODUCT_INFO_FILE
        chmod 644 $PRODUCT_INFO_FILE

        echo "${os_varient}=\"${varient_mark}\"" > $PRODUCT_INFO_FILE
        echo "product_name=\"$(get_product_name)\"" >> $PRODUCT_INFO_FILE
        echo "system_vendor=\"$(get_manufacturer)\"" >> $PRODUCT_INFO_FILE
    else
        # OS Varient
        existing_item="$(grep $os_varient $PRODUCT_INFO_FILE)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Write ${os_varient} to $PRODUCT_INFO_FILE"
            echo "${os_varient}=\"${varient_mark}\"" >> $PRODUCT_INFO_FILE
        fi
        # Product Name
        existing_item="$(grep product_name $PRODUCT_INFO_FILE)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Write product_name to $PRODUCT_INFO_FILE"
            echo "product_name=\"$(get_product_name)\"" >> $PRODUCT_INFO_FILE
        fi
        # Manufacturer
        existing_item="$(grep system_vendor $PRODUCT_INFO_FILE)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Write system_vendor to $PRODUCT_INFO_FILE"
            echo "system_vendor=\"$(get_manufacturer)\"" >> $PRODUCT_INFO_FILE
        fi
    fi

    local TEMPLATE_TOML_FILE="/etc/aziot/config.toml.edge.template"
    if [ -f $TEMPLATE_TOML_FILE ];
    then
        existing_item="$(grep additional_info $TEMPLATE_TOML_FILE)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Update $TEMPLATE_TOML_FILE"
            sed -i '/parent_hostname/ a\
\n\
# ==============================================================================\
# Additional information\
# ==============================================================================\
#\
# Uncomment the next line to override the system information from /etc/os-release\
#\
additional_info = "file:///etc/product-info.toml"' $TEMPLATE_TOML_FILE
        fi
    fi
}

######################################
# stop_iotedge_service
#
#    - Stop iotedge services before we do provisioning
#
# ARGUMENTS:
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function stop_iotedge_service()
{
    local status=$(sudo iotedge system status | grep -i running)

    if [ "$status" != "" ]; then
        log_info "Stop iotedge services ..."
        iotedge system stop 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
        long_running_command $!
    fi
}

######################################
# setup_hostname
#
#    - Get hostname from either given value, connnection string or DPS registration id.
#    - Update device hostname
#    - Remove existing containers with old hostname
#
# ARGUMENTS:
#    HOSTNAME
#    CONNECTION_STRING or REGISTRATION_ID
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function setup_hostname() {
    if [[ $# == 2 && "$1" != "" && "$2" != "" ]];
    then
        local NEW_HOSTNAME=$1
        # get hostname from connection string or DPS registration id
        if [[ "$1" == "true" ]];
        then
            NEW_HOSTNAME=$2
            if [[ "$2" != *"DeviceId="* ]];
            then
                log_info "Assign DPS registration id (${NEW_HOSTNAME}) as hostname"
            else
                local DEVICE_ID=${NEW_HOSTNAME#*;DeviceId=}
                NEW_HOSTNAME=${DEVICE_ID%;SharedAccessKey=*}
                log_info "Assign Device ID (${NEW_HOSTNAME}) as hostname"
            fi
        else
            log_info "New hostname: ${NEW_HOSTNAME}"
        fi

        # update device's hostname
        log_info "Update device hostname..."
        local OLD_HOSTNAME=`hostname`
        hostnamectl set-hostname $NEW_HOSTNAME 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
        sed -i "s/${OLD_HOSTNAME}/${NEW_HOSTNAME}/g" /etc/hosts 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
        sudo systemctl restart avahi-daemon.service 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT

        log_info "Device hostname is set completely"

        # remove the containers with old hostname
        if [[ "x$(docker ps -aq -f name=edgeHub -f name=edgeAgent)" != "x" ]];
        then
            log_info "Remove existing containers: edgeHub, edgeAgent"
            docker rm -f $(docker ps -aq -f name=edgeHub -f name=edgeAgent) 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
        fi
    fi
}

######################################
# dps_provisioning
#
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

function dps_provisioning() {
    if [[ $# != 3 || "$1" == "" || "$2" == "" || "$3" == "" ]];
    then
        log_error "Scope ID, Registration ID, and the Symmetric Key are required"
        exit ${EXIT_CODES[2]}
    fi

    # create config.toml
    log_info "Create instance configuration 'config.toml'."

    local SCOPE_ID=$1
    local REGISTRATION_ID=$2
    local SYMMETRIC_KEY=$3

    log_info "Set DPS provisioning parameters."

    local FILE_NAME="/etc/aziot/config.toml"

    # create a config.toml - will replace existing
    echo 'hostname = "'`hostname`'"' > $FILE_NAME
    echo 'additional_info = "file:///etc/product-info.toml"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo '## DPS provisioning with symmetric key' >> $FILE_NAME
    echo '[provisioning]' >> $FILE_NAME
    echo 'source = "dps"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo 'global_endpoint = "https://global.azure-devices-provisioning.net"' >> $FILE_NAME
    echo 'id_scope = "'$SCOPE_ID'"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo '[provisioning.attestation]' >> $FILE_NAME
    echo 'method = "symmetric_key"' >> $FILE_NAME
    echo 'registration_id = "'$REGISTRATION_ID'"' >> $FILE_NAME
    echo '' >> $FILE_NAME
    echo 'symmetric_key = { value = "'$SYMMETRIC_KEY'" }' >> $FILE_NAME
    echo '' >> $FILE_NAME

    log_info "Apply settings - this will restart the edge"
    iotedge config apply 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
    exit_code=$?
    if [[ $exit_code == 0 ]];
    then
        log_info "IotEdge has been configured successfully"
    else
        log_error "Cannot apply config! Please check ${BOLD}$STDERR_REDIRECT${DEFAULT} for details"
        exit ${EXIT_CODES[2]}
    fi
}

######################################
# cs_provisioning
#
#    - get the connection string from provided parameters and
#      run 'iotedge config' commands to apply the connection string
#
# ARGUMENTS:
#    CONNECTION_STRING
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function cs_provisioning() {
    if [[ $# != 1 || "$1" == "" ]];
    then
        log_error "Connection string is required"
        exit ${EXIT_CODES[2]}
    fi

    if [[ "$1" != *"HostName"* || "$1" != *"DeviceId"* || "$1" != *"SharedAccessKey"* ]];
    then
        log_error "Connection string is invalid! Make sure the connection string includes 'HostName', 'DeviceId' & 'SharedAccessKey' keywords or check if double quotes (\"\") are used as parameters!"
        exit ${EXIT_CODES[2]}
    fi

    log_info "Assign connection string to the config file"
    iotedge config mp --force --connection-string $1 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT

    log_info "Write configurations to config.toml"
    local FILE_NAME="/etc/aziot/config.toml"
    sed -i "1 a hostname = \"`hostname`\"" $FILE_NAME
    sed -i "2 a additional_info = \"file:///etc/product-info.toml\"" $FILE_NAME

    log_info "Apply settings - this will restart the edge"
    iotedge config apply 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
    exit_code=$?
    if [[ $exit_code == 0 ]];
    then
        log_info "IotEdge has been configured successfully"
    else
        log_error "Cannot apply config! Please check ${BOLD}$STDERR_REDIRECT${DEFAULT} for details"
        exit ${EXIT_CODES[2]}
    fi
}

######################################
# reset_percept_services
#
#    - restart docker and percept specific services
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function reset_percept_services() {
    log_info "Restart docker service ..."
    sudo systemctl restart docker 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
    exit_code=$?
    if [[ $exit_code == 0 ]];
    then
        log_info "Docker has been configured successfully"
    fi

    log_info "Restart osconfig service"
    sudo systemctl restart osconfig.service

    log_info "Restart defender service"
    sudo systemctl restart defender-iot-micro-agent.service
}
