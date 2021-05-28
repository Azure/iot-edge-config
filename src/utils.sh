#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# create flag:variable_name dictionary
declare -A flag_to_variable_dict

# output color indicators
RED=$(echo -en "\e[31m")
GREEN=$(echo -en "\e[32m")
MAGENTA=$(echo -en "\e[35m")
DEFAULT=$(echo -en "\e[00m")
BOLD=$(echo -en "\e[01m")
BLINK=$(echo -en "\e[5m")

# OPT_IN - set to true if the user opts in for sending telemetry information to us.
OPT_IN=false

# EXIT_CODES - an array of intigers indicating an exit status
declare -a EXIT_CODES=(0    # success
                       1    # invalid argument is given at the command line
                       2    # a required argument is missing
                       3    # os is not supported
                       4    # step 1 of apt-get failed
                       5    # step 2 of apt-get failed
                       6    # step 3 of apt-get failed
                       7    # step 4 of apt-get failed
                       8    # failed to install moby-engine
                       9    # a version of edge-runtime is already installed
                       10   # step 1 of installing edge-runtime failed
                       11   # step 2 of installing edge-runtime failed
                       12   # step 3 of installing edge-runtime failed
                       13   # step 4 of installing edge-runtime failed
                       14   # ctrl-c or kill
                      )

CORRELATION_VECTOR=""
DEVICE_UNIQUE_ID=""

######################################
# set_opt_out_selection
#
#    records the user's choice of opting out of telemetry
#
# ARGUMENTS:
#    does_the_user_NOT_consent_to_sending_telemetry
#    correlation vector specific to the run
#    scope id
#    registration id
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function set_opt_out_selection() {
    if [[ "$LOCAL_E2E" == "1" || $1 == true ]];
    then
        OPT_IN=false
        log_info "The user has opted out of sending usage telemetry."
    else
        OPT_IN=true
        log_info "The user has opted in for sending usage telemetry."

        # handle correlation vector
        if [ -z $2 ];
        then
            CORRELATION_VECTOR=$(generate_uuid)
        else
            CORRELATION_VECTOR=$2
        fi

        local ret_value=$(openssl dgst -hmac $INSTRUMENTATION_KEY <<< `echo $3$4`)
        DEVICE_UNIQUE_ID=${ret_value##* }
    fi
}

function get_opt_in_selection() {
    echo "$OPT_IN"
}

export -f set_opt_out_selection get_opt_in_selection

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
# cmd_parser
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
        printf "$LP$FS\n" $@
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

    STDOUT_REDIRECT=$TD"/"$(echo ${BASE_NAME%.*})-$(echo `date '+%Y-%m-%d'`).out
    echo "-----------------------------------" `date '+%H:%M:%S.%N'` "-----------------------------------" >> $STDOUT_REDIRECT

    STDERR_REDIRECT=$TD"/"$(echo ${BASE_NAME%.*})-$(echo `date '+%Y-%m-%d'`).err
    echo "-----------------------------------" `date '+%H:%M:%S.%N'` "-----------------------------------" >> $STDERR_REDIRECT
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
        exit ${EXIT_CODES[2]}
    else
        local platform=$1
        if [[ "$platform" == "" ]];
        then
            log_error "Unsupported platform."
            exit ${EXIT_CODES[3]}
        else
            sources="https://packages.microsoft.com/config/"$platform"/multiarch/prod.list"

            # sources list
            log_info "Adding '%s' to package sources lists." $sources
            wget $sources -q -O /etc/apt/sources.list.d/microsoft-prod.list 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
            local exit_code=$?
            if [[ $exit_code != 0 ]];
            then
                log_error "prepare_apt() step 1 failed with error: %d" exit_code
                exit ${EXIT_CODES[4]}
            fi
            log_info "Added '%s' to package sources lists." $sources

            log_info "Downloading key"
            local tmp_file=$(echo `mktemp -u`)
            wget https://packages.microsoft.com/keys/microsoft.asc -q -O $tmp_file 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
            exit_code=$?
            if [[ $exit_code != 0 ]];
            then
                log_error "prepare_apt() step 2 failed with error %d" exit_code
                rm -f /etc/apt/sources.list.d/microsoft-prod.list 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
                exit ${EXIT_CODES[5]}
            fi

            # unpack the key
            local gpg_file=/etc/apt/trusted.gpg.d/microsoft.gpg
            if [[ -f $gpg_file ]];
            then
                rm -f $gpg_file 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
            fi
            gpg --dearmor --output $gpg_file $tmp_file
            exit_code=$?

            rm -f $tmp_file 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT

            if [[ $exit_code != 0 ]];
            then
                log_error "prepare_apt() step 2 failed with error %d" $exit_code
                rm -f /etc/apt/sources.list.d/microsoft-prod.list 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
                exit ${EXIT_CODES[6]}
            fi
            log_info "Downloaded key"

            # update
            log_info "update - Retrieve new lists of packages"
            apt-get update 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT &
            long_running_command $!
            exit_code=$?
            log_info "update step completed with exit code: %d" $exit_code
        fi
    fi
}

BG_PROCESS_ACTIVE=false
BG_PROCESS_ID=-1
######################################
# long_running_process
#
#    while a long-running process executes, shows 'busy' waiting feedback
#
# ARGUMENTS:
#    the ID of a bg process
#
# OUTPUTS:
# RETURN:
#
######################################

