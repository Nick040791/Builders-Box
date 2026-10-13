#!/usr/bin/env python3
"""Fail a JMeter smoke run on any 5xx response or an error rate above a threshold.

Usage: perf/check-results.py <results.jtl> [max_error_pct]
A small error allowance exists because the Browse group can occasionally pick a
build that a concurrent Builder thread just deleted (a 404 test-data race, not a server fault).
"""
import csv
import sys

path = sys.argv[1]
max_err = float(sys.argv[2]) if len(sys.argv) > 2 else 2.0
rows = list(csv.DictReader(open(path, newline="")))
if not rows:
    sys.exit("No samples recorded")
failed = [r for r in rows if r["success"] != "true"]
server_errors = [r for r in rows if r["responseCode"].startswith("5")]
err_pct = 100.0 * len(failed) / len(rows)
elapsed = sorted(int(r["elapsed"]) for r in rows)
p95 = elapsed[min(len(elapsed) - 1, int(0.95 * len(elapsed)))]
print(f"samples={len(rows)} errors={len(failed)} ({err_pct:.2f}%) 5xx={len(server_errors)} "
      f"avg_ms={sum(elapsed)/len(elapsed):.1f} p95_ms={p95} max_ms={elapsed[-1]}")
for r in failed:
    print(f"  FAIL {r['label']}: {r['responseCode']} {r['failureMessage'][:120]}")
if server_errors or err_pct > max_err:
    sys.exit(f"Perf smoke failed (5xx={len(server_errors)}, error%={err_pct:.2f} > {max_err}?)")
