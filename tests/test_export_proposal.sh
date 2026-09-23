#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# S8 export contract (proposal §12): accepted contract + content-bound
# acceptance record -> staged, validated compact/modular proposal under an
# isolated output root. Cases are generated dynamically so digests stay
# correct when fixtures change.

export="skills/sdlc-scaffold/scripts/export-proposal.sh"
normalize="skills/sdlc-scaffold/scripts/normalize-workflow.sh"
checkacc="skills/sdlc-scaffold/scripts/check-acceptance.sh"

failures=0
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
ok()  { printf '  ok — %s\n' "$1"; }
bad() { printf '  MISMATCH — %s: %s\n' "$1" "$2"; failures=$((failures + 1)); }

expect_pass() { # label cmd...
  local label="$1"; shift
  if "$@" > "$work/last.log" 2>&1; then ok "$label"
  else bad "$label" "expected success"; sed 's/^/    /' "$work/last.log"; fi
}
expect_fail() { # label cmd...
  local label="$1"; shift
  if "$@" > "$work/last.log" 2>&1; then bad "$label" "expected refusal, got success"
  else ok "$label"; fi
}
dir_has_files() { [[ -n "$(find "$1" -type f -print -quit 2>/dev/null)" ]]; }

# --- Fixture builders ------------------------------------------------------

make_client() { # dir — a minimal client repository
  mkdir -p "$1/docs"
  printf '# Client policy\n' > "$1/docs/policy.md"
}

# mini contract: exercises all four reference classes in context_entry —
# pack/checklist.md (bundled, exists under input), docs/policy.md
# (client-repository), repo-rules (named), changes/... (runtime artifact).
write_mini_contract() { # dir
  mkdir -p "$1/pack"
  cat > "$1/SDLC.md" <<'EOF'
# Mini flow

```contract
id: mini-flow
kind: workflow
schema_version: workflow-contract/0.1.0
stages: 01-alpha | 02-beta
risk_scaling: none
owner: test-owner
```

## Stage 01

```contract
id: 01-alpha
kind: internal
purpose: Do alpha.
inputs: raw-request@E | pack/checklist.md@D | docs/policy.md@D
outputs: changes/{slice-id}/01-alpha.md
acceptance: alpha-done
decides: owner
may_not: skip-review
decisions: accept | reject
runtime_deps: none
adoption_deps: none
context_entry: pack/checklist.md | docs/policy.md | repo-rules | changes/{slice-id}/run.md
context_explore: none
context_never: secrets
on_missing_input: stop
on_conflict: stop
reentry: pending
review_fields: reviewer | decision
```

## Stage 02

```contract
id: 02-beta
kind: internal
purpose: Do beta.
inputs: changes/{slice-id}/01-alpha.md@runtime:01-alpha
outputs: changes/{slice-id}/02-beta.md
acceptance: beta-done
decides: owner
may_not: skip-review
decisions: accept | reject
runtime_deps: 01-alpha
adoption_deps: none
context_entry: none
context_explore: none
context_never: secrets
on_missing_input: stop
on_conflict: stop
reentry: pending
review_fields: reviewer | decision
```
EOF
  printf '# bundled checklist\n' > "$1/pack/checklist.md"
}

