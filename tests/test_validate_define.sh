#!/usr/bin/env bash
# The Define checks that do not depend on a cycle's shape.
#
# The accounting check is the one that matters most: it caught a real defect by
# hand before it was ever mechanised. The first draft of cycle 2026-09-29 themed
# 54 of 64 findings and reported three wrong counts, and the ten strays included
# a pattern nobody had named. This suite exists so the next one is caught in CI.
#
# Two kinds of fixture, for two different jobs.
#
# Cases about the SHIPPED RECORD mutate a copy of the shipped cycle file in a full
# tree copy, so the relative source link still resolves and the mutation is the
# only thing wrong. Every one of those mutations now goes through `mutate`, which
# fails the suite when its pattern matches nothing: the patterns are matched out of
# the artifact, so tampering with the artifact used to break the test's own mutation
# and the suite then reported the wrong check. See tests/lib/mutate.sh.
#
# Cases about SHAPE use a fixture built from nothing by tests/lib/define-fixture.sh,
# which knows its own answer. A record of a moment should not be asked to
# demonstrate shape, and a suite pinned to one cannot tell its own breakage from a
# defect.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"
. "$TEST_DIR/lib/mutate.sh"
. "$TEST_DIR/lib/define-fixture.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
CYCLE_REL="process/03-define/cycles/2026-09-29.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case: the gate resolves `from:` relative to the cycle file, so
# copying the file alone would refuse on an unresolved source before reaching
# the check under test.
fresh_tree() {
  local t="$TMP/t$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$t/process"
  printf '%s' "$t"
}

gate() { bash "$ROOT/process/03-define/validate-define.sh" "$1/$CYCLE_REL" 2>&1; }

# --- the shipped cycle passes -------------------------------------------------
# Read this one first when the suite is red. Every case about the shipped record
# mutates a copy of this file, so a failure here means the artifact is wrong and
# the cases below are reporting a broken baseline rather than a defect.
t="$(fresh_tree base)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" \
  "the shipped cycle file is within the contract — the baseline every case below mutates"
assert_contains "$out" "within the contract" "and the gate says so, naming no refusal"

# --- a run that read nothing does not report conformance -----------------------
# Over an empty cycles directory this said "0 file(s) within the contract" and
# exited 0: nothing was read, and the gate reported it all within the contract. CI
# runs this gate with no arguments, so emptying the directory left the log claiming
# a clean phase. An empty phase stays exit 0, as the scan gate already settled; the
# claim is what changes.
mkdir -p "$TMP/no-cycles"
out="$(DEFINE_CYCLES_DIR="$TMP/no-cycles" bash "$ROOT/process/03-define/validate-define.sh" 2>&1)"; rc=$?
assert_status 0 "$rc" "an empty cycles directory is not a refusal"
assert_contains "$out" "nothing was checked" "but the gate says it read nothing"
assert_not_contains "$out" "within the contract" \
  "and does not report files within the contract when it read none"

# --- accounting, as a set -----------------------------------------------------
# This was arithmetic comparing two totals. An external audit broke it two ways:
# lowercasing a finding's first letter removed it from the denominator, and two
# theme counts could move in opposite directions with the total reconciling.
# These cases cover the four distinct things that can be wrong with a set, which
# is what a total cannot distinguish.

# A finding deleted from the source — the case the arithmetic version passed.
t="$(fresh_tree drop_row)"
mutate "$t/process/01-scan/findings/2026-09-29.md" 's/^\| F03 \|.*\n//m' \
  "delete F03's row from the source"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a finding deleted from the source exits 1"
assert_contains "$out" "refuse[invented-accounting]" "an id accounted for but no longer in the source"
assert_contains "$out" "F03" "the refusal names which id"

# The same deletion, with the id mentioned in prose elsewhere in the source. The
# id set must come from table ROWS, not from anywhere the string appears — a
# loosened extractor passes this, which the mutation sweep found and nothing
# else caught.
t="$(fresh_tree drop_row_alibi)"
mutate "$t/process/01-scan/findings/2026-09-29.md" 's/^\| F03 \|.*\n//m' \
  "delete F03's row from the source, leaving it mentioned in prose"
printf '\nNote: F03 was reviewed separately.\n' >> "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a deleted row is still caught when its id appears in prose"
assert_contains "$out" "refuse[invented-accounting]" "ids come from table rows, not from any mention"

t="$(fresh_tree drop_id)"
mutate "$t/$CYCLE_REL" 's/\bF03 //' "drop F03 from the accounting block"
out="$(gate "$t")"
assert_contains "$out" "refuse[unaccounted]" "a finding left out of the accounting is refused"
assert_contains "$out" "nothing may be dropped" "the message states the rule it enforces"

