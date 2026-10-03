#!/usr/bin/env bash
# bin/cycle.sh reports where every cycle is. It had no test suite at all.
#
# An external audit found three defects, and the first is the one that mattered:
# inserting `example: yes` into the only real findings file made the cycle, its
# 64 findings, its themes and both decisions vanish from the report with no
# refusal anywhere, and both gates still passed. A status tool that can lose a
# cycle to a two-word edit without saying so is worse than none.
#
# The other two had never been exercised because only one cycle exists: problems
# were globbed into every cycle's report, and topics were printed with no
# linkage, which hid that one of them is referenced by nothing.
#
# Mutations run in a git worktree, never a copy of the tree. Twice today a
# mutation meant for a copy reached the real repository because a relative path
# was edited after a failed `cd`, and once it was committed.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
TMP="$(mktemp -d)"
SB="$TMP/wt"
cleanup() { git -C "$ROOT" worktree remove --force "$SB" >/dev/null 2>&1; rm -rf "$TMP"; }
trap cleanup EXIT

git -C "$ROOT" worktree add -q --detach "$SB" HEAD >/dev/null 2>&1 \
  || { printf 'test_cycle: could not create a worktree\n' >&2; exit 2; }
# The worktree is at HEAD; the script under test may be uncommitted.
cp "$ROOT/bin/cycle.sh" "$SB/bin/cycle.sh"
run() { ( cd "$SB" && bash bin/cycle.sh "$@" 2>&1 ); }

# --- the shipped tree ---------------------------------------------------------
out="$(run)"; rc=$?
assert_status 0 "$rc" "the shipped tree reports cleanly"
assert_contains "$out" "2026-09-29" "it names the real cycle"
assert_contains "$out" "64 findings" "it counts the findings"
assert_contains "$out" "chose D" "it reports a decision that was made"
assert_contains "$out" "chose F" "it reports the other decision"

# --- an example file is announced, not silently dropped -----------------------
# The audit's exploit. The assertion is that the cycle id still APPEARS, because
# the failure was a whole cycle disappearing with no trace.
perl -0pi -e 's/^(since: first run)$/example: yes\n$1/m' "$SB/process/01-scan/findings/2026-09-29.md"
out="$(run)"
assert_contains "$out" "2026-09-29" "a cycle marked as an example still appears in the report"
assert_contains "$out" "skipped" "it is reported as skipped"
assert_contains "$out" "example: yes" "the report says why it was skipped"
assert_not_contains "$out" "64 findings" "and it is not reported as a cycle"
git -C "$SB" checkout -q -- process/01-scan/findings/2026-09-29.md

# --- problems belong to their own cycle --------------------------------------
# Never exercised before, because only one cycle exists. A second cycle with its
# own problem must not inherit the first cycle's problems, and vice versa.
sed 's/2026-09-29/2026-11-01/g' "$SB/process/01-scan/findings/2026-09-29.md" \
  > "$SB/process/01-scan/findings/2026-11-01.md"
sed -e 's|cycles/2026-09-29|cycles/2026-11-01|g' -e 's|findings/2026-09-29|findings/2026-11-01|g' \
  "$SB/process/03-define/cycles/2026-09-29.md" > "$SB/process/03-define/cycles/2026-11-01.md"
sed 's|cycles/2026-09-29|cycles/2026-11-01|g' "$SB/process/03-define/problems/producing-themes.md" \
  > "$SB/process/03-define/problems/cadence.md"
cp "$SB/process/04-develop/options/producing-themes.md" "$SB/process/04-develop/options/cadence.md"

out="$(run)"
# The first cycle keeps its two and does not gain the new one.
first="$(printf '%s\n' "$out" | awk '/^2026-09-29$/{on=1;next} /^2026-11-01$/{on=0} on')"
assert_contains "$first" "2 stated" "the first cycle reports its own two problems"
assert_not_contains "$first" "cadence" "the first cycle does not inherit the second cycle's problem"
# The second cycle gets only its own.
second="$(printf '%s\n' "$out" | awk '/^2026-11-01$/{on=1;next} /^2026-09-01$/{on=0} on')"
assert_contains "$second" "1 stated" "the second cycle reports one problem"
assert_contains "$second" "cadence" "the second cycle reports its own problem"
assert_not_contains "$second" "agent-pr-approval" "the second cycle does not inherit the first cycle's problems"

rm -f "$SB/process/01-scan/findings/2026-11-01.md" \
      "$SB/process/03-define/cycles/2026-11-01.md" \
      "$SB/process/03-define/problems/cadence.md" \
      "$SB/process/04-develop/options/cadence.md"

# --- a topic nothing references is reported as such --------------------------
out="$(run)"
assert_contains "$out" "rests under" "a referenced topic says what references it"
assert_contains "$out" "referenced by no problem" "an unreferenced topic is reported as an orphan"

# --- one cycle by name --------------------------------------------------------
out="$(run 2026-09-29)"; rc=$?
assert_status 0 "$rc" "naming a cycle exits 0"
assert_not_contains "$out" "topics" "naming a cycle reports that cycle only"

out="$(run 2099-01-01)"; rc=$?
assert_status 1 "$rc" "an unknown cycle exits 1"

# --- it writes nothing --------------------------------------------------------
# The header says "Reads the tree. Writes nothing." Asserted rather than trusted.
before="$(git -C "$SB" status --porcelain)"
run >/dev/null
after="$(git -C "$SB" status --porcelain)"
assert_eq "$before" "$after" "running the report changes nothing on disk"

assert_done
