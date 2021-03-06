#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

source ../../src/utils.sh
source ../../src/validate-post-install.sh
source ../test_utils.sh

test_service_running() {
    is_service_running "servicenameA" "servicenameA Running"
    assert_eq 0 $?
}

test_service_ready() {
    is_service_running "servicenameA" "servicenameA Ready"
    assert_eq 0 $?
}

test_service_not_running() {
    is_service_running "servicenameA" "servicenameA Failed"
    assert_eq 1 $?
}

test_service_missing() {
    is_service_running "servicenameA" "servicenameB Running"
    assert_eq 1 $?
}

test_service_casesensitive() {
    is_service_running "servicenameA" "servicenameA ruNNing"
    assert_eq 0 $?
}

test_service_casesensitive() {
    is_service_running "servicenameA" "servicenameA ruNNing"
    assert_eq 0 $?
}

# run tests
test_service_running
test_service_ready
test_service_not_running
test_service_missing
test_service_casesensitive

show_test_totals
