#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

function is_service_running() {
    local retry_max=5
    local service_name=${1,,}

    for retry in $(seq 1 $retry_max)
    do

    local status=$(sudo iotedge system status)
    local iotedge_status=${status,,}

    service_status=$(awk '/'$service_name'/ {print $2}' <<< $iotedge_status)
    if [ "$service_status" != "running" ] && [ "$service_status" != "ready" ];
    then
        if [ $retry == $retry_max ];
        then
            log_error "'%s' is not running." $service_name
            log_error "Run these commands to gather additional logs:"
            log_error "sudo iotedge system logs"
            log_error "sudo iotedge check"
            return 1
        else
            # Wait 3 seconds and retry
            sleep 3
        fi
    else
        log_info "'%s' is running." $service_name
        return 0
    fi

    done
}

function is_percept_service_running() {
    local service_name=${1,,}

    sudo systemctl is-active --quiet $service_name
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_error "'%s' is not running." $service_name
        log_error "Run these commands to gather additional logs:"
        log_error "sudo systemctl status %s" $service_name
        return 1
    fi

    log_info "'%s' is running." $service_name
    return 0
}

######################################
# validate-post-install
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

function validate_post_install() {
    log_info "Post install validation starting."
    
    declare -a iotedge_services=("aziot-edged"
                                 "aziot-identityd"
                                 "aziot-keyd"
                                 "aziot-certd"
                                 "aziot-tpmd")

    for service_name in "${iotedge_services[@]}"
    do
        is_service_running $service_name
    done

    declare -a percept_services=("osconfig"
                                 "defender-iot-micro-agent")

    for service_name in "${percept_services[@]}"
    do
        is_percept_service_running $service_name
    done

    log_info "Post install validation completed."
}

######################################
# show_package_version
#
#    - Print the version of all installed packages
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function show_package_version() {
    log_info "Installed package version:"

    for package_name in "${percept_packages[@]}"
    do
        package_version=$(apt-cache policy $package_name | grep Installed | cut -d ' ' -f 4)
        log_info "  %s: %s" $package_name $package_version
    done
}

export -f validate_post_install show_package_version
