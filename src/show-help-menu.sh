#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to show help menu

######################################
# show_help
#
#    - Display HELP menu for options
#
# ARGUMENTS:
#    None
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function show_help() {
    echo ""
    echo "${BOLD}Usage: sudo ./azure-iot-edge-installer.sh [OPTION]...${DEFAULT}"
    echo ""
    echo "${BOLD}Basic:${DEFAULT}"
    echo -e "\t-h, --help\t\t\t\t\tPrint this help"
    echo -e "\t-f, --force\t\t\t\t\tRun installation immediately without prompt"
    echo -e "\t-u, --upgrade\t\t\t\t\tInstall upgrades for the installed packages only and ignore new package installation"
    echo ""
    echo "${BOLD}Connection String Provisioning:${DEFAULT}"
    echo -e "\t-c, --connection-string <CONNECTION_STRING>\tThe Azure IoT Edge Device Connection String"
    echo -e "${MAGENTA}\tThe default provisioning method. For example,"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -c \"<Connection String>\""
    echo -e "${DEFAULT}"
    echo "${BOLD}DPS Provisioning:${DEFAULT}"
    echo -e "\t-s, --scope-id <SCOPE_ID>\t\t\tThe Azure DPS ID Scope"
    echo -e "\t-r, --registration-id <REGISTRATION_ID>\t\tThe Azure DPS enrollment Registration ID"
    echo -e "\t-k, --symmetric-key <SYMMETRIC_KEY>\t\tThe Symmetric Key for the individual enrollment"
    echo -e "${MAGENTA}\tThree arguments above are all neccessary for DPS provisioning. For example,"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -s <ID Scope> -r <Registration ID> -k <Symmetric Key>"
    echo "${DEFAULT}"
    echo "${BOLD}Advanced:${DEFAULT}"
    echo -e "\t-hn, --hostname [HOSTNAME]\t\t\tSet hostname for both device & IoT Edge"
    echo -e "${MAGENTA}\tIf no value is given, the hostname is automatically extracted from the connection string (DeviceID field)"
    echo -e "\tor set as the DPS registration id. Otherwise, the given value would overwrite the automatic naming options.\n"
    echo -e "\tPlease also notice that the hostname should comply with RFC 1035."
    echo -e "\t - Hostname must be between 1 and 255 octets inclusive."
    echo -e "\t - Each label in the hostname (component separated by \".\") must be between 1 and 63 octets inclusive."
    echo -e "\t - Each label must start with an ASCII alphabet character (a-z, A-Z), end with an ASCII alphanumeric character (a-z, A-Z, 0-9), and must contain only ASCII alphanumeric character or hypens (a-z, A-Z, 0-9, \"-\")"
    echo "${DEFAULT}"
    echo -e "\t-i, --input-file <INPUT_FILE>\t\t\tRead the configurations from a JSON format input file"
    echo -e "${MAGENTA}\tIt supports the 'action' field. Please refer to .json files in the 'config' folder."
    echo -e "\tFor example, you can do provisioning only by this way: (make sure 'aziot-edge' is installed before running this)"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -i config/provision-only.json -c \"<Connection String>\""
    echo -e "\t- OR -"
    echo -e "\t$ sudo ./azure-iot-edge-installer.sh -i config/provision-only.json -s <ID Scope> -r <Registration ID> -k <Symmetric Key>"
    echo "${DEFAULT}"
    echo "${BOLD}Telemetry:${DEFAULT}"
    echo -e "\t-nt, --telemetry-opt-out\t\t\tDisable usage telemetry feature"
    echo -e "\t-cv, --correlation-vector\t\t\tCorrelation vector specific to the run\n"
}