write_acceptance() { # record-file contract-rel contract-abs [decision]
  local rec="$1" rel="$2" cpath="$3" dec="${4:-accept}"
  local dg; dg="$("$normalize" "$cpath" | shasum -a 256 | awk '{print $1}')"
  cat > "$rec" <<EOF
\`\`\`contract
id: acceptance-1
kind: contract-acceptance
schema_version: contract-acceptance/0.1.0
contract: $rel
contract_schema: workflow-contract/0.1.0
contract_digest: sha256:$dg
reviewer: test-owner
reviewed_at: 2026-09-20
decision: $dec
rationale: test acceptance
\`\`\`
EOF
}

# --- Case 1: compact export — all reference classes -------------------------
echo "case: compact export succeeds and relocates references"
mkdir -p "$work/c1/input" "$work/c1/client" "$work/c1/out"
write_mini_contract "$work/c1/input"; make_client "$work/c1/client"
write_acceptance "$work/c1/input/ACCEPTANCE.md" "SDLC.md" "$work/c1/input/SDLC.md"
expect_pass "compact export" \
  "$export" --input "$work/c1/input/SDLC.md" --acceptance "$work/c1/input/ACCEPTANCE.md" \
            --client "$work/c1/client" --output "$work/c1/out" --form compact
[[ -f "$work/c1/out/SDLC.md" && -f "$work/c1/out/pack/checklist.md" && -f "$work/c1/out/EXPORT-REPORT.md" ]] \
  && ok "compact output: SDLC.md + bundled copy + report" \
  || bad "compact output" "missing files: $(find "$work/c1/out" -type f)"
"$normalize" "$work/c1/out/SDLC.md" > "$work/c1/out.norm"
"$normalize" "$work/c1/input/SDLC.md" > "$work/c1/in.norm"
diff -q "$work/c1/in.norm" "$work/c1/out.norm" >/dev/null \
  && ok "exported compact preserves contract semantics" \
  || bad "semantics" "exported contract drifted"
grep -q 'bundled' "$work/c1/out/EXPORT-REPORT.md" \
  && grep -q 'client-repository' "$work/c1/out/EXPORT-REPORT.md" \
  && ok "report records bundled and client-repository classes" \
  || bad "report" "relocation classes missing"

# --- Case 2: modular export -------------------------------------------------
echo "case: modular export"
mkdir -p "$work/c2/input" "$work/c2/client" "$work/c2/out"
write_mini_contract "$work/c2/input"; make_client "$work/c2/client"
write_acceptance "$work/c2/input/ACCEPTANCE.md" "SDLC.md" "$work/c2/input/SDLC.md"
expect_pass "modular export" \
  "$export" --input "$work/c2/input/SDLC.md" --acceptance "$work/c2/input/ACCEPTANCE.md" \
            --client "$work/c2/client" --output "$work/c2/out" --form modular
[[ -f "$work/c2/out/ROUTER.md" && -f "$work/c2/out/CONTEXT.md" \
   && -f "$work/c2/out/stages/01-alpha/CONTEXT.md" \
   && -f "$work/c2/out/stages/01-alpha/pack/checklist.md" ]] \
  && ok "modular output: router, task map, stage files, bundled copy at stage-relative path" \
  || bad "modular output" "missing files: $(find "$work/c2/out" -type f)"
"$normalize" "$work/c2/out" > "$work/c2/out.norm"
"$normalize" "$work/c2/input/SDLC.md" > "$work/c2/in.norm"
diff -q "$work/c2/in.norm" "$work/c2/out.norm" >/dev/null \
  && ok "exported modular preserves contract semantics" \
  || bad "semantics" "modular contract drifted"

# --- Case 3: both forms normalize identically -------------------------------
echo "case: both forms — equivalent"
mkdir -p "$work/c3/input" "$work/c3/client" "$work/c3/out"
write_mini_contract "$work/c3/input"; make_client "$work/c3/client"
write_acceptance "$work/c3/input/ACCEPTANCE.md" "SDLC.md" "$work/c3/input/SDLC.md"
expect_pass "both forms" \
  "$export" --input "$work/c3/input/SDLC.md" --acceptance "$work/c3/input/ACCEPTANCE.md" \
            --client "$work/c3/client" --output "$work/c3/out" --form both
[[ -f "$work/c3/out/compact/SDLC.md" && -f "$work/c3/out/modular/ROUTER.md" ]] \
  && ok "both subtrees emitted" || bad "both" "subtrees missing"

# --- Case 4: contract modified after acceptance -----------------------------
echo "case: contract modified after acceptance (digest mismatch)"
mkdir -p "$work/c4/input" "$work/c4/client" "$work/c4/out"
write_mini_contract "$work/c4/input"; make_client "$work/c4/client"
write_acceptance "$work/c4/input/ACCEPTANCE.md" "SDLC.md" "$work/c4/input/SDLC.md"
sed -i '' 's/purpose: Do alpha./purpose: Do alpha differently./' "$work/c4/input/SDLC.md"
expect_fail "post-review edit invalidates acceptance" \
  "$export" --input "$work/c4/input/SDLC.md" --acceptance "$work/c4/input/ACCEPTANCE.md" \
            --client "$work/c4/client" --output "$work/c4/out" --form compact
dir_has_files "$work/c4/out" \
  && bad "c4 destination" "files were written despite refusal" \
  || ok "destination untouched on digest refusal"

# --- Case 5: missing acceptance record --------------------------------------
echo "case: missing acceptance record"
mkdir -p "$work/c5/input" "$work/c5/client" "$work/c5/out"
write_mini_contract "$work/c5/input"; make_client "$work/c5/client"
expect_fail "no record -> refuse" \
  "$export" --input "$work/c5/input/SDLC.md" --acceptance "$work/c5/input/NOPE.md" \
            --client "$work/c5/client" --output "$work/c5/out" --form compact

# --- Case 6: incomplete acceptance record ------------------------------------
echo "case: incomplete acceptance record (no reviewer)"
mkdir -p "$work/c6/input" "$work/c6/client" "$work/c6/out"
write_mini_contract "$work/c6/input"; make_client "$work/c6/client"
write_acceptance "$work/c6/input/ACCEPTANCE.md" "SDLC.md" "$work/c6/input/SDLC.md"
sed -i '' '/^reviewer:/d' "$work/c6/input/ACCEPTANCE.md"
expect_fail "missing reviewer -> refuse" \
  "$export" --input "$work/c6/input/SDLC.md" --acceptance "$work/c6/input/ACCEPTANCE.md" \
            --client "$work/c6/client" --output "$work/c6/out" --form compact

# --- Case 7: non-accept decision ---------------------------------------------
echo "case: decision is revise, not accept"
mkdir -p "$work/c7/input" "$work/c7/client" "$work/c7/out"
write_mini_contract "$work/c7/input"; make_client "$work/c7/client"
write_acceptance "$work/c7/input/ACCEPTANCE.md" "SDLC.md" "$work/c7/input/SDLC.md" revise
expect_fail "revise decision -> refuse" \
  "$export" --input "$work/c7/input/SDLC.md" --acceptance "$work/c7/input/ACCEPTANCE.md" \
            --client "$work/c7/client" --output "$work/c7/out" --form compact

# --- Case 8: invalid contract despite matching digest ------------------------
echo "case: invalid contract (acceptance valid, contract invalid)"
mkdir -p "$work/c8/input" "$work/c8/client" "$work/c8/out"
write_mini_contract "$work/c8/input"; make_client "$work/c8/client"
sed -i '' 's/on_missing_input: stop/on_missing_input: silently-continue/' "$work/c8/input/SDLC.md"
write_acceptance "$work/c8/input/ACCEPTANCE.md" "SDLC.md" "$work/c8/input/SDLC.md"
expect_fail "invalid contract -> refuse" \
  "$export" --input "$work/c8/input/SDLC.md" --acceptance "$work/c8/input/ACCEPTANCE.md" \
            --client "$work/c8/client" --output "$work/c8/out" --form compact

# --- Case 9: unrelocatable reference, both forms ------------------------------
echo "case: unrelocatable context_entry (compact and modular)"
for f in compact modular; do
  d="$work/c9-$f"; mkdir -p "$d/input" "$d/client" "$d/out"
  write_mini_contract "$d/input"; make_client "$d/client"
  sed -i '' 's/context_entry: pack\/checklist.md/context_entry: nope\/missing.md | pack\/checklist.md/' "$d/input/SDLC.md"
  write_acceptance "$d/input/ACCEPTANCE.md" "SDLC.md" "$d/input/SDLC.md"
  expect_fail "unrelocatable ref ($f) -> refuse" \
    "$export" --input "$d/input/SDLC.md" --acceptance "$d/input/ACCEPTANCE.md" \
              --client "$d/client" --output "$d/out" --form "$f"
  dir_has_files "$d/out" \
    && bad "c9-$f destination" "files written despite broken reference" \
    || ok "nothing written on broken reference ($f)"
done

# --- Case 10: repeat export is SAME, byte-identical ---------------------------
echo "case: repeated export is a no-op"
mkdir -p "$work/c10/input" "$work/c10/client" "$work/c10/out"
write_mini_contract "$work/c10/input"; make_client "$work/c10/client"
write_acceptance "$work/c10/input/ACCEPTANCE.md" "SDLC.md" "$work/c10/input/SDLC.md"
"$export" --input "$work/c10/input/SDLC.md" --acceptance "$work/c10/input/ACCEPTANCE.md" \
          --client "$work/c10/client" --output "$work/c10/out" --form compact >/dev/null
"$export" --input "$work/c10/input/SDLC.md" --acceptance "$work/c10/input/ACCEPTANCE.md" \
          --client "$work/c10/client" --output "$work/c10/out" --form compact > "$work/c10/pass2.log"
grep -q '^CREATE' "$work/c10/pass2.log" \
  && bad "repeat export" "second run created files: $(cat "$work/c10/pass2.log")" \
  || ok "second run reports only SAME"

# --- Case 11: mixed destination — conflict halts everything -------------------
echo "case: mixed destination (owner-edited + new files) — all-or-nothing"
mkdir -p "$work/c11/input" "$work/c11/client" "$work/c11/out"
write_mini_contract "$work/c11/input"; make_client "$work/c11/client"
write_acceptance "$work/c11/input/ACCEPTANCE.md" "SDLC.md" "$work/c11/input/SDLC.md"
printf '# Owner-authored file — differs from proposal\n' > "$work/c11/out/SDLC.md"
expect_fail "conflicting destination -> refuse" \
  "$export" --input "$work/c11/input/SDLC.md" --acceptance "$work/c11/input/ACCEPTANCE.md" \
            --client "$work/c11/client" --output "$work/c11/out" --form compact
grep -q 'Owner-authored file' "$work/c11/out/SDLC.md" \
  && ok "owner file preserved" || bad "c11" "owner file overwritten"
[[ ! -e "$work/c11/out/pack/checklist.md" && ! -e "$work/c11/out/EXPORT-REPORT.md" ]] \
  && ok "would-be-new files not written on conflict" \
  || bad "c11 atomicity" "partial package written"

# --- Case 12: output-root overlap, incl. symlink-resolved ---------------------
echo "case: output isolation from client and input roots"
mkdir -p "$work/c12/input" "$work/c12/client/proposals" "$work/c12/outside"
write_mini_contract "$work/c12/input"; make_client "$work/c12/client"
write_acceptance "$work/c12/input/ACCEPTANCE.md" "SDLC.md" "$work/c12/input/SDLC.md"
expect_fail "output inside client -> refuse" \
  "$export" --input "$work/c12/input/SDLC.md" --acceptance "$work/c12/input/ACCEPTANCE.md" \
            --client "$work/c12/client" --output "$work/c12/client/proposals" --form compact
ln -s "$work/c12/client/proposals" "$work/c12/linkout"
expect_fail "symlinked output inside client -> refuse" \
  "$export" --input "$work/c12/input/SDLC.md" --acceptance "$work/c12/input/ACCEPTANCE.md" \
            --client "$work/c12/client" --output "$work/c12/linkout" --form compact
mkdir -p "$work/c12/input/nested"
expect_fail "output inside input root -> refuse" \
  "$export" --input "$work/c12/input/SDLC.md" --acceptance "$work/c12/input/ACCEPTANCE.md" \
            --client "$work/c12/client" --output "$work/c12/input/nested" --form compact

# --- Case 13: determinism — same inputs, two outputs ---------------------------
echo "case: deterministic render (identical inputs -> byte-identical output)"
mkdir -p "$work/c13/input" "$work/c13/client" "$work/c13/outa" "$work/c13/outb"
write_mini_contract "$work/c13/input"; make_client "$work/c13/client"
write_acceptance "$work/c13/input/ACCEPTANCE.md" "SDLC.md" "$work/c13/input/SDLC.md"
"$export" --input "$work/c13/input/SDLC.md" --acceptance "$work/c13/input/ACCEPTANCE.md" \
          --client "$work/c13/client" --output "$work/c13/outa" --form both >/dev/null
"$export" --input "$work/c13/input/SDLC.md" --acceptance "$work/c13/input/ACCEPTANCE.md" \
          --client "$work/c13/client" --output "$work/c13/outb" --form both >/dev/null
diff -r "$work/c13/outa" "$work/c13/outb" >/dev/null \
  && ok "byte-identical outputs" || bad "determinism" "outputs differ"

# --- Case 14: equivalent compact/modular inputs -> identical outputs ----------
echo "case: equivalent inputs produce equivalent outputs"
mkdir -p "$work/c14/ina" "$work/c14/inb" "$work/c14/client" "$work/c14/outa" "$work/c14/outb"
cp examples/leaked-db-errors/compact/SDLC.md "$work/c14/ina/SDLC.md"
cp -R examples/leaked-db-errors/modular "$work/c14/inb/mod"
make_client "$work/c14/client"
write_acceptance "$work/c14/ina/ACC.md" "SDLC.md" "$work/c14/ina/SDLC.md"
write_acceptance "$work/c14/inb/ACC.md" "mod" "$work/c14/inb/mod"
expect_pass "export from compact input" \
  "$export" --input "$work/c14/ina/SDLC.md" --acceptance "$work/c14/ina/ACC.md" \
            --client "$work/c14/client" --output "$work/c14/outa" --form both
expect_pass "export from modular input" \
  "$export" --input "$work/c14/inb/mod" --acceptance "$work/c14/inb/ACC.md" \
            --client "$work/c14/client" --output "$work/c14/outb" --form both
diff -r "$work/c14/outa" "$work/c14/outb" >/dev/null \
  && ok "equivalent inputs -> byte-identical proposals" \
  || bad "equivalence" "compact and modular inputs rendered differently"

# --- Case 15: observation input is not a contract ------------------------------
echo "case: observation input refused even with a digest-matching record"
mkdir -p "$work/c15/input" "$work/c15/client" "$work/c15/out"
cat > "$work/c15/input/OBSERVATION.md" <<'EOF'
# observation snapshot

```contract
id: obs-1
kind: observation-claim
plane: workflow
status: observed
```
EOF
make_client "$work/c15/client"
write_acceptance "$work/c15/input/ACC.md" "OBSERVATION.md" "$work/c15/input/OBSERVATION.md"
expect_fail "observation input -> refuse" \
  "$export" --input "$work/c15/input/OBSERVATION.md" --acceptance "$work/c15/input/ACC.md" \
            --client "$work/c15/client" --output "$work/c15/out" --form compact

# --- Case 16: destination symlink escapes to the client repo (P1) ------------
echo "case: destination symlink bypass refused (client and output unchanged)"
mkdir -p "$work/c16/input" "$work/c16/client" "$work/c16/out"
write_mini_contract "$work/c16/input"; make_client "$work/c16/client"
write_acceptance "$work/c16/input/ACCEPTANCE.md" "SDLC.md" "$work/c16/input/SDLC.md"
ln -s "$work/c16/client" "$work/c16/out/pack"
expect_fail "symlinked dest escapes to client -> refuse" \
  "$export" --input "$work/c16/input/SDLC.md" --acceptance "$work/c16/input/ACCEPTANCE.md" \
            --client "$work/c16/client" --output "$work/c16/out" --form compact
[[ ! -e "$work/c16/client/checklist.md" ]] \
  && ok "client repo unchanged" || bad "c16" "write escaped into client repo"
[[ ! -e "$work/c16/out/SDLC.md" && ! -e "$work/c16/out/EXPORT-REPORT.md" ]] \
  && ok "destination unchanged on escape refusal" \
  || bad "c16" "partial package written"

# --- Case 17: dangling destination symlink fails closed (P1) -----------------
# pack -> missing-dir (relative, target absent): resolving it to the missing
# in-root path would let publish materialize a directory the owner never made.
echo "case: dangling destination symlink refused"
mkdir -p "$work/c17/input" "$work/c17/client" "$work/c17/out"
write_mini_contract "$work/c17/input"; make_client "$work/c17/client"
write_acceptance "$work/c17/input/ACCEPTANCE.md" "SDLC.md" "$work/c17/input/SDLC.md"
ln -s missing-dir "$work/c17/out/pack"
expect_fail "dangling dest symlink -> refuse" \
  "$export" --input "$work/c17/input/SDLC.md" --acceptance "$work/c17/input/ACCEPTANCE.md" \
            --client "$work/c17/client" --output "$work/c17/out" --form compact
[[ ! -e "$work/c17/out/missing-dir" ]] \
  && ok "dangling target not materialized" \
  || bad "c17" "export created the missing target directory"
[[ -z "$(find "$work/c17/out" -type f -print -quit)" ]] \
  && ok "nothing written through dangling link (destination unchanged)" \
  || bad "c17" "partial package written"

# --- Case 18: ancestor regular-file conflict refused before writes (P2) ------
echo "case: ancestor file conflict — all-or-nothing"
mkdir -p "$work/c18/input" "$work/c18/client" "$work/c18/out"
write_mini_contract "$work/c18/input"; make_client "$work/c18/client"
write_acceptance "$work/c18/input/ACCEPTANCE.md" "SDLC.md" "$work/c18/input/SDLC.md"
printf '# owner file blocking pack/\n' > "$work/c18/out/pack"
expect_fail "ancestor file -> refuse" \
  "$export" --input "$work/c18/input/SDLC.md" --acceptance "$work/c18/input/ACCEPTANCE.md" \
            --client "$work/c18/client" --output "$work/c18/out" --form compact
grep -q 'owner file blocking' "$work/c18/out/pack" \
  && ok "blocking file preserved" || bad "c18" "ancestor file touched"
[[ ! -e "$work/c18/out/SDLC.md" && ! -e "$work/c18/out/EXPORT-REPORT.md" ]] \
  && ok "no partial output on ancestor conflict" \
  || bad "c18" "partial package written"

# --- Case 19: in-root destination symlink still works (no over-refusal) ------
echo "case: in-root destination symlink resolves normally"
mkdir -p "$work/c19/input" "$work/c19/client" "$work/c19/out/realpack"
write_mini_contract "$work/c19/input"; make_client "$work/c19/client"
write_acceptance "$work/c19/input/ACCEPTANCE.md" "SDLC.md" "$work/c19/input/SDLC.md"
ln -s realpack "$work/c19/out/pack"
expect_pass "in-root symlink" \
  "$export" --input "$work/c19/input/SDLC.md" --acceptance "$work/c19/input/ACCEPTANCE.md" \
            --client "$work/c19/client" --output "$work/c19/out" --form compact
[[ -f "$work/c19/out/realpack/checklist.md" ]] \
  && ok "bundled file landed through in-root link" \
  || bad "c19" "in-root symlink mishandled"

# --- Case 20: contradictory decisions refused in both orders (P3) ------------
echo "case: duplicate decision fields refused"
for order in accept-first reject-first; do
  d="$work/c20-$order"; mkdir -p "$d/input" "$d/client" "$d/out"
  write_mini_contract "$d/input"; make_client "$d/client"
  write_acceptance "$d/input/ACCEPTANCE.md" "SDLC.md" "$d/input/SDLC.md"
  if [[ "$order" == "accept-first" ]]; then
    sed -i '' 's/^decision: accept$/decision: accept\ndecision: reject/' "$d/input/ACCEPTANCE.md"
  else
    sed -i '' 's/^decision: accept$/decision: reject\ndecision: accept/' "$d/input/ACCEPTANCE.md"
  fi
  expect_fail "contradictory decisions ($order) -> refuse" \
    "$export" --input "$d/input/SDLC.md" --acceptance "$d/input/ACCEPTANCE.md" \
              --client "$d/client" --output "$d/out" --form compact
  dir_has_files "$d/out" \
    && bad "c20-$order" "files written despite contradictory record" \
    || ok "nothing written ($order)"
done

# --- Case 21: unterminated acceptance block refused (P3) ----------------------
echo "case: unterminated acceptance block refused"
mkdir -p "$work/c21/input" "$work/c21/client" "$work/c21/out"
write_mini_contract "$work/c21/input"; make_client "$work/c21/client"
write_acceptance "$work/c21/input/ACCEPTANCE.md" "SDLC.md" "$work/c21/input/SDLC.md"
sed -i '' '$d' "$work/c21/input/ACCEPTANCE.md"   # drop closing fence
expect_fail "unterminated record -> refuse" \
  "$export" --input "$work/c21/input/SDLC.md" --acceptance "$work/c21/input/ACCEPTANCE.md" \
            --client "$work/c21/client" --output "$work/c21/out" --form compact

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures export-proposal check(s) failed" >&2
  exit 1
fi
echo "PASS: export proposal"
