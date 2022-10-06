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

VERSION_TAG="v$(apt-cache policy eai-installer | grep Installed | cut -d ' ' -f 4)"
if [[ $VERSION_TAG == "v" ]];
then
    VERSION_TAG="unknown"
fi

# Percept specific packages
declare -a percept_packages=("aziot-identity-service"
                             "aziot-edge"
                             "osconfig"
                             "defender-iot-micro-agent-edge")
declare -a package_versions=("1.4.0-1"
                             "1.4.0-1"
                             "1.0.3.2022061604"
                             "4.2.4")

# where am I
TOPDIR=$(dirname $0)

# script
printf "Welcome to azure-iot-edge-installer (${VERSION_TAG})\n"
printf "\n%s\n" "-------------------------"
printf "Telemetry\n"
printf "%s\n" "---------"
printf "The azure-iot-edge-installer collects usage data in order to improve your experience.\n"
printf "The data is anonymous and does not include commandline argument values.\n"
printf "The data is collected by Microsoft.\n"
printf "You can change your telemetry settings by adding -nt or --telemetry-opt-out to the command line.\n"
printf "\n"

# setup env
export DEBIAN_FRONTEND=noninteractive

# import utils
source utils.sh
log_init
handlers_init

# add flag:variable_name dictionary entries
add_option_args "TELEMETRY_OPT_OUT" -nt --telemetry-opt-out
add_option_args "VERBOSE_LOGGING" -v --verbose
add_option_args "SCOPE_ID" -s --scope-id
add_option_args "REGISTRATION_ID" -r --registration-id
add_option_args "SYMMETRIC_KEY" -k --symmetric-key
add_option_args "CORRELATION_VECTOR" -cv --correlation-vector
add_option_args "FORCE_RUN" -f --force
add_option_args "SHOW_HELP" -h --help
add_option_args "CONNECTION_STRING" -c --connection-string
add_option_args "HOSTNAME" -hn --hostname
add_option_args "UPGRADE" -u --upgrade
add_option_args "INPUT_FILE" -i --input-file

# load help menu
source show-help-menu.sh

# parse command line inputs and fetch output from parser
declare -A parsed_cmds="$(cmd_parser $@)"

# show usage
if [[ ${#@} == 0 || "${parsed_cmds["SHOW_HELP"]}" != "" ]];
then
    show_help
    exit ${EXIT_CODES[0]}
fi

# show special characters limitation for connection string
if [[ "$@" == *"-c"* || "$@" == *"--connection-string"* ]];
then
    conn_string="${parsed_cmds["CONNECTION_STRING"]}"
    device_tmp=${conn_string#*;DeviceId=}
    device_id=${device_tmp%;SharedAccessKey=*}

    if [[ ${#@} > 0 && ${#parsed_cmds[*]} == 0 ]] ||
       [[ "${device_id}" == *"="* || "${device_id}" == *"%"* || "${device_id}" == *"!"* || "${device_id}" == *"$"* ]];
    then
        echo "CONNECTION_STRING = \"${conn_string}\""
        echo ""
        echo "${YELLOW}Please notice the installer does not support the following special characters for DeviceId in the connection string!"
        echo " - equal sign ( = )"
        echo " - percent sign ( % )"
        echo " - exclamation mark ( ! )"
        echo " - dollar sign ( $ )${DEFAULT}"
        show_help
        exit ${EXIT_CODES[1]}
    fi
fi

# validate that all arguments are acceptable / known
if [[ ${#@} > 0 && ${#parsed_cmds[*]} == 0 ]];
then
    array=("$*")
    echo Unknown argument "${array[*]}"
    show_help
    exit ${EXIT_CODES[1]}
fi

# upgrade packages
if [[ "${parsed_cmds["UPGRADE"]}" != "" ]];
then
    only_upgrade
    exit ${EXIT_CODES[0]}
fi

# parse input config file
if [[ "${parsed_cmds["INPUT_FILE"]}" != "" ]];
then
    source read-config-file.sh
    prepare_json
    file_parser ${parsed_cmds["INPUT_FILE"]}
fi

# check arguments for provisioning
if [[ "${parsed_cmds["INPUT_FILE"]}" == "" ]] ||
   [[ "${parsed_cmds["INPUT_FILE"]}" != "" && "${parsed_cfgs[{action}{do_provisioning}]}" == "true" ]];
then
if [[ "${parsed_cmds["CONNECTION_STRING"]}" == "" ]];
then
if [[ "${parsed_cmds["SCOPE_ID"]}" == "" || "${parsed_cmds["REGISTRATION_ID"]}" == "" || "${parsed_cmds["SYMMETRIC_KEY"]}" == "" ]];
then
    echo Missing provisioning argument
    echo     defined: "'"${!parsed_cmds[@]}"'"
    echo     given: "'"${parsed_cmds[@]}"'"
    show_help
    exit ${EXIT_CODES[2]}
fi
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

### Installation ###
if [[ "${parsed_cmds["INPUT_FILE"]}" == "" ]] ||
   [[ "${parsed_cmds["INPUT_FILE"]}" != "" && "${parsed_cfgs[{action}{do_install}]}" == "true" ]];
then

# run scripts in order, can take parsed input from above
platform=$(get_platform)
prepare_apt $platform

source install-container-management.sh
install_container_management

source install-edge-runtime.sh
install_edge_runtime

source install-percept-packages.sh
install_osconfig
install_defender

configure_percept_services

fi

### Hotfix ###
if [[ "${parsed_cmds["INPUT_FILE"]}" == "" ]] ||
   [[ "${parsed_cmds["INPUT_FILE"]}" != "" && "${parsed_cfgs[{action}{do_hotfix}]}" == "true" ]];
then

source install-hotfix.sh
is_aarch64
if [ "$?" == "0" ];
then
    # arm64
    install_defender_hotfix
else
    # amd64
    log_info "No hotfix is required!"
fi

fi

### Provisioning & Configuration ###
source provision-and-configure.sh
if [[ "${parsed_cmds["INPUT_FILE"]}" == "" ]] ||
   [[ "${parsed_cmds["INPUT_FILE"]}" != "" && "${parsed_cfgs[{action}{do_provisioning}]}" == "true" ]];
then

setup_product_info
stop_iotedge_service
if [[ "${parsed_cmds["CONNECTION_STRING"]}" == "" ]];
then
    setup_hostname ${parsed_cmds["HOSTNAME"]} ${parsed_cmds["REGISTRATION_ID"]}
    dps_provisioning ${parsed_cmds["SCOPE_ID"]} ${parsed_cmds["REGISTRATION_ID"]} ${parsed_cmds["SYMMETRIC_KEY"]}
else
    setup_hostname ${parsed_cmds["HOSTNAME"]} ${parsed_cmds["CONNECTION_STRING"]}
    cs_provisioning ${parsed_cmds["CONNECTION_STRING"]}
fi

fi
reset_percept_services

### Validation ###
source validate-post-install.sh
validate_post_install
show_package_version

exit ${EXIT_CODES[0]}
