#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

validator="skills/verify-change/scripts/validate-verify-change.sh"
fixtures="tests/fixtures/verify-change"
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
run_case missing-receipt fail
run_case unreviewed-receipt fail
run_case invalid-decision fail
run_case revision-mismatch fail

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures verify-change fixture(s) mismatched" >&2
  exit 1
fi

echo "PASS: verify-change fixtures"
