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
# The orphan is constructed. It used to be `classifier-models` in the shipped
# tree, which made this assertion rest on data: that topic is what the
# `producing-themes` problem's whole cost argument is drawn from, and once the
# problem declared the `rests on:` link it had always relied on in prose, the
# only orphan in the tree disappeared and so did the assertion's subject.
printf '# Discovery — a topic no problem points at\n\ndated: 2026-09-29\n' \
  > "$SB/process/02-discover/topics/unreferenced-topic.md"
out="$(run)"
assert_contains "$out" "rests under" "a referenced topic says what references it"
assert_contains "$out" "referenced by no problem" "an unreferenced topic is reported as an orphan"
assert_contains "$out" "unreferenced-topic" "and names which topic has no parent"
rm -f "$SB/process/02-discover/topics/unreferenced-topic.md"

# --- the count it reports is the count the source records ---------------------
# count_rows() carried its own expression for what a finding is. It was anchored,
# so it survived the lowercasing exploit, and it read the WHOLE FILE — so a
# markdown table anywhere in a findings file was reported as findings.
# findings-contract.md permits content in `## Looked at`, so this is a
# contract-valid file that the report over-counted.
#
# No count is written literally. The report is compared against the harvester,
# which is the one thing that decides what a finding is.
decoy="$SB/process/01-scan/findings/2026-11-02.md"
{
  printf '# Scan cycle — 2026-11-02\n\nsince: 2026-09-29\nnothing found: no\n\n'
  printf '## Looked at\n\n'
  printf -- '- web: release notes, 2026-09-29 to 2026-11-02.\n'
  printf -- '- X: the syndication endpoint, 2026-09-29 to 2026-11-02.\n'
  printf -- '- YouTube: channel feeds, 2026-09-29 to 2026-11-02.\n\n'
  printf 'What could not be reached, as a table:\n\n'
  printf '| id | what |\n|---|---|\n| F91 | a decoy row |\n| F92 | another decoy row |\n\n'
  printf '## Findings\n\n'
  printf '| id | what | source | dated | kind | might affect (guess) | consequence guess |\n'
  printf '|---|---|---|---|---|---|---|\n'
  printf '| F01 | A thing happened | https://example.com/a | 2026-10-30 | practice-change | build (guess) | low |\n'
  printf '| F02 | Another thing happened | https://example.com/b | 2026-11-01 | practice-change | build (guess) | low |\n'
} > "$decoy"

out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" "$decoy" 2>&1)"; rc=$?
assert_status 0 "$rc" "the decoy fixture is within the stage 1 contract"

want="$(/bin/bash "$ROOT/process/01-scan/findings-ids.sh" "$decoy" | grep -c .)"
out="$(run 2026-11-02)"
reported="$(printf '%s\n' "$out" | sed -n 's/.*01 scan *\([0-9][0-9]*\) findings.*/\1/p' | head -1)"
assert_eq "$want" "$reported" "the report counts the findings the source records"
rm -f "$decoy"

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
