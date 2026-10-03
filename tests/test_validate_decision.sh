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

# The suite supplies its own decider list. Pointing at the real DECIDERS.md
# would make these cases fail whenever a person is added or removed, which is a
# test coupled to data rather than to behaviour — the defect that broke this
# suite once already when a decision was first made.
cat > "$TMP/DECIDERS.md" <<'DEC'
# Authorized deciders

| Name | Since |
|---|---|
| Matt Van Dusen | 2026-01-01 |
| Ada Lovelace | 2026-01-01 |
DEC
export DECIDERS_FILE="$TMP/DECIDERS.md"

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

# The invariant: decided_by denotes a natural person authorized to decide.
#
# The previous version of this block asserted exactly `the team`, `Claude` and
# `reviewer` — the three literals the old denylist regex was written for. It
# proved the list contained three words and never tested the invariant, so an
# external audit passed `the Platform Engineering Team` and `Claude Opus 5`
# through a check this repository calls irreplaceable.
#
# These cases are deliberately chosen to sit OUTSIDE whatever the implementation
# obviously handles: multi-word roles, versioned model names, a vendor prefix, a
# plausible-looking human who simply is not authorized. If the implementation is
# rewritten, these must still pass.
for bad in \
  'the team' 'Claude' 'reviewer' \
  'the Platform Engineering Team' 'Claude Opus 5' 'Anthropic Claude Opus 5.1' \
  'Engineering Leadership Group' 'the SRE on call' 'GPT-5' 'our LLM' \
  'nobody' 'TBD' 'A. N. Other' \
  'Matt' 'Ada' 'Van Dusen' 'Matt Van Dusen and the team' 'matt van dusen'
do
  out="$(bash "$GATE" "$(record A "$bad" 2026-10-01)" 2>&1)"; rc=$?
  assert_status 1 "$rc" "refuses decided_by: $bad"
done

# And the positive half, which is what makes it an allowlist rather than a
# denylist: a listed decider is accepted, and so is a second one.
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "an authorized decider is accepted"
out="$(bash "$GATE" "$(record A 'Ada Lovelace' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a second authorized decider is accepted"

# The two messages, because the fix differs. A role needs replacing; a real
# person needs adding to the list.
out="$(bash "$GATE" "$(record A 'the Platform Engineering Team' 2026-10-01)" 2>&1)"
assert_contains "$out" "a role or a machine" "a role gets the role message"
out="$(bash "$GATE" "$(record A 'Grace Hopper' 2026-10-01)" 2>&1)"
assert_contains "$out" "not listed in DECIDERS.md" "an unlisted person is told to be added"

# No decider list at all must fail closed, not open.
out="$(DECIDERS_FILE=/nonexistent/DECIDERS.md bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a missing decider list refuses rather than passing everything"

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
# These use the REAL DECIDERS.md, because they are checking real records. The
# fixture list above is for the synthetic cases only.
unset DECIDERS_FILE

out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/producing-themes.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the measure-first record is within the contract"

out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/agent-pr-approval.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the record that amends STANDARDS.md is within the contract"

# The real list must actually name the person the real records name, or the two
# agree only by the gate not looking.
assert_contains "$(cat "$ROOT/DECIDERS.md")" \
  "$(sed -n 's/^decided_by:[[:space:]]*//p' "$ROOT/process/05-deliver/decisions/agent-pr-approval.md" | head -1)" \
  "the real decider list names the person the real record names"

assert_done
