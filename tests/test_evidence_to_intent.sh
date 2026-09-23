#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

validator=skills/evidence-to-intent/scripts/validate-evidence.sh
spec_validator=skills/evidence-to-intent/scripts/validate-specification.sh
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

"$validator" tests/fixtures/valid
"$validator" tests/fixtures/contradictory

mkdir -p "$tmp/run-1"
cat > "$tmp/run-1/intent-specification.md" <<'SPEC'
---
run_id: run-1
status: provisional
implementation_authorized: false
review_status: pending
reviewer:
reviewed_at:
decision:
rationale:
source_revision: fixture
---
# Intent specification
## Purpose and explicit boundary
Pending owner review.
## Owner facts and unresolved questions
Pending owner review.
## Evidence inventory by E/D/R/A class
Pending owner review.
## Contradictions, exclusions, and applicability
Pending owner review.
## Independently derived responsibility map
Pending owner review.
## Proposed intent and acceptance evidence
Pending owner review.
## Deterministic/orchestration/AI/human split
Pending owner review.
## External handoffs and non-responsibilities
Pending owner review.
## Candidate-name comparison
Pending owner review.
## Assumptions and NOT FOUND items
Pending owner review.
## Owner decision block
Pending owner review.
SPEC
"$spec_validator" "$tmp/run-1/intent-specification.md" --output-root "$tmp"

assert_fails() {
  local expected="$1" output="$2"
  shift 2
  set +e
  "$@" >"$output" 2>&1
  local status=$?
  set -e
  test "$status" -eq 2
  grep -q "$expected" "$output"
}

assert_fails 'duplicate evidence id: R-DUP-001' "$tmp/invalid.out" "$validator" tests/fixtures/invalid
grep -q 'invalid review_status: invented' "$tmp/invalid.out"
grep -q 'invalid kind: invented-kind' "$tmp/invalid.out"
grep -q 'invalid status: invented-status' "$tmp/invalid.out"
grep -q 'empty required field' "$tmp/invalid.out"
set +e
"$validator" tests/fixtures/invalid > "$tmp/invalid-second.out" 2>&1
second_status=$?
set -e
test "$second_status" -eq 2
cmp "$tmp/invalid.out" "$tmp/invalid-second.out"
assert_fails 'outside input root' "$tmp/traversal.out" "$validator" tests/fixtures/traversal

mkdir -p "$tmp/symlink/research/claims"
ln -s /etc/passwd "$tmp/symlink/escape"
cat > "$tmp/symlink/research/claims/symlink.md" <<'CARD'
---
id: R-PATH-002
title: Symlink escape
kind: empirical-claim
status: evaluated
review_status: reviewed
source_locator: ../../escape
---
# Symlink escape
CARD
assert_fails 'symlink source locators are not supported' "$tmp/symlink.out" "$validator" "$tmp/symlink"

mkdir -p "$tmp/malformed/research/claims"
printf '# Missing frontmatter\n' > "$tmp/malformed/research/claims/card.md"
assert_fails 'malformed frontmatter' "$tmp/malformed.out" "$validator" "$tmp/malformed"

sed '/^rationale:$/d' "$tmp/run-1/intent-specification.md" > "$tmp/run-1/invalid-spec.md"
assert_fails 'rationale:missing required field' "$tmp/spec.out" "$spec_validator" "$tmp/run-1/invalid-spec.md" --output-root "$tmp"

mkdir -p "$tmp/nested/run-1"
cp "$tmp/run-1/intent-specification.md" "$tmp/nested/run-1/intent-specification.md"
assert_fails 'must equal OUTPUT_ROOT/run-1/intent-specification.md' "$tmp/nested.out" "$spec_validator" "$tmp/nested/run-1/intent-specification.md" --output-root "$tmp"

sed 's/^run_id: run-1$/run_id:/' "$tmp/run-1/intent-specification.md" > "$tmp/run-1/empty-run-id.md"
assert_fails 'run_id:empty required field' "$tmp/empty.out" "$spec_validator" "$tmp/run-1/empty-run-id.md" --output-root "$tmp"

sed 's/^review_status: pending$/review_status: reviewed/' "$tmp/run-1/intent-specification.md" > "$tmp/run-1/reviewed-invalid.md"
assert_fails 'reviewer:required when reviewed' "$tmp/reviewed.out" "$spec_validator" "$tmp/run-1/reviewed-invalid.md" --output-root "$tmp"

sed '/^## Purpose and explicit boundary$/{n;d;}' "$tmp/run-1/intent-specification.md" > "$tmp/run-1/empty-section.md"
assert_fails 'section:missing or empty: Purpose and explicit boundary' "$tmp/section.out" "$spec_validator" "$tmp/run-1/empty-section.md" --output-root "$tmp"

echo "PASS: evidence-to-intent validators"
