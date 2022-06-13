#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###################################### 
# test-uninstall
# 
# clean up between e2-e runs
# ARGUMENTS:
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    0
######################################

#Question - is 'sudo' really needed here?
#Answer   - it doesn't hurt!

      sudo apt-get remove --purge aziot-edge aziot-identity-service -y
      sudo docker rm $(sudo docker ps -a -q) > /dev/null 2>&1
      sudo docker rmi -f $(sudo docker images -aq) /dev/null 2>&1
      sudo apt-get remove --purge moby-cli moby-engine -y


echo Uninstall Azure IoTEdge and its subs
sudo apt-get remove --purge --autoremove aziot-edge aziot-identity-service -y

echo Remove any dangling docker containers
sudo docker rm $(sudo docker ps -a -q) > /dev/null 2>&1

echo Remove all docker images
sudo docker rmi -f $(sudo docker images -aq) > /dev/null 2>&1

echo Remove moby-engine and its subs
sudo apt-get remove --purge --autoremove moby-cli moby-engine -y

echo Remove log, output and error files
sudo rm -f /tmp/azure-iot-edge-installer*.* > /dev/null 2>&1
