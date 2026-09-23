#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# S10 outcome-evaluation tests — evaluate-outcome.sh (proposal §14).
# Dynamic fixtures: a valid workflow contract with its own acceptance
# record; targets carry an acceptance record and a digest-bound intent
# link; evidence exercises observed/missing/conflicted/stale/
# non-comparable, baseline handling, destination preflight, determinism.

EVAL="skills/evaluate-outcome/scripts/evaluate-outcome.sh"
NORM="skills/sdlc-scaffold/scripts/normalize-workflow.sh"

failures=0
check() { # name, ok(0)/bad(1), detail
  if [[ "$2" -eq 0 ]]; then printf '  ok — %s\n' "$1"; else
    printf '  MISMATCH — %s: %s\n' "$1" "$3"; failures=$((failures + 1))
  fi
}

t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT
repo="$t/repo"; outdir="$t/out"; mkdir -p "$repo" "$outdir"

# minimal VALID workflow contract — workflow block + one declared stage
mk_contract() { # FILE
  cat > "$1" <<'EOF'
# Contract
```contract
id: mini
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-a
risk_scaling: none
owner: tester
```
```contract
id: 01-a
kind: internal
purpose: exercise the evaluator
inputs: none
outputs: changes/{s}/o.md
acceptance: a
decides: tester
may_not: x
decisions: accept
runtime_deps: none
adoption_deps: none
context_entry: c
context_explore: none
context_never: none
on_missing_input: stop
on_conflict: retain-both
reentry: r
review_fields: review_status | decision
```
EOF
}

# content-bound acceptance record for an arbitrary reviewed document
mk_record() { # FILE REVIEWEDFILE SCHEMA
  local rd; rd="sha256:$("$NORM" "$2" | shasum -a 256 | awk '{print $1}')"
  cat > "$1" <<EOF
# Acceptance
\`\`\`contract
id: acc-$3
kind: contract-acceptance
schema_version: contract-acceptance/0.1.0
contract: $(basename "$2")
contract_schema: $3
contract_digest: $rd
reviewer: owner
reviewed_at: 2026-09-20
decision: accept
rationale: reviewed for dogfood pilot
\`\`\`
EOF
}

mk_targets() { # FILE — two targets: O-P (product), O-R (process)
  local digest; digest="sha256:$("$NORM" "$repo/SDLC.md" | shasum -a 256 | awk '{print $1}')"
  cat > "$1" <<EOF
# Targets
\`\`\`contract
id: targets-test
kind: outcome-targets
schema_version: outcome-targets/0.1.0
intent_digest: $digest
target: O-P ; product ; claims resolvable to sources ; measure:claim-source-resolution ; unit:ratio ; scope:snapshot-claims ; duration:6d ; basis:manual-count
target: O-R ; process ; review effort per slice ; measure:review-effort ; unit:review-hours ; scope:per-slice ; duration:6d ; basis:owner-log
\`\`\`
EOF
}

mk_evidence() { # FILE — stdin body of evidence/lesson lines
  { printf '%s\n' '# Evidence' '' '```contract' \
      'id: ev-test' 'kind: outcome-evidence' 'schema_version: outcome-evidence/0.1.0'
    cat
    printf '%s\n' '```'; } > "$1"
}

mk_contract "$repo/SDLC.md"
mk_record "$repo/SDLC.accept.md" "$repo/SDLC.md" workflow-contract/0.1.0
mk_targets "$repo/targets.md"
mk_record "$repo/targets.accept.md" "$repo/targets.md" outcome-targets/0.1.0

# full declared comparability surface for a supported before/after:
# fixed fields period/unit/basis/rev + measure/scope checked against the
# target + sampling/conditions declared pairwise.
OP_TAIL='measure:claim-source-resolution ; scope:snapshot-claims ; sampling:full-snapshot ; conditions:clean-checkout'
OR_TAIL='measure:review-effort ; scope:per-slice ; sampling:owner-logged ; conditions:normal-week'

mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
lesson: acceptance records caught a post-review edit ; owner:note-4
EOF
mk_evidence "$repo/baseline.md" <<EOF
evidence: O-P ; 15/20 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 5.0 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:review-hours ; basis:owner-log ; rev:r0 ; $OR_TAIL
EOF

