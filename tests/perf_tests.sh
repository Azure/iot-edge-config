#!/usr/bin/env bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

###################################### 
# perf_tests
#
# runs performance tests
# ARGUMENTS:
#    an integer - number of times to run each test
# OUTPUTS:
# RETURN:
#   0 on success, -1 otherwise
######################################


subscription=$(az account show | awk '/"id/ { print substr($2,2,36) }')

# for each test ...
echo ./track_duration.sh -c $1 -t ./e2e-tests/test-devicestate.sh $subscription
cd e2e-tests
../track_duration.sh -v -c $1 -t ./test-devicestate.sh $subscription
cd ..

exit 0