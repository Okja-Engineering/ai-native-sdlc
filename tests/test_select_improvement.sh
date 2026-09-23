#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# S9 selection-slice tests — select-eligible.sh (proposal §13). Dynamic
# fixtures; validates fact-state separation, exact ID/value matching,
# applicability vs. readiness, dependency-graph errors, determinism,
# provenance, and the no-writes / never-accepted boundaries.

SEL="skills/select-improvement/scripts/select-eligible.sh"

failures=0
check() { # name, ok(0)/bad(1), detail
  if [[ "$2" -eq 0 ]]; then printf '  ok — %s\n' "$1"; else
    printf '  MISMATCH — %s: %s\n' "$1" "$3"; failures=$((failures + 1))
  fi
}

t="$(mktemp -d)"; trap 'rm -rf "$t"' EXIT

mkfacts() { # items... -> writes $t/facts.md
  { printf '%s\n' '# Owner facts' '' '```contract' \
      'id: owner-facts-test' 'kind: owner-facts' 'schema_version: owner-facts/0.1.0'
    for i in "$@"; do printf 'fact: %s\n' "$i"; done
    printf '%s\n' '```'; } > "$t/facts.md"
}

card_a() { # DIR — applies on F-1=true, needs CAP-1=present
  cat > "$1/A.md" <<'EOF'
# Card A
```contract
id: C-A
kind: selection-card
schema_version: selection-card/0.1.0
title: Practice A
practice: does A
research_card: R-X-001
research_path: research/patterns/a.md
research_status: pending-owner-review
applies_when: F-1 = true
requires_capability: CAP-1 = present
depends_on: none
status: proposed
```
EOF
}
card_b() { # DIR — applies on F-2=true, no capability, depends on C-A
  cat > "$1/B.md" <<'EOF'
# Card B
```contract
id: C-B
kind: selection-card
schema_version: selection-card/0.1.0
title: Practice B
practice: does B
research_card: R-X-002
research_path: research/patterns/b.md
research_status: pending-owner-review
applies_when: F-2 = true
requires_capability: none
depends_on: C-A
status: proposed
```
EOF
}

mkdir -p "$t/cards"; card_a "$t/cards"; card_b "$t/cards"
CARDS="$t/cards"

echo "== S9 selection slice"

# 1. eligible when all facts established
mkfacts \
  'F-1 = true ; obs:run-01 ; established' \
  'F-2 = true ; interview:i1 ; established' \
  'CAP-1 = present ; path:.devin/ci ; established' \
  'C-A = adopted ; owner:decision-7 ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
grep -q 'eligible and ready:' "$t/out.txt" \
  && awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q 'C-A — Practice A' \
  && awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q 'C-B — Practice B' \
  && check "eligible when all facts established" 0 "" \
  || check "eligible when all facts established" 1 "$(cat "$t/out.txt")"

# 2. missing fact is a gap, never inferred
mkfacts \
  'F-1 = true ; obs:run-01 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'C-B' \
  && awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'F-2 not established' \
  && awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'F-2 (needed by C-B)' \
  && check "missing fact reported as gap, never inferred" 0 "" \
  || check "missing fact reported as gap, never inferred" 1 "$(cat "$t/out.txt")"

# 3. established-false is inapplicable, not unknown
mkfacts \
  'F-1 = false ; obs:run-02 ; established' \
  'F-2 = true ; obs:run-02 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = adopted ; owner:d ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/inapplicable:/,/unknown:/' "$t/out.txt" | grep -q 'C-A' \
  && awk '/inapplicable:/,/unknown:/' "$t/out.txt" | grep -q "F-1 established 'false' != required 'true'" \
  && ! awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'C-A' \
  && check "established-false is inapplicable, not unknown" 0 "" \
  || check "established-false is inapplicable, not unknown" 1 "$(cat "$t/out.txt")"

# 4. conflicted fact reports conflicted
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = - ; obs:r3+interview:i2 ; conflicted' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/conflicted:/,/missing-fact/' "$t/out.txt" | grep -q 'C-B' \
  && awk '/conflicted:/,/missing-fact/' "$t/out.txt" | grep -q 'F-2 conflicted' \
  && check "conflicted fact reports conflicted" 0 "" \
  || check "conflicted fact reports conflicted" 1 "$(cat "$t/out.txt")"

# 5. same fact in incompatible states fails validation — either order
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-1 = - ; obs:r2 ; conflicted' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q "fact 'F-1' declared twice" "$t/err.txt" \
  && check "conflicting fact states fail validation" 0 "" \
  || check "conflicting fact states fail validation" 1 "rc=$rc $(cat "$t/err.txt")"