run_eval() { # extra args...
  "$EVAL" --contract "$repo/SDLC.md" --contract-acceptance "$repo/SDLC.accept.md" \
    --targets "$repo/targets.md" --targets-acceptance "$repo/targets.accept.md" \
    --evidence "$repo/evidence.md" \
    --baseline "$repo/baseline.md" --implementation-rev r1 \
    --inputs-root "$repo" --out "$outdir/receipt.md" "$@"
}

echo "== S10 outcome evaluation"

# 1. happy path — receipt created, both kinds observed, comparison supported
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 0 ]] && grep -q 'CREATE ' "$t/out.txt" \
  && grep -q 'outcome: O-P ; product ; observed' "$t/out.txt" \
  && grep -q 'comparison: supported' "$t/out.txt" \
  && grep -q 'baseline: "15/20"' "$t/out.txt" \
  && grep -q 'contract_acceptance:' "$t/out.txt" \
  && grep -q 'targets_acceptance:' "$t/out.txt" \
  && check "observed outcomes with supported before/after" 0 "" \
  || check "observed outcomes with supported before/after" 1 "rc=$rc $(cat "$t/err.txt" "$t/out.txt")"

# 2. missing acceptance record refuses before evaluation
rm -f "$outdir/receipt.md"
rc=0; run_eval --targets-acceptance "$repo/nonexistent.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && check "missing acceptance refuses" 0 "" \
  || check "missing acceptance refuses" 1 "rc=$rc $(cat "$t/err.txt")"

# 3. altered targets after acceptance refuse
cp "$repo/targets.md" "$t/targets.orig"
sed -i '' 's/claims resolvable/claims partially resolvable/' "$repo/targets.md"
rm -f "$outdir/receipt.md"
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
mv "$t/targets.orig" "$repo/targets.md"
[[ "$rc" -ne 0 ]] && grep -qi 'differs from reviewed digest' "$t/err.txt" \
  && check "altered targets after acceptance refuse" 0 "" \
  || check "altered targets after acceptance refuse" 1 "rc=$rc $(cat "$t/err.txt")"

# 4. changed contract breaks the accepted-intent link
cp "$repo/SDLC.md" "$t/SDLC.orig"
sed -i '' 's/risk_scaling: none/risk_scaling: low-collapses/' "$repo/SDLC.md"
rm -f "$outdir/receipt.md"
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
mv "$t/SDLC.orig" "$repo/SDLC.md"
[[ "$rc" -ne 0 ]] && check "changed contract breaks accepted-intent link" 0 "" \
  || check "changed contract breaks accepted-intent link" 1 "rc=$rc $(cat "$t/err.txt")"

# 5. missing baseline — observation still reported, improvement NOT FOUND
rm -f "$outdir/receipt.md"
run_eval --baseline "" > "$t/out.txt"
grep -q 'outcome: O-P ; product ; observed' "$t/out.txt" \
  && grep -q 'baseline: NOT FOUND' "$t/out.txt" \
  && grep -q 'comparison: unsupported' "$t/out.txt" \
  && check "missing baseline reports observation, improvement NOT FOUND" 0 "" \
  || check "missing baseline reports observation, improvement NOT FOUND" 1 "$(cat "$t/out.txt")"

# 6. conflicting evidence — both values preserved verbatim
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-P ; 12/20 ; owner:recount ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; conflicted' "$t/out.txt" \
  && grep -q '"19/20"' "$t/out.txt" && grep -q '"12/20"' "$t/out.txt" \
  && check "conflicting evidence preserved verbatim" 0 "" \
  || check "conflicting evidence preserved verbatim" 1 "$(cat "$t/out.txt")"

# 7. unit mismatch → non-comparable naming the field
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 4 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:wall-clock-days ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-R ; process ; non-comparable' "$t/out.txt" \
  && grep -q 'non-comparable: unit!=review-hours' "$t/out.txt" \
  && check "unit mismatch reported non-comparable naming field" 0 "" \
  || check "unit mismatch reported non-comparable naming field" 1 "$(cat "$t/out.txt")"