t="$(fresh_tree invent)"
mutate "$t/$CYCLE_REL" 's/\bF64\b/F64 F99/' "account for an id the source does not carry"
assert_contains "$(gate "$t")" "refuse[invented-accounting]" "an invented id is refused"

t="$(fresh_tree dupe)"
mutate "$t/$CYCLE_REL" 's/\bF10 /F10 F10 /' "account for F10 twice"
assert_contains "$(gate "$t")" "refuse[duplicate-accounting]" "an id accounted for twice is refused"

# No block at all must refuse, not fall back to arithmetic.
t="$(fresh_tree no_block)"
mutate "$t/$CYCLE_REL" 's/<!-- accounting:ids -->.*?<!-- \/accounting:ids -->//s' \
  "remove the accounting block"
assert_contains "$(gate "$t")" "refuse[no-accounting]" "a cycle with no accounting block is refused"

# A theme count changed. The theme is found by position rather than by its text:
# matching `**7 findings · mostly \`high\`` pinned this case to one theme's wording
# and to its number, and when the artifact was tampered with the pattern stopped
# matching and this assertion failed about the wrong thing.
t="$(fresh_tree counts)"
mutate "$t/$CYCLE_REL" 's/^\*\*(\d+) findings/"**" . ($1 - 4) . " findings"/me' \
  "take four off the first theme count"
assert_contains "$(gate "$t")" "refuse[counts-disagree]" "theme counts that do not sum to the accounting are refused"

t="$(fresh_tree outlier_drop)"
mutate "$t/$CYCLE_REL" 's/^- \*\*.*?\n//ms' "remove the first outlier"
assert_contains "$(gate "$t")" "refuse[counts-disagree]" "losing an outlier is caught too"

# The documented limit, asserted so nobody mistakes it for coverage: moving a
# count between themes leaves the set unchanged and is NOT detected. Per-theme
# ids would close it, and cycle 2026-09-29 predates them.
#
# The two theme counts are the first and the last, found by position. Naming them
# by their numbers pinned the case to the artifact: the issue's deletion exploit
# decremented theme 2, the first half of the substitution stopped matching, the
# second half still applied, and this assertion went red saying a documented limit
# had been closed.
t="$(fresh_tree launder)"
mutate "$t/$CYCLE_REL" 's/^\*\*(\d+) findings/"**" . ($1 - 1) . " findings"/me' \
  "take one off the first theme count"
mutate "$t/$CYCLE_REL" 's/\A(.*)^\*\*(\d+) findings/"$1**" . ($2 + 1) . " findings"/mse' \
  "put it on the last theme count"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "moving a count between themes is NOT detected — the documented limit"

# Lowercasing a finding's prose must no longer change the accounting. The old
# counter was `grep -cE '^| [A-Z]'`, which dropped the row from the denominator.
t="$(fresh_tree lowercase)"
mutate "$t/process/01-scan/findings/2026-09-29.md" \
  's/^(\| F03 \| )([A-Z])/$1 . lc($2)/me' "lowercase the first letter of F03's what cell"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "lowercasing a finding's first letter no longer removes it"

# --- an empty outlier list says so in the BODY, not in the heading -------------
# define-contract.md calls Outliers "the load-bearing section", and the refusal
# that makes it load-bearing read the heading along with the list: the section was
# taken as `/^## Outliers/,/^---/`, so any of `none`, `empty` or `nothing`
# anywhere in that range satisfied it — including in the heading.
#
# The contract's own name for the section is "Outliers — surfaced because they fit
# nothing". A cycle using the contract's wording and listing no outliers at all
# therefore passed, which is exactly the case the refusal exists for. Found when
# bin/next.sh was made to scaffold the section from the contract: every skeleton it
# produced defeated the check by carrying the contract's heading.
# empty_outliers <tree> [body line] — replace the whole Outliers section with the
# contract's own heading, and optionally one line of body.
empty_outliers() {
  mutate "$1/$CYCLE_REL" \
    "s/^## Outliers.*?(?=^---)/## Outliers — surfaced because they fit nothing\n\n${2:-}\n/ms" \
    "replace the outlier section with the contract's heading"
}

t="$(fresh_tree empty_outliers_heading)"
empty_outliers "$t"
body="$(sed -n '/^## Outliers/,/^---/p' "$t/$CYCLE_REL")"
assert_eq "0" "$(printf '%s\n' "$body" | grep -cE '^- \*\*')" "the fixture lists no outliers"
assert_contains "$body" "they fit nothing" "and its heading carries the word the check looked for"
out="$(gate "$t")"
# Not asserted on the exit status: emptying the outlier list also makes the theme
# counts disagree, so exit 1 would be satisfied by a refusal that has nothing to do
# with this check — which is the whole failure mode this suite is being repaired
# for. The refusal code is the assertion.
assert_contains "$out" "refuse[silent-empty-outliers]" \
  "the emptiness has to be stated in the section, not implied by its title"

