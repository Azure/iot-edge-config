#!/usr/bin/env bash

exec 3>&1

# bring in the utils library
source ../../src/utils.sh
source ../test_utils.sh

log_init
assert_file $OUTPUT_FILE

WC_L=`wc -l "$OUTPUT_FILE"`
WC=${WC_L% *}
assert_eq 0 $WC

log_error "%s %d %.3f" one 2 12.3042
log_error "two three"
WC_L=`wc -l "$OUTPUT_FILE"`
WC=${WC_L% *}
assert_eq 2 $WC

log_warn "%s %d %.3f" one 2 12.3042
log_warn "two three"
WC_L=`wc -l "$OUTPUT_FILE"`
WC=${WC_L% *}
assert_eq 4 $WC

log_info "%s %d %.3f" one 2 12.3042
log_info "two three"
WC_L=`wc -l "$OUTPUT_FILE"`
WC=${WC_L% *}
assert_eq 6 $WC

STRVAL1="One"
INTVAL1=45
FLOATVAL1=2453.56890
log_info "---------------------------------------------"
log_info "'%s'  ;" "$STRVAL1"
log_info "%.2f" $FLOATVAL1
WC_L=`wc -l "$OUTPUT_FILE"`
WC=${WC_L% *}
assert_eq 9 $WC

show_test_totals
rm $OUTPUT_FILE