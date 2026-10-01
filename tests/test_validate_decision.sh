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

# record <chosen> <decided_by> <dated>
record() {
  cat > "$TMP/process/05-deliver/decisions/thing.md" <<REC
# Decision — thing

problem: [p](../../03-define/problems/thing.md)
options: [o](../../04-develop/options/thing.md)
chosen: $1
decided_by: $2
dated: $3
REC
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

# --- the shipped record -------------------------------------------------------
out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/producing-themes.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the real decision record is within the contract"

assert_done