# 8. insufficient comparability info — missing unit reported, not inferred
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit: ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; non-comparable' "$t/out.txt" \
  && grep -qE 'non-comparable: [^;]*unit' "$t/out.txt" \
  && check "missing unit reported non-comparable, not inferred" 0 "" \
  || check "missing unit reported non-comparable, not inferred" 1 "$(cat "$t/out.txt")"

# 9. different dates, equal duration — still comparable
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-10-01..2026-10-07 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-10-01..2026-10-07 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; observed' "$t/out.txt" \
  && grep -q 'comparison: supported' "$t/out.txt" \
  && check "different dates, equal duration stay comparable" 0 "" \
  || check "different dates, equal duration stay comparable" 1 "$(cat "$t/out.txt")"

# 10. changed implementation revision — stale + re-evaluation required
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; stale' "$t/out.txt" \
  && grep -q 'reevaluation: required' "$t/out.txt" \
  && grep -q 'rev:r0' "$t/out.txt" \
  && check "changed revision marks stale, preserves observation" 0 "" \
  || check "changed revision marks stale, preserves observation" 1 "$(cat "$t/out.txt")"

# 11. determinism — identical inputs, identical receipt bytes
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > /dev/null
cp "$outdir/receipt.md" "$t/r1.md"
rm -f "$outdir/receipt.md"
run_eval > /dev/null
cmp -s "$t/r1.md" "$outdir/receipt.md" \
  && check "identical inputs produce identical receipt" 0 "" \
  || check "identical inputs produce identical receipt" 1 "$(diff "$t/r1.md" "$outdir/receipt.md")"

# 12a. destination inside inspected repo refused
rc=0; "$EVAL" --contract "$repo/SDLC.md" --contract-acceptance "$repo/SDLC.accept.md" \
  --targets "$repo/targets.md" --targets-acceptance "$repo/targets.accept.md" \
  --evidence "$repo/evidence.md" \
  --implementation-rev r1 --inputs-root "$repo" --out "$repo/receipt.md" \
  > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ ! -f "$repo/receipt.md" ]] \
  && check "destination inside inspected repo refused" 0 "" \
  || check "destination inside inspected repo refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 12b. existing differing file REFUSEd and preserved
printf 'owner content\n' > "$outdir/receipt.md"
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ "$(cat "$outdir/receipt.md")" == "owner content" ]] \
  && check "existing differing receipt preserved (REFUSE)" 0 "" \
  || check "existing differing receipt preserved (REFUSE)" 1 "rc=$rc $(cat "$t/err.txt")"

# 12c. identical re-run → SAME
rm -f "$outdir/receipt.md"; run_eval > /dev/null
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 0 ]] && grep -q '^SAME ' "$t/out.txt" \
  && check "repeat evaluation reports SAME" 0 "" \
  || check "repeat evaluation reports SAME" 1 "rc=$rc $(cat "$t/out.txt")"

# 12d. --out that IS a directory → refused, nothing written
mkdir -p "$t/dirdest"
rc=0; run_eval --out "$t/dirdest" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ -z "$(find "$t/dirdest" -type f)" ]] \
  && check "directory destination refused" 0 "" \
  || check "directory destination refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 12e. --out symlink to the inspected repository → refused; repo untouched
ln -s "$repo" "$t/sneaky"
rc=0; run_eval --out "$t/sneaky" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ ! -e "$repo/receipt.md" && ! -e "$repo/sneaky" ]] \
  && check "destination symlink into inspected repo refused" 0 "" \
  || check "destination symlink into inspected repo refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 12f. --out symlink to a file inside the inspected repo → refused
printf 'seed\n' > "$repo/existing.md"
ln -s "$repo/existing.md" "$t/linkout"
rc=0; run_eval --out "$t/linkout" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ "$(cat "$repo/existing.md")" == "seed" ]] \
  && check "destination symlink to repo file refused, file preserved" 0 "" \
  || check "destination symlink to repo file refused, file preserved" 1 "rc=$rc $(cat "$t/err.txt")"
rm -f "$repo/existing.md"

# 12g. --out dangling symlink → refused (fail closed)
ln -s "$t/nonexistent-target" "$t/dangling"
rc=0; run_eval --out "$t/dangling" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 4 ]] && [[ ! -e "$t/nonexistent-target" ]] \
  && check "dangling destination symlink refused" 0 "" \
  || check "dangling destination symlink refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 13. missing evidence → missing + gap
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; missing' "$t/out.txt" \
  && grep -q 'O-P: evidence NOT FOUND' "$t/out.txt" \
  && check "missing evidence reported with gap" 0 "" \
  || check "missing evidence reported with gap" 1 "$(cat "$t/out.txt")"

