# Insert file header

# Insert function header
function cleanup() {
	echo Starting cleanup
	
	local armToken=$1
	local apiToken=$2
	local device_id=$3
	local token_id=$4

	# Clean up device if it exists
	local out=$(curl -X GET -H "Authorization:$apiToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/devices/${device_id})
	echo $out
	local device_exists=$(jq -r '.id' <<< "$out")
	if [ "$device_exists" == "$device_id" ];
	then
		echo Device ${device_id} exists
		echo Delete device ${device_id}
		curl -X DELETE -H "Authorization:Bearer $armToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/devices/${device_id}
	else
		echo Device ${device_id} does not exist
	fi;

	# Clean up API token if it exists
	local out=$(curl -X GET -H "Authorization:$apiToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/apiTokens/${token_id})
	echo $out
	local apiToken_exists=$(jq -r '.id' <<< "$out")
	if [ "$apiToken_exists" == "$token_id" ];
	then
		echo API token ${token_id} exists
		echo Delete API token ${token_id}
		curl -X DELETE -H "Authorization:Bearer $armToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/apiTokens/${token_id}
	else
		echo API token ${token_id} does not exist
	fi;

	echo Completed cleanup
}

# Azure IoT DDE team subscription
subscription=377c3343-75bb-4244-98a3-0fb84a830c4b

# Create a random number to make sure create new resources per each run
let num=$RANDOM*$RANDOM
prefix=e2e
token_id="${prefix}testtoken${num}"
device_id="${prefix}testdevice${num}"
device_displayName=$device_id
device_template=dtmi:z3kvj66agb:gi4gydpmx 
test_result=1 # fail by default

# The Central app is stored in PipelineResources-IoTEdgeConfig resource group
echo Get access token to subscription "Azure IoT DDE team subscription"
out=$(az account get-access-token --resource https://apps.azureiotcentral.com -s ${subscription})
echo $out
armToken=$(jq -r '.accessToken' <<< "$out")

# Create API token
echo Create API token to interact with Central app "https://e2etest-iotc-iiot-asset-app.azureiotcentral.com"
out=$(curl -X PUT -d '{"roles":[{"role":"ca310b8d-2f4a-44e0-a36e-957c202cd8d4"}]}' -H "Content-Type:application/json" -H "Authorization:Bearer $armToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/apiTokens/${token_id});
echo $out
apiToken=$(jq -r '.token' <<< "$out")

if [ "$apiToken" == "null" ]; then 
	echo Failed to create API token. Exit.
	exit $test_result;
fi;

echo Create a new device
out=$(curl -X PUT -d '{"displayName":"'$device_displayName'","instanceOf":"'$device_template'","simulated":false,"approved":true}' -H "Content-Type: application/json" -H "Authorization:$apiToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/devices/${device_id})
echo $out
devicestate_before=$(jq -r '.provisioned' <<< "$out")
echo New device state is provisioned=$devicestate_before

if [ "$devicestate_before" != "false" ]; then 
	echo "Error: New device must not be provisioned. Cleanup and exit."
	cleanup "$armToken" "$apiToken" "$device_id" "$token_id"
	exit $test_result
else
	echo "Device is not provisioned as expected. Continue."; 
fi;

echo Get device credentials
creds=$(curl -X GET -H "Authorization:$apiToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/devices/${device_id}/credentials)
echo $creds
scope_id=$(jq -r '.idScope' <<< "$creds")
primary_key=$(jq -r '.symmetricKey.primaryKey' <<< "$creds")

echo Run the Azure IoT Edge Installer
#wget https://github.com/Azure/iot-edge-config/releases/download/latest/azure-iot-edge-installer.sh \
#&& chmod +x azure-iot-edge-installer.sh \
#&& ./azure-iot-edge-installer.sh -scopeId $scope_id -symmetricKey $primary_key \
#&& rm -rf azure-iot-edge-installer.sh

# device state should be provisioned after running the script
out=$(curl -X GET -H "Authorization:$apiToken" https://e2etest-iotc-iiot-asset-app.azureiotcentral.com/api/preview/devices/${device_id})
echo $out
devicestate_after=$(jq -r '.provisioned' <<< "$out")
echo After running azure-iot-edge-installer.sh, new device state is provisioned=$devicestate_before

if [ "$devicestate_after" != "true" ]; then 
	echo "Error: Device must be provisioned. Exit."; 
else
	echo "Device is provisioned as expected. Success."; 
	$test_result=0 # success
fi;

# Clean up
cleanup "$armToken" "$apiToken" "$device_id" "$token_id"
exit $test_result