#!/usr/bin/env bash
set -euo pipefail

mkdir -p coverage

# Resolve Crystal executable (Linux CI typically has `crystal` on PATH).
CRYSTAL_BIN="${CRYSTAL_BIN:-crystal}"
if ! command -v "$CRYSTAL_BIN" >/dev/null 2>&1; then
  if command -v crystal.exe >/dev/null 2>&1; then
    CRYSTAL_BIN="crystal.exe"
  else
    echo "crystal executable not found on PATH. On Windows, use scripts/coverage.ps1." >&2
    exit 1
  fi
fi

# This project uses Crystal's built-in reachability analysis as a "coverage proxy".
# It reports method-level hit counts and can emit a Codecov-compatible JSON payload.
"$CRYSTAL_BIN" tool unreachable --tallies -f codecov spec/runner.cr > coverage/coverage.json
"$CRYSTAL_BIN" tool unreachable --tallies -f csv spec/runner.cr > coverage/unreachable.csv

# Produce a small summary focused on `src/` (library code only).
awk -F, '
  NR==1 { next }
  $3 ~ /^src[\\\\/]/ {
    total++
    if ($1 + 0 > 0) covered++
  }
  END {
    if (total == 0) {
      print "No methods found under src/."
      exit 0
    }
    pct = (covered * 100.0) / total
    printf("Reachability (methods under src/): %d/%d (%.2f%%)\\n", covered, total, pct)
    print "Report files:"
    print "- coverage/coverage.json (codecov format)"
    print "- coverage/unreachable.csv (counts + locations)"
  }
' coverage/unreachable.csv | tee coverage/summary.txt
