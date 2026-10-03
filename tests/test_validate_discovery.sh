#!/usr/bin/env bash
# The Discover gate: what is checkable about a discovery artifact.
#
# Both shipped topics must pass, and they have deliberately different shapes —
# one uses bare `[E]` markers and numbered headings, the other bold `**[E]**`
# and unnumbered. A gate that only accepted one of them would have encoded the
# newer artifact's markup as a rule, which is the failure the contract deferred
# its gate to avoid.
#
# Every refusal is asserted by its distinctive message. A non-zero exit cannot
# tell "no coverage section" from "an invented grade", and an operator who
# cannot read a gate bypasses it.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/02-discover/validate-discovery.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case, because the gate resolves local links relative to the
# artifact and a copied file alone would refuse on an unresolved link before
# reaching the check under test.
fresh() {
  local t="$TMP/$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$t/"
  printf '%s' "$t"
}
NEW=topics/agent-pr-approval.md
OLD=topics/classifier-models.md
gate() { bash "$GATE" "$1/process/02-discover/$2" 2>&1; }

# --- both shipped topics pass, despite differing in form ----------------------
t="$(fresh base)"
out="$(gate "$t" "$NEW")"; rc=$?
assert_status 0 "$rc" "the newer topic is within the contract"
out="$(gate "$t" "$OLD")"; rc=$?
assert_status 0 "$rc" "the older topic is within the contract, with different markup"

out="$(bash "$GATE" 2>&1)"; rc=$?
assert_status 0 "$rc" "both shipped topics pass when the gate runs over the directory"
assert_contains "$out" "2 file(s) within the contract" "it reports how many it checked"

# --- fields -------------------------------------------------------------------
t="$(fresh dated)"; perl -0pi -e 's/^dated: .*\n//m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[undated]" "an undated artifact is refused"

t="$(fresh status)"; perl -0pi -e 's/^status: .*\n//m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-status]" "a statusless artifact is refused"

# --- the question in the asker's own words ------------------------------------
t="$(fresh question)"
perl -0pi -e "s/## The question, in the asker's own words/## Background/" "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-question]" "an artifact not stating the question is refused"
assert_contains "$out" "answers a different question" "the message says why a tidied restatement is the problem"

# The older topic labels the question in bold rather than as a heading. Both are
# accepted, so stripping only the quotation has to be what trips it.
t="$(fresh quote)"; perl -0pi -e 's/^> .*\n//mg' "$t/process/02-discover/$OLD"
assert_contains "$(gate "$t" "$OLD")" "refuse[question-not-quoted]" \
  "a question section with no quotation is refused"

# --- coverage, in three parts -------------------------------------------------
t="$(fresh vbh)"
perl -0pi -e 's/[Vv]erified by hand/Checked/g' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-verified-by-hand]" "coverage without a verified-by-hand part is refused"
assert_contains "$out" "a pile of agent output" "the message says what the section is protecting against"

t="$(fresh notreached)"
perl -0pi -e 's/[Nn]ot reached/Other/g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-not-reached]" \
  "coverage that lists only successes is refused"

# --- the hollow artifact the external audit built ----------------------------
# These checks used to grep the WHOLE FILE for each phrase, so `no-reached` was
# satisfied by the substring inside "not reached" and `no-verified-by-hand` by a
# sentence DENYING hand verification. A whole artifact passed.
hollow() { # heading-for-coverage -> path
  local p="$TMP/hollow$2.md"
  cat > "$p" <<EOF
# Discovery — something

dated: 2026-10-03
status: discovery complete, not assessed

## The question, in the asker's own words

> should we turn it on

$1

Everything was reached. Nothing was not reached. Nothing was verified by hand — we took the agent's word for all of it.

## Claims

It is completely safe. **[E]**

Grades are the STANDARDS.md scheme: [V] vendor, never outcome evidence.

## What could not be established

Nothing. Everything was established.

## Where this stops

Nowhere.
EOF
  printf '%s' "$p"
}

out="$(bash "$GATE" "$(hollow '## 2 · Coverage' a)" 2>&1)"; rc=$?
assert_status 1 "$rc" "the hollow artifact is refused"
assert_contains "$out" "refuse[no-reached]" "a denial does not satisfy the reached part"
assert_contains "$out" "refuse[no-verified-by-hand]" "a sentence denying hand verification does not satisfy it"

# And not because of the heading. `^#+ *coverage` required the word immediately
# after the hashes, so a numbered heading was refused while a plain one passed —
# heading-shape coupling, and the only reason the hollow artifact was caught at
# all before this change.
out="$(bash "$GATE" "$(hollow '## Coverage' b)" 2>&1)"; rc=$?
assert_status 1 "$rc" "the hollow artifact is refused with a plain heading too"
assert_not_contains "$out" "refuse[no-coverage]" "a numbered coverage heading is accepted"

