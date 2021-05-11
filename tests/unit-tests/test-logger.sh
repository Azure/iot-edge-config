#!/usr/bin/env bash

# bring in the utils library
source ../../src/utils.sh

output_init
echo OUT_FILE: $OUTPUT_FILE

output_error "%s %d %.3f" one 2 12.3042
output_error "two three"

output_warn "%s %d %.3f" one 2 12.3042
output_warn "two three"

output_info "%s %d %.3f" one 2 12.3042
output_info "two three"