mkfacts \
  'F-1 = - ; obs:r2 ; conflicted' \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q "fact 'F-1' declared twice" "$t/err.txt" \
  && check "conflicting states fail regardless of order" 0 "" \
  || check "conflicting states fail regardless of order" 1 "rc=$rc $(cat "$t/err.txt")"

# 6. unreviewed/unpromoted observation is not established
mkfacts \
  'F-1 = - ; obs:run-09 ; unknown' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'C-A' \
  && awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'F-1 not established' \
  && ! awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q 'C-A' \
  && check "unpromoted observation reference is not established" 0 "" \
  || check "unpromoted observation reference is not established" 1 "$(cat "$t/out.txt")"

# 7. unmet capability blocks readiness (applicable, not ready)
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = - ; obs:r4 ; unknown' \
  'C-A = adopted ; owner:d ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q 'C-A' \
  && awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q 'capability: CAP-1 not established' \
  && awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'CAP-1 (needed by C-A)' \
  && check "unmet capability blocks readiness, card stays applicable" 0 "" \
  || check "unmet capability blocks readiness, card stays applicable" 1 "$(cat "$t/out.txt")"

# 8. selected-but-not-established prerequisite blocks
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q 'C-A' \
  && awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q 'C-B' \
  && awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q 'prerequisite C-A not adopted' \
  && check "selected prerequisite is not implemented" 0 "" \
  || check "selected prerequisite is not implemented" 1 "$(cat "$t/out.txt")"

# 9. adopted prerequisite unblocks
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = adopted ; owner:d ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q 'C-B' \
  && check "adopted prerequisite unblocks dependent card" 0 "" \
  || check "adopted prerequisite unblocks dependent card" 1 "$(cat "$t/out.txt")"

# 10. missing dependency target is a graph error (exit 3)
mkdir -p "$t/cards-missing"; card_a "$t/cards-missing"
sed 's/depends_on: none/depends_on: C-ZZZ/' "$t/cards-missing/A.md" > "$t/cards-missing/tmp"
mv "$t/cards-missing/tmp" "$t/cards-missing/A.md"
mkfacts
rc=0; "$SEL" "$t/cards-missing" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 3 ]] && grep -q "depends on unknown card 'C-ZZZ'" "$t/err.txt" \
  && check "missing dependency target is a graph error" 0 "" \
  || check "missing dependency target is a graph error" 1 "rc=$rc $(cat "$t/err.txt")"

# 11. cycle is a graph error, not ordinary ineligibility
mkdir -p "$t/cards-cyc"
cat > "$t/cards-cyc/A.md" <<'EOF'
```contract
id: C-A
kind: selection-card
schema_version: selection-card/0.1.0
title: A
practice: a
research_card: R-1
research_path: r/a.md
research_status: reviewed
applies_when: none
requires_capability: none
depends_on: C-B
status: proposed
```
EOF
cat > "$t/cards-cyc/B.md" <<'EOF'
```contract
id: C-B
kind: selection-card
schema_version: selection-card/0.1.0
title: B
practice: b
research_card: R-2
research_path: r/b.md
research_status: reviewed
applies_when: none
requires_capability: none
depends_on: C-A
status: proposed
```
EOF
mkfacts
rc=0; "$SEL" "$t/cards-cyc" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 3 ]] && grep -q 'dependency cycle' "$t/err.txt" \
  && grep -q 'C-A' "$t/err.txt" && grep -q 'C-B' "$t/err.txt" \
  && check "cycle produces a graph error, not ineligible" 0 "" \
  || check "cycle produces a graph error, not ineligible" 1 "rc=$rc $(cat "$t/err.txt")"

# 12. deterministic output
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/run1.txt"
"$SEL" "$CARDS" "$t/facts.md" > "$t/run2.txt"
cmp -s "$t/run1.txt" "$t/run2.txt" \
  && check "identical inputs produce identical report" 0 "" \
  || check "identical inputs produce identical report" 1 "$(diff "$t/run1.txt" "$t/run2.txt")"

# 13. provenance carried: research locator + owner-fact evidence; nothing accepted
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = adopted ; owner:d ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
grep -q 'R-X-001, research/patterns/a.md (provisional: pending-owner-review)' "$t/out.txt" \
  && grep -q 'fact: F-1 = true \[established · obs:r1\]' "$t/out.txt" \
  && grep -q 'capability: CAP-1 = present \[established · path:x\]' "$t/out.txt" \
  && grep -q 'adoption: C-A = adopted \[established · owner:d\]' "$t/out.txt" \
  && ! grep -q 'accepted' "$t/out.txt" \
  && check "provenance carried (research locator + fact evidence); none accepted" 0 "" \
  || check "provenance carried (research locator + fact evidence); none accepted" 1 "$(cat "$t/out.txt")"

