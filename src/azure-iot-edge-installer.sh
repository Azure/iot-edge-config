#!/usr/bin/env bash

# import utils
source utils.sh

VERSION_TAG="v0.0.0-rc0"

# script 
echo "Running azure-iot-edge-installer.sh"

# if helper scripts dont exist, fetch via wget 
if [ -d "iot-edge-installer" ]
then
    echo "Directory iot-edge-installer exists." 
else
    mkdir iot-edge-installer
    cd iot-edge-installer
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/validate-tier1-os.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/install-container-management.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/install-edge-runtime.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/validate-post-install.sh
    wget https://github.com/Azure/iot-edge-config/releases/download/${VERSION_TAG}/utils.sh
    echo "Downloaded helper files to temporary directory ./iot-edge-installer"
fi

# add permission to run
chmod +x validate-tier1-os.sh
chmod +x install-container-management.sh
chmod +x install-edge-runtime.sh
chmod +x validate-post-install.sh

# create flag:variable_name dictionary
declare -A flag_to_variable_dict

# add flag:variable_name dictionary entries
# if you require new flags to be parsed, add more lines here
flag_to_variable_dict[-v]="VERBOSE_LOGGING"
flag_to_variable_dict[--verbose]="VERBOSE_LOGGING"
flag_to_variable_dict[-dp]="DEVICE_PROVISIONING"
flag_to_variable_dict[--device-provisioning]="DEVICE_PROVISIONING"
flag_to_variable_dict[-ap]="AZURE_CLOUD_IDENTITY_PROVIDER"
flag_to_variable_dict[--azure-cloud-identity-provider]="AZURE_CLOUD_IDENTITY_PROVIDER"
flag_to_variable_dict[-s]="SCOPE_ID"
flag_to_variable_dict[--scope-id]="SCOPE_ID"
flag_to_variable_dict[-r]="REGISTRATION_ID"
flag_to_variable_dict[--registration-id]="REGISTRATION_ID"
flag_to_variable_dict[-k]="SYMMETRIC_KEY"
flag_to_variable_dict[--symmetric-key]="SYMMETRIC_KEY"

# create flag:variable_name dictionary
declare -A parsed_cmd

# parse command line inputs
cmd_parser $@

# fetch output from parser
parsed_cmd="$(cmd_parser)"

# sample usage
echo ""
echo "Verbose Logging: ${parsed_cmd[VERBOSE_LOGGING]}"
echo "Device provisioning: ${parsed_cmd[DEVICE_PROVISIONING]}"
echo "Azure Cloud Identity Provider: ${parsed_cmd[AZURE_CLOUD_IDENTITY_PROVIDER]}"
echo ""

# run scripts in order, can take parsed input from above
./validate-tier1-os.sh
./install-container-management.sh
./install-edge-runtime.sh
./validate-post-install.sh
cd ..

# cleanup
if [ -d "iot-edge-installer" ] 
then
    rm -rf iot-edge-installer
    echo "Removed temporary directory files for iot-edge-installer" 
fi