# And a section that DECLARES it is empty, in band and with a reason, still passes
# that check, so the fix is not simply "always refuse an empty list". An empty
# outlier list is a legitimate state the contract permits.
DECL='<!-- declared-empty: every finding this cycle fitted a theme -->'
t="$(fresh_tree empty_outliers_declared)"
empty_outliers "$t" "$DECL"
out="$(gate "$t")"
assert_not_contains "$out" "refuse[silent-empty-outliers]" \
  "a section that declares itself empty, with a reason, is accepted"

# WHAT THIS CHECK USED TO BE, and why a sentence is not a declaration.
#
# It was a lexical test for `none|empty|nothing` over the section's body, so prose
# that merely used one of those words satisfied it. Two consequences, both real:
#
#   * the shipped cycle's own explanation of why outliers matter contains "nothing"
#     twice, so for THAT artifact this refusal could never fire — delete all three
#     outliers and the section still satisfied its own emptiness check
#   * the same shape in the Discover gate let a topic delete all seven of its
#     "could not be established" items, assert the opposite, and pass
#
# Both cases are below. The first is the one the lexical check was documented as
# allowing; it is now refused.
t="$(fresh_tree empty_outliers_prose)"
empty_outliers "$t" "The one that clusters with nothing is often the most valuable."
out="$(gate "$t")"
assert_contains "$out" "refuse[silent-empty-outliers]" \
  "prose that merely uses the word does not declare the section empty"

# A plainer sentence saying exactly the right thing, which is still a sentence.
t="$(fresh_tree empty_outliers_stated)"
empty_outliers "$t" "None this cycle: every finding fitted a theme."
out="$(gate "$t")"
assert_contains "$out" "refuse[silent-empty-outliers]" \
  "a sentence stating the section is empty is not the declared form either"

# A declaration inside a FENCED BLOCK declares nothing. Found by attacking this
# check after writing it, and the same class `field` above already skips fences
# for: a fenced example of `rests on: none` donated itself as the real field's
# value. A cycle that documents the convention must not thereby satisfy it.
t="$(fresh_tree empty_outliers_fenced)"
empty_outliers "$t" '```\n<!-- declared-empty: all themed -->\n```'
out="$(gate "$t")"
assert_contains "$out" "refuse[silent-empty-outliers]" \
  "a declaration shown inside a fenced block does not declare the section empty"

# A declaration carrying no reason does not declare anything — the same rule the
# `not-a-claim` and `dead-pointer` declarations are held to.
t="$(fresh_tree empty_outliers_noreason)"
empty_outliers "$t" '<!-- declared-empty: -->'
out="$(gate "$t")"
assert_contains "$out" "refuse[silent-empty-outliers]" \
  "a declaration with no reason does not declare the section empty"

# The two gates have to hold the same form. They are separate scripts with no
# shared library, so the thing that keeps them together is that both suites pin the
# same behaviour — this case and its twin in tests/test_validate_discovery.sh.
assert_not_contains "$(cat "$ROOT/process/03-define/validate-define.sh")" \
  "none|empty|nothing" \
  "the gate no longer decides emptiness by searching prose for a word"

# --- method -------------------------------------------------------------------
t="$(fresh_tree method)"
mutate "$t/$CYCLE_REL" 's/^method: .*\n//m' "remove the method field"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-method]" "an undeclared method is refused"
assert_contains "$out" "before trusting the grouping" "the message says why it matters"

# --- outlier section ----------------------------------------------------------
t="$(fresh_tree outliers)"
mutate "$t/$CYCLE_REL" 's/^## Outliers.*?(?=^## Where)//ms' "remove the outlier section"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-outlier-section]" "a missing Outliers section is refused"
assert_contains "$out" "look identical" "the message says why an empty one must say so"

# --- source -------------------------------------------------------------------
t="$(fresh_tree source)"
mutate "$t/$CYCLE_REL" 's/^from: .*\n/from: nothing in particular\n/m' \
  "replace the from field with something that links nothing"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-source]" "a cycle with no linked source is refused"

t="$(fresh_tree gone)"
rm -f "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[source-unresolved]" "a source that does not resolve is refused"


