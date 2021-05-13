#!/usr/bin/env bash

###################################### 
# validate-tier1-os.sh
# 
# Utility function to check if the current OS is a tier 1 OS as per the definition below
# https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1
# ARGUMENTS:
#    Current OS ID
#   Current OS VERSION ID
# OUTPUTS:
#    Write output to stdout
# RETURN:
#    0 if OS is tier 1, 1 otherwise
######################################

source utils.sh

function is_os_tier1() {    

    local os_id=$1
    local os_version_id=$2
    log_info "OS ID: '%s'; OS Version ID: '%s'" $os_id $os_version_id

    case $os_id in

        ubuntu)
            echo "OS is Ubuntu"
            if [ "$os_version_id" == "18.04" ];
            then
                echo "Version is 18.04"
                return 0
            fi;
            ;;

        raspbian)
            echo "OS is Raspbian"
            return 0
            ;;

        *)
            echo "OS is not Tier 1"
            ;;
    esac

    return 1
}

function get_platform() {
    local os_id=$1
    local os_version_id=$2
	local os_platform=""
    
    case $os_id in
        ubuntu)
            if [ $os_version_id == "18.04" ];  
            then
                os_platform="ubuntu/18.04"
            fi
            ;;

        raspbian)
            os_platform="debian/stretch"
            ;;
    esac
    
	echo "$os_platform"
}
