#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

VERSION_TAG="v0.0.0-rc0"

# create flag:variable_name dictionary
declare -A flag_to_variable_dict

add_option_args() {
    if [[ $# > 1 ]];
    then
        local option_flag=$1; shift
        local var_name=$1; shift
        flag_to_variable_dict[$option_flag]=$var_name
    fi
}

# generic command line parser
function cmd_parser() {
    # create flag:variable_name dictionary
    declare -A parsed_cmd

    for arg in "$@"
    do
        if [[ $arg == -* ]];
        then
            # iterate over all the keys in dictionary
            local valid_arg="false"
            for k in ${!flag_to_variable_dict[*]};
            do
                # if arg==key, then we store into flag_to_val_dict 
                if [ "$arg" == "$k" ];
                then 
                    # set parsed_cmd, which is varname:value
                    parsed_cmd[${flag_to_variable_dict[$k]}]=$2
                    valid_arg="true"
                    break
                fi
            done

            # found an unknown argument
            if [[ "$valid_arg" == "false" ]];
            then
                parsed_cmd=()
                break
            fi
        fi
        shift # Remove argument name from processing
    done

    # view content of entire dictionary
    echo '('
    for key in  "${!parsed_cmd[@]}";
    do
        echo "[$key]=${parsed_cmd[$key]}"
    done
    echo ')'
}

#
line_prefix() {
    local TIME_STAMP=$(echo `date '+%Y-%m-%d %H:%M:%S.%N'`)
    echo "$TIME_STAMP $1"
}

#
log() {
    if [[ $# > 1 ]];
    then
        local TYPE=$1; shift
        local LP=$(line_prefix "[$TYPE]: ")
        local FS=$1; shift

        if [[ -f "$OUTPUT_FILE" ]];
        then
            printf "$LP$FS\n" $@ >> "$OUTPUT_FILE"
        fi
        printf "$LP$FS\n" $@ > /dev/stdout
    fi
}

#
# logger 
log_init() {
    local BASE_NAME=`basename $0`
    local TD=$TEMPDIR
    if [[ "$TD" == "" ]];
    then
        TD="/tmp"
    fi
    OUTPUT_FILE=$TD"/"$(echo ${BASE_NAME%.*})-$(echo `date '+%Y-%m-%d'`).log
    touch $OUTPUT_FILE

    echo "All logs will be appended to this file '"$OUTPUT_FILE"'"
}

#
log_error() {
    log "ERR" "$@"
}

#
log_info() {
    log "INFO" "$@"
}

#
log_warn() {
    log "WARN" "$@"
}

#
log_debug() {
    log "DEBUG" "$@"
}

export -f log_init log_error log_info log_warn log_debug

######################################
# prepare_apt
#
#    installs Azure IoT Edge Runtime 1.2
#    generates the edge's configuration file from template and
#       fills in the DPS provisioning section from provided parameters
#
# ARGUMENTS:
#    OS_PLATFORM - a string specifying the location of specific platform files
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function prepare_apt() {
    if [ $# != 1 ];
    then
        exit 1
    else
        local platform=$1
        if [[ "$platform" == "" ]];
        then
            log_error "Unsupported platform."
            exit 2
        else
            sources="https://packages.microsoft.com/config/"$platform"/multiarch/prod.list"

            # sources list
            log_info "Adding'%s' to repository lists." $sources
            wget $sources -q -O /etc/apt/sources.list.d/microsoft-prod.list

            # the key
            wget https://packages.microsoft.com/keys/microsoft.asc -q -O /dev/stdout | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

            # update
            apt update
        fi
    fi
}
