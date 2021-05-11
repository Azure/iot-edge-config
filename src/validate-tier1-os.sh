#!/bin/bash

###################################### 
# validate-tier1-os.sh
# 
# Utility function to check if the current OS is a part of OS array
# ARGUMENTS:
#	Current OS ID
#   Current OS VERSION ID
#   List of OSes to compare
# OUTPUTS:
#	Write output to stdout
# RETURN:
#	0 if OS is part of the OS array, 1 otherwise
######################################
function is_os_array() {	
	
	declare -A OS
	
	local os_id=$1
	local os_version_id=$2
	local os_array=$3	
	
	for i in "${os_array[@]}";
	do
		eval "${os_array["$i"]}"
		if [ "${OS[ID]}" == "$os_id" ];
		then
			if [ "${OS[VERSION_ID]}" == "*" ];
			then
				return 0;
			elif [ "${OS[VERSION_ID]}" == "$os_version_id" ];
			then
				return 0;
			fi;
		fi;
	done
	
	return 1;	
}

# tier 1 OS list as per the definition below
# https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1
Ubuntu1804="declare -A OS=([ID]='ubuntu' [VERSION_ID]='18.04')"
Raspbian="declare -A OS=([ID]='raspbian' [VERSION_ID]='*')"

declare -A Tier1OSList=(["0"]=${Ubuntu1804} ["1"]=${Raspbian})

. /etc/os-release

is_os_array $ID $VERSION_ID $Tier1OSList
echo $?
