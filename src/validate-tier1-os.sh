#!/bin/bash

###################################### 
# validate-tier1-os.sh
# 
# Utility function to check if the current OS is a tier 1 OS as per the definition below
# https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1
# ARGUMENTS:
#	None
# OUTPUTS:
#	Write output to stdout
# RETURN:
#	0 if OS is tier 1, 1 otherwise
######################################

function is_os_tier1() {	
	
	local os_is_tier1=1
	
	. /etc/os-release
			
	case $ID in
		
		ubuntu)
			echo "OS is Ubuntu"
			if [ "$VERSION_ID" == "18.04" ];
			then
				echo "Version is 18.04";
				os_is_tier1=0
			fi;
			;;
		
		raspbian)
			echo "OS is Raspbian";
			os_is_tier1=0
			;;
		
		*)
			echo "OS is not Tier 1"
			;;
	esac
	
	return $os_is_tier1
}

is_os_tier1
echo $?
