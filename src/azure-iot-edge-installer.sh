#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


# where am i
TOPDIR=$(dirname $0)

# import utils
source $TOPDIR/utils.sh
ensure_sudo "$@"
log_init

VERSION_TAG="v0.0.0-rc0"

# add flag:variable_name dictionary entries
add_option_args -v "VERBOSE_LOGGING"
add_option_args --verbose "VERBOSE_LOGGING"
add_option_args -dp "DEVICE_PROVISIONING"
add_option_args --device-provisioning "DEVICE_PROVISIONING"
add_option_args -ap "AZURE_CLOUD_IDENTITY_PROVIDER"
add_option_args --azure-cloud-identity-provider "AZURE_CLOUD_IDENTITY_PROVIDER"
add_option_args -s "SCOPE_ID"
add_option_args --scope-id "SCOPE_ID"
add_option_args -r "REGISTRATION_ID"
add_option_args --registration-id "REGISTRATION_ID"
add_option_args -k "SYMMETRIC_KEY"
add_option_args --symmetric-key "SYMMETRIC_KEY"

# parse command line inputs and fetch output from parser
declare -A parsed_cmds="$(cmd_parser $@)"

# validate that all arguments are acceptable / known
if [[ ${#@} > 0 && ${#parsed_cmds[*]} == 0 ]];
then
    array=("$*")
    echo Unknown argument "${array[*]}"
    echo Usage
    exit 1
fi

#
download_bash_script() {
    if [[ $# == 1 ]];
    then
        local file_name=$1
        local url_text=https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/$file_name
        local tmp_file=$(echo `mktemp -u`)

        log_info "attempting to download '%s'." $file_name

        # attempt to download to a temporary file.
        wget $url_text -q -O $tmp_file
        # uncomment for testing local changes
        # cp ../$TOPDIR/$file_name .

        # validate request
        exit_code=$?
        if [[ $exit_code != 0 ]];
        then
            log_error "Failed to download '%s'" $file_name
            echo  "Failed to download '" $file_name "' - error" $exit_code

            rm $tmp_file
            exit $exit_code
        else
            log_info "downloaded '%s'" $file_name

            mv -f $tmp_file $file_name
            chmod +x $file_name
        fi
    fi
}

# script 
log_info "Running azure-iot-edge-installer.sh"

# if helper scripts dont exist, fetch via wget 
if [ -d "iot-edge-installer" ]
then
    log_info "Directory iot-edge-installer already exists." 
else
    log_info "Preparing install directory."
    mkdir iot-edge-installer
fi

cd iot-edge-installer

log_info "Downloading helper files to temporary directory ./iot-edge-installer"
download_bash_script validate-tier1-os.sh
download_bash_script install-container-management.sh
download_bash_script install-edge-runtime.sh
download_bash_script validate-post-install.sh
download_bash_script utils.sh
log_info "downloaded helper files to temporary directory ./iot-edge-installer"

# check if current OS is Tier 1
source /etc/os-release
source validate-tier1-os.sh
is_os_tier1
if [ "$?" != "0" ];
then 
    log_error "This OS is not supported. Please visit this link for more information https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1."
else
    # run scripts in order, can take parsed input from above
    platform=$(get_platform)
    prepare_apt $platform

    source install-container-management.sh
    install_container_management

    ./install-edge-runtime.sh
    ./validate-post-install.sh
fi

# cleanup, always
cd ..
if [ -d "iot-edge-installer" ] 
then
    log_info "Removing temporary directory files for iot-edge-installer."
    rm -rf iot-edge-installer
    log_info "Removed temporary directory files for iot-edge-installer."
fi
