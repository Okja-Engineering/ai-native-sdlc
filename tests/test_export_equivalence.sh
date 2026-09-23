#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib/materialize.sh

# Consumer of the callable normalizer (proposal §12.6): canonical semantics
# come from skills/sdlc-scaffold/scripts/normalize-workflow.sh.
normalize="skills/sdlc-scaffold/scripts/normalize-workflow.sh"

failures=0
check() { # name, condition-hold(0)/fail(1), detail
  if [[ "$2" -eq 0 ]]; then printf '  ok — %s\n' "$1"; else
    printf '  MISMATCH — %s: %s\n' "$1" "$3"; failures=$((failures + 1))
  fi
}

compact="examples/leaked-db-errors/compact/SDLC.md"
modular="examples/leaked-db-errors/modular"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

echo "case: semantic equivalence (expected identical normalized contracts)"
"$normalize" "$compact" > "$work/compact.norm"
"$normalize" "$modular" > "$work/modular.norm"
diff -u "$work/compact.norm" "$work/modular.norm" > "$work/equiv.diff" 2>&1
check "compact and modular normalize identically" "$?" "$(head -5 "$work/equiv.diff")"

echo "case: semantic drift (expected equivalence failure naming the field)"
cp -R "$modular" "$work/drifted"
# Change the deciding role on stage 06 — a semantic, not textual, difference.
sed -i '' 's/^decides: merge-authority$/decides: accountable-engineer/' \
  "$work/drifted/stages/06-merge-decision/CONTEXT.md"
"$normalize" "$work/drifted" > "$work/drifted.norm"
if diff -q "$work/compact.norm" "$work/drifted.norm" >/dev/null 2>&1; then
  check "drift detected" 1 "forms compared equal despite changed decides field"
else
  dout="$(diff -u "$work/compact.norm" "$work/drifted.norm" || true)"
  if printf '%s' "$dout" | grep -q 'decides'; then
    check "drift detected" 0 ""
  else
    check "drift detected" 1 "diff did not name the changed field"
  fi
fi

echo "case: item-boundary regression (comma-item vs pipe-list must differ)"
# `acceptance: alpha,beta` is ONE item containing a comma; `alpha | beta` is
# TWO items. If normalization joins items with commas these compare equal —
# the encoding must keep boundaries unambiguous.
cat > "$work/formA.md" <<'EOF'
```contract
id: 01-x
acceptance: alpha,beta
```
EOF
cat > "$work/formB.md" <<'EOF'
```contract
id: 01-x
acceptance: alpha | beta
```
EOF
"$normalize" "$work/formA.md" > "$work/formA.norm"
"$normalize" "$work/formB.md" > "$work/formB.norm"
if diff -q "$work/formA.norm" "$work/formB.norm" >/dev/null 2>&1; then
  check "item boundaries preserved" 1 \
    "one-item 'alpha,beta' normalized identically to two-item 'alpha | beta'"
else
  dout="$(diff -u "$work/formA.norm" "$work/formB.norm" || true)"
  printf '%s' "$dout" | grep -q 'acceptance' \
    && check "item boundaries preserved" 0 "" \
    || check "item boundaries preserved" 1 "diff did not name the acceptance field"
fi

echo "case: repeated export (expected idempotent)"
dst="$work/target1"
materialize "$modular" "$dst" > "$work/pass1.log"
materialize "$modular" "$dst" > "$work/pass2.log"
grep -q '^REFUSE\|^CREATE' "$work/pass2.log" \
  && check "second materialize is a no-op" 1 "$(cat "$work/pass2.log")" \
  || check "second materialize is a no-op" 0 ""

echo "case: owner edits (expected refuse, content preserved)"
dst2="$work/target2"
materialize "$modular" "$dst2" >/dev/null
target_file="$dst2/ROUTER.md"
printf '# Owner-authored router — do not overwrite\n' > "$target_file"
materialize "$modular" "$dst2" > "$work/pass3.log" && rc=0 || rc=$?
if [[ "$rc" -ne 0 ]] \
  && grep -q 'REFUSE ROUTER.md' "$work/pass3.log" \
  && grep -q 'Owner-authored router' "$target_file"; then
  check "owner-edited file refused and preserved" 0 ""
else
  check "owner-edited file refused and preserved" 1 "rc=$rc $(cat "$work/pass3.log")"
fi

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures export-equivalence check(s) failed" >&2
  exit 1
fi
echo "PASS: export equivalence"
