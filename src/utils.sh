#!/usr/bin/env bash

VERSION_TAG="v0.0.0-rc0"
#OUTPUT_FILE = &1

#
line_prefix() {
    local TIME_STAMP=$(echo `date '+%Y-%m-%d %H:%M:%S.%N'`)
    echo "$TIME_STAMP $1"
}

#
#
output_init() {
    local BASE_NAME=`basename $0`
    local TD=$TEMPDIR
    if [[ "$TD" == "" ]]; then
        TD="/tmp"
    fi
    OUTPUT_FILE=$TD"/"$(echo ${BASE_NAME%.*})-$(echo `date '+%Y-%m-%d'`).log
    touch $OUTPUT_FILE
}

#
output_error() {
    if [[ $# > 0 ]]; then
        local FS=$1
        shift
        local LP=$(line_prefix "[ERR]: ")
        printf "$LP$FS\n" $@ >> "$OUTPUT_FILE"
    fi
}

#
output_info() {
    if [[ $# > 0 ]]; then
        local FS=$1
        shift
        local LP=$(line_prefix "[INFO]: ")
        printf "$LP$FS\n" $@ >> "$OUTPUT_FILE"
    fi
}

#
output_warn() {
    if [[ $# > 0 ]]; then
        local FS=$1
        shift
        local LP=$(line_prefix "[WARN]: ")
        printf "$LP$FS\n" $@ >> "$OUTPUT_FILE"
    fi
}

export output_init output_error output_info output_warn