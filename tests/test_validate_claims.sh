#!/usr/bin/env bash
# The speed-claim tripwire. It had no test at all — it only ever ran in CI, as a
# pattern inlined in the workflow, which made it unrunnable locally.
#
# An external audit wrote a document with six explicit speed claims and the gate
# printed ok. Two separate reasons, and the second is the worse one:
#
#   1. The pattern had no entry for `quicker` — the repository's own preferred
#      word — nor bare `throughput`, `lead time`, `sooner` or `accelerated`.
#   2. After widening, the pattern contained `(our |the |)` — an empty
#      alternative, invalid ERE. git grep errored, the script sent stderr to
#      /dev/null and treated a non-zero exit as clean, and the gate printed ok
#      having evaluated nothing.
#
# So this suite checks both: that the forms are caught, and that a pattern which
# does not compile is loud rather than silent.
#
# Mutations run in a git worktree, never a copy of the tree.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
TMP="$(mktemp -d)"
SB="$TMP/wt"
cleanup() { git -C "$ROOT" worktree remove --force "$SB" >/dev/null 2>&1; rm -rf "$TMP"; }
trap cleanup EXIT

git -C "$ROOT" worktree add -q --detach "$SB" HEAD >/dev/null 2>&1 \
  || { printf 'test_validate_claims: could not create a worktree\n' >&2; exit 2; }
cp "$ROOT/bin/validate-claims.sh" "$SB/bin/validate-claims.sh"

# claim <text> -> output of the gate with that text in a tracked document
claim() {
  printf '%s\n' "$1" > "$SB/claim.md"
  ( cd "$SB" && git add -A >/dev/null 2>&1; bash bin/validate-claims.sh 2>&1 )
}
clear_claim() { rm -f "$SB/claim.md"; ( cd "$SB" && git add -A >/dev/null 2>&1 ); }

# --- the shipped tree is clean ------------------------------------------------
out="$(cd "$SB" && bash bin/validate-claims.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "the shipped tree carries no speed claim"
assert_contains "$out" "no speed claims" "it says so"
# And it says how many documents that was over. The gate's own header already holds
# the rule that a check which evaluated nothing must not read as "nothing found" —
# it fixed the >1 exit from a pattern that would not compile, and left this half:
# `git grep` exits 1 both for "no match" and for "the pathspec matched no files".
# Pinned as a NUMBER and not as the words "tracked document", which the old message
# already contained — the first version of this assertion passed against the unfixed
# gate for exactly that reason. Not pinned to a literal count either, because that
# grows with the repository and would make the suite a staleness alarm.
scanned_n="$(printf '%s' "$out" | sed -n 's/.* in \([0-9][0-9]*\) tracked document.*/\1/p')"
counted=no
[ -n "$scanned_n" ] && [ "$scanned_n" -gt 1 ] && counted=yes
assert_eq "yes" "$counted" "the clean report names how many documents it read"

# --- a pathspec that matches nothing is not a clean tree -----------------------
# Measured in a throwaway clone: with every markdown file dropped from the index
# this printed the same "no speed claims in tracked documents" line and exited 0,
# over 32 documents and over none. One over-broad `:(exclude)` does it, and the
# excludes are edited whenever a new directory of recorded claims appears.
#
# Driven by emptying the index rather than by editing the pathspec, so the
# assertion is about the gate's answer and not about the spelling of one exclude.
( cd "$SB" && git rm -q --cached $(git ls-files -- '*.md') ) >/dev/null 2>&1
out="$(cd "$SB" && bash bin/validate-claims.sh 2>&1)"; rc=$?
assert_status 2 "$rc" "a pathspec matching no tracked document cannot run"
assert_contains "$out" "nothing was checked" "and the gate says nothing was checked"
assert_not_contains "$out" "no speed claims" "and does not report the tree clean"
( cd "$SB" && git reset -q HEAD -- . ) >/dev/null 2>&1

