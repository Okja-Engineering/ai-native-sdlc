#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

validator="skills/sdlc-scaffold/scripts/validate-scaffold-input.sh"
fixtures="tests/fixtures/sdlc-scaffold"
failures=0

run_case() {
  local name="$1" repo="$2" spec="$3" expected="$4"
  printf 'case: %s (expected %s)\n' "$name" "$expected"
  if "$validator" "$repo" "$spec" >/dev/null 2>&1; then
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

run_case valid "$fixtures/valid/target-repo" "$fixtures/valid/workflow-specification.md" pass
run_case missing-repo "$fixtures/valid/nonexistent-repo" "$fixtures/valid/workflow-specification.md" fail
run_case missing-spec "$fixtures/missing-spec/target-repo" "$fixtures/missing-spec/workflow-specification.md" fail
run_case bad-spec "$fixtures/bad-spec/target-repo" "$fixtures/bad-spec/workflow-specification.md" fail

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures sdlc-scaffold fixture(s) mismatched" >&2
  exit 1
fi

echo "PASS: sdlc-scaffold fixtures"
