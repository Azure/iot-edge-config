#!/usr/bin/env bash

echo "Running test-validate-tier1-os.sh"

source ../../src/utils.sh
source ../../src/validate-tier1-os.sh
source ../../tests/test_utils.sh

test_ubuntu1804() {
    ID="ubuntu"
    VERSION_ID="18.04"
    is_os_tier1 "$ID" "$VERSION_ID"
    assert_eq 0 $?
}

test_raspbian() {
    ID="raspbian"
    VERSION_ID="10"
    is_os_tier1 "$ID" "$VERSION_ID"
    assert_eq 0 $?
}

test_tier2() {
    ID="debian"
    VERSION_ID="9"
    is_os_tier1 "$ID" "$VERSION_ID"
    assert_eq 1 $?
}

# run tests
test_ubuntu1804
test_raspbian
test_tier2