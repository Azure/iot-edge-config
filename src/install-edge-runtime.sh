#script to install edge runtime 1.2
echo "Running install-edge-runtime.sh"

# sudo apt-get update

# install Azure IoT Edge Runtime 1.2
# sudo apt-get install aziot-edge -y

# create .toml from template 
# sudo cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml

sed -i '/## Manual provisioning with connection string/,/## Manual provisioning with symmetric key/c\
## Manual provisioning with connection string\
[provisioning]\
source = $1\
connection_string = $2\

## Manual provisioning with symmetric key\
'  sample.toml

# sudo iotedge config apply