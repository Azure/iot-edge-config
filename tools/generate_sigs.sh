#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# generate sha256 for each component and update the installer
sha256sum azure-iot-edge-installer.sh > INST_SHASUMS

echo -n '' > COMP_SHASUMS
declare -a file_list=(install-container-management.sh  install-edge-runtime.sh  utils.sh  validate-post-install.sh  validate-tier1-os.sh)
for file in ${file_list[@]};
do
    sha256sum $file >> COMP_SHASUMS
done
