#!/bin/sh

sudo dpkg -i eai-installer_*.deb

if [ "$?" != "0" ];
then
    echo "************************************************************************"
    echo " The installation failed. Please try again..."
    echo "************************************************************************"
else
    echo "************************************************************************"
    echo " Edge AI Installer is installed successfully!"
    echo " You can get more details from the help menu:"
    echo "  $ cd /usr/local/microsoft/eai-installer"
    echo "  $ sudo ./azure-iot-edge-installer.sh --help"
    echo "************************************************************************"   
fi