# --- an outlier section that lists outliers is accepted ------------------------
# Found by tests/mutate-sweep.sh, by loosening `-eq 0` to `-ge 0` on the outlier
# count. The silent-empty check has two halves — nothing listed, and nothing saying
# it is empty — and only the refusal was covered. Nothing established that a section
# LISTING outliers is accepted, so with the count loosened a populated section is
# refused and no suite noticed.
#
# The shipped cycle cannot distinguish the two halves, because its outlier prose
# happens to contain the word "nothing" and that satisfies the second half on its
# own. This fixture takes those words out, so the count is the only thing left to
# decide it.
t="$(fresh_tree outliers_listed)"
awk '
  /^## Outliers/ { inside = 1 }
  inside && /^---/ { inside = 0 }
  inside {
    gsub(/[Nn]othing/, "little"); gsub(/[Nn]one/, "neither"); gsub(/[Ee]mpty/, "bare")
  }
  { print }
' "$t/$CYCLE_REL" > "$t/edited" && mv "$t/edited" "$t/$CYCLE_REL"
assert_eq "0" "$(sed -n '/^## Outliers/,/^---/p' "$t/$CYCLE_REL" | grep -ciE 'none|empty|nothing')" \
  "the fixture's outlier section says none of none, empty or nothing"
nout="$(sed -n '/^## Outliers/,/^---/p' "$t/$CYCLE_REL" | grep -cE '^- \*\*')"
[ "$nout" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "and it still lists outliers (found $nout)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "an outlier section that lists outliers is accepted"
assert_not_contains "$out" "refuse[silent-empty-outliers]" "and is not called silently empty"

# --- the gate with no arguments reads the cycles directory ---------------------
# Found by loosening `-gt 0` to `-ge 0` on the argument count. The gate then took the
# "files were named" branch with nothing named, looped over nothing, and reported
# "0 file(s) within the contract" and exit 0. CI runs this gate with no arguments, so
# that is a gate reporting a clean tree having evaluated nothing — the shape this
# repository keeps finding.
out="$(cd "$ROOT" && bash process/03-define/validate-define.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "the gate with no arguments passes over the real cycle files"
assert_not_contains "$out" "0 file(s) within the contract" \
  "and does not report having checked nothing"
ncyc="$(ls "$ROOT"/process/03-define/cycles/*.md 2>/dev/null | grep -c .)"
assert_contains "$out" "$ncyc file(s) within the contract" \
  "it checked every cycle file in the directory (found $ncyc)"
# --- a cycle cannot rest on a worked example ----------------------------------
# `example: yes` means "not a real scan". Two words in the findings file and
# bin/cycle.sh collapsed to a skipped line, both gates reported the files within
# the contract, and the Define cycle's `from:` still resolved to the now-example
# file and was accepted. findings-contract.md disclosed the inverse case — an
# example that forgets its marker — and this direction nowhere.
#
# The marker is not refused on its own: an example with nothing reading it is
# exactly what findings/2026-09-01.md is. What is refused is the contradiction
# between the marker and a cycle that depends on the file.
t="$(fresh_tree example_source)"
SRC="$t/process/01-scan/findings/2026-09-29.md"
mutate "$SRC" 's/^nothing found: (.*)$/nothing found: $1\nexample: yes/m' \
  "mark the source as a worked example"
assert_contains "$(cat "$SRC")" "example: yes" "the fixture marks the source as an example"
out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" "$SRC" 2>&1)"; rc=$?
assert_status 0 "$rc" "stage 1 accepts the marker, because an example is a legitimate file"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a cycle whose source is marked as an example exits 1"
assert_contains "$out" "refuse[source-is-example]" "and the refusal names the marker"
assert_contains "$out" "not a real scan" "and says what the marker means"

# `example: no` is the field's other legal value and says the opposite. Loosening
# the comparison from `= yes` to "the field is present" refuses this, and nothing
# else in this suite notices — found by mutating it.
t="$(fresh_tree example_no)"
SRC="$t/process/01-scan/findings/2026-09-29.md"
mutate "$SRC" 's/^nothing found: (.*)$/nothing found: $1\nexample: no/m' \
  "declare the source is not an example"
assert_contains "$(cat "$SRC")" "example: no" "the fixture declares the source is not an example"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a source that declares \`example: no\` is within the contract"

# The worked example that ships here is read by nothing, and must stay within the
# contract — the refusal is about the dependency, not about the marker.
out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" \
  "$ROOT/process/01-scan/findings/2026-09-01.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the shipped worked example is still within the contract"
assert_contains "$(cat "$ROOT/process/01-scan/findings/2026-09-01.md")" "example: yes" \
  "and it does carry the marker, so that assertion is about a marked file"

# --- the declared count is the denominator ------------------------------------
# The set comparison establishes that the accounting matches the source. It says
# nothing about what the source was supposed to contain, so a finding could be
# deleted from the source, dropped from the accounting block and decremented out
# of one theme count, and every check above still reconciled. `from:` declares the
# count and nothing read it.
#
# No number is written literally in any of these cases. They read the declared
# count out of the file, change the file, and compare against what they computed —
# a literal would pin this suite to today's artifact, which is the coupling that
# made a tampered artifact break the suite's own mutations.

# declared_count <cycle file> — the count the `from:` field states.
declared_count() {
  sed -n 's/^from:.*,[[:space:]]*\([0-9][0-9]*\)[[:space:]]*findings.*/\1/p' "$1" | head -1
}

# drop_finding <tree> <id> — delete the row from the source, drop the id from the
# accounting block, and take one off the first theme count, so every check that
# existed before this one still reconciles.
drop_finding() {
  local t="$1" id="$2"
  mutate "$t/process/01-scan/findings/2026-09-29.md" "s/^\\| $id \\|.*\\n//m" \
    "delete $id's row from the source"
  mutate "$t/$CYCLE_REL" "s/\\b$id //" "drop $id from the accounting block"
  awk 'BEGIN { done = 0 }
       done == 0 && /^\*\*[0-9]+ findings/ {
         match($0, /[0-9]+/)
         printf "%s%d%s\n", substr($0, 1, RSTART - 1), substr($0, RSTART, RLENGTH) - 1, \
           substr($0, RSTART + RLENGTH)
         done = 1; next
       }
       { print }' "$t/$CYCLE_REL" > "$t/cycle.tmp" && mv "$t/cycle.tmp" "$t/$CYCLE_REL"
}

t="$(fresh_tree deletion)"
before="$(declared_count "$t/$CYCLE_REL")"
drop_finding "$t" F07
# The mutation has to have landed, or the assertions below would be about an
# unmodified file. This is asserted rather than assumed: a mutation that silently
# does nothing is how a suite reports a defect in the wrong place.
assert_eq "$((before - 1))" \
  "$(/bin/bash "$ROOT/process/01-scan/findings-ids.sh" "$t/process/01-scan/findings/2026-09-29.md" | grep -c .)" \
  "the fixture now records one finding fewer than the cycle declares"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a deleted finding reconciled through the accounting still exits 1"
assert_contains "$out" "refuse[declared-count]" "the declared count is compared to the source"
assert_contains "$out" "declares $before findings" "the refusal names the count the record declares"
assert_contains "$out" "the source records $((before - 1))" "and the count the source actually carries"
assert_contains "$out" "not a filter" "and the rule it enforces"

# The stated limit, so nobody reads this as more than it is: correcting the
# declared count as well makes the record internally consistent again and the gate
# passes. The denominator is anchored to what the scan recorded, not to the world.
# CONTROLS.md CTRL-4 says so in the same words.
t="$(fresh_tree deletion_full)"
before="$(declared_count "$t/$CYCLE_REL")"
drop_finding "$t" F07
mutate "$t/$CYCLE_REL" "s/, $before findings/, @{[$before - 1]} findings/" \
  "correct the declared count to match"
assert_eq "$((before - 1))" "$(declared_count "$t/$CYCLE_REL")" "the declared count was corrected too"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "editing the declared count as well is NOT detected — the stated limit"

# A `from:` that links a source and states no count at all.
t="$(fresh_tree nocount)"
mutate "$t/$CYCLE_REL" 's/^(from: \[[^\n]*\]\([^)]*\)).*$/$1/m' \
  "strip the item count off the from field"
assert_eq "" "$(declared_count "$t/$CYCLE_REL")" "the fixture now declares no count"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a from: field with no item count exits 1"
assert_contains "$out" "refuse[no-declared-count]" "and names the missing count"

# --- a finding moved out of the findings table --------------------------------
# A way to drop a finding that was not one of the reported exploits: take the row
# out of `## Findings` and leave it in a table inside `## Looked at`, which the
# findings contract permits content in. Stage 1 accepts the file — the row is not
# in the findings table, so nothing there looks at it — and the id is still
# present in the file, so an extractor reading the whole file sees no change.
t="$(fresh_tree moved_row)"
SRC="$t/process/01-scan/findings/2026-09-29.md"
before="$(declared_count "$t/$CYCLE_REL")"
moved="$(grep '^| F07 |' "$SRC")"
mutate "$SRC" 's/^\| F07 \|.*\n//m' "take F07'\''s row out of the findings table"
awk -v row="$moved" '
  $0 ~ /^## Findings[[:space:]]*$/ && done == 0 {
    print "| id | what |"; print "|---|---|"; print row; print ""
    done = 1
  }
  { print }' "$SRC" > "$SRC.tmp" && mv "$SRC.tmp" "$SRC"
