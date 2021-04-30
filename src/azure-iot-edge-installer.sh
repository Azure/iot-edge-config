#script 
echo "Running azure-iot-edge-installer.sh"

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