# 14. lesson listed as candidate, never confirmed
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
lesson: targets drifted once before acceptance ; owner:note-4
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'status:candidate' "$t/out.txt" \
  && grep -q 'Candidate lessons' "$t/out.txt" \
  && ! grep -q 'confirmed' "$t/out.txt" \
  && check "lessons listed as candidates only" 0 "" \
  || check "lessons listed as candidates only" 1 "$(cat "$t/out.txt")"

# 15. malformed evidence item rejected
mk_evidence "$repo/evidence.md" <<'EOF'
evidence: O-P is probably fine ; obs:run-9
EOF
rm -f "$outdir/receipt.md"
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && check "malformed evidence item rejected" 0 "" \
  || check "malformed evidence item rejected" 1 "rc=$rc $(cat "$t/err.txt")"

# 16. evidence for undeclared outcome rejected
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-ZZZ ; 1 ; obs:r ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
EOF
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'undeclared outcome' "$t/err.txt" \
  && check "evidence for undeclared outcome rejected" 0 "" \
  || check "evidence for undeclared outcome rejected" 1 "rc=$rc $(cat "$t/err.txt")"

# 17. unterminated targets fence fails closed
{ printf '%s\n' '# Targets' '' '```contract' 'id: x' 'kind: outcome-targets'; } > "$repo/targets.bad.md"
rc=0; "$EVAL" --contract "$repo/SDLC.md" --contract-acceptance "$repo/SDLC.accept.md" \
  --targets "$repo/targets.bad.md" --targets-acceptance "$repo/targets.accept.md" \
  --evidence "$repo/evidence.md" \
  --implementation-rev r1 --inputs-root "$repo" --out "$outdir/r.md" \
  > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'unterminated' "$t/err.txt" \
  && check "unterminated targets fence fails closed" 0 "" \
  || check "unterminated targets fence fails closed" 1 "rc=$rc $(cat "$t/err.txt")"
rm -f "$repo/targets.bad.md"

# 18. negative + inconclusive outcomes representable
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 5/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 9.0 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:wall-clock-days ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; observed ; "5/20"' "$t/out.txt" \
  && grep -q 'outcome: O-R ; process ; non-comparable' "$t/out.txt" \
  && ! grep -qiE 'verdict|score|pass|fail' "$t/out.txt" \
  && check "negative and inconclusive outcomes emitted without verdict" 0 "" \
  || check "negative and inconclusive outcomes emitted without verdict" 1 "$(cat "$t/out.txt")"

# --- Finding regressions ------------------------------------------------------

# 19. every baseline record evaluated — conflicting baseline stays unsupported
for order in a b; do
  if [[ "$order" == a ]]; then
    mk_evidence "$repo/baseline.md" <<EOF
evidence: O-P ; 15/20 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-P ; 10/20 ; obs:rerun ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 5.0 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:review-hours ; basis:owner-log ; rev:r0 ; $OR_TAIL
EOF
  else
    mk_evidence "$repo/baseline.md" <<EOF
evidence: O-P ; 10/20 ; obs:rerun ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-P ; 15/20 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 5.0 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:review-hours ; basis:owner-log ; rev:r0 ; $OR_TAIL
EOF
  fi
  rm -f "$outdir/receipt.md"
  run_eval > "$t/out.txt"
  grep -q 'baseline: conflicting observations' "$t/out.txt" \
    && grep -q '"15/20"' "$t/out.txt" && grep -q '"10/20"' "$t/out.txt" \
    && grep -q 'comparison: unsupported' "$t/out.txt" \
    && ! grep -q 'comparison: supported' "$t/out.txt" \
    && check "conflicting baseline preserved, unsupported (order $order)" 0 "" \
    || check "conflicting baseline preserved, unsupported (order $order)" 1 "$(cat "$t/out.txt")"
