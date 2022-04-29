#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###################################### 
# test-ihedgecs
# 
# End to end test to validate that the azure-iot-edge-installer.sh
# succesfully gets the Central device to provisioned state
# ARGUMENTS:
#    subscription - The Azure subscription where the Central app is created
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    0 if test succeeds, 1 otherwise
######################################

# Azure IoT DDE team subscription
subscription=$1

# Create a random number to make sure create new resources per each run
let num=$RANDOM*$RANDOM
prefix=e2e
iothub_id="${prefix}-ih-${num}"
edge_device_id="${prefix}-testdevice-${num}"
device_displayName=$edge_device_id
rg_name=PipelineResources-IoTEdgeConfig

az account set -s ${subscription}

echo Create the test IoT Hub '${iothub_id}' for the run
az iot hub create --resource-group ${rg_name} --location westus2 --name ${iothub_id} --sku S2

echo Create the edge device '${edge_device_id}' for the run, edge enabled
az iot hub device-identity create -n ${iothub_id} -d ${edge_device_id} --ee

echo Retrieve the connection string
out=$(az iot hub device-identity connection-string show  -n ${iothub_id} -d ${edge_device_id})
device_connection_string=$(jq -r '.connectionString' <<< "$out")

echo Configure the edge device with a test deployment manifest
az iot edge set-modules --hub-name ${iothub_id} --device-id ${edge_device_id} --content ./test-edge-deployment.json

echo Run the Azure IoT Edge Installer
#wget -O azure-iot-edge-installer.sh https://github.com/Azure/iot-edge-config/releases/latest/download/azure-iot-edge-installer.sh \
cd ./../../src
chmod u+x azure-iot-edge-installer.sh
sudo LOCAL_E2E=1 ./azure-iot-edge-installer.sh --telemetry-opt-out --connection-string "${device_connection_string}"
chmod u-x azure-iot-edge-installer.sh

# Give 2 mins for changes to propagate to central app
sleep 120

# Clean up
 az iot hub delete --resource-group ${rg_name} --name ${iothub_id}