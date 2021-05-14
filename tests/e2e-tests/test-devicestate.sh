#!/usr/bin/env bash
###################################### 
# test-devicestate
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

###################################### 
# Clean up test resources
# ARGUMENTS:
#    armToken - Azure Resource Manager token for itneracting with the Azure subscription
#     apiToken - the API token used for interaction with Central app
#    device_id - the ID of the newly created device
#    token_id - the API token ID used for interaction with Central app
#   rg - resource group name for central app
#   centralapp_name - central app name
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    Void
######################################
function cleanup() {
    echo Starting cleanup
    
    local armToken=$1
    local apiToken=$2
    local device_id=$3
    local token_id=$4
    local rg=$5
    local centralapp_name=$6

    # Clean up device if it exists
    local out=$(curl -X GET -H "Authorization:$apiToken" https://${centralapp_name}.azureiotcentral.com/api/preview/devices/${device_id})
    echo $out
    local device_exists=$(jq -r '.id' <<< "$out")
    if [ "$device_exists" == "$device_id" ];
    then
        echo Device ${device_id} exists
        echo Delete device ${device_id}
        curl -X DELETE -H "Authorization:Bearer $armToken" https://${centralapp_name}.azureiotcentral.com/api/preview/devices/${device_id}
    else
        echo Device ${device_id} does not exist
    fi;

    # Clean up API token if it exists
    local out=$(curl -X GET -H "Authorization:$apiToken" https://${centralapp_name}.azureiotcentral.com/api/preview/apiTokens/${token_id})
    echo $out
    local apiToken_exists=$(jq -r '.id' <<< "$out")
    if [ "$apiToken_exists" == "$token_id" ];
    then
        echo API token ${token_id} exists
        echo Delete API token ${token_id}
        curl -X DELETE -H "Authorization:Bearer $armToken" https://${centralapp_name}.azureiotcentral.com/api/preview/apiTokens/${token_id}
    else
        echo API token ${token_id} does not exist
    fi;

    # Clean up central app
    echo Clean up central app
    az iot central app delete -g ${rg} -n ${centralapp_name} -y

    echo Completed cleanup
}

# Azure IoT DDE team subscription
subscription=$1

# Create a random number to make sure create new resources per each run
let num=$RANDOM*$RANDOM
prefix=e2e
token_id="${prefix}testtoken${num}"
device_id="${prefix}testdevice${num}"
device_displayName=$device_id
device_template=dtmi:z3kvj66agb:gi4gydpmx 
test_result=1 # fail by default
rg=PipelineResources-IoTEdgeConfig
centralapp_name=${prefix}test-iotc-iiot-asset-app${num}

# The Central app is stored in PipelineResources-IoTEdgeConfig resource group
echo Get access token to subscription "Azure IoT DDE team subscription"
out=$(az account get-access-token --resource https://apps.azureiotcentral.com -s ${subscription})
echo $out
armToken=$(jq -r '.accessToken' <<< "$out")

# Create a central app
echo Create a central app
az iot central app create -g ${rg} -n ${centralapp_name} -s ${centralapp_name} --template iotc-iiot-asset

# Create API token
echo Create API token to interact with Central app
out=$(curl -X PUT -d '{"roles":[{"role":"ca310b8d-2f4a-44e0-a36e-957c202cd8d4"}]}' -H "Content-Type:application/json" -H "Authorization:Bearer $armToken" https://${centralapp_name}.azureiotcentral.com/api/preview/apiTokens/${token_id});
echo $out
apiToken=$(jq -r '.token' <<< "$out")

if [ "$apiToken" == "null" ]; 
then 
    echo Failed to create API token. Exit.
    exit $test_result;
fi;

echo Create a new device
out=$(curl -X PUT -d '{"displayName":"'$device_displayName'","instanceOf":"'$device_template'","simulated":false,"approved":true}' -H "Content-Type: application/json" -H "Authorization:$apiToken" https://${centralapp_name}.azureiotcentral.com/api/preview/devices/${device_id})
echo $out
devicestate_before=$(jq -r '.provisioned' <<< "$out")
echo New device state is provisioned=$devicestate_before

if [ "$devicestate_before" != "false" ]; 
then 
    echo "Error: New device must not be provisioned. Cleanup and exit."
    cleanup "$armToken" "$apiToken" "$device_id" "$token_id" "$rg" "$centralapp_name"
    exit $test_result
else
    echo "Device is not provisioned as expected. Continue."; 
fi;

echo Get device credentials
creds=$(curl -X GET -H "Authorization:$apiToken" https://${centralapp_name}.azureiotcentral.com/api/preview/devices/${device_id}/credentials)
echo $creds
scope_id=$(jq -r '.idScope' <<< "$creds")
primary_key=$(jq -r '.symmetricKey.primaryKey' <<< "$creds")

echo Run the Azure IoT Edge Installer
wget https://github.com/Azure/iot-edge-config/releases/latest/download/azure-iot-edge-installer.sh \
&& chmod +x azure-iot-edge-installer.sh \
&& ./azure-iot-edge-installer.sh --scope-id "$scope_id" --registration-id "$device_id" --symmetric-key "$primary_key"\
&& rm -rf azure-iot-edge-installer.sh

# device state should be provisioned after running the script
out=$(curl -X GET -H "Authorization:$apiToken" https://${centralapp_name}.azureiotcentral.com/api/preview/devices/${device_id})
echo $out
devicestate_after=$(jq -r '.provisioned' <<< "$out")
echo After running azure-iot-edge-installer.sh, new device state is provisioned=$devicestate_after

if [ "$devicestate_after" != "true" ]; 
then 
    echo "Error: Device must be provisioned. Exit."; 
else
    echo "Device is provisioned as expected. Success."; 
    $test_result=0 # success
fi;

# Clean up
cleanup "$armToken" "$apiToken" "$device_id" "$token_id" "$rg" "$centralapp_name"
echo test_result: $test_result
exit $test_result
