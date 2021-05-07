#!/usr/bin/bash

# Stop script on NZEC
set -e

# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

#bring in the library
source common_functions.sh

#
time_stamp=`date '+%B/%d/%Y %H:%M:%S'`
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
done

out_file_name=$test_name'_'"$(echo $time_stamp | sed 's;/;;g')"
csv_file=$out_file_name.csv
jsn_file=$out_file_name.json
echo "" > "$csv_file"
echo "" > "$jsn_file"

average_time=$(bc -l <<< $total/$count)
verbose_output ""
verbose_output "average run time for '$test_command' is: $average_time seconds"
verbose_output "----------------------------------------------------------------------------------------------\n"

#generate csv
printf "%s\n" '-------------------------------------------------------------------------------------------------------------------------------------------'
printf "| %-40s| %-40s| %-30s| %-20s|\n" 'OS Identity' Test Timestamp Duration
printf "%s\n" '-------------------------------------------------------------------------------------------------------------------------------------------'
for ((iter=0; iter < $count; iter++))
do
    printf "%s, %s, %s, %.3f\r\n" "$os_name $os_kernel" $test_name "$time_stamp" ${runs[$iter]} >> "$csv_file"
    printf "| %-40s| %-40s| %-30s| %-20.3f|\n" "$os_name $os_kernel" $test_name "$time_stamp" ${runs[$iter]}
done
printf "%s\n" '-------------------------------------------------------------------------------------------------------------------------------------------'
printf "\r\n%s, %s, %s, %.3f\r\n" "$os_name $os_kernel" $test_name "$time_stamp" $average_time >> "$csv_file"
printf "| %-40s| %-40s| %-30s| %-20.3f|\n" "$os_name $os_kernel" $test_name "$time_stamp" $average_time

#generate JSON
printf "{\r\n" >> "$jsn_file"
printf "    \"OS Identity\": \"%s\",\r\n" "$os_name $os_kernel" >> "$jsn_file"
printf "    \"Test Name\": \"%s\",\r\n" $test_name >> "$jsn_file"
printf "    \"Timestamp\": \"%s\",\r\n" "$time_stamp" >> "$jsn_file"
printf "    \"Iterations\": [\r\n" >> "$jsn_file"
for ((iter=0; iter < $count-1; iter++))
do
    printf "        { \"Iteration\": "%d", \"Duration\": "%.3f" },\r\n" $iter ${runs[$iter]} >> "$jsn_file"
done
printf "        { \"Iteration\": "%d", \"Duration\": "%.3f" }\r\n" $iter ${runs[$count]} >> "$jsn_file"
printf "    ],\r\n" >> "$jsn_file"
printf "    \"Average\": "%.3f"\r\n" $average_time >> "$jsn_file"
printf "}\r\n" >> "$jsn_file"
