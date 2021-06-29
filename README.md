# Azure IoT Edge configuration tool [![Build Status](https://dev.azure.com/mseng/VSIoT/_apis/build/status/Azure%20IoT%20Edge/iotedgehubdev?branchName=master)](https://dev.azure.com/Azure-IoT-DDE-EdgeExperience/IoTEdgeConfig/_build?definitionId=28&branchName=main)

## Overview
Azure IoT Edge configuration tool (the Tool) is a command-line tool that installs IoT Edge runtime version 1.2 and configures Azure IoT Edge on a device. The tool greatly simplifies the configuration of IoT Edge by automating several steps into single command.
 
The tool is useful to install and configure IoT Edge on any given device (physical or virtual) to get started with just one command. The tool is also useful by OT persona in production who are required to perform the task and can eliminate the skill gaps.
 
The tool can also be integrated into the existing IT Automation tools like Ansible Towers, Puppet, Chef, etc.

## Getting started

### Pre-requisites
* Physical device or virtual machine. You must setup by yourself as the tool neither installs OS nor creates VM 
* Your physical device or VM must be running [Tier1 OS supported by IoT Edge](https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#linux-containers)
* IoT Edge config tool supports DPS based provisioning using SAS Key only. You must manually create IoT Hub instance that links to DPS scope and/or create IoT Central manually.

### Test with Azure IoT Hub
1. Use existing IoT Hub & DPS or create a new Hub
    * Create [IoT Hub](https://ms.portal.azure.com/#create/Microsoft.IotHub) and create [DPS](https://ms.portal.azure.com/#create/Microsoft.IoTDeviceProvisioning)
    * Link IoT Hub to the [DPS scope](https://docs.microsoft.com/en-us/azure/iot-dps/quick-setup-auto-provision)
2. Go to DPS resource and create [individual enrollment](https://docs.microsoft.com/en-us/azure/iot-dps/quick-create-simulated-device-symm-key#create-a-device-enrollment-entry-in-the-portal). 
    * Go to DPS - Manage enrollments - Add individual enrollment
    * Make sure to use Symmetric Key for attestation type and IoT Edge device == true is selected (default is false)
    * Retrieve the following information from the DPS resource page
        * 'Registration ID' (Recommendation: Use the same ID as Device ID for Hub)
        * ID Scope available in [Overview menu](https://docs.microsoft.com/en-us/azure/iot-dps/quick-create-simulated-device-symm-key#run-the-provisioning-code-for-the-device)
        * Primary SAS Key from individual enrollment menu
3. On a device or VM, run the command below. Copy and paste values from above into the script arguments below.

```Command arguments
wget https://github.com/Azure/iot-edge-config/releases/latest/download/azure-iot-edge-installer.sh -O azure-iot-edge-installer.sh \
&& chmod +x azure-iot-edge-installer.sh \
&& sudo -H ./azure-iot-edge-installer.sh -s <IDScope> -r <RegistrationID> -k <Symmetric Key> \
&& rm -rf azure-iot-edge-installer.sh
```

Upon completion of the script, go to IoT Hub - IoT Edge page and check the device is created and check system modules ($edgeAgent and $edgeHub) are created. Note that $edgeHub module will only get deployed when the first custom edge module is deployed.

### Test with Azure IoT Central
1. Create a new IoT Central App; Go to [IoT Central](https://apps.azureiotcentral.com/) and click <+ Build> button. Select any app template or create custom app.
2. Create a new device by clicking <+ New> button
3. In 'All devices' view, click on the created devie and click Connect button. Dialoge with ID Scope, Device ID and Primary key will be displayed. Make sure to use authentication type = Shared access signature (SAS)
4. On a device or VM, run the command below. Copy and paste values from above dialog into the script arguments below.

```Command arguments
wget https://github.com/Azure/iot-edge-config/releases/latest/download/azure-iot-edge-installer.sh -O azure-iot-edge-installer.sh \
&& chmod +x azure-iot-edge-installer.sh \
&& sudo -H ./azure-iot-edge-installer.sh -s <IDScope> -r <RegistrationID> -k <Symmetric Key> \
&& rm -rf azure-iot-edge-installer.sh

```
Upon completion of the script, go to All devices view and Device status should be changed from registered to provisioned.

### Uninstalling IoT Edge runtime and Moby-Engine
You can uninstall both IoT Edge runtime and Moby-Engine with following commands in the following sequences.

1. Uninstall Edge runtime
    * sudo apt-get remove --purge aziot-edge aziot-identity-service -y
2. Enumerate and remove edge modules
    * sudo docker ps -a
    * sudo docker rm -f <container ID>
    * sudo docker images -a
    * sudo docker rmi -f <image ID>
3. Remove Moby
    * sudo apt-get remove --purge moby-cli moby-engine -y
4. Restart your device
    * sudo reboot
  
### Supported script arguments
* Verbose logging: -v or --verbose
* IDScope: -s or --scope-id
* Registration ID: -r or --registration-id
* Symmetric Key: -k or --symmetric-key

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
