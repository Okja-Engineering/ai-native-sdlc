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
. "$ROOT/bin/lib-rendering.sh"
. "$TEST_DIR/lib/retired-claim.sh"
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

# And "not recorded" is only a true sentence while the contract still declares the
# field the report looks for. A report that hardcodes a field name goes on saying
# "not recorded" after a rename, about an artifact that records one — so the drift
# is announced.
cp "$SB/process/03-define/define-contract.md" "$TMP/define-contract.bak"
grep -v "^| \`$dur_field\` |" "$TMP/define-contract.bak" > "$SB/process/03-define/define-contract.md"
assert_eq "0" "$(grep -c "^| \`$dur_field\` |" "$SB/process/03-define/define-contract.md")" \
  "the fixture really did remove the declaration"
out="$(run 2026-09-29)"
assert_contains "$out" "no longer declared" \
  "the report says so when the contract stops declaring the field it reads"
cp "$TMP/define-contract.bak" "$SB/process/03-define/define-contract.md"
out="$(run 2026-09-29)"
assert_not_contains "$out" "no longer declared" \
  "and says nothing about drift while the declaration is there"

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
# --- the two numbers a tripwire needs -----------------------------------------
# A decision commits to two more cycles and expires on a date. One missed cycle
# ends it. Nothing in the repository could compute either number, so both were
# going to be remembered or lost.
#
# `CYCLE_TODAY` is how the suite drives fixed dates through the real arithmetic.
# A report that reads the wall clock is otherwise testable only by hardcoding
# today, which is a test that fails tomorrow.
runat() { ( cd "$SB" && CYCLE_TODAY="$1" bash bin/cycle.sh 2>&1 ); }

# The date arithmetic. Every case is a pair a reader can check by eye, and the
# set covers what a naive implementation gets wrong: a month boundary, a year
# boundary, a leap day, and the day itself.
#
# None of these is today's date or the shipped decision's expiry. The shipped
# values are asserted separately, by reading them rather than by repeating them.
decision="$SB/process/05-deliver/decisions/producing-themes.md"
cp "$decision" "$TMP/decision.bak"

# The field is replaced where it belongs, next to `dated:`, rather than appended.
set_expiry() { # value
  grep -v '^expires:' "$TMP/decision.bak" \
    | awk -v v="$1" '{ print } /^dated:/ && !ins { print "expires: " v; ins = 1 }' > "$decision"
}

while IFS='|' read -r today expiry want; do
  [ -n "$today" ] || continue
  set_expiry "$expiry"
  out="$(runat "$today")"
  line="$(printf '%s\n' "$out" | grep 'expir')"
  assert_contains "$line" "$want" "on $today, an expiry of $expiry reads \`$want\`"
done <<'CASES'
2027-01-10|2027-01-10|, today
2027-01-10|2027-01-11|in 1 day
2027-01-10|2027-02-10|in 31 days
2027-01-10|2027-03-10|in 59 days
2028-02-27|2028-03-01|in 3 days
2027-02-27|2027-03-01|in 2 days
2026-12-30|2027-01-02|in 3 days
2027-03-10|2027-03-08|2 days ago
CASES

# An expiry in the past is the state the whole field exists to make visible, so it
# is not reported in the same voice as one in the future.
set_expiry "2027-03-08"
out="$(runat 2027-03-10)"
assert_contains "$(printf '%s\n' "$out" | grep 'expir')" "!!" \
  "an expiry in the past is flagged on its own line, not reported as ordinary"
set_expiry "2027-03-12"
out="$(runat 2027-03-10)"
assert_not_contains "$(printf '%s\n' "$out" | grep 'expir')" "!!" \
  "and an expiry still ahead is not flagged"

# A malformed expiry must say it is malformed. A report that silently drops it is
# worse than one that says nothing, because it looks like a tree with no tripwire.
for bad in "soon" "2027-02-31" "2027-13-01" "30/11/2026" "2027-3-8"; do
  set_expiry "$bad"
  out="$(runat 2027-01-10)"
  assert_contains "$out" "not a date" "an expiry of \`$bad\` is reported as unreadable"
  assert_contains "$out" "$bad" "and the unreadable value is quoted back"
done

# A decision with no expiry at all is a real state — most decisions do not expire
# — and it is said rather than left blank.
grep -v '^expires:' "$TMP/decision.bak" > "$decision"
assert_eq "0" "$(grep -c '^expires:' "$decision")" "the fixture really did remove the field"
out="$(runat 2027-01-10)"
assert_contains "$out" "no decision declares one" \
  "a tree where nothing declares an expiry says so"

# `none` is a declaration that the decision does not expire, and that is NOT the
# same state as the field being absent. Reporting both as "no decision declares
# one" would hide a record that answered the question.
set_expiry "none — nothing about this one is waiting on a measurement"
out="$(runat 2027-01-10)"
line="$(printf '%s\n' "$out" | grep 'expir')"
assert_contains "$line" 'declare `none`' "a declared \`none\` is reported as a declaration"
assert_not_contains "$line" "no decision declares one" "and not as an absent field"

# And `none` has to be the whole first word. `amends:` had the prefix version of
# this defect, where `nonetheless, ...` read as a declaration that nothing changed.
set_expiry "nonetheless this one runs out on 2027-01-20"
out="$(runat 2027-01-10)"
line="$(printf '%s\n' "$out" | grep 'expir')"
assert_contains "$line" "not a date" "a value beginning \`nonetheless\` is not read as \`none\`"

# A date followed by a note is a date.
set_expiry "2027-01-20 — unless the comparison lands first"
out="$(runat 2027-01-10)"
line="$(printf '%s\n' "$out" | grep 'expir')"
assert_contains "$line" "in 10 days" "a date followed by a note is read as the date"

cp "$TMP/decision.bak" "$decision"

# The shipped record's own expiry is read, not repeated. Hardcoding the date here
# would pin the test to a decision that is meant to be superseded.
shipped="$(sed -n 's/^expires:[[:space:]]*//p' "$decision" | head -1)"
assert_contains "$shipped" "-" "the open decision declares an expiry"
[ -n "$shipped" ] && any=yes || any=no
assert_eq "yes" "$any" "and the value was read from the record, not repeated here"
out="$(runat 2026-10-01)"
assert_contains "$out" "$shipped" "and the report names it"
assert_not_contains "$out" "not a date" "and it parses"

# --- days since the last cycle ------------------------------------------------
# F's stated failure is a cycle that quietly stops happening, and intent.md notes
# that such a failure leaves no trace. This is the trace.
last="$(ls "$SB/process/01-scan/findings"/*.md | sed -e 's|.*/||' -e 's|\.md$||' | sort | tail -1)"
assert_contains "$last" "-" "the newest findings file has a dated name"
out="$(runat "$last")"
assert_contains "$out" "last scan" "the report names when the last scan was"
line="$(printf '%s\n' "$out" | grep 'last scan')"
assert_contains "$line" ", today" "a scan dated today is nought days ago"

# Thirty-three days on, across two month boundaries.
y="$(printf '%s\n' "$last" | awk -F- '{print $1}')"
out="$(runat "$y-11-01")"
line="$(printf '%s\n' "$out" | grep 'last scan')"
assert_contains "$line" ", 33 days ago" "and the count is the days between the two dates"

# A worked example is not a scan. The report already refuses to count an
# `example: yes` file as a cycle; counting one as the LAST cycle would reset the
# tripwire by adding a file, which is the two-word edit this suite exists for.
printf '# Scan cycle — %s-12-01\n\nsince: %s\nexample: yes\nnothing found: no\n' "$y" "$last" \
  > "$SB/process/01-scan/findings/$y-12-01.md"
out="$(runat "$y-12-02")"
line="$(printf '%s\n' "$out" | grep 'last scan')"
assert_contains "$line" "$last" "an example-marked file is not counted as the last scan"
assert_not_contains "$line" "$y-12-01" "and the report does not name it as one"
rm -f "$SB/process/01-scan/findings/$y-12-01.md"

# An unreadable CYCLE_TODAY must not read as a clean report. A wrong today makes
# every number below it wrong, silently.
out="$( ( cd "$SB" && CYCLE_TODAY=tomorrow bash bin/cycle.sh 2>&1 ) )"; rc=$?
assert_status 2 "$rc" "an unreadable CYCLE_TODAY exits 2"
assert_contains "$out" "CYCLE_TODAY" "and says which input it could not read"

# --- the block order is pinned, and the documents agree with it ----------------
# `README.md` said "the `topics` block is the last thing printed". It had not been
# true since a `dates` block was added after it, and nothing noticed — the same
# staleness class `README.md` and `spec.md` both claim was repaired by deleting
# hand-typed duplicates, back as a claim about output ordering rather than a count.
#
# Two things are asserted, and the second is the one that stops this recurring: the
# order itself, and that no tracked document names a block as the last one unless it
# IS the last one. So adding a seventh block is a test failure until the sentence
# describing the output is updated with it.
blocks="$(run | sed -n 's/^\([a-z][a-z]*\)$/\1/p' | tr '\n' ' ' | sed 's/ $//')"
assert_eq "topics dates" "$blocks" "the report prints its trailing blocks in a pinned order"

last_block="${blocks##* }"
assert_eq "dates" "$last_block" "and the last block is the one the documents must name"

# Every tracked document that says a named block is the last thing printed has to
# name THIS one. The sentence is matched rather than the file, so a second document
# making the claim is covered without editing a list here.
#
# A line that RECORDS a corrected claim is exempt, declared in band with a reason —
# `<!-- corrected-claim: ... -->`, the form AGENTS.md, CONTROLS.md and DECIDERS.md
# already use. A correction has to quote the sentence it corrects, so without the
# exemption this check would refuse the only honest way to record that it was wrong.
#
# THE PREDICATE MOVED TO tests/lib/retired-claim.sh, and this is one of the two false
# refusals on issue #116. It was a `case` chain over the raw line, which was wrong in
# both directions at once:
#
#   it refused a document that QUOTED the retired sentence inside a fenced block — so
#   the one place that has to be able to show a reader the sentence could not show it
#
#   it accepted a declaration written inside an inline code span, so a document
#   illustrating the form retired a live claim
#
# It also differed from the near-identical rule in tests/test_doc_claims.sh: that one
# requires the declaration to NAME the phrase it retires and this one did not. Two
# copies of three rules is two things to get wrong, so there is one copy now and this
# suite keeps only the thing that is specific to it — which block is the last one.
#
# stale_last_block_claims <files...> -> the files carrying one
LASTBLOCK_CLAIM='the last thing printed|the last thing it prints'
stale_last_block_claims() {
  local hit f lno text out=""
  for hit in $(retired_claim_offenders corrected-claim "$LASTBLOCK_CLAIM" "$@"); do
    f="${hit%:*}"; lno="${hit##*:}"
    text="$(sed -n "${lno}p" "$f" 2>/dev/null)"
    # A line naming THIS block is making a TRUE claim, so it is not stale and needs no
    # retirement. Kept per line rather than per file: an earlier draft of this skipped
    # the whole document when any line named the right block, which would have let a
    # stale sentence ride along beside a correct one.
    case "$text" in
      *"\`$last_block\` block is the last thing"*) continue ;;
    esac
    out="$out $f"
  done
  printf '%s' "$out"
}

tracked_md=""
for f in $(git -C "$ROOT" ls-files -- '*.md'); do tracked_md="$tracked_md $ROOT/$f"; done
assert_eq "" "$(stale_last_block_claims $tracked_md)" \
  "no document names a block as the last thing printed unless it is \`$last_block\`"

# And the check has to be able to fire, three ways, or the line above is a check that
# cannot fail. The third case is the one found by loosening: broadening the exemption
# from `corrected-claim` to any HTML comment broke nothing, because no fixture carried
# a comment that was not a declaration.
printf 'The `topics` block is the last thing printed.\n' > "$TMP/p1.md"
case "$(stale_last_block_claims "$TMP/p1.md")" in
  *p1.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a document naming the wrong block as last is caught"

printf 'The `topics` block is the last thing printed. <!-- a note about something else -->\n' > "$TMP/p2.md"
case "$(stale_last_block_claims "$TMP/p2.md")" in
  *p2.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a comment that is not a declaration does not exempt the claim"

printf 'The `topics` block is the last thing printed. <!-- corrected-claim: -->\n' > "$TMP/p3.md"
case "$(stale_last_block_claims "$TMP/p3.md")" in
  *p3.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a declaration carrying no reason does not exempt it either"

printf 'This said the `topics` block is the last thing printed. <!-- corrected-claim: the last thing printed — it was true until the dates block landed -->\n' > "$TMP/p4.md"
assert_eq "" "$(stale_last_block_claims "$TMP/p4.md")" \
  "and a correction quoting the sentence it corrects is allowed to say it"

# The declaration has to NAME the phrase it retires, which is the rule
# tests/test_doc_claims.sh already held and this check did not until the two were made
# one. A reason about something else retires nothing.
printf 'The `topics` block is the last thing printed. <!-- corrected-claim: a reason about something else entirely -->\n' > "$TMP/p5.md"
case "$(stale_last_block_claims "$TMP/p5.md")" in
  *p5.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a declaration naming no phrase does not exempt the claim"

# --- the false refusal, from #116 ----------------------------------------------
# A document that QUOTES the retired sentence in order to show it was retired was
# refused, so the one place that has to be able to display it could not. Four display
# forms, because assuming they behave alike is how four of this week's holes were made.
printf '# A note\n\nREADME.md used to say:\n\n```\nThe `topics` block is the last thing printed.\n```\n' > "$TMP/q1.md"
assert_eq "" "$(stale_last_block_claims "$TMP/q1.md")" \
  "a quotation inside a backtick fence is not a claim"

printf '# A note\n\nREADME.md used to say:\n\n~~~\nThe `topics` block is the last thing printed.\n~~~\n' > "$TMP/q2.md"
assert_eq "" "$(stale_last_block_claims "$TMP/q2.md")" \
  "a quotation inside a tilde fence is not a claim"

printf '# A note\n\n<!-- README.md used to say:\nThe `topics` block is the last thing printed.\n-->\n' > "$TMP/q3.md"
assert_eq "" "$(stale_last_block_claims "$TMP/q3.md")" \
  "a quotation inside an HTML comment is not a claim"

printf '# A note\n\nREADME.md used to say:\n\n    The `topics` block is the last thing printed.\n\nand it stopped being true.\n' > "$TMP/q4.md"
assert_eq "" "$(stale_last_block_claims "$TMP/q4.md")" \
  "a quotation inside an indented block is not a claim"

# And an inline code span is NOT a display form for a sentence — a reader reads it —
# so that one is still a claim. Written out rather than assumed alike with the four
# above.
printf '# A note\n\nREADME.md said `the last thing printed` was the topics block.\n' > "$TMP/q5.md"
case "$(stale_last_block_claims "$TMP/q5.md")" in
  *q5.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a sentence inside an inline code span is still read, because a reader reads it"

# --- and the declaration cannot be displayed either ----------------------------
# The other direction of the same defect: a document showing a reader what the
# declaration looks like must not thereby retire a live claim.
printf 'The `topics` block is the last thing printed. `<!-- corrected-claim: the last thing printed — a reason -->`\n' > "$TMP/r1.md"
case "$(stale_last_block_claims "$TMP/r1.md")" in
  *r1.md*) ok=yes ;; *) ok=no ;;
esac
assert_eq "yes" "$ok" "a declaration shown inside an inline code span retires nothing"

# --- it writes nothing --------------------------------------------------------
# The header says "Reads the tree. Writes nothing." Asserted rather than trusted.
before="$(git -C "$SB" status --porcelain)"
run >/dev/null
after="$(git -C "$SB" status --porcelain)"
assert_eq "$before" "$after" "running the report changes nothing on disk"

assert_done
