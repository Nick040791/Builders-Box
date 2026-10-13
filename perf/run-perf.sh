#!/usr/bin/env bash
# Usage: perf/run-perf.sh [users] [duration_s] [ramp_s]
# Runs the Builder's Box JMeter plan non-GUI against localhost and builds the HTML dashboard.
set -euo pipefail
cd "$(dirname "$0")"
USERS=${1:-25}; DURATION=${2:-180}; RAMP=${3:-30}
STAMP=$(date +%Y%m%d-%H%M)
mkdir -p results
OUT="report-${USERS}u-${STAMP}"
jmeter -n -t builders-box.jmx \
  -Jusers="$USERS" -Jduration="$DURATION" -Jramp="$RAMP" \
  -Jjmeter.reportgenerator.overall_granularity=10000 \
  -Jjmeter.reportgenerator.report_title="Builder's Box API - ${USERS} users" \
  -l "results/run-${USERS}u-${STAMP}.jtl" -e -o "$OUT"
echo "Dashboard: perf/$OUT/index.html"
