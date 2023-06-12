#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Record start time, this value is used for calculating execution time
start=`date +%s`

if [[ $EUID -ne 0 ]];
then
    echo "$(echo -en "\e[31m")ERROR: $(echo -en "\e[00m")$0 requires elevated privileges.. "
    exit 1
fi

VERSION_TAG="v0.0.5"

# where am I
TOPDIR=$(dirname $0)

######################################
# download_bash_script
#
#    downloads a single bash script from release according to VERSION_TAG
# ARGUMENTS:
#    file_name to be downloaded from release
# OUTPUTS:
#    Write output to stdout
# RETURN:
######################################

function download_bash_script() {
    if [[ $# == 1 ]];
    then
        local file_name=$1
        local url_text=https://github.com/Inimco/iot-edge-config/releases/download/${VERSION_TAG}/$file_name
        local tmp_file=$(echo `mktemp -u`)

        printf "attempting to download '%s'.\n" $file_name

        # attempt to download to a temporary file.
        # use 'sudo LOCAL_E2E=1 ./azure-iot-edge-installer.sh {}' to validate local source...
        if [ "$LOCAL_E2E" == "1" ];
        then
            printf "Testing local file '%s'\n" "../$TOPDIR/$file_name"
            cp ../$TOPDIR/$file_name .
        else
            printf "wget '%s' -q -O '%s'\n" $url_text $tmp_file
            wget $url_text -q -O $tmp_file

            # validate request
            exit_code=$?
            if [[ $exit_code != 0 ]];
            then
                printf "ERROR: Failed to download '%s'; error: %d\n" $file_name $exit_code

                rm $tmp_file
                exit $exit_code
            else
                printf "downloaded '%s'\n" $file_name

                mv -f $tmp_file $file_name
                chmod +x $file_name
            fi
        fi
    fi
}

# script
printf "Welcome to azure-iot-edge-installer\n"
printf "\n%s\n" "-------------------------"
printf "Telemetry\n"
printf "%s\n" "---------"
printf "The azure-iot-edge-installer collects usage data in order to improve your experience.\n"
printf "The data is anonymous and does not include commandline argument values.\n"
printf "The data is collected by Microsoft.\n"
printf "You can change your telemetry settings by adding -nt or --telemetry-opt-out to the command line.\n"
printf "\n"

# if helper scripts dont exist, fetch via wget 
if [ -d "iot-edge-installer" ];
then
    printf "Directory iot-edge-installer already exists.\n" 
else
    printf "Preparing install directory.\n"
    mkdir iot-edge-installer
fi

cd iot-edge-installer

printf "Downloading helper files to temporary directory ./iot-edge-installer\n"
download_bash_script validate-tier1-os.sh
download_bash_script install-container-management.sh
download_bash_script install-edge-runtime.sh
download_bash_script validate-post-install.sh
download_bash_script utils.sh
printf "Downloaded helper files to temporary directory ./iot-edge-installer\n"

# import utils
source utils.sh
log_init
handlers_init

function show_help() {
    echo ""
    echo "${BOLD}Usage: sudo ./azure-iot-edge-installer.sh [OPTION]...${DEFAULT}"
    echo ""
    echo "${BOLD}Basic:${DEFAULT}"
    echo -e "\t-h, --help\t\t\t\t\tPrint this help"
    echo ""
    echo "${BOLD}Connection String Provisioning:${DEFAULT}"
    echo -e "\t-c, --connection-string <CONNECTION_STRING>\tThe Azure IoT Edge Device Connection String"
    echo -e "${MAGENTA}\tThe default provisioning method. For example,"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -c \"<Connection String>\""
    echo -e "${DEFAULT}"
    echo "${BOLD}DPS Provisioning:${DEFAULT}"
    echo -e "\t-s, --scope-id <SCOPE_ID>\t\t\tThe Azure DPS ID Scope"
    echo -e "\t-r, --registration-id <REGISTRATION_ID>\t\tThe Azure IoT DPS enrollment Registration ID"
    echo -e "\t-k, --symmetric-key <SYMMETRIC_KEY>\t\tThe Symmetric Key for the individual enrollment"
    echo -e "${MAGENTA}\tThree arguments above are all neccessary for DPS provisioning. For example,"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -s <ID Scope> -r <Registration ID> -k <Symmetric Key>"
    echo "${DEFAULT}"
    echo "${BOLD}Telemetry:${DEFAULT}"
    echo -e "\t-nt, --telemetry-opt-out\t\t\tDisable usage telemetry feature"
    echo -e "\t-cv, --correlation-vector\t\t\tCorrelation vector specific to the run\n"
}

# add flag:variable_name dictionary entries
add_option_args "TELEMETRY_OPT_OUT" -nt --telemetry-opt-out
add_option_args "VERBOSE_LOGGING" -v --verbose
add_option_args "SCOPE_ID" -s --scope-id
add_option_args "REGISTRATION_ID" -r --registration-id
add_option_args "SYMMETRIC_KEY" -k --symmetric-key
add_option_args "CORRELATION_VECTOR" -cv --correlation-vector
add_option_args "SHOW_HELP" -h --help
add_option_args "CONNECTION_STRING" -c --connection-string

# parse command line inputs and fetch output from parser
declare -A parsed_cmds="$(cmd_parser $@)"

# show usage
if [[ ${#@} == 0 || "${parsed_cmds["SHOW_HELP"]}" != "" ]];
then
    show_help
    exit ${EXIT_CODES[1]}
fi

# validate that all arguments are acceptable / known
if [[ ${#@} > 0 && ${#parsed_cmds[*]} == 0 ]];
then
    array=("$*")
    echo Unknown argument "${array[*]}"
    show_help
    exit ${EXIT_CODES[1]}
fi

# is a connection string given for provisioning?
if [[ "${parsed_cmds["CONNECTION_STRING"]}" == "" ]];
then
    # validate that all DPS parameters have been provided
    if [[ "${parsed_cmds["SCOPE_ID"]}" == "" || "${parsed_cmds["REGISTRATION_ID"]}" == "" || "${parsed_cmds["SYMMETRIC_KEY"]}" == "" ]];
    then
        echo Missing argument
        echo     defined: "'"${!parsed_cmds[@]}"'"
        echo     given: "'"${parsed_cmds[@]}"'"
        show_help
        exit ${EXIT_CODES[2]}
    fi
else
    if [[ "${parsed_cmds["CONNECTION_STRING"]}" == "true" ]];
    then
        echo Missing argument
        echo     The IoTEdge device connection string must be provided with the '-c / --connection-string' option
        show_help
        exit ${EXIT_CODES[2]}
    fi
fi

set_opt_out_selection ${parsed_cmds["TELEMETRY_OPT_OUT"]} ${parsed_cmds["CORRELATION_VECTOR"]} ${parsed_cmds["SCOPE_ID"]} ${parsed_cmds["REGISTRATION_ID"]}

# check if current OS is Tier 1
source validate-tier1-os.sh
is_os_tier1
if [ "$?" != "0" ];
then 
    log_error "This OS is not supported. Please visit this link for more information https://docs.microsoft.com/en-us/azure/iot-edge/support?view=iotedge-2020-11#tier-1."
    exit ${EXIT_CODES[3]}
fi

# run scripts in order, can take parsed input from above
platform=$(get_platform)
prepare_apt $platform

source install-container-management.sh
install_container_management

source install-edge-runtime.sh
if [[ "${parsed_cmds["CONNECTION_STRING"]}" == "" ]];
then
    install_edge_runtime_dps ${parsed_cmds["SCOPE_ID"]} ${parsed_cmds["REGISTRATION_ID"]} ${parsed_cmds["SYMMETRIC_KEY"]}
else
    install_edge_runtime_cs ${parsed_cmds["CONNECTION_STRING"]}
fi

source validate-post-install.sh
validate_post_install

exit ${EXIT_CODES[0]}
