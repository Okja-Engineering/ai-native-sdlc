#!/usr/bin/env bash
# CONTROLS.md must describe gates that exist and refusals they actually emit.
#
# A control document is the one artifact here with a strong incentive to drift
# optimistic: it is read by people assessing the process, and nothing about
# writing prose forces it to stay true. So every control cites the script that
# enforces it and the refusal codes that script emits, and this suite checks
# both. A control claiming a refusal no gate produces is the failure mode.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
DOC="$ROOT/CONTROLS.md"

assert_file_exists "$DOC" "the controls document exists"

# --- every gate named in the document exists ----------------------------------
# Scripts are cited as `process/<phase>/validate-<thing>.sh` in backticks.
# Gates live beside their phase, except the STANDARDS.md gate, which has no
# phase to live beside — #18 established that applying a decision is a field
# plus a link rather than a sixth phase, so it sits in bin/ with the other
# repository-level tools. The first version of this pattern matched only
# process/ and reported CTRL-8's refusals as emitted by nothing.
gates="$(grep -oE '(process/[0-9a-z-]+|bin)/validate-[a-z-]+\.sh' "$DOC" | sort -u)"
assert_contains "$gates" "validate-decision.sh" "the document cites the deliver gate"
assert_contains "$gates" "validate-define.sh" "the document cites the define gate"
assert_contains "$gates" "validate-findings.sh" "the document cites the scan gate"

missing_gates=""
for g in $gates; do
  [ -f "$ROOT/$g" ] || missing_gates="$missing_gates $g"
done
assert_eq "" "$missing_gates" "every gate the document names exists"

# --- every refusal code cited appears in some gate ----------------------------
# Codes appear in the refusal tables as `code` in backticks. Collect anything
# shaped like a refusal code, then require each to be present in a gate script.
# This is the check that stops a control claiming enforcement it does not have.
codes="$(grep -oE '^\| `[a-z][a-z-]{3,}`' "$DOC" | tr -d '|` ' | sort -u)"
n=0; orphans=""
for c in $codes; do
  n=$((n + 1))
  found=no
  for g in $gates; do
    grep -q -- "$c" "$ROOT/$g" && { found=yes; break; }
  done
  [ "$found" = yes ] || orphans="$orphans $c"
done

assert_eq "" "$orphans" "every refusal code cited is emitted by a gate"
[ "$n" -ge 15 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the document cites at least 15 refusal codes (found $n)"

# --- codes mentioned in prose, not only in tables -----------------------------
# CTRL-6 lists its refusals inline rather than as a table. Spot-check that those
# resolve too, since a prose list is exactly where an invented code would hide.
for c in nothing-found empty-cycle filename; do
  assert_contains "$(cat "$ROOT/process/01-scan/validate-findings.sh")" "$c" \
    "scan gate emits '$c' as the document claims"
done

# --- the honest section is present and not empty ------------------------------
# The whole document is worth less than nothing if it lists controls and omits
# what is not controlled.
assert_contains "$(cat "$DOC")" "## What is not controlled" "the not-controlled section exists"
notctl="$(sed -n '/^## What is not controlled/,$p' "$DOC" | grep -cE '^\*\*[0-9]+\.')"
[ "$notctl" -ge 6 ] && many=yes || many=no
assert_eq "yes" "$many" "the not-controlled section lists at least 6 gaps (found $notctl)"

# --- it must not claim compliance ---------------------------------------------
# The one assertion here that is about wording rather than structure. A control
# document that drifts into claiming an audit it has not had is the specific
# dishonesty worth guarding, and it is cheap to catch the direct forms.
doc="$(cat "$DOC")"
assert_not_contains "$doc" "SOC 2 compliant" "it does not claim SOC 2 compliance"
assert_not_contains "$doc" "SOC 2 certified" "it does not claim SOC 2 certification"
assert_not_contains "$doc" "fully audited" "it does not claim to be audited"
assert_contains "$doc" "has not been audited" "it states plainly that it has not been audited"

# --- the undecided control is stated as undecided ------------------------------
# CTRL-1 and item 2 cover the separation-of-duties question that discovery found
# unresolved. Claiming it would be the worst available error.
assert_contains "$doc" "Undecided, in both directions" "the unresolved control is marked undecided"
assert_contains "$doc" "not a requirement we met" "it distinguishes our practice from a requirement"

assert_done
