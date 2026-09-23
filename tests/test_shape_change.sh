#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

validator="skills/shape-change/scripts/validate-shape-change.sh"
fixtures="tests/fixtures/shape-change"
failures=0

run_case() {
  local name="$1" expected="$2"
  local fixture="$fixtures/$name"
  printf 'case: %s (expected %s)\n' "$name" "$expected"
  if "$validator" "$fixture" >/dev/null 2>&1; then
    actual="pass"
  else
    actual="fail"
  fi
  if [[ "$actual" != "$expected" ]]; then
    printf '  MISMATCH: expected %s, got %s\n' "$expected" "$actual"
    failures=$((failures + 1))
  else
    printf '  ok\n'
  fi
}

run_case valid pass
run_case missing-slice fail
run_case unreviewed-intent fail
run_case invalid-decision fail

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures shape-change fixture(s) mismatched" >&2
  exit 1
fi

echo "PASS: shape-change fixtures"
