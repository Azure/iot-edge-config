#!/usr/bin/env bash

###################################### 
# track_duration
#
# compute duration of runs for a given command and report them as messages
# to a predefined device associated with a specific azure iot hub
# ARGUMENTS:
#   v/verbose   if set, generates verbose logs
#   c/count     specify the number of runs
#   t/test      sepcify which command to run. Must be the last parameter
#               all arguments will be passed as is to the specified command
# OUTPUTS:
#   sends duration reports to the cloud
# RETURN:
#   0 on success, -1 otherwise
######################################

# Stop script on NZEC
set -e

# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

# bring in the library
source common_functions.sh

#
verbose=false
count=1
test_command=""
script_name="$(basename "$0")"
declare -a runs
while [ $# -ne 0 ]
do
    name="$1"
    case "$name" in
        -v|--verbose|-[Vv]erbose)
            verbose=true
            ;;
        -c|--count|-[Cc]ount)
            shift
            count=$1
            ;;
        -t|--test|-[Tt]est)
            shift
            test_command="$@"
            test_name="$1"
            shift $(bc <<< $#-1)
            ;;
        -?|--?|-h|--help|-[Hh]elp)
            echo "Usage: $script_name [OPTIONS] -t|--test TestToRun [TEST_OPTIONS]"
            echo "       $script_name -h|-?|--help"
            echo ""
            echo "$script_name is a simple command line interface for collecting test runs duration averages."
            echo "      --test option specifies which test to run, with arguments, and must appear as the last option."
            echo ""
            echo "Options:"
            echo "  --verbose,-Verbose             Display diagnostics information."
            echo "  --count,-Count                 Specify number of runs."
            echo "  -?,--?,-h,--help,-Help         Shows this help message"
            echo ""
            exit 0
            ;;
        *)
            error_output "Unknown argument \`$name\`"
            exit 1
    esac

    shift
done

if [ $count -lt 0 ];
then
    exit 0
fi

if [ "$test_command" == "" ];
then
    exit 0
fi

#
IH_CONN_STR=$(az iot hub device-identity connection-string show -n e2etest-iotc-hub -d e2etest_iotc_d | awk '/connection/ { print $2 }' | sed -e 's;";;g')

time_stamp=`date '+%Y-%m-%d %H:%M:%S'`
os_name="`uname`"
os_kernel="`uname -r`"

total=0.0
verbose_output ""
for ((curr = 1; curr <= $count; curr++))
do
    start=`date +%s.%N`
    command $test_command
    end=`date +%s.%N`

    runs[$curr-1]=$(bc <<< $end-$start)
    total=$(bc <<< $total+${runs[$curr-1]})
    verbose_output "run $curr took $(bc <<< $end-$start) seconds"
    python3 send_one_message_to_iot_hub_device.py "$IH_CONN_STR" "{\"OSName\": \"$os_name\", \"Kernel\": \"$os_kernel\", \"TestName\": \"$test_name\", \"TimeStamp\": \"$time_stamp\", \"Duration\": ${runs[$iter]}}"
done

verbose_output ""
verbose_output "average run time for '$test_command' is: $(echo "scale = 3; $total/$count" | bc) seconds"
verbose_output "----------------------------------------------------------------------------------------------\n"
