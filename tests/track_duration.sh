#!/usr/bin/bash

# Stop script on NZEC
set -e

# Exposing stream 3 as a pipe to standard output of the script itself
exec 3>&1

#
error_output() {
    printf "%b\n" "${red:-}Error: $1${normal:-}" >&2
}

output() {
    printf "%b\n" "${cyan:-}${normal:-} $1" >&3
}

verbose_output() {
    if [ "$verbose" = true ]; then
        output "$1"
    fi
}

#
verbose=false
count=1
script_name="$(basename "$0")"
while [ $# -ne 0 ]
do
    name="$1"
    case "$name" in
        -v|--verbose|-[Vv]erbose)
            verbose=true
            non_dynamic_parameters+=" $name"
            ;;
        -c|--count|-[Cc]ount)
            shift
            count=$1
            ;;
        -t|--test|-[Tt]est)
            shift
            test_command="$@"
	    shift $(bc <<< $#-1)
            ;;
        -?|--?|-h|--help|-[Hh]elp)
            echo "Usage: $script_name [OPTIONS] -t|--test <command with arguments>"
            echo "       $script_name -h|-?|--help"
            echo ""
            echo "$script_name is a simple command line interface for collecting test runs time averages"
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

total=0.0
verbose_output ""
for ((curr = 1; curr <= $count; curr++))
do
    start=`date +%s.%N`
    command $test_command
    end=`date +%s.%N`
    total=$(bc <<< $total+$end-$start)
    verbose_output "run $curr took $(bc <<< $end-$start) seconds"
done

verbose_output ""
verbose_output "----------------------------------------------------------------------------------------------"
output "average run time for '$test_command' is: $(bc -l <<< $total/$count) seconds"