# 14. selector performs no writes
mkfacts 'F-1 = true ; obs:r1 ; established'
before="$(find "$t/cards" -type f | sort | xargs shasum -a 256; shasum -a 256 "$t/facts.md")"
"$SEL" "$CARDS" "$t/facts.md" > /dev/null
after="$(find "$t/cards" -type f | sort | xargs shasum -a 256; shasum -a 256 "$t/facts.md")"
[[ "$before" == "$after" ]] \
  && check "selector performs no writes" 0 "" \
  || check "selector performs no writes" 1 "cards dir changed"

# 15. unsupported predicate syntax rejected
mkdir -p "$t/cards-badpred"; card_a "$t/cards-badpred"
sed 's/applies_when: F-1 = true/applies_when: F-1 ~ true/' \
  "$t/cards-badpred/A.md" > "$t/cards-badpred/tmp" && mv "$t/cards-badpred/tmp" "$t/cards-badpred/A.md"
mkfacts
rc=0; "$SEL" "$t/cards-badpred" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'unsupported predicate syntax' "$t/err.txt" \
  && check "unsupported predicate syntax rejected" 0 "" \
  || check "unsupported predicate syntax rejected" 1 "rc=$rc $(cat "$t/err.txt")"

# 16. malformed fact item rejected
mkfacts 'F-1 is probably true ; obs:r1 ; established'
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'malformed fact item' "$t/err.txt" \
  && check "malformed fact item rejected" 0 "" \
  || check "malformed fact item rejected" 1 "rc=$rc $(cat "$t/err.txt")"

# 17. shipped starter cards: well-formed, deterministic, visibly provisional
mkfacts \
  'outcome-decomposable = true ; obs:run-01 ; established' \
  'observable-outcome = identifiable ; obs:run-01 ; established' \
  'named-reviewer = assigned ; interview:i1 ; established' \
  'ai-assisted-changes = present ; obs:run-01 ; established' \
  'deterministic-check-runner = present ; path:.devin/ci ; established' \
  'repeatable-checks = feasible ; obs:run-01 ; established' \
  'consequence-bearing-steps = present ; obs:run-01 ; established' \
  'named-decision-owner = assigned ; interview:i1 ; established' \
  'production-metrics = available ; obs:run-01 ; established' \
  'baseline-captured = true ; obs:run-01 ; established' \
  'C-01 = adopted ; owner:d1 ; established' \
  'C-02 = adopted ; owner:d2 ; established'
"$SEL" "skills/select-improvement/cards" "$t/facts.md" > "$t/out.txt"
ok17=0
for c in C-01 C-02 C-03 C-04 C-05; do
  awk '/eligible and ready:/,/applicable —/' "$t/out.txt" | grep -q "$c" || ok17=1
done
grep -q 'provisional: pending-owner-review' "$t/out.txt" || ok17=1
"$SEL" "skills/select-improvement/cards" "$t/facts.md" > "$t/out2.txt"
cmp -s "$t/out.txt" "$t/out2.txt" || ok17=1
check "five starter cards eligible, provisional, deterministic" "$ok17" "$(cat "$t/out.txt")"

# 18. unterminated fence fails closed — no report
{ printf '%s\n' '# Owner facts' '' '```contract' \
    'id: owner-facts-test' 'kind: owner-facts' 'schema_version: owner-facts/0.1.0' \
    'fact: F-1 = true ; obs:r1 ; established'
} > "$t/facts.md"   # no closing fence
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'unterminated contract fence' "$t/err.txt" \
  && ! grep -q 'selection report' "$t/out.txt" \
  && check "unterminated facts fence fails closed" 0 "" \
  || check "unterminated facts fence fails closed" 1 "rc=$rc $(cat "$t/err.txt")"

# 19. whitespace-only fact source fails closed
mkfacts 'F-1 = true ;    ; established'
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && ! grep -q 'selection report' "$t/out.txt" \
  && check "whitespace-only source fails closed" 0 "" \
  || check "whitespace-only source fails closed" 1 "rc=$rc $(cat "$t/err.txt")"
mkfacts 'F-1 = true ; bogus:r1 ; established'
rc=0; "$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'not a documented locator' "$t/err.txt" \
  && check "undocumented locator prefix fails closed" 0 "" \
  || check "undocumented locator prefix fails closed" 1 "rc=$rc $(cat "$t/err.txt")"

# 20. duplicate singleton field fails closed — both orders
mkdir -p "$t/cards-dup"; card_a "$t/cards-dup"
awk '{print} /^status: proposed$/{print "status: rejected"}' \
  "$t/cards-dup/A.md" > "$t/cards-dup/tmp" && mv "$t/cards-dup/tmp" "$t/cards-dup/A.md"