# --- the six forms the audit used --------------------------------------------
# Each is asserted separately. The audit's document contained all six at once, so
# catching any one of them would have made the suite pass while five walked
# through: a test input that trips two guards together proves neither, because a
# guard that never fires on its own cannot be told from one that does not work.
# The rule is in AGENTS.md, "Tests: pin the invariant, not the literals", from
# issue #29 — which a clone cannot read, hence the sentence rather than the number.
for c in \
  'This loop makes our team quicker.' \
  'We ship 3x quicker than before.' \
  'Our lead time dropped 40%.' \
  'Throughput is up 60%.' \
  'The median cycle time fell from nine days to two.' \
  'Delivery is accelerated.' \
  'Engineers are 2x more productive.'
do
  out="$(claim "$c")"; rc=$?
  assert_status 1 "$rc" "refuses: $c"
done
clear_claim

# --- and the older forms still caught ----------------------------------------
for c in \
  'This makes us faster.' \
  'Teams ship faster with it.' \
  'It speeds up delivery.' \
  'A 40% velocity improvement.' \
  'We saw a 10x productivity gain.'
do
  out="$(claim "$c")"; rc=$?
  assert_status 1 "$rc" "still refuses: $c"
done
clear_claim

# --- a recorded vendor claim is not our claim --------------------------------
# The scan and discovery contracts REQUIRE recording a vendor's claim as a
# claim. Those directories are excluded, and that exclusion is load-bearing.
printf 'cycle\n\n| id | what |\n|---|---|\n| F01 | TypeSafe states "193.6x Faster" |\n' \
  > "$SB/process/01-scan/findings/2099-01-01.md"
out="$(cd "$SB" && git add -A >/dev/null 2>&1; bash bin/validate-claims.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "a vendor's speed claim recorded in findings/ is not refused"
rm -f "$SB/process/01-scan/findings/2099-01-01.md"
( cd "$SB" && git add -A >/dev/null 2>&1 )

# --- and the scope is what the documents say it is -----------------------------
# The pathspec carried FOUR excludes and `AGENTS.md` names two. The gate's own header
# warns that "one over-broad entry turns the gate off silently", and `tests/*` was that
# entry: a speed claim appended to a fixture passed while the same line in
# `STANDARDS.md` was caught. The fourth, `bin/validate-claims.sh`, was DEAD — the
# include is `*.md`, so it never matched — and it read as a documented self-exemption
# while being none.
#
# Asserted behaviourally, not by reading the pathspec: a claim in each place either is
# or is not refused. A test that grepped the script for its excludes would pass against
# any spelling of the same hole.
printf 'Our pipeline makes delivery 3x faster.\n' > "$SB/tests/fixtures/scan/claim-probe.md"
out="$(cd "$SB" && git add -A >/dev/null 2>&1; bash bin/validate-claims.sh 2>&1)"; rc=$?
assert_status 1 "$rc" "a speed claim in a tests/ document is refused"
assert_contains "$out" "claim-probe.md" "and the refusal names the file"
rm -f "$SB/tests/fixtures/scan/claim-probe.md"
( cd "$SB" && git add -A >/dev/null 2>&1 )

# Our own reasoning is in scope: a problem, an option set and a decision are us
# writing, not a record of what someone else said.
for d in process/03-define/problems process/04-develop/options process/05-deliver/decisions; do
  printf 'Our pipeline makes delivery 3x faster.\n' > "$SB/$d/claim-probe.md"
  out="$(cd "$SB" && git add -A >/dev/null 2>&1; bash bin/validate-claims.sh 2>&1)"; rc=$?
  assert_status 1 "$rc" "a speed claim in $d is refused"
  rm -f "$SB/$d/claim-probe.md"
  ( cd "$SB" && git add -A >/dev/null 2>&1 )
done

# A record of what others said is not, and `topics/` as well as `findings/` — the two
# directories AGENTS.md names, both asserted, so neither exclusion can be removed
# silently either.
for d in process/01-scan/findings process/02-discover/topics; do
  printf 'TypeSafe states its product makes delivery 3x faster.\n' > "$SB/$d/claim-probe.md"
  out="$(cd "$SB" && git add -A >/dev/null 2>&1; bash bin/validate-claims.sh 2>&1)"; rc=$?
  assert_status 0 "$rc" "a recorded vendor claim in $d is not refused"
  rm -f "$SB/$d/claim-probe.md"
  ( cd "$SB" && git add -A >/dev/null 2>&1 )