# --- a coverage part has to NAME something ------------------------------------
# The whole guard here used to be two numbers: a minimum count of separators and
# a minimum character count, with a comment asserting that "a fabricated part
# tops out around 43 characters and 2 separators". That is false. A sentence
# denying that anything was checked passed with two commas added to it, and the
# same sentence without the commas was refused. The suite pinned the two
# numbers, so the gate and its tests agreed with each other and both measured
# punctuation.
#
# What is pinned below is the behaviour instead: a coverage part names something
# the rest of the artifact also carries. No case here knows how the gate finds a
# name, or counts anything, so a different implementation of the same rule still
# passes.

# An artifact whose body names real things — a repository, an API, a commit, a
# benchmark — so that a coverage part has something it can resolve against. The
# three coverage parts are supplied per case, and the two not under test always
# name things, so one case trips one guard. A case that trips two guards at once
# proves neither, because a guard that never fires alone cannot be told from one
# that does not work — and this suite broke that rule twice. The rule is in
# AGENTS.md, "Tests: pin the invariant, not the literals", from issue #29, which a
# clone cannot read.
artifact() { # reached not-reached verified-by-hand suffix -> path
  local p="$TMP/cov$4.md"
  cat > "$p" <<EOF
# Discovery — something

dated: 2026-10-03
status: discovery complete, not assessed

## The question, in the asker's own words

> should we turn it on

## 2 · Coverage

**Reached:** $1
**Not reached:** $2
**Verified by hand:** $3

## Claims

The GitHub REST API returned 300 pull requests, and the SemIf source was read at commit 23cf1f3. [E]

Grades are the STANDARDS.md scheme: [V] vendor, never outcome evidence, [S] standard, [P] practitioner, [O] open.

## What could not be established

- the JevBench sealed items [O]

## Where this stops

Here.
EOF
  printf '%s' "$p"
}

NAMED='the GitHub REST API, the SemIf source at commit 23cf1f3, and JevBench'

# The control first, so a later refusal cannot be the gate refusing everything.
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" "$NAMED" ctl)" 2>&1)"; rc=$?
assert_status 0 "$rc" "an artifact whose three coverage parts name things is within the contract"

# The artifact from #32, which the two numbers passed. Each part is varied on its
# own so the refusal that fires names the part that is hollow.
DENY='Nothing was verified by hand, nothing whatsoever; we took the agent'"'"'s word for all of it.'
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" "$DENY" deny)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a verified-by-hand part denying that anything was checked is refused"
assert_contains "$out" "refuse[empty-verified-by-hand]" "the refusal is empty-verified-by-hand"
assert_contains "$out" "verified by hand" "the refusal names the part that resolves to nothing"

# The SAME sentence with the punctuation taken out. It must be refused for the
# same reason, because punctuation is not what decides.
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" 'Nothing was verified by hand we took the agent'"'"'s word for all of it' denyflat)" 2>&1)"
assert_contains "$out" "refuse[empty-verified-by-hand]" "the same denial without punctuation is refused the same way"

# And the mutation in the other direction, which is the one the old thresholds
# could not survive: a part that is long and heavily separated and still names
# nothing. This passes both old numbers comfortably.
LONG='well, we did, broadly, go through, item by item, all of the things; and then, after that, we went through them again, carefully, twice over'
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" "$LONG" long)" 2>&1)"
assert_contains "$out" "refuse[empty-verified-by-hand]" "a long, heavily punctuated part that names nothing is refused"

# The converse, and the strongest pin on the invariant: a part far below both old
# thresholds — short, no separators at all — that names one thing the artifact
# carries. It must be accepted, because naming something is the whole bar.
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" 'JevBench' short)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a short part with no separators that names something is accepted"

# A part that names things the artifact carries nowhere else resolves to nothing.
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" 'QuuxCorp and FooBench, read in full, twice' noref)" 2>&1)"
assert_contains "$out" "refuse[empty-verified-by-hand]" "a part naming things the artifact never mentions again is refused"

# A TRUNCATION of a name the artifact carries is not that name. Found by
# mutating the comparison rather than deleting it: swapping the whole-name match
# for a substring match caused no test to fail, which means the suite did not
# pin the match. Same defect, and the same fix, as the truncated source id in
# the STANDARDS.md suite.
out="$(bash "$GATE" "$(artifact "$NAMED" "$NAMED" 'JevB' trunc)" 2>&1)"
assert_contains "$out" "refuse[empty-verified-by-hand]" "a part naming a truncation of a real name is refused"

# The other two parts, each on its own, with their own refusal code.
out="$(bash "$GATE" "$(artifact 'everything, all of it, every last thing' "$NAMED" "$NAMED" r)" 2>&1)"
assert_contains "$out" "refuse[empty-coverage-part]" "a reached part that names nothing is refused"
assert_contains "$out" "'reached'" "the refusal names the reached part"

