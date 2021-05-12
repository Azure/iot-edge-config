#!/usr/bin/env bash

# import utils
source utils.sh
source validate-tier1-os.sh

VERSION_TAG="v0.0.0-rc0"

log_init
log_info "Running azure-iot-edge-installer.sh"

# if helper scripts dont exist, fetch via wget 
if [ -d "iot-edge-installer" ]
then
    log_info "Directory iot-edge-installer exists." 
else
    log_info "Preparing install directory."
    mkdir iot-edge-installer
    cd iot-edge-installer

    log_info "Downloding helper files to temporary directory ./iot-edge-installer"
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/validate-tier1-os.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/install-container-management.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/install-edge-runtime.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/validate-post-install.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/utils.sh
    log_info "Downloaded helper files to temporary directory ./iot-edge-installer"
fi

# add permission to run
chmod +x validate-tier1-os.sh
chmod +x install-container-management.sh
chmod +x install-edge-runtime.sh
chmod +x validate-post-install.sh

# check if current OS is Tier 1
. /etc/os-release
is_os_tier1 $ID $VERSION_ID
if [ "$?" != "0" ]
then 
    log_error "This OS is not supported. Exit."
fi

# run scripts in order
./install-container-management.sh
./install-edge-runtime.sh
./validate-post-install.sh
cd ..

# cleanup
if [ -d "iot-edge-installer" ] 
then
    log_info "Removing temporary directory files for iot-edge-installer."
    rm -rf iot-edge-installer
    log_info "Removed temporary directory files for iot-edge-installer."
fi
