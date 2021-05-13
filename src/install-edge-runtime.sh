#script to install edge runtime 1.2

# update
# sudo apt-get update

# install Azure IoT Edge Runtime 1.2
# sudo apt-get install aziot-edge -y

# create .toml from template 
# sudo cp /etc/aziot/config.toml.edge.template /etc/aziot/config.toml

CONNECTION_STRING=$1

# replace with connection string
sed -i '/## Manual provisioning with connection string/,/## Manual provisioning with symmetric key/c\
## Manual provisioning with connection string\
\
[provisioning]\
source = "manual"\
connection_string = \"'$CONNECTION_STRING'\" \
\
\
## Manual provisioning with symmetric key\
'  sample.toml

# sudo iotedge config apply