done
# restore canonical baseline
mk_evidence "$repo/baseline.md" <<EOF
evidence: O-P ; 15/20 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 5.0 ; owner:log ; period:2026-08-01..2026-08-07 ; unit:review-hours ; basis:owner-log ; rev:r0 ; $OR_TAIL
EOF

# 20. equal values are not duplicates — both-revisions-old rows mark
# re-evaluation; a current row plus an older same-value row stays observed
# with the historical record preserved. Both record orders.
for order in a b; do
  if [[ "$order" == a ]]; then
    mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-8 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r0b ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
  else
    mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r0b ; $OP_TAIL
evidence: O-P ; 19/20 ; obs:run-8 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r0 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
  fi
  rm -f "$outdir/receipt.md"
  run_eval > "$t/out.txt"
  grep -q 'outcome: O-P ; product ; stale' "$t/out.txt" \
    && grep -q 'reevaluation: required' "$t/out.txt" \
    && grep -q 'rev:r0\]' "$t/out.txt" && grep -q 'rev:r0b\]' "$t/out.txt" \
    && grep -q 'obs:run-8' "$t/out.txt" && grep -q 'obs:run-9' "$t/out.txt" \
    && check "same-value old-revision rows preserved, re-evaluate (order $order)" 0 "" \
    || check "same-value old-revision rows preserved, re-evaluate (order $order)" 1 "$(cat "$t/out.txt")"
done
# mixed current + historical same-value → observed, history preserved verbatim
for order in a b; do
  if [[ "$order" == a ]]; then
    mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-P ; 19/20 ; obs:run-7 ; period:2026-08-10..2026-08-16 ; unit:ratio ; basis:manual-count ; rev:r0 ; measure:claim-source-resolution ; scope:snapshot-claims ; sampling:full-snapshot ; conditions:clean-checkout
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
  else
    mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-7 ; period:2026-08-10..2026-08-16 ; unit:ratio ; basis:manual-count ; rev:r0 ; measure:claim-source-resolution ; scope:snapshot-claims ; sampling:full-snapshot ; conditions:clean-checkout
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
  fi
  rm -f "$outdir/receipt.md"
  run_eval > "$t/out.txt"
  grep -q 'outcome: O-P ; product ; observed' "$t/out.txt" \
    && grep -q 'earlier revision(s) preserved' "$t/out.txt" \
    && grep -q 'rev:r0\]' "$t/out.txt" && grep -q 'obs:run-7' "$t/out.txt" \
    && check "current observation + preserved history (order $order)" 0 "" \
    || check "current observation + preserved history (order $order)" 1 "$(cat "$t/out.txt")"
done
# same-value rows with different units → comparability gap surfaced, not dropped
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-P ; 19/20 ; owner:recount ; period:2026-09-14..2026-09-20 ; unit:percent ; basis:manual-count ; rev:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; non-comparable' "$t/out.txt" \
  && grep -q 'unit!=ratio' "$t/out.txt" \
  && grep -q 'obs:run-9' "$t/out.txt" && grep -q 'owner:recount' "$t/out.txt" \
  && check "same-value differing-unit rows surface non-comparable" 0 "" \
  || check "same-value differing-unit rows surface non-comparable" 1 "$(cat "$t/out.txt")"

# 21. undocumented field names are malformed — exit 2, no receipt
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; bogus:2026-09-14..2026-09-20 ; bogus:ratio ; bogus:manual-count ; bogus:r1 ; $OP_TAIL
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && [[ ! -f "$outdir/receipt.md" ]] \
  && check "bogus field names rejected before output" 0 "" \
  || check "bogus field names rejected before output" 1 "rc=$rc $(cat "$t/err.txt")"
# unsupported trailing field name also rejected
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; $OP_TAIL ; bogus:x
EOF
rc=0; run_eval > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && check "unsupported trailing field rejected" 0 "" \
  || check "unsupported trailing field rejected" 1 "rc=$rc $(cat "$t/err.txt")"

