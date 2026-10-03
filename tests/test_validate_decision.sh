#!/usr/bin/env bash
# The Deliver gate: a decision is made by a human, and the record names which one.
#
# Every refusal is asserted by its distinctive message, not by exit status alone.
# A non-zero exit cannot tell "nobody decided" from "that option does not exist",
# and a gate an operator cannot read gets bypassed.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/05-deliver/validate-decision.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A record beside a real option set, so the options link resolves and the thing
# under test is the only thing wrong with the file.
mkdir -p "$TMP/process/04-develop/options" "$TMP/process/05-deliver/decisions"
cat > "$TMP/process/04-develop/options/thing.md" <<'OPTS'
# Develop — thing
## A · First way
## B · Second way
OPTS

# A document for the record to amend, with a back-link, so the reciprocal check
# has something real to resolve against.
cat > "$TMP/STANDARD.md" <<'STD'
# A standard

Some claim.

decided: [thing](process/05-deliver/decisions/thing.md)
STD

# record <chosen> <decided_by> <dated> [amends]
# amends defaults to a resolving, reciprocated link. Pass a 4th argument to
# override it, or the literal string OMIT to leave the field out entirely.
record() {
  local amends="${4-[s](../../../STANDARD.md#a-standard)}"
  {
    printf '%s\n\n' '# Decision — thing'
    printf '%s\n' 'problem: [p](../../03-define/problems/thing.md)'
    printf '%s\n' 'options: [o](../../04-develop/options/thing.md)'
    printf 'chosen: %s\n' "$1"
    printf 'decided_by: %s\n' "$2"
    printf 'dated: %s\n' "$3"
    [ "$amends" = OMIT ] || printf 'amends: %s\n' "$amends"
  } > "$TMP/process/05-deliver/decisions/thing.md"
  printf '%s' "$TMP/process/05-deliver/decisions/thing.md"
}

# --- pending is a valid state -------------------------------------------------
out="$(bash "$GATE" "$(record pending '' '')" 2>&1)"; rc=$?
assert_status 0 "$rc" "a pending record with nobody named exits 0"
assert_contains "$out" "within the contract" "pending is reported as within the contract"

# --- the gate the contract named ---------------------------------------------
out="$(bash "$GATE" "$(record A '' 2026-10-01)" 2>&1)"; rc=$?
assert_status 1 "$rc" "chosen without a decider exits 1"
assert_contains "$out" "refuse[undecided-by]" "the refusal is undecided-by"
assert_contains "$out" "a decision is made by a human" "the message says why"

out="$(bash "$GATE" "$(record A 'the team' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[not-a-person]" "a team is not a person"

out="$(bash "$GATE" "$(record A 'Claude' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[not-a-person]" "a model is not a person"

out="$(bash "$GATE" "$(record A 'reviewer' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[not-a-person]" "a role is not a person"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a named human is accepted"

# --- companion checks, equally shape-independent ------------------------------
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' '')" 2>&1)"
assert_contains "$out" "refuse[undated-decision]" "a decided record must be dated"

out="$(bash "$GATE" "$(record Z 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[chosen-not-an-option]" "an option that does not exist is refused"
assert_contains "$out" "go back to Develop" "the message says where to go instead"

out="$(bash "$GATE" "$(record pending 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[pending-but-decided]" "a record cannot be both pending and decided"

# --- amends: the decision has to land somewhere -------------------------------
# For five phases the repository's stated output — a change to our standards —
# was never produced, because nothing carried a decision to the document. These
# check the link exists and resolves in BOTH directions; a one-way pointer would
# let the standard and the decision disagree silently.

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 OMIT)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decided record with no amends exits 1"
assert_contains "$out" "refuse[no-amends]" "the refusal is no-amends"
assert_contains "$out" "never reaches one" "the message says why an unlinked decision is the problem"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 none)" 2>&1)"
assert_contains "$out" "refuse[bare-none-amends]" "a bare 'none' cannot be told from an oversight"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 'none — chose to measure first, nothing about how we work changed')" 2>&1)"; rc=$?
assert_status 0 "$rc" "'none' with a reason is accepted"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 'STANDARD.md section 1')" 2>&1)"
assert_contains "$out" "refuse[amends-not-linked]" "naming a document without linking it is refused"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 '[s](../../../NOPE.md)')" 2>&1)"
assert_contains "$out" "refuse[amends-unresolved]" "an amended document that does not exist is refused"

# The reciprocal half. Remove the back-link and the pair stops agreeing.
cp "$TMP/STANDARD.md" "$TMP/STANDARD.bak"
grep -v '^decided:' "$TMP/STANDARD.bak" > "$TMP/STANDARD.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "an amended document that does not cite the decision is refused"
assert_contains "$out" "the grade on that claim is unsupported" "the message says what the missing back-link costs"
cp "$TMP/STANDARD.bak" "$TMP/STANDARD.md"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a reciprocated link is accepted once restored"

# --- the shipped records ------------------------------------------------------
out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/producing-themes.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the measure-first record is within the contract"

out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/agent-pr-approval.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the record that amends STANDARDS.md is within the contract"

assert_done
