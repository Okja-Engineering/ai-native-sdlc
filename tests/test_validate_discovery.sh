#!/usr/bin/env bash
# The Discover gate: what is checkable about a discovery artifact.
#
# Both shipped topics must pass, and they have deliberately different shapes —
# one uses bare `[E]` markers and numbered headings, the other bold `**[E]**`
# and unnumbered. A gate that only accepted one of them would have encoded the
# newer artifact's markup as a rule, which is the failure the contract deferred
# its gate to avoid.
#
# Every refusal is asserted by its distinctive message. A non-zero exit cannot
# tell "no coverage section" from "an invented grade", and an operator who
# cannot read a gate bypasses it.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/02-discover/validate-discovery.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case, because the gate resolves local links relative to the
# artifact and a copied file alone would refuse on an unresolved link before
# reaching the check under test.
fresh() {
  local t="$TMP/$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$t/"
  printf '%s' "$t"
}
NEW=topics/agent-pr-approval.md
OLD=topics/classifier-models.md
gate() { bash "$GATE" "$1/process/02-discover/$2" 2>&1; }

# --- both shipped topics pass, despite differing in form ----------------------
t="$(fresh base)"
out="$(gate "$t" "$NEW")"; rc=$?
assert_status 0 "$rc" "the newer topic is within the contract"
out="$(gate "$t" "$OLD")"; rc=$?
assert_status 0 "$rc" "the older topic is within the contract, with different markup"

out="$(bash "$GATE" 2>&1)"; rc=$?
assert_status 0 "$rc" "both shipped topics pass when the gate runs over the directory"
assert_contains "$out" "2 file(s) within the contract" "it reports how many it checked"

# --- fields -------------------------------------------------------------------
t="$(fresh dated)"; perl -0pi -e 's/^dated: .*\n//m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[undated]" "an undated artifact is refused"

t="$(fresh status)"; perl -0pi -e 's/^status: .*\n//m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-status]" "a statusless artifact is refused"

# --- the question in the asker's own words ------------------------------------
t="$(fresh question)"
perl -0pi -e "s/## The question, in the asker's own words/## Background/" "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-question]" "an artifact not stating the question is refused"
assert_contains "$out" "answers a different question" "the message says why a tidied restatement is the problem"

# The older topic labels the question in bold rather than as a heading. Both are
# accepted, so stripping only the quotation has to be what trips it.
t="$(fresh quote)"; perl -0pi -e 's/^> .*\n//mg' "$t/process/02-discover/$OLD"
assert_contains "$(gate "$t" "$OLD")" "refuse[question-not-quoted]" \
  "a question section with no quotation is refused"

# --- coverage, in three parts -------------------------------------------------
t="$(fresh vbh)"
perl -0pi -e 's/[Vv]erified by hand/Checked/g' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-verified-by-hand]" "coverage without a verified-by-hand part is refused"
assert_contains "$out" "a pile of agent output" "the message says what the section is protecting against"

t="$(fresh notreached)"
perl -0pi -e 's/[Nn]ot reached/Other/g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-not-reached]" \
  "coverage that lists only successes is refused"

# --- the open section ---------------------------------------------------------
t="$(fresh open)"
perl -0pi -e 's/## What could not be established/## Notes/' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-open-section]" "a missing open section is refused"
assert_contains "$out" "claims completeness" "the message says what omitting it asserts"

# --- where this stops ---------------------------------------------------------
t="$(fresh stops)"
perl -0pi -e 's/[Ww]here this stops/Closing/g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-where-this-stops]" \
  "an artifact that does not say where it stops is refused"

# --- grades -------------------------------------------------------------------
# Not "every claim is graded" — the gate cannot check that and says so. This is
# that an invented grade is caught.
t="$(fresh enum)"
perl -0pi -e 's/\*\*\[V\]\*\*/**[X]**/' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[grade-not-in-enum]" "a grade outside the enum is refused"
assert_contains "$out" "E, S, V, P, O" "the message names the enum"

t="$(fresh nogrades)"
perl -0pi -e 's/\[([ESVPO])\]//g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-grades]" "an artifact with no graded claims is refused"

# --- links resolve ------------------------------------------------------------
# The shipped topics carry only http sources, so a mutation had nothing to
# break — the first version of this test passed while proving nothing. A broken
# local link is appended instead.
t="$(fresh links)"
printf '\nSee [the problem](../../03-define/problems/nope.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[link-unresolved]" "a local link that does not resolve is refused"

# And a link that does resolve must not trip it.
t="$(fresh goodlink)"
printf '\nSee [the problem](../../03-define/problems/agent-pr-approval.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"; rc=$?
assert_status 0 "$rc" "a local link that resolves is accepted"

# --- the gate must not pretend to check what it cannot ------------------------
# The contract named four checks. Two are not mechanisable without a claim
# convention the artifacts do not have, and one is deliberately omitted. If a
# later edit quietly adds a recommendation-language check, this fails — the
# false-positive it would produce is documented in the gate's own header.
src="$(cat "$GATE")"
assert_contains "$src" "NOT CHECKABLE" "the gate states which contract checks it cannot make"
assert_contains "$src" "DELIBERATELY NOT BUILT" "the gate states which check it declines to make"
assert_not_contains "$src" 'refuse "$f" "-" "recommendation' \
  "the gate does not refuse on recommendation language"

assert_done