# 22. measure/scope independently checked against evidence — mismatch and
# absence both reported, never assumed equivalent
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; measure:other-thing ; scope:snapshot-claims ; sampling:full-snapshot ; conditions:clean-checkout
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; non-comparable' "$t/out.txt" \
  && grep -q 'measure!=claim-source-resolution' "$t/out.txt" \
  && check "measure mismatch reported non-comparable" 0 "" \
  || check "measure mismatch reported non-comparable" 1 "$(cat "$t/out.txt")"
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; non-comparable' "$t/out.txt" \
  && grep -qE 'non-comparable: [^;]*measure[^;]*scope' "$t/out.txt" \
  && check "missing measure/scope reported, not assumed" 0 "" \
  || check "missing measure/scope reported, not assumed" 1 "$(cat "$t/out.txt")"

# 23. sampling/conditions undeclared → comparison unsupported, named gap;
# the observation itself is still reported
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; measure:claim-source-resolution ; scope:snapshot-claims
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'outcome: O-P ; product ; observed' "$t/out.txt" \
  && grep -q 'comparison: unsupported — insufficient comparability information' "$t/out.txt" \
  && grep -q 'sampling not declared' "$t/out.txt" \
  && check "missing sampling gates comparison, not observation" 0 "" \
  || check "missing sampling gates comparison, not observation" 1 "$(cat "$t/out.txt")"
# differing declared conditions → unsupported, names both values
mk_evidence "$repo/evidence.md" <<EOF
evidence: O-P ; 19/20 ; obs:run-9 ; period:2026-09-14..2026-09-20 ; unit:ratio ; basis:manual-count ; rev:r1 ; measure:claim-source-resolution ; scope:snapshot-claims ; sampling:full-snapshot ; conditions:dirty-checkout
evidence: O-R ; 3.5 ; owner:log ; period:2026-09-14..2026-09-20 ; unit:review-hours ; basis:owner-log ; rev:r1 ; $OR_TAIL
EOF
rm -f "$outdir/receipt.md"
run_eval > "$t/out.txt"
grep -q 'conditions differs' "$t/out.txt" \
  && grep -q 'comparison: unsupported' "$t/out.txt" \
  && check "differing conditions gate comparison" 0 "" \
  || check "differing conditions gate comparison" 1 "$(cat "$t/out.txt")"

# 24. contract must itself validate — prose-only file refuses
printf 'not a workflow contract\n' > "$repo/bad.md"
rm -f "$outdir/receipt.md"
rc=0; run_eval --contract "$repo/bad.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
rm -f "$repo/bad.md"
[[ "$rc" -eq 2 ]] && [[ ! -f "$outdir/receipt.md" ]] \
  && check "invalid workflow contract refused" 0 "" \
  || check "invalid workflow contract refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 25. valid but UNACCEPTED workflow contract refuses
cat > "$repo/SDLC.reject.md" <<EOF
# Acceptance
\`\`\`contract
id: acc-reject
kind: contract-acceptance
schema_version: contract-acceptance/0.1.0
contract: SDLC.md
contract_schema: workflow-contract/0.1.0
contract_digest: sha256:$("$NORM" "$repo/SDLC.md" | shasum -a 256 | awk '{print $1}')
reviewer: owner
reviewed_at: 2026-09-20
decision: reject
rationale: not ready
\`\`\`
EOF
rm -f "$outdir/receipt.md"
rc=0; run_eval --contract-acceptance "$repo/SDLC.reject.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
rm -f "$repo/SDLC.reject.md"
[[ "$rc" -eq 2 ]] && [[ ! -f "$outdir/receipt.md" ]] \
  && check "unaccepted workflow contract refused" 0 "" \
  || check "unaccepted workflow contract refused" 1 "rc=$rc $(cat "$t/err.txt")"

# 26. missing --contract-acceptance → usage failure, no evaluation
rm -f "$outdir/receipt.md"
rc=0; "$EVAL" --contract "$repo/SDLC.md" --targets "$repo/targets.md" \
  --targets-acceptance "$repo/targets.accept.md" --evidence "$repo/evidence.md" \
  --implementation-rev r1 --inputs-root "$repo" --out "$outdir/receipt.md" \
  > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && [[ ! -f "$outdir/receipt.md" ]] \
  && check "missing contract acceptance arg refuses" 0 "" \
  || check "missing contract acceptance arg refuses" 1 "rc=$rc $(cat "$t/err.txt")"

echo
if [[ "$failures" -eq 0 ]]; then echo "PASS: evaluate-outcome"; else
  echo "FAIL: $failures check(s)"; exit 1; fi
