#!/usr/bin/env bash

if command -v tput &>/dev/null && tty -s; then
  RED=$(tput setaf 1)
  GREEN=$(tput setaf 2)
  MAGENTA=$(tput setaf 5)
  NORMAL=$(tput sgr0)
  BOLD=$(tput bold)
else
  RED=$(echo -en "\e[31m")
  GREEN=$(echo -en "\e[32m")
  MAGENTA=$(echo -en "\e[35m")
  NORMAL=$(echo -en "\e[00m")
  BOLD=$(echo -en "\e[01m")
fi

#
error_output() {
    printf "%b\n" "${RED:-}Error: $1${NORMAL:-}" >&2
}

output() {
    printf "%b\n" "${BOLD:-}${NORMAL:-} $1" >&2
}

verbose_output() {
    if [ "$verbose" = true ];
    then
        output "$1"
    fi
}

export -f output error_output verbose_output

NR_PASSING=0
NR_FAILING=0
NR_TOTALS=0
assert_eq() {
    local expected=$1; shift
    local actual=$1; shift

    NR_TOTALS=$(bc <<< $NR_TOTALS+1)
    if [ "$expected" == "$actual" ];
    then
        NR_PASSING=$(bc <<< $NR_PASSING+1)
    else
        NR_FAILING=$(bc <<< $NR_FAILING+1)
        error_output "expected: $expected; actual: $actual"
    fi
}

assert_file() {
    local file_name=$1; shift

    NR_TOTALS=$(bc <<< $NR_TOTALS+1)
    if [[ -f $file_name ]];
    then
        NR_PASSING=$(bc <<< $NR_PASSING+1)
    else
        NR_FAILING=$(bc <<< $NR_FAILING+1)
        error_output "please call log_init prior to running the tests."
        exit -1
    fi
}

show_test_totals() {
    local BN=`basename $0`

    printf "\n"
    printf "$BN: total tests %d; %d passing; %d failing" "$NR_TOTALS" $NR_PASSING $NR_FAILING
    printf "\n\n"
}

export -f assert_eq assert_file show_test_totals