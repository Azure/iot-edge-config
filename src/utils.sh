#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# create flag:variable_name dictionary
declare -A flag_to_variable_dict

RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")
MAGENTA=$(echo -en "\e[35m")
DEFAULT=$(echo -en "\e[00m")
BOLD=$(echo -en "\e[01m")
BLINK=$(echo -en "\e[5m")


######################################
# add_option_args
#
#    declare a valid command-line argument(s)
#
# ARGUMENTS:
#    OPTION_NAME    The name of the argument (e.g "VERBOSE")
#    a list of one or more argument switches (e.g "-v", "--verbose")
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function add_option_args() {
    if [[ $# > 1 ]];
    then
        local option_name=$1; shift
        while [ $# -ne 0 ];
        do
            flag_to_variable_dict[$1]=$option_name
            shift
        done
    fi
}

######################################
# clear_option_args
#
#    clears the list of valid command-line arguments
#
# ARGUMENTS:
#
# OUTPUTS:
#
# RETURN:
#
######################################

function clear_option_args() {
    flag_to_variable_dict=()
}

######################################
# clear_option_args
#
#    populates a dictionary of arguments and values from
#    a given command line
#
# ARGUMENTS:
#    command line
# OUTPUTS:
#
# RETURN:
#    dictionary
######################################

function cmd_parser() {
    # create flag:variable_name dictionary and initialize to empty string
    declare -A parsed_cmd
    for key in ${!flag_to_variable_dict[*]};
    do
        parsed_cmd[${flag_to_variable_dict[$key]}]=""
    done

    while [ $# -ne 0 ];
    do
        if [[ $1 == -* ]];
        then
            local valid_argument=false
            # for each key in the dictionary
            for key in ${!flag_to_variable_dict[*]};
            do
                if [ "$1" == "$key" ]
                then
                    valid_argument=true
                    if [[ $# == 1 || $2 == -* ]];
                    then
                        parsed_cmd[${flag_to_variable_dict[$key]}]=true
                    else
                        parsed_cmd[${flag_to_variable_dict[$key]}]=$2
                        shift
                    fi
                    break
                fi
            done

            # found an unknown argument
            if [[ "$valid_argument" == "false" ]];
            then
                parsed_cmd=()
                break
            fi
        else
            parsed_cmd=()
            break
        fi

        shift
    done

    # view content of entire dictionary
    echo '('
    for key in "${!parsed_cmd[@]}";
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
function announce_my_log_file() {
    printf '\n------\n%s%s%s%s%s\n------\n\n' "$GREEN" "$BOLD" "$BLINK" "$1 '$2'" "$DEFAULT"
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

    announce_my_log_file "All logs will be appended to file" $OUTPUT_FILE
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

export -f announce_my_log_file log_init log_error log_info log_warn log_debug

######################################
# prepare_apt
#
#    adds the needed microsoft sources list and key to the apt repository
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
