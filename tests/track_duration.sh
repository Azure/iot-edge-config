#!/bin/bash

# Stop script on NZEC
set -e

# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

#bring in the library
source common_functions.sh

#
time_stamp=`date '+%Y-%m-%d %H:%M:%S'`
os_name="`uname`"
os_kernel="`uname -r`"
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
        --iot_hub)
            shift
            IH_CONN_STR=$1
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
            echo "  --iot_hub                      Specify iot hub connection string."
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
    python3 ih_send_one_message.py "$IH_CONN_STR" "{\"OSName\": \"$os_name\", \"Kernel\": \"$os_kernel\", \"TestName\": \"$test_name\", \"TimeStamp\": \"$time_stamp\", \"Duration\": ${runs[$iter]}}"
done

verbose_output ""
verbose_output "average run time for '$test_command' is: $(echo "scale = 3; $total/$count" | bc) seconds"
verbose_output "----------------------------------------------------------------------------------------------\n"