function long_running_command() {
    if [[ $# == 1 ]];
    then
        BG_PROCESS_ID=$1
        BG_PROCESS_ACTIVE=true

        while [ $BG_PROCESS_ACTIVE == true ];
        do
            for next_symbol in '-' '\\' '|' '/';
            do
                echo -en "$next_symbol\b"
                sleep 0.15
                local MYPS=$(ps -a | awk '/'$BG_PROCESS_ID'/ {print $1}')
                if [ "$MYPS" == "" ];
                then
                    BG_PROCESS_ACTIVE=false
                    break
                fi
            done
        done
        echo -en " \b"
        wait $BG_PROCESS_ID
        BG_PROCESS_ID=-1
    fi
}

######################################
# handle_ctrl_c
#
#     will be called when 'ctrl-c' or kill-9 is issued by the user.
#     if a bg process has been launched, wait for it to finish.
#
# ARGUMENTS:
#
# OUTPUTS:
#
# RETURN:
#
######################################

function handle_ctrl_c() {
    log_info "ctrl C\n"
    if [[ "$BG_PROCESS_ID" != "-1" ]];
    then
        while kill -0 $BG_PROCESS_ID &> /dev/null;
        do
            wait $BG_PROCESS_ID;
        done

        BG_PROCESS_ACTIVE=false
        BG_PROCESS_ID=-1
    fi

    exit ${EXIT_CODES[14]}
}

######################################
# handle_exit
#
#    will report telemetry if user has opted in
#    will be called whenever an exit is encountered
#
# ARGUMENTS:
#    exit code
#
# OUTPUTS:
# RETURN:
#
######################################

function handle_exit() {
    local e_code=$?
    log_info "Exit %d" $e_code

    local end=`date +%s`
    runtime=$((end-start))
    log_info "Runtime duration %d" $runtime

    send_appinsight_event_telemetry $e_code $runtime

    # cleanup, always
    cd ..
    if [ -d "iot-edge-installer" ]
    then
        log_info "Removing temporary directory files for iot-edge-installer."
        rm -rf iot-edge-installer 
        log_info "Removed temporary directory files for iot-edge-installer."
    fi

    if [[ "$LOCAL_E2E" == "1" ]];
    then
        if [[ $e_code != 0 ]];
        then
            echo errors-file -----------------------------
            cat $STDERR_REDIRECT
            echo errors-file -----------------------------
        fi
        echo stdout-file -----------------------------
        cat $STDOUT_REDIRECT
        echo stdout-file -----------------------------
    fi

    announce_my_log_file "All logs were appended to" $OUTPUT_FILE
}

######################################
# handlers_init
#
# ARGUMENTS:
#    initialize handlers
#
# OUTPUTS:
# RETURN:
#
######################################

function handlers_init() {
    trap handle_ctrl_c SIGINT
    trap handle_exit EXIT
}

export -f handlers_init

######################################
# generate_uuid
#
# ARGUMENTS:
#    generate UUIDs
#
# OUTPUTS: UUID
# RETURN:
#
######################################

source /etc/os-release
function generate_uuid() {
    case $ID in
        ubuntu)
            uuidgen
            ;;

        raspbian)
            uuid
            ;;

        *)
            log_error "OS is not Tier 1"
            ;;
    esac
}

# Constants
INSTRUMENTATION_KEY="d403f627-57b8-4fb0-8001-c51b7466682d"
INGESTION_POINT="https://dc.services.visualstudio.com/v2/track"
TELEMETRY_EVENT_NAME="Azure-IoT-Edge-Installer-Summary"
TELEMETRY_SCHEMA_VERSION="1.0"

######################################
# send_appinsight_event_telemetry
#
#    Send Application Insights event as a REST POST request with JSON body containing telemetry
#
# ARGUMENTS:
#    CustomProperties: "status":[EXIT_CODE]
#    CustomMeasurements: "duration":    
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################

function send_appinsight_event_telemetry ()
{
    local customPropertiesObj='"status":'$1''
    local customMeasurementsObj='"duration":'$2''

    # validate that the user has opted in for telemetry collection
    local optin=$(get_opt_in_selection)
    if [[ $optin == true ]];
    then
        log_info "Ready to send telemetry to AppInsights endpoint with wget"
        local CurrentTime=$(echo `date --utc '+%Y-%m-%dT%H:%M:%S.%N'`)

        wget --header='Content-Type: application/json' --header='Accept-Charset: UTF-8' --post-data '{"name":"Microsoft.ApplicationInsights.'$INSTRUMENTATION_KEY'.Event","time": "'$CurrentTime'","iKey": "'$INSTRUMENTATION_KEY'","tags":{"ai.cloud.roleInstance": "'$DEVICE_UNIQUE_ID'"},"data":{"baseType": "EventData","baseData": {"ver": "'$TELEMETRY_SCHEMA_VERSION'","name": "'$TELEMETRY_EVENT_NAME'","cv": "'$CORRELATION_VECTOR'","properties":{'$customPropertiesObj'},"measurements":{'$customMeasurementsObj'}}}}' $INGESTION_POINT 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT

        log_info "Finished sending telemetry to AppInsights endpoint with wget"
    fi
}

