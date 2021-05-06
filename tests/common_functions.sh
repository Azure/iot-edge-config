#!/usr/bin/bash

#
error_output() {
    printf "%b\n" "${red:-}Error: $1${normal:-}" >&2
}

output() {
    printf "%b\n" "${cyan:-}${normal:-} $1" >&3
}

verbose_output() {
    if [ "$verbose" = true ];
    then
        output "$1"
    fi
}

export -f error_output
export -f output
export -f verbose_output