assert_contains "$(cat "$SRC")" "| F07 |" "the row is still in the file"
out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" "$SRC" 2>&1)"; rc=$?
assert_status 0 "$rc" "stage 1 accepts the file, so the Define gate is the only thing standing here"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a finding moved out of the findings table exits 1"
assert_contains "$out" "refuse[declared-count]" "and the declared count catches it"

# --- the gate will not run without the harvester ------------------------------
# Exit 2 is "could not run". Reporting the tree clean with no denominator is the
# shape bin/validate-claims.sh was caught in, and it is worse than a refusal.
t="$(fresh_tree noharvest)"
rm -f "$t/process/01-scan/findings-ids.sh"
out="$(FINDINGS_IDS="$t/process/01-scan/findings-ids.sh" bash "$ROOT/process/03-define/validate-define.sh" "$t/$CYCLE_REL" 2>&1)"; rc=$?
assert_status 2 "$rc" "a missing id harvester exits 2 rather than reporting the tree clean"
assert_contains "$out" "will not run without it" "and says it will not run"

# --- a problem is checked too -------------------------------------------------
# No gate read a problem or an option at all. `rests on:` is the only thing
# carrying the Discover-to-Define edge, and nothing resolved it: `cycle.sh`
# reported `classifier-models` as referenced by no problem and that was the whole
# of the enforcement. The invariant is that a problem names a Discover topic that
# exists, or says in band that it ran without one.
PROBLEM_REL="process/03-define/problems/producing-themes.md"
pgate() { bash "$ROOT/process/03-define/validate-define.sh" "$1/$PROBLEM_REL" 2>&1; }

