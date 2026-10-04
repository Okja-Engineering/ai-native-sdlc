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

# Announcing the skip was #36's repair and it is not enough on its own. The whole
# of the cycle below the findings file — its themes, its problems, its two
# decisions — still left the report, and what the reader is told is that a file is
# an example. The report now says which Define cycles are reading it, because that
# is the contradiction: a worked example cannot be a real cycle's source.
assert_contains "$out" "2026-09-29" "the dependent Define cycle is named"
assert_contains "$out" "reads it" "and the report says it is being read"
git -C "$SB" checkout -q -- process/01-scan/findings/2026-09-29.md

# The worked example that ships here is read by nothing, so it gets the skip line
# and no contradiction — the report is about the dependency, not the marker.
out="$(run)"
example_block="$(printf '%s\n' "$out" | awk '/^2026-09-01$/{on=1;next} /^[0-9]{4}-/{on=0} on')"
assert_contains "$example_block" "skipped" "the shipped worked example is reported as skipped"
assert_not_contains "$example_block" "reads it" "and nothing is reported as reading it"

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

# A count it cannot establish must not be reported as zero. Zero is a real count —
# a cycle that found nothing — so printing it for a cycle nobody could read would
# say the scan was quiet when nothing was measured.
cp "$SB/process/01-scan/findings-contract.md" "$TMP/contract.bak"
awk '$0 == "<!-- contract:columns -->" { print; print "- `what`"; skip = 1; next }
     skip > 0 && /^- / { next }
     { skip = 0; print }' "$TMP/contract.bak" > "$SB/process/01-scan/findings-contract.md"
out="$(run 2026-09-29)"
assert_not_contains "$out" "0 findings" "a count that cannot be established is not reported as zero"
assert_contains "$out" "? findings" "it is reported as unknown"
cp "$TMP/contract.bak" "$SB/process/01-scan/findings-contract.md"

# And the report refuses to run at all without the harvester, rather than
# falling back to an idea of its own about what a finding is.
mv "$SB/process/01-scan/findings-ids.sh" "$TMP/findings-ids.sh"
out="$(run 2026-09-29)"; rc=$?
assert_status 2 "$rc" "no harvester exits 2"
assert_contains "$out" "will not run without it" "and says it will not run without one"
mv "$TMP/findings-ids.sh" "$SB/process/01-scan/findings-ids.sh"

# --- one cycle by name --------------------------------------------------------
out="$(run 2026-09-29)"; rc=$?
assert_status 0 "$rc" "naming a cycle exits 0"
assert_not_contains "$out" "topics" "naming a cycle reports that cycle only"

out="$(run 2099-01-01)"; rc=$?
assert_status 1 "$rc" "an unknown cycle exits 1"

# --- what the convergence pass cost -------------------------------------------
# Decision F commits to recording the pass duration across two more cycles, and
# the report named everything about a cycle except that. The field is declared in
# define-contract.md and read by no gate, so this report is the only place a
# person sees it.
#
# The field name is read out of the contract rather than written here, so the test
# is about the chain from the declaration to the report.
dur_field="$(sed -n '/^## Required fields$/,/^## /p' "$ROOT/process/03-define/define-contract.md" \
  | sed -n 's/^| `\([a-z_ ]*\)` *|.*convergence pass took.*/\1/p' | head -1)"
[ -n "$dur_field" ] && any=yes || any=no
assert_eq "yes" "$any" "the contract declares a field for the pass duration"

sed 's/2026-09-29/2026-11-03/g' "$SB/process/01-scan/findings/2026-09-29.md" \
  > "$SB/process/01-scan/findings/2026-11-03.md"
sed -e 's|findings/2026-09-29|findings/2026-11-03|g' \
    -e "s|^method: .*|method: read by hand, not by classifier\n$dur_field: about two hours, in one sitting|" \
  "$SB/process/03-define/cycles/2026-09-29.md" > "$SB/process/03-define/cycles/2026-11-03.md"
assert_contains "$(cat "$SB/process/03-define/cycles/2026-11-03.md")" "$dur_field: about two hours" \
  "the fixture really does carry a duration"

out="$(run 2026-11-03)"
assert_contains "$out" "about two hours, in one sitting" \
  "the report names how long the convergence pass took"
define_line="$(printf '%s\n' "$out" | grep '03 define')"
assert_contains "$define_line" "about two hours" \
  "and it says so on the line that reports the rest of the cycle's state"
rm -f "$SB/process/01-scan/findings/2026-11-03.md" "$SB/process/03-define/cycles/2026-11-03.md"

# A cycle that does not record it must be SAID to not record it. A blank would
# read as a pass that took no time, and an omitted phrase as a cycle nobody
# asked. The shipped cycle predates the field, so it is the real case.
out="$(run 2026-09-29)"
define_line="$(printf '%s\n' "$out" | grep '03 define')"
assert_contains "$define_line" "not recorded" \
  "a cycle that records no duration is reported as not recording one"

# --- a cycle with no themes is reported as a cycle with no themes --------------
# count_themes() was `grep -cE ... || echo 0`. `grep -c` ALREADY prints 0 and
# exits 1 when it matches nothing, so the fallback printed a second zero and the
# report read `0\n0 themes, 0\n0 outliers` across four lines. Unreachable while
# the only cycle in the tree had seven themes; a scaffolded cycle has none, and
# bin/next.sh now scaffolds one for every new date.
sed 's/2026-09-29/2026-11-04/g' "$SB/process/01-scan/findings/2026-09-29.md" \
  > "$SB/process/01-scan/findings/2026-11-04.md"
{
  printf '# Define — cycle 2026-11-04\n\n'
  printf 'dated: 2026-11-04\n'
  printf 'from: [`process/01-scan/findings/2026-11-04.md`](../../01-scan/findings/2026-11-04.md), 64 findings\n'
  printf 'method: nothing has been read yet\n'
  printf 'status: defined, not decided\n\n## Themes\n\n*To be written.*\n'
} > "$SB/process/03-define/cycles/2026-11-04.md"
out="$(run 2026-11-04)"
define_line="$(printf '%s\n' "$out" | grep '03 define')"
assert_contains "$define_line" "0 themes, 0 outliers" \
  "an unthemed cycle reports no themes and no outliers on one line"
assert_eq "0" "$(printf '%s\n' "$out" | grep -cE '^[0-9]+ (themes|outliers)')" \
  "and no count spills onto a line of its own, which is what a doubled zero did"
rm -f "$SB/process/01-scan/findings/2026-11-04.md" "$SB/process/03-define/cycles/2026-11-04.md"

# --- it writes nothing --------------------------------------------------------
# The header says "Reads the tree. Writes nothing." Asserted rather than trusted.
before="$(git -C "$SB" status --porcelain)"
run >/dev/null
after="$(git -C "$SB" status --porcelain)"
assert_eq "$before" "$after" "running the report changes nothing on disk"

assert_done
