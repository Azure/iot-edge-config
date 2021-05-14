#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

if [[ $EUID -ne 0 ]];
then
    echo "ERROR: $0 requires elevated priveledges.. "
    exit 1
fi

# where am i
TOPDIR=$(dirname $0)

######################################
# download_bash_script
#
#    downloads a single bash script from release according to VERSION_TAG
# ARGUMENTS:
#    file_name to be downloaded from release
# OUTPUTS:
#    Write output to stdout
# RETURN:
######################################

function download_bash_script() {
    if [[ $# == 1 ]];
    then
        local file_name=$1
        local url_text=https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/$file_name
        local tmp_file=$(echo `mktemp -u`)

        printf "attempting to download '%s'.\n" $file_name > /dev/stdout

        # attempt to download to a temporary file.
        # use 'sudo LOCAL_E2E=1 ./azure-iot-edge-installer.sh {}' to validate local source...
        if [ "$LOCAL_E2E" == "1" ];
        then
            printf "Testing local file '%s'\n" "../$TOPDIR/$file_name" > /dev/stdout
            cp ../$TOPDIR/$file_name .
        else
            wget $url_text -q -O $tmp_file

            # validate request
            exit_code=$?
            if [[ $exit_code != 0 ]];
            then
                printf "ERROR: Failed to download '%s'; error: %d\n" $file_name $exit_code > /dev/stdout

                rm $tmp_file
                exit $exit_code
            else
                printf "downloaded '%s'\n" $file_name > /dev/stdout

                mv -f $tmp_file $file_name
                chmod +x $file_name
            fi
        fi
    fi
}

# script
printf "Running azure-iot-edge-installer.sh\n" > /dev/stdout

# if helper scripts dont exist, fetch via wget 
if [ -d "iot-edge-installer" ];
then
    printf "Directory iot-edge-installer already exists.\n"  > /dev/stdout
else
    printf "Preparing install directory.\n" > /dev/stdout
    mkdir iot-edge-installer
fi

cd iot-edge-installer

printf "Downloading helper files to temporary directory ./iot-edge-installer\n" > /dev/stdout
download_bash_script validate-tier1-os.sh
download_bash_script install-container-management.sh
download_bash_script install-edge-runtime.sh
download_bash_script validate-post-install.sh
download_bash_script utils.sh
printf "Downloaded helper files to temporary directory ./iot-edge-installer\n" > /dev/stdout

# import utils
source utils.sh
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

if [[ "${parsed_cmds["SCOPE_ID"]}" == "" || "${parsed_cmds["REGISTRATION_ID"]}" == "" || "${parsed_cmds["SYMMETRIC_KEY"]}" == "" ]];
then
    echo Missing argument
    echo Usage
    exit 1
fi

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

    source install-edge-runtime.sh
    install_edge_runtime ${parsed_cmds["SCOPE_ID"]}  ${parsed_cmds["REGISTRATION_ID"]} ${parsed_cmds["SYMMETRIC_KEY"]}

    source validate-post-install.sh
    validate_post_install
fi

# cleanup, always
cd ..
if [ -d "iot-edge-installer" ] 
then
    log_info "Removing temporary directory files for iot-edge-installer."
    rm -rf iot-edge-installer
    log_info "Removed temporary directory files for iot-edge-installer."
fi