t="$(fresh_tree problem)"
out="$(pgate "$t")"; rc=$?
assert_status 0 "$rc" "the shipped problem is within the contract"

t="$(fresh_tree problem2)"
out="$(bash "$ROOT/process/03-define/validate-define.sh" \
  "$t/process/03-define/problems/agent-pr-approval.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "and so is the other shipped problem"

t="$(fresh_tree norests)"
perl -0pi -e 's/^rests on: .*\n//m' "$t/$PROBLEM_REL"
out="$(pgate "$t")"; rc=$?
assert_status 1 "$rc" "a problem with no rests on: exits 1"
assert_contains "$out" "refuse[no-rests-on]" "the refusal is no-rests-on"
assert_contains "$out" "a declared skip" "the message says why a skip has to be declared"

# `none` with a reason is the declared way to record a problem stated without
# discovery. Bare `none` cannot be told from the field being forgotten, which is
# the same reasoning as `amends: none` and an empty outlier list.
t="$(fresh_tree bare_none)"
perl -0pi -e 's/^rests on: .*/rests on: none/m' "$t/$PROBLEM_REL"
out="$(pgate "$t")"; rc=$?
assert_status 1 "$rc" "a bare rests on: none exits 1"
assert_contains "$out" "refuse[bare-none-rests-on]" "the refusal is bare-none-rests-on"

t="$(fresh_tree real_none)"
perl -0pi -e 's/^rests on: .*/rests on: none — the cycle stated this question specifically enough to define from/m' \
  "$t/$PROBLEM_REL"
out="$(pgate "$t")"; rc=$?
assert_status 0 "$rc" "rests on: none with a reason is accepted"

# `none` has to be the whole first word. The same prefix defect was found in the
# Deliver gate, where `amends: nonetheless, ...` was read as a declaration that
# nothing changed.
for sneaky in \
  'nonetheless, we read around the question first' \
  'nonexistent, there was no topic to point at'
do
  t="$(fresh_tree "sneaky$(printf '%s' "$sneaky" | cksum | cut -d' ' -f1)")"
  perl -0pi -e "s/^rests on: .*/rests on: $sneaky/m" "$t/$PROBLEM_REL"
  out="$(pgate "$t")"; rc=$?
  assert_status 1 "$rc" "refuses a rests on: starting with none but not meaning it: ${sneaky%%,*}"
done

t="$(fresh_tree unlinked)"
perl -0pi -e 's/^rests on: .*/rests on: the classifier discovery/m' "$t/$PROBLEM_REL"
out="$(pgate "$t")"
assert_contains "$out" "refuse[rests-on-not-linked]" "a topic named but not linked is refused"

