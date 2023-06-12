#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

######################################
# validate-tier1-os.sh
# 
# Utility function to check if the current OS is a tier 1 OS as per the definition below
# https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1
# ARGUMENTS:
#    Current OS ID - taken from /etc/os-release
#    Current OS VERSION ID - taken from /etc/os-release
#    Current OS VERSION CODENAME - taken from /etc/os-release
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    0 if OS is tier 1, 1 otherwise
######################################

function is_os_tier1() {
    log_info "OS ID: '%s'; OS Version ID: '%s'; VERSION_CODENAME: '%s'" $ID $VERSION_ID $VERSION_CODENAME

    case $ID in
        ubuntu)
            if [ "$VERSION_ID" == "18.04" ] || [ "$VERSION_ID" == "20.04" ] || [ "$VERSION_ID" == "22.04" ];
            then
                return 0
            fi
            ;;

        raspbian)
            if [ "$VERSION_CODENAME" == "bullseye" ] || [ "$VERSION_CODENAME" == "stretch" ] || [ "$VERSION_ID" == "9" ] || [ "$VERSION_ID" == "11" ];
            then
                return 0
            fi
            ;;

        *)
            log_error "OS is not Tier 1"
            ;;
    esac

    return 1
}


######################################
# get_platform
# 
# Utility function to construct the os_platform string which is used
#    for locating binaries.
# ARGUMENTS:
#    Current OS ID - taken from /etc/os-release
#    Current OS VERSION ID - taken from /etc/os-release
#    Current OS VERSION CODENAME - taken from /etc/os-release
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    os_platform string (e.g. ubuntu/18.04)
######################################

function get_platform() {
    local os_platform=""

    case $ID in
        ubuntu)
            if [[ $VERSION_ID == "18.04" ]];
            then
                os_platform="$ID/$VERSION_ID/multiarch"
            else
                os_platform="$ID/$VERSION_ID"
            fi
            ;;

        raspbian)
            if [ "$VERSION_CODENAME" == "bullseye" ] || [ "$VERSION_ID" == "11" ];
            then
                os_platform="$ID_LIKE/11"               
            else
                os_platform="$ID_LIKE/stretch/multiarch"
            fi
            ;;
    esac

    echo "$os_platform"
}

export -f is_os_tier1 get_platform

