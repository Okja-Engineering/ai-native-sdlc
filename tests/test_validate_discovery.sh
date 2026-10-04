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

# --- a run that read nothing does not report conformance -----------------------
# Over an empty topics directory this said "0 file(s) within the contract" and
# exited 0: no artifact was read, and the gate reported every one of them within
# the contract. CI runs this gate with no arguments, so emptying or moving the
# directory left the log claiming a clean phase.
#
# A phase with no artifact is a real state and is still exit 0 — the scan gate
# already settled that, calling it a first run — so what changes is the claim, not
# the status. "nothing was checked" is the phrase the controls gate and the claims
# gate already use for the same thing.
mkdir -p "$TMP/no-topics"
out="$(DISCOVER_TOPICS_DIR="$TMP/no-topics" bash "$GATE" 2>&1)"; rc=$?
assert_status 0 "$rc" "an empty topics directory is not a refusal"
assert_contains "$out" "nothing was checked" "but the gate says it read nothing"
assert_not_contains "$out" "within the contract" \
  "and does not report files within the contract when it read none"

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

# --- an empty open section DECLARES it, and a word in prose is not that --------
#
# This is the control behind the external audit's sixth question — where did the
# process say it could not verify something — and it was a word search. The check
# read the section's body for `none|nothing|everything was`, so an artifact could
# delete every disclosure it owed, assert the opposite, and pass on one incidental
# word. Reproduced by a review against `topics/agent-pr-approval.md`: all seven
# items deleted and replaced with "The discovery was exhaustive and nothing of
# consequence remains outstanding", and the gate reported it within the contract.
#
# Two more ways in were found while repairing it, and NEITHER NEEDED A WORD:
#
#   * the section's own trailing `---` separator was inside the body the check
#     read, and `---` begins with a list marker, so it counted as an open item and
#     the emptiness check never ran
#   * an `[O]` anywhere in the body counted as an item, so one line of prose
#     carrying a grade marker was enough
#
# So the body is now scoped to the next heading OR the next `---`, the way Define
# already scopes its outlier section, and an open item is a list item carrying an
# `[O]` grade — the form this contract asks for and both shipped topics use.
#
# What is pinned below is the invariant: an empty section declares itself empty, in
# band, with a reason — the same shape as `not-a-claim` and `dead-pointer`. No case
# here knows the gate's expression, so a different implementation of the same rule
# still passes, and a case asserting a word would be the defect back again.
#
# THE FIXTURE IS BUILT, not mutated out of a shipped topic. These cases are about
# shape, per AGENTS.md, and a hollow artifact that was never one of the inputs is
# the only honest test of a repair derived from the inputs. It carries the trailing
# `---` every shipped topic has, so every case below is also the separator case.
topic() { # <open-section body> <suffix> -> path
  local p="$TMP/open$2.md"
  cat > "$p" <<EOF
# Discovery — whether to turn the thing on

dated: 2026-10-04
status: discovery complete, not assessed

## The question, in the asker's own words

> should we turn it on

## 2 · Coverage

**Reached:** the GitHub REST API, and the SemIf source at commit 23cf1f3
**Not reached:** JevBench
**Verified by hand:** the GitHub REST API

## Claims

The GitHub REST API returned 300 pull requests, and the SemIf source was read at commit 23cf1f3. JevBench was not read at all. [E]

Grades are the STANDARDS.md scheme: [V] vendor, never outcome evidence, [S] standard, [P] practitioner, [O] open.

## What could not be established

$1

---

## Where this stops

Here.
EOF
  printf '%s' "$p"
}

# The control first, so a refusal below cannot be the gate refusing everything.
out="$(bash "$GATE" "$(topic '- **Whether JevBench seals its slice. [O]**' ctl)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a built topic listing one open item is within the contract"

# The review's artifact, with the separator the review's own copy had removed.
HOLLOW='The discovery was exhaustive and nothing of consequence remains outstanding.'
out="$(bash "$GATE" "$(topic "$HOLLOW" hollow)" 2>&1)"; rc=$?
assert_status 1 "$rc" "an open section emptied of items and asserting the opposite is refused"
assert_contains "$out" "refuse[silent-empty-open]" \
  "the word \"nothing\" in a sentence does not declare a section empty"

# The same sentence with every one of the three searched words taken out. It has to
# be refused for the SAME reason, because a word is not what decides.
out="$(bash "$GATE" "$(topic 'The discovery was exhaustive and no item of consequence remains outstanding.' flat)" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "the same assertion carrying no searched word is refused the same way"

