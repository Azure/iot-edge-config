#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to install percept related packages

######################################
# install_osconfig
#
#    - Install OSConfig
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function install_osconfig() {
    # OSConfig
    log_info "Installing osconfig..."
    apt-get install -o Dpkg::Options::="--force-confdef" osconfig="${package_versions[2]}" -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "osconfig installation failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Installed osconfig"
}

######################################
# install_defender
#
#    - Install Defender for IoT (defender-iot-micro-agent-edge)
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function install_defender() {
    # Defender for IoT
    log_info "Installing defender..."
    apt-get install -o Dpkg::Options::="--force-confdef" defender-iot-micro-agent-edge="${package_versions[3]}" -y 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
    long_running_command $!
    exit_code=$?
    if [[ $exit_code != 0 ]];
    then
        log_info "defender installation failed with exit code: %d" $exit_code
        exit ${EXIT_CODES[10]}
    fi
    log_info "Installed defender"
}

######################################
# configure_percept_services
#
#    - Fix the warning and error messages from 'iotedge check' command
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    updates the global variable OK_TO_CONTINUE in case of success to true.
######################################

function configure_percept_services() {
    log_info "Set Docker default parameters"
    local FILE_NAME="/etc/docker/daemon.json"
    local existing_item=""

    if [ ! -f $FILE_NAME ];
    then
        log_info "Create $FILE_NAME"
        # create a docker daemon.json
        echo '{' > $FILE_NAME
        echo '    "dns": ["1.1.1.1", "8.8.8.8"],' >> $FILE_NAME
        echo '    "log-driver": "json-file",' >> $FILE_NAME
        echo '    "log-opts": {' >> $FILE_NAME
        echo '        "max-size": "10m",' >> $FILE_NAME
        echo '        "max-file": "3"' >> $FILE_NAME
        echo '    }' >> $FILE_NAME
        echo '}' >> $FILE_NAME
        chmod 644 $FILE_NAME
    else
        # Log Driver & Options
        existing_item="$(grep log-driver $FILE_NAME)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Add Log driver & options to $FILE_NAME"
            sed -i '1 a\
    "log-driver": "json-file",\
    "log-opts": {\
        "max-size": "10m",\
        "max-file": "3"\
    },' $FILE_NAME
        fi

        # DNS
        existing_item="$(grep dns $FILE_NAME)"
        if [ "x$existing_item" == "x" ];
        then
            log_info "Add DNS to $FILE_NAME"
            sed -i '1 a\
    "dns": ["1.1.1.1", "8.8.8.8"],' $FILE_NAME
        fi
    fi
}
