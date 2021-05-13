#!/usr/bin/env bash

# where am i
TOPDIR=$(dirname $0)

# import utils
source $TOPDIR/utils.sh
ensure_sudo "$@"
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

# parse command line inputs and fetch output from parser
declare -A parsed_cmds="$(cmd_parser $@)"

# sample usage
echo ""
echo "Scope ID: ${parsed_cmds[SCOPE_ID]}"
echo "Registration/Device ID: ${parsed_cmds[REGISTRATION_ID]}"
echo "Symmetric Key: ${parsed_cmds[SYMMETRIC_KEY]}"
echo ""

# run scripts in order, can take parsed input from above
./validate-tier1-os.sh
./install-container-management.sh
./install-edge-runtime.sh ${parsed_cmds[SCOPE_ID]} ${parsed_cmds[REGISTRATION_ID]} ${parsed_cmds[SYMMETRIC_KEY]}
./validate-post-install.sh
cd ..

# cleanup, always
if [ -d "iot-edge-installer" ] 
then
    log_info "Removing temporary directory files for iot-edge-installer."
    rm -rf iot-edge-installer
    log_info "Removed temporary directory files for iot-edge-installer."
fi
