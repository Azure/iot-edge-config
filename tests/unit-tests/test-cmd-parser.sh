#!/usr/bin/env bash

# import utils.sh
source ../../src/utils.sh

# create flag:variable_name dictionary
declare -A flag_to_variable_dict

# add flag:variable name dictionary entries
flag_to_variable_dict[-v]="VERBOSE_LOGGING"
flag_to_variable_dict[-dp]="DEVICE_PROVISIONING"
flag_to_variable_dict[-ap]="AZURE_CLOUD_IDENTITY_PROVIDER"
flag_to_variable_dict[-s]="SCOPE_ID"
flag_to_variable_dict[-r]="REGISTRATION_ID"
flag_to_variable_dict[-k]="SYMMETRIC_KEY"

# unit test to test all illegal flags, output should be empty
test_illegal_flags() {
    # create flag:variable_name dictionary
    declare -A parsed_cmd

    # parse command line inputs
    cmd_parser -illegal val -t anotherillegalval -z yetanotherillegalval

    # fetch output from parser
    parsed_cmd="$(cmd_parser)"

    # compare output, should be empty
    if [ "${parsed_cmd[*]}" != "" ]; then
        echo "Failed to pass unit test 'test_illegal_flags' in test-cmd-parser.sh. Non-empty result: ${parsed_cmd[*]}"
    fi
}

test_all_legal_flags() {
    # create flag:variable_name dictionary
    declare -A parsed_cmd

    # parse command line inputs
    cmd_parser -dp 1 -ap 5 -s 2 -r 4 -k 3 -v 6

    # fetch output from parser
    parsed_cmd="$(cmd_parser)"

    # compare output, should be 123456
    if [ "${parsed_cmd[*]}" != "1 2 3  4 5 6" ]; then
        echo "Failed to pass unit test 'test_all_legal_flags' in test-cmd-parser.sh. Non-empty result: ${parsed_cmd[*]}"
    fi
}

test_extra_arguments() {
    # create flag:variable_name dictionary
    declare -A parsed_cmd

    # parse command line inputs
    cmd_parser illegalinput 0 -ap 4 -s 1 -r 3 more -extra -k 2

    # fetch output from parser
    parsed_cmd="$(cmd_parser)"

    # compare output, should be 1 2 3 4
    if [ "${parsed_cmd[*]}" != "1 2  3 4" ]; then
        echo "Failed to pass unit test 'test_extra_arguments' in test-cmd-parser.sh. Non-empty result: ${parsed_cmd[*]}"
    fi
}

# run all tests
test_illegal_flags
test_all_legal_flags
test_extra_arguments