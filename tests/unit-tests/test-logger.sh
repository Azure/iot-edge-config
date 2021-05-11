#!/usr/bin/env bash

# bring in the utils library
source ../../src/utils.sh

log_init
echo OUT_FILE: $OUTPUT_FILE

log_error "%s %d %.3f" one 2 12.3042
log_error "two three"

log_warn "%s %d %.3f" one 2 12.3042
log_warn "two three"

log_info "%s %d %.3f" one 2 12.3042
log_info "two three"

STRVAL1="One"
INTVAL1=45
FLOATVAL1=2453.56890
log_info "---------------------------------------------"
log_info "'%s'  ;" "$STRVAL1"
log_info "%2.f" $FLOATVAL1

cat $OUTPUT_FILE
rm $OUTPUT_FILE