# A line of prose carrying a grade marker is not an open item.
out="$(bash "$GATE" "$(topic 'Everything in scope was established. [O]' grade)" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "an [O] in prose is not an item, so the section is still silently empty"

# An empty section that DECLARES it, with a reason, is accepted — the repair must
# not be "always refuse an empty section". A phase that genuinely left nothing open
# is a real state and a legitimate one.
DECL='<!-- declared-empty: every question in scope was answered, and the searches that found nothing are recorded under Coverage -->'
out="$(bash "$GATE" "$(topic "$DECL" decl)" 2>&1)"; rc=$?
assert_status 0 "$rc" "an open section that declares itself empty, with a reason, is accepted"
assert_not_contains "$out" "silent-empty-open" "and is not called silently empty"

# A declaration carrying no reason does not exempt anything — the same rule the
# `not-a-claim` and `dead-pointer` declarations are held to.
out="$(bash "$GATE" "$(topic '<!-- declared-empty: -->' noreason)" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "a declaration with no reason does not declare a section empty"

# A declaration inside a FENCED BLOCK declares nothing. Found by attacking this
# check after writing it, and the third time this repository has paid for the same
# class: a fenced example of `rests on: none` donated itself as the real field's
# value, and an example row in a fenced block in DECIDERS.md would have authorized
# everyone it named. An artifact documenting the convention must not thereby
# satisfy it.
out="$(bash "$GATE" "$(topic '```'$'\n''<!-- declared-empty: every question was answered -->'$'\n''```' fenced)" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "a declaration shown inside a fenced block does not declare the section empty"

# An indented line is not a list item — four spaces is a code block in Markdown, so
# a reader does not see an item where the gate counted one. Found by the same
# attack. The leading-whitespace tolerance this removes bought nothing: both shipped
# topics write their items flush left, and a nested item always has a parent that
# counts.
out="$(bash "$GATE" "$(topic '    - nothing was left open [O]' indented)" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "an indented line carrying [O] is not an open item"

# And the declaration has to be IN the section. One in a later section exempts
# nothing: the same scope error that let a heading satisfy Define's outlier check.
p="$(topic "$HOLLOW" elsewhere)"
printf '\n%s\n' "$DECL" >> "$p"
out="$(bash "$GATE" "$p" 2>&1)"
assert_contains "$out" "refuse[silent-empty-open]" \
  "a declaration in a later section does not empty this one"

# The section ends at its own `---`, not at the next heading. This is the third way
# in, and the one that is realistic rather than adversarial: the grade key is a
# required element, both shipped topics write it as a bold line carrying `[O]`, and
# a document that puts it in a footer below its last section donates it to that
# section as an open item. The open section here is hollow and the artifact passed.
#
# Built as its own fixture because the grade key has to move for the case to exist,
# and `topic` above carries it in Claims where both shipped topics have it.
p="$TMP/footer.md"
cat > "$p" <<EOF
# Discovery — whether to turn the thing on

dated: 2026-10-04
status: discovery complete, not assessed

## The question, in the asker's own words

> should we turn it on

## 2 · Coverage

**Reached:** the GitHub REST API, and the SemIf source at commit 23cf1f3
**Not reached:** JevBench
**Verified by hand:** the GitHub REST API

## Claims

The GitHub REST API returned 300 pull requests, and the SemIf source was read at commit 23cf1f3. JevBench was not read at all. [E]

## Where this stops

Here.

## What could not be established

$HOLLOW

---

**Grades** are the STANDARDS.md scheme: [E] empirical, [S] standard, [V] vendor never outcome evidence, [P] practitioner, [O] open.
EOF
out="$(bash "$GATE" "$p" 2>&1)"; rc=$?
assert_status 1 "$rc" "a hollow open section is refused with the grade key in a footer below it"
assert_contains "$out" "refuse[silent-empty-open]" \
  "a line below the section's own --- separator is not one of its items"

# The suite must not be able to pass by pinning a word list back in. This is the
# third time this repository has shipped a word search standing in for a reading —
# after the two-number coverage proxy and the four-phrase dead-pointer match — so
# the shape is refused here, not just the instance.
src="$(cat "$GATE")"
assert_not_contains "$src" "none|nothing|everything was" \
  "the gate no longer decides emptiness by searching prose for a word"

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

