#!/usr/bin/env bash

# generic command line parser
function cmd_parser() {
    for arg in "$@"
    do
        if [[ $arg == -* ]]; then
            # iterate over all the keys in dictionary
            for k in ${!flag_to_variable_dict[*]} ; do
                # if arg==key, then we store into flag_to_val_dict 
                if [ "$arg" == "$k" ]; then 
                    # set parsed_cmd, which is varname:value
                    parsed_cmd[${flag_to_variable_dict[$k]}]=$2
                    break
                fi
            done
        fi
        shift # Remove argument name from processing
    done
    
    # view content of entire dictionary
    # echo '('
    # for key in  "${!parsed_cmd[@]}" ; do
    #     echo "[$key]=${parsed_cmd[$key]}"
    # done
    # echo ')'
}