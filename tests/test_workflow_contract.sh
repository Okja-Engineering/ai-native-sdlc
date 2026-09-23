#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# Consumer of the callable validator (proposal §12.6): the checks live in
# skills/sdlc-scaffold/scripts/validate-workflow-contract.sh so the exporter
# runs the same rules the S6 fixtures pin down.

validator="skills/sdlc-scaffold/scripts/validate-workflow-contract.sh"

failures=0

run_case() {
  local name="$1" path="$2" expected="$3"
  printf 'case: %s (expected %s)\n' "$name" "$expected"
  local actual=pass
  "$validator" "$path" >/dev/null 2>&1 || actual=fail
  if [[ "$actual" != "$expected" ]]; then
    printf '  MISMATCH: expected %s, got %s\n' "$expected" "$actual"
    "$validator" "$path" || true
    failures=$((failures + 1))
  else
    printf '  ok\n'
  fi
}

run_case "example-compact"        examples/leaked-db-errors/compact/SDLC.md                         pass
run_case "example-modular"        examples/leaked-db-errors/modular                                 pass
run_case "missing-authority"      tests/fixtures/workflow-contract/missing-authority.md             fail
run_case "conflicting-outputs"    tests/fixtures/workflow-contract/conflicting-outputs.md           fail
run_case "stale-evidence"         tests/fixtures/workflow-contract/stale-evidence.md                fail
run_case "undeclared-runtime-dep" tests/fixtures/workflow-contract/undeclared-runtime-dep.md        fail
run_case "runtime-output-mismatch" tests/fixtures/workflow-contract/runtime-output-mismatch.md      fail
run_case "runtime-path-alias"     tests/fixtures/workflow-contract/runtime-path-alias.md            fail
run_case "bad-enum-missing-input" tests/fixtures/workflow-contract/bad-enum-missing-input.md        fail
run_case "bad-enum-conflict"      tests/fixtures/workflow-contract/bad-enum-conflict.md             fail
run_case "bad-provenance"         tests/fixtures/workflow-contract/bad-provenance.md                fail
run_case "duplicate-field"        tests/fixtures/workflow-contract/duplicate-field.md               fail
run_case "malformed-line"         tests/fixtures/workflow-contract/malformed-line.md                fail
run_case "external-missing-actor" tests/fixtures/workflow-contract/external-missing-actor.md        fail
run_case "unsupported-version"    tests/fixtures/workflow-contract/unsupported-version.md           fail
run_case "no-workflow-block"      tests/fixtures/workflow-contract/no-workflow-block.md             fail
run_case "two-workflow-blocks"    tests/fixtures/workflow-contract/two-workflow-blocks.md           fail

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures workflow-contract case(s) mismatched" >&2
  exit 1
fi
echo "PASS: workflow-contract"
