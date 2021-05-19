#!/usr/bin/env bash

exec 3>&1

# bring in the utils library
source ../../src/utils.sh
source ../test_utils.sh

function test_flag_on() {
    set_opt_in_selection true
    assert_eq $(get_opt_in_selection) true
}

function test_flag_off() {
    set_opt_in_selection false
    assert_eq $(get_opt_in_selection) false
}

test_flag_on
test_flag_off
show_test_totals