mkfacts 'F-1 = true ; obs:r1 ; established'
rc=0; "$SEL" "$t/cards-dup" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'duplicate singleton field: status' "$t/err.txt" \
  && check "duplicate status (proposed then rejected) fails closed" 0 "" \
  || check "duplicate status (proposed then rejected) fails closed" 1 "rc=$rc $(cat "$t/err.txt")"
card_a "$t/cards-dup"   # restore, then rejected-first variant
awk '/^status: proposed$/{print "status: rejected"} {print}' \
  "$t/cards-dup/A.md" > "$t/cards-dup/tmp" && mv "$t/cards-dup/tmp" "$t/cards-dup/A.md"
rc=0; "$SEL" "$t/cards-dup" "$t/facts.md" > "$t/out.txt" 2> "$t/err.txt" || rc=$?
[[ "$rc" -eq 2 ]] && grep -q 'duplicate singleton field: status' "$t/err.txt" \
  && check "duplicate status (rejected then proposed) fails closed" 0 "" \
  || check "duplicate status (rejected then proposed) fails closed" 1 "rc=$rc $(cat "$t/err.txt")"

# 21. absent adoption fact is a missing-fact gap
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'C-A = adopted (needed by C-B)' \
  && check "absent adoption fact reported as gap" 0 "" \
  || check "absent adoption fact reported as gap" 1 "$(cat "$t/out.txt")"

# 22. unknown adoption fact is a gap; conflicted and non-adopted are not
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = - ; obs:r9 ; unknown'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'C-A = adopted (needed by C-B)' \
  && awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q "adoption fact 'C-A = adopted' not established" \
  && check "unknown adoption fact reported as gap" 0 "" \
  || check "unknown adoption fact reported as gap" 1 "$(cat "$t/out.txt")"

mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = - ; obs:r9+interview:i2 ; conflicted'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q 'C-A adoption evidence conflicted' \
  && ! awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'C-A' \
  && check "conflicted adoption evidence blocks without gap" 0 "" \
  || check "conflicted adoption evidence blocks without gap" 1 "$(cat "$t/out.txt")"

mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = rejected ; owner:d3 ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" | grep -q "adoption fact established 'rejected' != 'adopted'" \
  && ! awk '/missing-fact gaps:/,0' "$t/out.txt" | grep -q 'C-A' \
  && check "established non-adopted value blocks without gap" 0 "" \
  || check "established non-adopted value blocks without gap" 1 "$(cat "$t/out.txt")"

# 23. provenance survives on failed applicability (existing fact, wrong value)
mkfacts \
  'F-1 = false ; owner:decision-17 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established' \
  'C-A = adopted ; owner:d ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/inapplicable:/,/unknown:/' "$t/out.txt" | grep -q 'C-A' \
  && awk '/inapplicable:/,/unknown:/' "$t/out.txt" | grep -q 'fact: F-1 = false \[established · owner:decision-17\]' \
  && check "inapplicable card keeps fact provenance" 0 "" \
  || check "inapplicable card keeps fact provenance" 1 "$(cat "$t/out.txt")"

# 24. provenance survives on conflicted evidence
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = - ; obs:r3+interview:i2 ; conflicted' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/conflicted:/,/missing-fact/' "$t/out.txt" | grep -q 'fact: F-2 = - \[conflicted · obs:r3+interview:i2\]' \
  && check "conflicted fact keeps provenance" 0 "" \
  || check "conflicted fact keeps provenance" 1 "$(cat "$t/out.txt")"

# 25. provenance survives on blocked capability and adoption checks
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'F-2 = true ; obs:r1 ; established' \
  'CAP-1 = - ; obs:r4 ; unknown' \
  'C-A = rejected ; owner:d3 ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/applicable — blocked/,/inapplicable:/' "$t/out.txt" > "$t/blk.txt"
grep -q 'capability: CAP-1 = - \[unknown · obs:r4\]' "$t/blk.txt" \
  && grep -q 'adoption: C-A = rejected \[established · owner:d3\]' "$t/blk.txt" \
  && check "blocked capability and adoption keep provenance" 0 "" \
  || check "blocked capability and adoption keep provenance" 1 "$(cat "$t/blk.txt")"

# 26. absent facts report gaps without invented provenance
mkfacts \
  'F-1 = true ; obs:r1 ; established' \
  'CAP-1 = present ; path:x ; established'
"$SEL" "$CARDS" "$t/facts.md" > "$t/out.txt"
awk '/unknown:/,/conflicted:/' "$t/out.txt" | grep -q 'C-B' \
  && ! grep -q 'F-2 = ' "$t/out.txt" \
  && check "absent fact reports gap without invented provenance" 0 "" \
  || check "absent fact reports gap without invented provenance" 1 "$(cat "$t/out.txt")"

echo
if [[ "$failures" -eq 0 ]]; then echo "PASS: select-improvement"; else
  echo "FAIL: $failures check(s)"; exit 1; fi
