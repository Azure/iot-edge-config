#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#script to read JSON format input file

######################################
# prepare_json
#
#    - Check perl package for json query feature
#
# ARGUMENTS:
#
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################
function prepare_json() {
    if [ "x$(command -v json_pp)" != "x" ];
    then
        log_info "Perl JSON::PP module is available"
    else
        log_error "Please install 'perl' package for --input-file option by running '${YELLOW}sudo apt-get install perl -y${DEFAULT}'."
        exit ${EXIT_CODES[6]}
    fi
}

######################################
# file_parser
#
#    - Parse configurations from the input json file
#
# ARGUMENTS:
#    JSON file path
# OUTPUTS:
#    Write output to stdout
# RETURN:
#
######################################
declare -A parsed_cfgs
declare -a cfg_options=("{action}{do_install}"
                        "{action}{do_provisioning}"
                        "{action}{do_hotfix}")

function file_parser() {
    local perl_cmd='local $/;my $json=JSON::PP->new;print $json->encode( $json->decode(<STDIN>)->'
    local is_found=false

    if [ $# != 1 ];
    then
        exit ${EXIT_CODES[2]}
    else
        input_file=$1
        if [ -f $input_file ];
        then
            log_info "Read configurations from %s ..." $input_file
            for key in ${!cfg_options[*]};
            do
                cat $input_file | perl -MJSON::PP -e "${perl_cmd}${cfg_options[$key]} )" 2>>$STDERR_REDIRECT 1>>$STDOUT_REDIRECT
                exit_code=$?
                if [[ $exit_code == 0 ]];
                then
                    is_found=true
                fi

                parsed_cfgs[${cfg_options[$key]}]=$(cat $input_file | perl -MJSON::PP -e "${perl_cmd}${cfg_options[$key]} )" 2>>$STDERR_REDIRECT)
                log_info "\t${YELLOW}${cfg_options[$key]} = ${parsed_cfgs[${cfg_options[$key]}]}${DEFAULT}"
            done
            if [[ $is_found == false ]];
            then
                log_error "Cannot find valid item! Please check the input file."
                exit ${EXIT_CODES[2]}
            fi

            # prompt to users for action
            if [[ "${parsed_cmds["FORCE_RUN"]}" == "" ]];
            then
                read -p "Is the configuration correct? [Y/n] " ans
                if [ ${ans^} == 'Y' ];
                then
                    log_info "Processing the configuration ..."
                else
                    exit ${EXIT_CODES[2]}
                fi
            else
                log_info "Force to process the configuration ..."
            fi
        else
            log_error "The config file '%s' does not exist!" $input_file
            exit ${EXIT_CODES[2]}
        fi
    fi
}