t="$(fresh_tree topicgone)"
rm -f "$t/process/02-discover/topics/classifier-models.md"
out="$(pgate "$t")"
assert_contains "$out" "refuse[rests-on-unresolved]" "a topic link that does not resolve is refused"

# Resolving is not enough: it has to resolve to a DISCOVER TOPIC. A link to any
# file that happens to exist would satisfy "the topic exists" while establishing
# nothing about the edge.
t="$(fresh_tree nottopic)"
perl -0pi -e 's|^rests on: .*|rests on: [`../cycles/2026-09-29.md`](../cycles/2026-09-29.md)|m' "$t/$PROBLEM_REL"
out="$(pgate "$t")"
assert_contains "$out" "refuse[rests-on-not-a-topic]" "a link to something that is not a Discover topic is refused"

# A field shown as an EXAMPLE is not the field. Found by attacking this check
# after writing it: a fenced `rests on: none — ...` ahead of the real field was
# read as the field's value, so the real link was never looked at and the gate
# reported the problem within the contract. Same class as the example row in
# DECIDERS.md that would have authorized everyone it named.
t="$(fresh_tree fenced)"
perl -0pi -e 's|^# Problem|# Problem\n\n```\nrests on: none — what the skip form looks like\n```\n|' "$t/$PROBLEM_REL"
perl -0pi -e 's|^rests on: \[|rests on: [|m' "$t/$PROBLEM_REL"
out="$(pgate "$t")"; rc=$?
assert_status 0 "$rc" "a fenced example does not stop the real rests on: being read"

t="$(fresh_tree fenced2)"
perl -0pi -e 's|^rests on: .*\n||m' "$t/$PROBLEM_REL"
perl -0pi -e 's|^# Problem|# Problem\n\n```\nrests on: none — what the skip form looks like\n```\n|' "$t/$PROBLEM_REL"
out="$(pgate "$t")"; rc=$?
assert_status 1 "$rc" "and a fenced example on its own does not satisfy the field"
assert_contains "$out" "refuse[no-rests-on]" "the refusal is no-rests-on"

# No Discover topics directory at all. Reachable only when the link resolves and
# the directory does not, because an unresolvable link returns before this. Found
# by tests/mutate-sweep.sh: deleting this refusal left every suite green, so the
# branch that says "nothing can establish the edge" was itself unestablished.
t="$(fresh_tree notopicsdir)"
perl -0pi -e 's|^rests on: .*|rests on: [`c`](../cycles/2026-09-29.md)|m' "$t/$PROBLEM_REL"
rm -rf "$t/process/02-discover/topics"
out="$(pgate "$t")"; rc=$?
assert_status 1 "$rc" "a tree with no Discover topics directory exits 1"
assert_contains "$out" "refuse[rests-on-not-a-topic]" "the refusal is rests-on-not-a-topic"
assert_contains "$out" "no Discover topics directory" "the message says the directory is missing"

# And problems are in the denominator of a bare run, not only of an explicit one.
# A check nobody invokes is not a control, and CI invokes this with no arguments.
t="$(fresh_tree bare_run)"
perl -0pi -e 's/^rests on: .*\n//m' "$t/$PROBLEM_REL"
out="$(DEFINE_CYCLES_DIR="$t/process/03-define/cycles" \
       DEFINE_PROBLEMS_DIR="$t/process/03-define/problems" \
       bash "$ROOT/process/03-define/validate-define.sh" 2>&1)"; rc=$?
assert_status 1 "$rc" "a run with no arguments reads problems as well as cycles"
assert_contains "$out" "refuse[no-rests-on]" "and refuses the problem it found"

# --- and the problem denominator is printed, like the cycle one ----------------
# The same reasoning the empty-input sweep applied to cycles, pointed at problems:
# a count nobody prints is a count nobody can check. Both of these were found by
# tests/mutate-sweep.sh, which made each comparison always true and saw nothing go
# red. Derived from the directory rather than written out, so adding a problem does
# not make the assertion stale.
out="$(cd "$ROOT" && bash process/03-define/validate-define.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "the bare run over the real tree passes"
nprob="$(ls "$ROOT"/process/03-define/problems/*.md 2>/dev/null | grep -c .)"
assert_contains "$out" "$nprob problem(s) checked" \
  "it says how many problems it checked (found $nprob)"

# An explicit run reports what was named and nothing else. The problem line belongs
# to the directory walk, so naming one file must not make the gate talk about a
# phase it did not read.
out="$(cd "$ROOT" && bash process/03-define/validate-define.sh "$CYCLE_REL" 2>&1)"; rc=$?
assert_status 0 "$rc" "naming one cycle file passes"
assert_not_contains "$out" "problem(s) checked" \
  "and does not claim to have checked problems it did not walk"
