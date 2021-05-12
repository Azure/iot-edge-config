#!/usr/bin/env bash

# import utils.sh
source ../../src/utils.sh

# unit test to test all illegal flags, output should be empty
test_illegal_flags() {
    # parse sample input to parser
    declare -A parsed_cmds="$(cmd_parser -illegal val -t anotherillegalval -z yetanotherillegalval)"

    # compare output, should be empty
    if [ "${parsed_cmds[*]}" != "" ]; then
        echo "Failed to pass unit test 'test_illegal_flags' in test-cmd-parser.sh. Non-empty result: ${parsed_cmds[*]}"
    fi
}

test_all_legal_flags() {
    # parse sample input to parser
    declare -A parsed_cmds="$(cmd_parser -dp 1 -ap 5 -s 2 -r 4 -k 3 -v 6)"

    # compare output, should be 123456
    if [ "${parsed_cmds[*]}" != "1 2 3 4 5 6" ]; then
        echo "Failed to pass unit test 'test_all_legal_flags' in test-cmd-parser.sh. Non-empty result: ${parsed_cmds[*]}"
    fi
}

test_extra_arguments() {
    # parse sample input to parser
    declare -A parsed_cmds="$(cmd_parser illegalinput 0 -ap 4 -s 1 -r 3 more -extra -k 2)"

    # compare output, should be 1 2 3 4
    if [ "${parsed_cmds[*]}" != "1 2 3 4" ]; then
        echo "Failed to pass unit test 'test_extra_arguments' in test-cmd-parser.sh. Non-empty result: ${parsed_cmds[*]}"
    fi
}

# run all tests
test_illegal_flags
test_all_legal_flags
test_extra_arguments