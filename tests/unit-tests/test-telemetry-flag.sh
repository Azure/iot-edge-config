#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

exec 3>&1

# bring in the utils library
source ../../src/utils.sh
source ../test_utils.sh

function test_flag_on() {
    set_opt_out_selection true
    assert_eq $(get_opt_in_selection) false
}

function test_flag_off() {
    set_opt_out_selection false
    assert_eq $(get_opt_in_selection) true
}

test_flag_on
test_flag_off
show_test_totals