# Both halves of that block, because the empty half is the one a loosened guard
# reaches: with `$# -eq 0` always true, an explicit run falls into "no problem files"
# rather than into the count, and an assertion on the count alone sees nothing.
assert_eq "1" "$(printf '%s\n' "$out" | grep -c .)" \
  "an explicit run prints one summary line and nothing about a phase it did not walk"
# --- the anchors, on a fixture built from nothing ------------------------------
# Three of this gate's expressions are anchored to the start of a line and had no
# test. An anchor is invisible: remove it and the gate still reads plausibly, still
# passes every case above, and starts counting mentions as structure. AGENTS.md's
# rule is the one that applies — mutation-test the comparison, not just the guard,
# because deleting a check proves it is reachable and loosening it proves it is
# sufficient.
#
# Each case asserts WHAT THE ANCHOR PROTECTS, not the expression. The fixture is
# built by tests/lib/define-fixture.sh and passes the gate by construction, so the
# only difference between the baseline and the case is the mention that was added.
#
# The fourth anchored expression, the source's id harvest, moved into
# process/01-scan/findings-ids.sh and is covered by tests/test_findings_ids.sh.

anchor_gate() { bash "$ROOT/process/03-define/validate-define.sh" "$1" 2>&1; }

# The baseline. Nothing below means anything if this does not pass.
cyc="$(define_fixture "$TMP/anchor_base" "3 2" 1)"
out="$(anchor_gate "$cyc")"; rc=$?
assert_status 0 "$rc" "a cycle built from nothing is within the contract"

# `grep -q '^## Outliers'` — the section's EXISTENCE. Unanchored, a sentence
# mentioning the heading satisfies it, and a cycle with no outlier section at all
# passes the check the contract calls load-bearing.
cyc="$(define_fixture "$TMP/anchor_heading" "3 2" 1)"
mutate "$cyc" 's/^## Outliers.*?(?=^---)/Nothing here mentions a `## Outliers` section as a heading.\n\n/ms' \
  "replace the outlier section with a sentence that mentions its heading"
assert_contains "$(cat "$cyc")" '## Outliers' "the fixture still contains the heading text"
assert_eq "0" "$(grep -c '^## Outliers' "$cyc")" "but not at the start of any line"
out="$(anchor_gate "$cyc")"
assert_contains "$out" "refuse[no-outlier-section]" \
  "a heading mentioned inside a sentence is not an outlier section"

# `grep -cE '^- \*\*'` — the outlier COUNT, which feeds the reconciliation. The
# fixture declares one outlier; writing it inside a sentence instead of as a list
# item must leave the count at zero, so the counts no longer reconcile. Unanchored,
# the mention is counted and the cycle passes while the outlier is not surfaced —
# which is the whole point of the section.
cyc="$(define_fixture "$TMP/anchor_bullet" "3 2" 1)"
mutate "$cyc" 's/^- \*\*An outlier(.*?)\*\*$/One was recorded as prose: - **An outlier$1** — a mention, not an item./ms' \
  "move the outlier from a list item into the middle of a sentence"
assert_contains "$(cat "$cyc")" '- **An outlier' "the fixture still contains the list-item marker"
assert_eq "0" "$(grep -c '^- \*\*' "$cyc")" "but not at the start of any line"
out="$(anchor_gate "$cyc")"
assert_contains "$out" "refuse[counts-disagree]" \
  "an outlier written into a sentence is not counted as surfaced"

# `grep -oE '^\*\*[0-9]+ findings'` — the THEME COUNTS that are summed. Unanchored,
# any `**N findings` in prose is added to the sum, so a cycle can be made to
# reconcile by writing a number in a sentence rather than by accounting for
# anything. The fixture already reconciles, so adding the mention must change
# nothing.
cyc="$(define_fixture "$TMP/anchor_themecount" "3 2" 1)"
mutate "$cyc" 's/^Why we think it is a theme: it is a built fixture\.$/Why we think it is a theme: a sibling carried **9 findings** and this one did not./m' \
  "mention a theme count inside a sentence"
assert_contains "$(cat "$cyc")" '**9 findings' "the fixture now mentions a count in prose"
assert_eq "0" "$(grep -c '^\*\*9 findings' "$cyc")" "but not at the start of any line"
out="$(anchor_gate "$cyc")"; rc=$?
assert_status 0 "$rc" "a count mentioned inside a sentence is not added to the theme sum"
assert_not_contains "$out" "refuse[counts-disagree]" "so the reconciliation is unchanged by it"

# The denominator for the mutations above, printed rather than trusted.
mutate_done 20

assert_done