# --- the verdict comes from the artifact, not from scratch state ----------------
# The link check used to collect its results in `/tmp/_vd_bad.$$` — the only temp
# path in the repository not from `mktemp` — and then ask `[ -s ]` about the file.
# Two ways that reads the wrong thing, both reproduced before this was written:
#
#   an unwritable FILE already at the path   the redirect fails, the `while` body
#                                            never runs, `[ -s ]` is false, and a
#                                            broken link PASSES. Exit 0.
#   a DIRECTORY already at the path          `[ -s ]` is true of a directory, so
#                                            the gate refuses an artifact with no
#                                            broken link at all, with an empty
#                                            refusal list. Exit 1. `rm -f` cannot
#                                            clear it, so it stays for every run.
#
# A gate whose answer can be changed by something outside the artifact is not a
# gate. Both directions are asserted, because a fix that only closed the false
# pass would leave the false refusal, and the false refusal is the one an operator
# cannot clear.
#
# THE PID IS NOT PREDICTED. `bash -c` gets its own PID, creates the blocker at
# that PID, and then `exec`s the gate — which keeps the PID, so `$$` inside the
# gate is exactly the PID the blocker was made for. No guessing and no retry, so
# this cannot pass by missing. `$BASHPID` would be the direct way to read a
# subshell's PID and arrived in bash 4.0; /bin/bash on macOS is 3.2.
#
# The blocker is created under /tmp because that is where the defect lived. It is
# removed after every run, and the name carries the PID, so two suites running at
# once cannot collide.
BLOCKED_PID_FILE="$TMP/blocked-pid"
blocked_clean() {
  local p
  p="$(cat "$BLOCKED_PID_FILE" 2>/dev/null)"
  case "$p" in ''|*[!0-9]*) return 0 ;; esac
  chmod 700 "/tmp/_vd_bad.$p" 2>/dev/null
  rm -rf "/tmp/_vd_bad.$p"
}
trap 'blocked_clean; rm -rf "$TMP"' EXIT

# gate_blocked <file|dir> <tree> <topic>
gate_blocked() {
  /bin/bash -c '
    echo $$ > "$4"
    case "$1" in
      file) : > "/tmp/_vd_bad.$$"; chmod 000 "/tmp/_vd_bad.$$" ;;
      dir)  mkdir -p "/tmp/_vd_bad.$$" ;;
    esac
    exec /bin/bash "$2" "$3"
  ' blocked "$1" "$GATE" "$2/process/02-discover/$3" "$BLOCKED_PID_FILE" 2>&1
}

# A broken link is still refused with the path taken by a file it cannot write.
t="$(fresh blockedfile)"
printf '\nSee [the problem](./nope-does-not-exist.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate_blocked file "$t" "$NEW")"; rc=$?
blocked_clean
assert_status 1 "$rc" "a broken link is refused even with the old scratch path unwritable"
assert_contains "$out" "refuse[link-unresolved]" "and the refusal is still the link check"
assert_contains "$out" "nope-does-not-exist.md" "and still names the link"

# And a sound artifact is not refused with a directory at the same path. This is
# the false-refusal half: nothing is wrong with this file.
t="$(fresh blockeddir)"
out="$(gate_blocked dir "$t" "$NEW")"; rc=$?
blocked_clean
assert_status 0 "$rc" "a sound artifact is accepted with a directory at the old scratch path"
assert_not_contains "$out" "link-unresolved" "and no refusal is invented from the scratch state"

# Both at once: a directory at the path and a genuinely broken link. The refusal
# has to name the link rather than arrive empty.
t="$(fresh blockeddirbad)"
printf '\nSee [the problem](./nope-does-not-exist.md).\n' >> "$t/process/02-discover/$NEW"
out="$(gate_blocked dir "$t" "$NEW")"; rc=$?
blocked_clean
assert_status 1 "$rc" "a broken link is refused with a directory at the old scratch path"
assert_contains "$out" "nope-does-not-exist.md" "and the refusal names the link, not nothing"

# WHAT IS NOT ASSERTED HERE, and why it is not
#
# The obvious wrong repair is a temp file from `mktemp` with the write left
# unchecked: that closes the predictable-path half and leaves the fail-open. It was
# written as a mutant and this suite stayed green over all three blocked cases,
# because the mutant only fails open when the temp area itself is broken.
#
# The way to break it would be an unwritable TMPDIR, and that does not work here: a
# bare `mktemp` on macOS takes its directory from the system rather than from
# TMPDIR, so `TMPDIR=<unwritable> mktemp` succeeds. A pair of assertions on TMPDIR
# was written, measured not to catch the mutant, and removed rather than shipped —
# it would have read as coverage of exactly the case it does not cover.
#
# So that mutant is recorded as uncaught instead of papered over. What the three
# cases above do pin is the property the defect actually violated: nothing outside
# the artifact can change the verdict.

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
