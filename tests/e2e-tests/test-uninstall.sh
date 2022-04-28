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
echo Uninstall Azure IoTEdge and its subs
sudo apt-get remove --purge --auto-remove aziot-edge -y

echo Remove any dangling docker containers
sudo docker rm $(sudo docker ps -a -q) > /dev/null 2>&1

echo Remove all docker images
sudo docker rmi -f $(sudo docker images -aq) /dev/null 2>&1

echo Remove moby-engine and its subs
sudo apt-get remove --purge --auto-remove moby-engine -y

echo Remove log, output and error files
sudo rm -f /tmp/azure-iot-edge-installer*.* > /dev/null 2>&1
