#!/usr/bin/env bash

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

# add flag:variable_name dictionary entries
# if you require new flags to be parsed, add more lines here
add_option_args -v "VERBOSE_LOGGING"
add_option_args --verbose "VERBOSE_LOGGING"
add_option_args -dp "DEVICE_PROVISIONING"
add_option_args --device-provisioning "DEVICE_PROVISIONING"
add_option_args -ap "AZURE_CLOUD_IDENTITY_PROVIDER"
add_option_args --azure-cloud-identity-provider "AZURE_CLOUD_IDENTITY_PROVIDER"
add_option_args -s "SCOPE_ID"
add_option_args --scope-id "SCOPE_ID"
add_option_args -r "REGISTRATION_ID"
add_option_args --registration-id "REGISTRATION_ID"
add_option_args -k "SYMMETRIC_KEY"
add_option_args --symmetric-key "SYMMETRIC_KEY"


# generic command line parser
function cmd_parser() {
    # create flag:variable_name dictionary
    declare -A parsed_cmd

    for arg in "$@"
    do
        if [[ $arg == -* ]]; then
            # iterate over all the keys in dictionary
            for k in ${!flag_to_variable_dict[*]} ; do
                # if arg==key, then we store into flag_to_val_dict 
                if [ "$arg" == "$k" ]; 
                then 
                    # set parsed_cmd, which is varname:value
                    parsed_cmd[${flag_to_variable_dict[$k]}]=$2
                    break
                fi
            done
        fi
        shift # Remove argument name from processing
    done
    
    # view content of entire dictionary
    echo '('
    for key in  "${!parsed_cmd[@]}" ; do
        echo "[$key]=${parsed_cmd[$key]}"
    done
    echo ')'
}