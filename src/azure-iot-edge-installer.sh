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

# run scripts in order
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