done

# --- a pattern that does not compile must be loud ----------------------------
# This is the assertion that matters most. The gate printed ok for an invalid
# pattern because a non-zero git grep exit was read as "nothing found".
cp "$SB/bin/validate-claims.sh" "$TMP/good.sh"
# The mutation uses an UNMATCHED PAREN, which is invalid in POSIX ERE on every
# platform. The first version used an empty alternative — `(our |the |)` — which
# is what the real bug was, and that is accepted by GNU grep as simply meaning
# "optional" while BSD rejects it. So the test passed on macOS and failed on
# ubuntu, asserting a platform quirk rather than the gate's behaviour.
#
# Worth recording which way round that is: the defect that shipped was invisible
# on Linux and caught on macOS. Every other portability bug in this repository
# has gone the other way.
perl -0pi -e "s/OWN='\(our \|the \|your \|my \|their \)\?'/OWN='(unterminated'/" "$SB/bin/validate-claims.sh"
# Confirm the mutation actually landed. A mutation that does not mutate looks
# identical to a test that works, and this suite has already been fooled once.
assert_contains "$(cat "$SB/bin/validate-claims.sh")" "OWN='(unterminated'" "the broken-pattern mutation applied"
out="$(cd "$SB" && bash bin/validate-claims.sh 2>&1)"; rc=$?
assert_status 2 "$rc" "a pattern that does not compile exits 2, not 0"
assert_contains "$out" "nothing was checked" "it says nothing was checked"
assert_not_contains "$out" "no speed claims" "it does not report the tree clean"
cp "$TMP/good.sh" "$SB/bin/validate-claims.sh"

# --- the honest limit, asserted so it is not mistaken for coverage -----------
# A lexical rule cannot be categorical. This phrasing is a real speed claim and
# passes, deliberately: the gate is a tripwire for the obvious forms, and the
# script's header says which of the two it is.
out="$(claim 'Our engineers spend less time waiting.')"; rc=$?
assert_status 0 "$rc" "a speed claim with no speed word passes — the documented limit"
clear_claim

src="$(cat "$ROOT/bin/validate-claims.sh")"
assert_contains "$src" "not enforcement of the rule" "the gate says it is a tripwire, not enforcement"


# --- the percentage and multiplier clauses, on their own -----------------------
# Found by tests/mutate-sweep.sh, by dropping one alternative of the pattern at a
# time. Two clauses — PCT and the line carrying MULT and PCT together — could be
# removed with every case above still passing, because each of those cases is caught
# by a different clause. `Our lead time dropped 40%` is the RATE clause, not PCT;
# `A 40% velocity improvement` is RATE as well, because PCT wants "improvement in
# velocity" and not "velocity improvement".
#
# Same rule as the block above, one clause further down: a guard that never fires on
# its own cannot be told from one that does not work.
for c in \
  'Reviews are 50% faster.' \
  'The loop is 30% quicker.' \
  'Engineers are 25% more productive.' \
  'We measured a 20% improvement in throughput.' \
  'We measured a 15% improvement in velocity.'
do
  out="$(claim "$c")"; rc=$?
  assert_status 1 "$rc" "refuses the percentage form: $c"
done
clear_claim

for c in \
  'It is 3x faster.' \
  'A 2.5x quicker loop.' \
  'Teams are 4x more effective.' \
  'We saw 10x productivity.'
do
  out="$(claim "$c")"; rc=$?
  assert_status 1 "$rc" "refuses the multiplier form: $c"
done
clear_claim

# A third clause nothing reached: the verb-then-rate form. Every case above that
# names a rate word puts it FIRST — "lead time dropped", "throughput is up" — and
# this clause is the other word order. It could be dropped with every case above
# still passing.
for c in \
  'We improved our velocity.' \
  'That increased throughput.' \
  'We reduced lead time.' \
  'It cut cycle time.'
do
  out="$(claim "$c")"; rc=$?
  assert_status 1 "$rc" "refuses the verb-then-rate form: $c"
done
clear_claim

assert_done
