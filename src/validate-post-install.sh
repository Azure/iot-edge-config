#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###################################### 
# validate-post-install.sh
# 
# Utility function to check if the IoT Edgre Runtime local services are running
# ARGUMENTS:
#    Service name
#    "sudo iotedge system status" output
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    0 if service is running, 1 otherwise
######################################
source utils.sh

function is_service_running() {
    local service_name=${1,,}
    local iotedge_status=${2,,}

    service_status=$(awk '/'$service_name'/ {print $2}' <<< $iotedge_status)
    if [ "$service_status" != "running" ] && [ "$service_status" != "ready" ];
    then
        log_error "'%s' is not running." $service_name
        log_error "Run these commands to gather additional logs:"
        log_error "sudo iotedge system logs"
        log_error "sudo iotedge check"
        echo false
    fi

    log_info "'%s' is running." $service_name
	echo true
}

function validate_post_install() {
    log_info "Post install validation starting."
    local status=$(sudo iotedge system status)
    
    declare -a iotedge_services=("aziot-edged"
                                 "aziot-identityd"
                                 "aziot-keyd"
                                 "aziot-certd"
                                 "aziot-tpmd")

    for service_name in "${iotedge_services[@]}"
    do
        is_service_running $service_name "$status"
    done

    log_info "Post install validation completed."
}

export -f validate_post_install
