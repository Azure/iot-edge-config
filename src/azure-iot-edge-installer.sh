#!/usr/bin/env bash

# import utils
source src/utils.sh
source src/validate-tier1-os.sh

ensure_sudo 
log_init

VERSION_TAG="v0.0.0-rc0"

#
download_bash_script() {
    if [[ $# == 1 ]];
    then
        local file_name=$1
        local url_text=https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/$file_name
        local tmp_file=$(echo `mktemp -u`)

        log_info "downloading '%s'" $file_name

        # attempt to download to a temporary file.
        wget $url_text -q -O $tmp_file

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

log_info "Downloding helper files to temporary directory ./iot-edge-installer"
download_bash_script validate-tier1-os.sh
download_bash_script install-container-management.sh
download_bash_script install-edge-runtime.sh
download_bash_script validate-post-install.sh
download_bash_script utils.sh
log_info "download_bash_scripted helper files to temporary directory ./iot-edge-installer"

# check if current OS is Tier 1
. /etc/os-release
is_os_tier1 $ID $VERSION_ID
if [ "$?" != "0" ]
then 
    log_error "This OS is not supported. Please visit this link for more information https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1. Exit."
fi

# parse command line inputs and fetch output from parser
declare -A parsed_cmds="$(cmd_parser $@)"

# sample usage
echo ""
echo "Verbose Logging: ${parsed_cmds[VERBOSE_LOGGING]}"
echo "Device provisioning: ${parsed_cmds[DEVICE_PROVISIONING]}"
echo "Azure Cloud Identity Provider: ${parsed_cmds[AZURE_CLOUD_IDENTITY_PROVIDER]}"
echo ""

# run scripts in order, can take parsed input from above
platform=$(get_platform "$ID" "$VERSION_ID")
./install-container-management.sh $platform
./install-edge-runtime.sh
./validate-post-install.sh
cd ..

# cleanup, always
if [ -d "iot-edge-installer" ] 
then
    log_info "Removing temporary directory files for iot-edge-installer."
    rm -rf iot-edge-installer
    log_info "Removed temporary directory files for iot-edge-installer."
fi
