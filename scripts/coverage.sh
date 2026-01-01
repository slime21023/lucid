#!/usr/bin/env bash
set -euo pipefail

mkdir -p bin coverage

crystal build --debug spec/runner.cr -o bin/spec_runner

if ! command -v kcov >/dev/null 2>&1; then
  echo "kcov is not installed. Install it (e.g. Debian/Ubuntu: sudo apt-get install -y kcov)." >&2
  exit 1
fi

kcov \
  --clean \
  --include-path=src \
  --exclude-pattern=spec,lib \
  coverage \
  ./bin/spec_runner

echo "Coverage report generated at: coverage/index.html"

