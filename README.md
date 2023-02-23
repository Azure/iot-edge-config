
# Azure IoT Edge Configuration Tool V2
Note: The config tool v2 is currently at **beta stage** and is compatible with **Ubuntu 20.04 devices**. For devices outside of the current scope, feel free to try v2 or use the original [IoT Edge config tool](https://github.com/Azure/iot-edge-config).

## What is the Edge Config Tool?

The Edge Config Tool enables you to securely connect, deploy, and manage your Edge devices to and leverage the power of Azure. It makes it easy for device builders and systems/solution integrators/builders to use Azure to manage and secure their light edge devices. For more information, see https://aka.ms/LinuxEdgeIoTSuite.  

### What’s in the Edge Config Tool? 

The Edge Config Tool includes 3 key Azure services. Taken together, these services enable you to focus on creating differentiated value for your business (e.g., through AI/ML and data-driven insights instead of focusing on managing infrastructure). The 3 services are IoT Edge, Defender for IoT and OSConfig: 

1. **IoT Edge** – Azure IoT Edge is Microsoft's tool for remotely and securely deploying and managing cloud-native workloads—such as AI, Azure services, or your own business logic—to run directly on your IoT devices. IoT Edge can be used to optimize cloud spend and enable your devices to react faster to local changes and operate reliably even in extended offline periods. By using IoT Edge, you can:   
    - Deploy Azure IoT Edge on premises to break up data silos and consolidate operational data at scale in the Azure Cloud.   
    - Remotely and securely deploy and manage cloud-native workloads—such as AI, Azure services, or your own business logic—to run directly on your IoT devices.   
    - Optimize cloud spend and enable your devices to react faster to local changes and operate reliably even in extended offline periods.   

2. **Defender for IoT** - Defender for IoT provides a comprehensive set of security features and capabilities that can be integrated into their products during the development process. This helps to secure devices from the ground up and reduces the risk of vulnerabilities and attacks. The solution can be customized to meet the specific security needs of different IoT devices and can be integrated with the device builder's existing development tools and processes. With Defender for IoT, one can: 
    - Comply with industry regulations and standards: Defender for IoT helps device builders to comply with relevant security regulations and standards, such as the NIST Cybersecurity Framework, by providing a comprehensive set of security controls. 
    - Proactively monitor the security posture of an IoT device: Defender for IoT provides security posture recommendations based on the CIS benchmark, along with device-specific recommendations. With the micro-agent, users can also get visibility into operating system security, including OS configuration, firewall settings, and permissions. 
    - Secure your products against cyber threats: The solution provides real-time monitoring and protection (EDR - Endpoint Detection and Response) against malware, hacking, unauthorized access, and other security threats, helping to ensure the security of IoT devices throughout their lifecycle. 
    - Ensure interoperability with Microsoft SIEM/SOAR and XDR to stop attacks with automated, cross-domain security and built-in AI.  

    In summary, Defender for IoT provides device builders with a comprehensive set of security features and capabilities that help to secure IoT devices from the ground up and reduce the risk of vulnerabilities and attacks. It enables device builders to deliver secure, compliant, and trustworthy IoT products to their customers. 

3. **OSConfig** - OSConfig for IoT is a compact (< 5MB) agent which brings configuration management capabilities into your Azure IoT twin-based workflows. To deploy devices at scale and to keep devices healthy and productive, solution operators need configuration management. Key examples include network settings, hostnames, time zones, security benchmarks, firewall rules, SSH users, and so on.  
By using Azure IoT with OSConfig for configuration management, you can:   

    - Reduce the number of device images you need to maintain (thanks to dynamic configuration at deploy time).  
    - Reduce the frequency of full image updates (thanks to targeted reconfiguration at deploy time or any time).  
    - Eliminate all the baggage of heavy weight server management tools from your IoT/Edge solution (thanks to very small agent) 

## Device Setup
### Compatible Hardware 
The configuration tool V2 supports Ubuntu 20.04 devices and has been officially validated for the following devices:
- NVIDIA AGX Orin/Orin NX
- NVIDIA AGX Xavier/Xavier NX (only on Jetpack 5.0)

If you run into any problems with hardware compatibility, please feel free to open an issue on GitHub.

## How to Install
**Prerequisite**
1.	Make sure the developer kit is connected to the internet before executing the configuration tool V2!
2.	Set up Azure Basics
    - If you do not have an IoT Hub, follow “Create an IoT Hub” in [Use the Azure portal to create an IoT Hub | Microsoft Docs](https://docs.microsoft.com/en-us/azure/iot-hub/iot-hub-create-through-portal). You can skip this step if you already have an IoT Hub.
    - Once you have an IoT Hub, choose one of these two options:
      	- **[Option I] Provision with connection string**: If you are not familiar with the process of getting the IoT Hub connection string, refer to the steps in [Appendix: Provision with connection string](https://github.com/Azure/iot-edge-config/tree/config_tool_v2#provision-with-connection-string)
      	- **[Option II] Provision with DPS**: If you are not familiar with this process, refer to the steps in [Appendix: Provision with DPS](https://github.com/Azure/iot-edge-config/tree/config_tool_v2#provision-with-dps)
3.	Save the **connection string** to a .txt file (or if using DPS provisioning, save Registration_ID, Symmetric Primary Key, the IoT Hub host name, DPS Scope ID to a .txt file).

**Install the Edge Configuration Tool V2 online (Recommended Option)**

This is the recommended method for installing the latest config tool. 
1. Config Linux Software Repository for Microsoft Products
    ```
    curl -sSL https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft-prod.list; curl -sSL https://packages.microsoft.com/keys/microsoft.asc | sudo tee /etc/apt/trusted.gpg.d/microsoft.asc
    ```
2. Install the Edge Configuration Tool V2 with apt-get
    ```
    sudo apt-get update; sudo apt list edge-config-tool; sudo apt-get install edge-config-tool; cd /usr/local/microsoft/edge-config-tool
    ```

**Install the Edge Configuration Tool V2 with offline package (Alternative Option)**

This is an alternative method for installing the config tool. If you have already completed the previous step (apt-get installation), you can skip to the next section to connect your device to Azure.
1.	Download the config tool V2 .deb file (ex: **edge-config-tool_2.0.0_arm64.deb**)
2.	Copy the **config tool V2 file** and the **txt file that contains provision info** to your NV developer kit by USB drive
3.	Install the Edge Config Tool V2 with following commands from the directory of the .deb file.
    ```
    sudo chmod +x edge-config-tool_2.0.0_arm64.deb; sudo dpkg -i edge-config-tool_2.0.0_arm64.deb; cd /usr/local/microsoft/edge-config-tool
    ```
    **[Note]** 2.0.0 is the current configuration tool V2 version, if you are using other versions, please modify the command accordingly.

**Execute the configuration tool V2 and connect to Azure**
1. To execute the configuration tool V2 and set the developer kit Azure ready, you can choose one of the provisioning mechanisms below when executing the configuration tool V2. Make sure you are under the directory of “/usr/local/microsoft/edge-config-tool” when executing the following command.

    **[Connection String]**
    ```
    sudo ./azure-iot-edge-installer.sh -c  “<Azure IoT Edge Device Connection String>”
    ```
    **[DPS]**
    ```
    sudo ./azure-iot-edge-installer.sh -s <ID Scope> -r <Registration ID> -k <Symmetric Key>
    ```

    **[Note]** To disable the telemetry sending to Microsoft, add the parameter **-nt** or **–telemetry-opt-out** when executing the shell script.
2.	Refer to the help menu for more options:
    ```
    sudo ./azure-iot-edge-installer.sh -h
    ```

## Post-Install Experience
### Using the Services in the Fundamentals Package
- **Defender for IoT**
    1.	To configure the Defender for IoT agent-based solution, please follow [“Configure data collection” section and the “Log Analytics creation”](https://docs.microsoft.com/en-us/azure/defender-for-iot/device-builders/how-to-configure-agent-based-solution).
    2.	Navigate to IoT Hub > Your hub > Defender for IoT > Overview and review the information. Refer to the following guidance for detail.
        - [Investigate security recommendations](https://docs.microsoft.com/en-us/azure/defender-for-iot/device-builders/tutorial-investigate-security-recommendations)
        - [Investigate security alerts](https://docs.microsoft.com/en-us/azure/defender-for-iot/device-builders/tutorial-investigate-security-alerts)
    3.	Refer to [Micro agent event collection (Preview)](https://docs.microsoft.com/en-us/azure/defender-for-iot/device-builders/concept-event-aggregation) for more applications with the Defender for IoT.
- **OSConfig**: Refer to the following guidance to try the OSconfig features. (More scenarios are available under the same category: “What can I provision and manage”.)
  - [Working with host names using Azure IoT and OSConfig](https://docs.microsoft.com/en-us/azure/osconfig/howto-hostname?tabs=portal)
  - [Reboot or shut down devices with Azure IoT and OSConfig](https://docs.microsoft.com/en-us/azure/osconfig/howto-rebootshutdown?tabs=portal%2Csingle)

### Updating Packages
The configuration tool V2 installs specific versions of Microsoft fundamental packages (IoTEdge, OSConfig, Defender for IoT). This is the verified known stable combination. Please refer to the release note for versions information. If for any reason you want to use the latest fundamental packages, run the following command AFTER you have successfully run the configuration tool V2. This will trigger the update of those components.
```
sudo ./azure-iot-edge-installer.sh -u
```

### Uninstallation
1.	Uninstall Edge runtime & Azure device-side agents
```
$ sudo apt-get remove --purge aziot-edge aziot-identity-service osconfig edge-config-tool -y
```
2.	Enumerate and remove edge modules
```
$ sudo docker ps -a
$ sudo docker rm -f <container id>
$ sudo docker images
$ sudo docker rmi -f <image id>
```
3.	Restart your device
```
$ sudo reboot
```

## Troubleshooting
### Edge runtime and module status
The expected status of IoT Edge runtime response is **“NA”** or **“417 – The device’s deployment configuration is not set”**. It will change to **“200 – OK”** after the first module deployment. (You can simply click the “Set Modules” to trigger an empty deployment.)

For **DefenderMicroAgent** and **OSConfig module**, it is expected to see the states show **“NA”**. As long as you get the following INFO notification from the configuration tool V2 output, you are good to go.

### Configuration Check
Use the following command if you want to verify the configuration tool V2 is correctly setup.
```
dpkg-query -s edge-config-tool
```
The IoT Edge Check is a useful tool for checking the status of edge agent and edge hub. Before you proceed to the check process, please double confirm if system time has been synchronized after network configured.
```
Sudo timedatectl status
```
Then, you can perform configuration and connectivity checks. 
```
Sudo iotedge check
```

### Internal DNS (Highly Recommended)
If your network environment is under corpnet, you may need to follow the steps below to add an internal DNS server for Docker network to avoid IoTEdge connectivity issue.
(follow the instruction carefully, or refer to [VI Editor with Commands in Linux/Unix Tutorial](https://www.guru99.com/the-vi-editor.html) to learn details about editing file in terminal.)
1.	When the device is already connected to the corpnet, use the following command to check the DNS server IP.
```
$ sudo systemd-resolve --status
```
2.	In a terminal window, us the following command to open the config file:
```
$ sudo vi /etc/docker/daemon.json
```
3.	Find the following line and move the cursor to the `highlighted location`. Then press “i” to enter insert mode.
> “dns”: [`“`1.1.1.1”, “8.8.8.8”],
4.	Insert the characters so the line is modified as below. (Your DNS server IP needs to be the fist element in the array.)
> “dns”: [`“<DNS server IP>”`, “1.1.1.1”, “8.8.8.8”],
5.	Press Esc key to exit the insert mode.
6.	Type **“:wq”** to save and exit.
7.	Restart Docker service after the configuration is updated.
```
$ sudo systemctl restart docker
```

### Further IoT Edge diagnostic
For information about each of the diagnostic checks this tool runs, including what to do if you get an error or warning, see [IoT Edge troubleshoot checks](https://github.com/Azure/iotedge/blob/main/doc/troubleshoot-checks.md). The configuration tool V2 performs the installation and default setup process. However, there are other factors that impact the behavior of IoT Edge runtime/service (such as network configuration, firewall…). Therefore, please do check the following IoT Edge troubleshooting guidance if you encounter IoT Edge issues:
- [Common errors – Azure IoT Edge | Microsoft Docs](https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot-common-errors?view=iotedge-2020-11)
- [Troubleshoot – Azure IoT Edge | Microsoft Docs](https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot?view=iotedge-2020-11)
- [Troubleshoot from the Azure portal – Azure IoT Edge | Microsoft Docs](https://docs.microsoft.com/en-us/azure/iot-edge/troubleshoot-in-portal?view=iotedge-2020-11)

[Note] DPS provisioning does not contain IoTHub’s hostname, so users need to add additional parameter for iotedge check command. Refer to the following links for troubleshooting:
- [iotedge check with DPS & x.509 configuration returns “cannot resolve IoT Hub hostname” Errors · Issue #2033 · Azure/iotedge (github.com)](https://github.com/Azure/iotedge/issues/2033) 
- [iotedge check incorrectly shows an error when using DPS · Issue #2313 · Azure/iotedge (github.com)](https://github.com/Azure/iotedge/issues/2313)

## Appendix
### Provision with connection string
1.	**Register your device**
In your IoT hub in the Azure portal, IoT Edge devices are created and managed separately from IoT devices that are not edge enabled.
    1. Sign in to the Azure portal and navigate to your IoT hub.
    2. In the left pane, select **IoT Edge** from the menu, then select **Add an IoT Edge device**.
    3. On the Create a device page, provide the following information:
        1. Create a descriptive device ID. Make a note of this device ID, as you'll use it later.
        2. Select **Symmetric key** as the authentication type.
        3. Use the default settings to auto-generate authentication keys and connect the new device to your hub.
    4. Select **Save**.
Now that you have a device registered in IoT Hub, retrieve the information that you use to complete installation and provisioning of the IoT Edge runtime.

2.	**View registered devices and retrieve provisioning information**
Devices that use symmetric key authentication need their connection strings to complete installation and provisioning of the IoT Edge runtime.
All the edge-enabled devices that connect to your IoT hub are listed on the IoT Edge page.
 
When you're ready to set up your device, you need the connection string that links your physical device with its identity in the IoT hub.
Devices that authenticate with symmetric keys have their connection strings available to copy in the portal.
1. From the **IoT Edge** page in the portal, click on the device ID from the list of IoT Edge devices.
2. Copy the value of either **Primary Connection String** or **Secondary Connection String**.

Refer to [Create and provision an IoT Edge device on Linux using symmetric keys - Azure IoT Edge | Microsoft Docs](https://docs.microsoft.com/en-us/azure/iot-edge/how-to-provision-single-device-linux-symmetric?view=iotedge-2020-11&tabs=azure-portal%2Cubuntu) for more details.

### Provision with DPS
1.	Set-Up Azure Basics – If you do not have an IoT Hub (and DPS linked to your IoT Hub), follow these [instructions](https://learn.microsoft.com/en-us/azure/iot-dps/quick-setup-auto-provision) to create an IoT Hub, create a DPS instance, and link the IoT Hub to your DPS instance
2.	Create an individual enrollment within the DPS resource
    1.	Specify the Mechanism to be **Symmetric Key**, and set **IoT Edge Device = TRUE**. Refer to the image below for filling in remaining fields.
    2.	Copy the following for later use.
        1. the **Registration_ID**,
        2. **Symmetric Primary Key**,
        3. the **IoT Hub host name** that’s been assigned.
        4. **DPS Scope ID** (found in DPS overview page)
 
    3.	[Note] If the dropdown menu from the final field in the image above does not include an IoT Hub, still proceed to the next page – where the option will likely update.
    4.	[Note] The configuration tool V2 does not support the following characters for DeviceID: `=, %, !, $`
    5.	[Note] If you would like to utilize the hostname option (**-hn** or **--hostname**) to assign hostname as DeviceId, please also notice the following special characters do not comply with RFC 1035 for hostname naming: `+ _ # * ? ( ) , : @ '`

### NVIDIA Xavier/Orin Guidance
For NVIDIA Jetson devices, you will need the following equipment for setup via GUI:
- External monitor + USB keyboard/mouse
- **[Orin Only]** DP-to-DP cable and monitor with display port (DP-to-HDMI cable will not work)
- **[JP4.x OS/FW Only]** Additional physical host machine with Ubuntu OS (This is only required if your developer kit currently boots with JP4.x OS/FW(Ubuntu 18.04))
  - Please see Device Setup for more information
  
**If you are setting up your device for the first time,** refer to this guidance:
- **Orin**: See [Getting Started with Jetson Orin guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-agx-orin-devkit).
- **Xavier**: See [Getting Started With Jetson Xavier NX guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-xavier-nx-devkit). Note that you will need to flash Jetpack 5.0 or later for your device to be compatible with configuration tool V2.

**[Important]** When going through the Jetson device setup, make sure you include not only the Jetson Linux BSP but also the JetPack SDK if you plan to deploy DeepStream workloads to the device.

**If your DK is already setup but not registered to Azure**, refer to this guidance:
1.	Check the OS of your device by running command **“lsb_release -a”**. Orin devices will likely be Ubuntu 20.0.4, which is sufficient for the configuration tool V2. Xavier devices will likely be Ubuntu 18.0.4, which needs to be upgraded to use the configuration tool V2.
2.	For devices on Ubuntu 18.04: You will need to flash Jetpack 5.0 or later for your device to be compatible with configuration tool V2. Navigate to NVIDIA’s guidance for flashing your specific device.
3.	For devices on Ubuntu 20.04: You can proceed to run the configuration tool V2. But it is recommended to install the latest version of Jetpack 5.0 by following Step 2 of [Getting Started with Jetson Orin guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-agx-orin-devkit).

**If your DK is already registered to an IoT Hub/Edge account**, you can still follow the guidance of using connection string to run the configuration tool V2 and connect to the same IoTHub. The configuration tool V2 should effectively install Defender for IoT and OSConfig.