out="$(bash "$GATE" "$(artifact "$NAMED" 'nothing at all, nothing whatsoever, we got to all of it' "$NAMED" n)" 2>&1)"
assert_contains "$out" "refuse[empty-coverage-part]" "a not-reached part that names nothing is refused"
assert_contains "$out" "'not reached'" "the refusal names the not-reached part"

# The suite must not be able to pass by pinning the old numbers back in.
src="$(cat "$GATE")"
assert_not_contains "$src" "PART_MIN_SEPS" "the gate no longer counts separators"
assert_not_contains "$src" "PART_MIN_CHARS" "the gate no longer counts characters"

# --- the open section ---------------------------------------------------------
t="$(fresh open)"
perl -0pi -e 's/## What could not be established/## Notes/' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-open-section]" "a missing open section is refused"
assert_contains "$out" "claims completeness" "the message says what omitting it asserts"

# --- where this stops ---------------------------------------------------------
t="$(fresh stops)"
perl -0pi -e 's/[Ww]here this stops/Closing/g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-where-this-stops]" \
  "an artifact that does not say where it stops is refused"

# --- grades -------------------------------------------------------------------
# Not "every claim is graded" — the gate cannot check that and says so. This is
# that an invented grade is caught.
t="$(fresh enum)"
perl -0pi -e 's/\*\*\[V\]\*\*/**[X]**/' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[grade-not-in-enum]" "a grade outside the enum is refused"
assert_contains "$out" "E, S, V, P, O" "the message names the enum"

t="$(fresh nogrades)"
perl -0pi -e 's/\[([ESVPO])\]//g' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-grades]" "an artifact with no graded claims is refused"

# --- the refusals that had no test at all ------------------------------------
# Found by the external audit in #22: `no-grade-key` and `silent-empty-open`
# were emitted by the gate and asserted nowhere. `silent-empty-open` is the one
# guarding whether an artifact actually left anything open, which is directly
# load-bearing for the audit's sixth question.
# The key is one line declaring the scheme. Removing only the phrase "never
# outcome evidence" was not enough — the first version of the check matched any
# line pairing "vendor" with a [V] marker, and this artifact has several. The
# mutation has to remove the LINE.
t="$(fresh gradekey)"
perl -0pi -e 's/^\*\*Grades\*\* are the.*\n//m' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[no-grade-key]" "an artifact that does not declare the grade scheme is refused"
assert_contains "$out" "never outcome evidence" "the message says what a reader cannot know without it"

# And a line declaring only two grades is not a key either.
t="$(fresh gradekey2)"
perl -0pi -e 's/^\*\*Grades\*\* are the.*$/**Grades**: `[E]` empirical and `[S]` standard./m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-grade-key]" "a partial key is refused"

# An open section that lists nothing and does not say so. The gate accepts an
# explicit statement of emptiness and refuses silence, same as Define's outlier
# check — an omitted list and an empty one look identical otherwise.
t="$(fresh silentopen)"
perl -0pi -e 's{(## What could not be established\n).*?(\n## Where this stops)}{$1\nSome prose with no items at all in it.\n$2}s' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[silent-empty-open]" "an open section listing nothing without saying so is refused"

# And the same section, empty but explicit, is accepted.
t="$(fresh explicitopen)"
perl -0pi -e 's{(## What could not be established\n).*?(\n## Where this stops)}{$1\nNothing — everything in scope was established.\n$2}s' "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_not_contains "$out" "refuse[silent-empty-open]" "an explicitly empty open section is accepted"

t="$(fresh nocoverage)"
perl -0pi -e 's/^## Coverage$/## Notes/m' "$t/process/02-discover/$NEW"
assert_contains "$(gate "$t" "$NEW")" "refuse[no-coverage]" "an artifact with no coverage section is refused"

# --- links resolve ------------------------------------------------------------
# The shipped topics carry only http sources, so a mutation had nothing to
# break — the first version of this test passed while proving nothing. A broken
# local link is appended instead.
t="$(fresh links)"
printf '\nSee [the problem](../../03-define/problems/nope.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"
assert_contains "$out" "refuse[link-unresolved]" "a local link that does not resolve is refused"

# And a link that does resolve must not trip it.
t="$(fresh goodlink)"
printf '\nSee [the problem](../../03-define/problems/agent-pr-approval.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate "$t" "$NEW")"; rc=$?
assert_status 0 "$rc" "a local link that resolves is accepted"

# --- the gate must not pretend to check what it cannot ------------------------
# The contract named four checks. Two are not mechanisable without a claim
# convention the artifacts do not have, and one is deliberately omitted. If a
# later edit quietly adds a recommendation-language check, this fails — the
# false-positive it would produce is documented in the gate's own header.
src="$(cat "$GATE")"
assert_contains "$src" "NOT CHECKABLE" "the gate states which contract checks it cannot make"
assert_contains "$src" "DELIBERATELY NOT BUILT" "the gate states which check it declines to make"
assert_not_contains "$src" 'refuse "$f" "-" "recommendation' \
  "the gate does not refuse on recommendation language"

assert_done
