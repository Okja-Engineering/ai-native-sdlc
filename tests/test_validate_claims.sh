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

# --- the six forms the audit used --------------------------------------------
# Each is asserted separately. The audit's document contained all six at once,
# so catching any one of them would have made the suite pass while five walked
# through — the trip-two-guards-with-one-case failure from #29.
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

# --- a pattern that does not compile must be loud ----------------------------
# This is the assertion that matters most. The gate printed ok for an invalid
# pattern because a non-zero git grep exit was read as "nothing found".
cp "$SB/bin/validate-claims.sh" "$TMP/good.sh"
perl -0pi -e "s/OWN='\(our \|the \|your \|my \|their \)\?'/OWN='(our |the |your |my |their |)'/" "$SB/bin/validate-claims.sh"
# Confirm the mutation actually landed. A mutation that does not mutate looks
# identical to a test that works, and this suite has already been fooled once.
assert_contains "$(cat "$SB/bin/validate-claims.sh")" "their |)" "the broken-pattern mutation applied"
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

assert_done
