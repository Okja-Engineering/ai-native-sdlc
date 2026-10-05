#!/usr/bin/env bash
# A document must not say a path does not exist when it does.
#
# An external audit found six contradictions between the documents and the
# repository. Five of them were one shape: five documents and one gate's own
# refusal message told the reader that a phase which had been built for days did
# not exist. The class was created by one commit naming the stage as not built
# where it was referenced, and never revisited when the stage shipped.
#
# This is the narrow mechanical check for that class. It cannot catch a document
# that is subtly out of date; it catches one that names a path and asserts the
# path is absent. That is the form the six took.
#
# Dated artifacts are exempt. A findings file, a cycle, a topic, an option set
# and a decision record are records of a moment, and this repository holds that
# editing a record in place destroys what made it a record. Where one of those
# said a phase did not exist, it was ANNOTATED rather than rewritten, and the
# annotation is what the exemption looks for.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
. "$ROOT/bin/lib-rendering.sh"
. "$TEST_DIR/lib/retired-claim.sh"
cd "$ROOT" || exit 2

# The phrases that assert absence. Narrow on purpose: each is a form actually
# found, not a guess at what someone might write.
ABSENCE='does not exist|is not built|was never built|neither exists|do not exist|is named and not built'

# Paths a document might claim are absent. Enumerated from the tree rather than
# guessed, so a new phase is covered without editing this list.
paths="$(ls -d process/*/ bin 2>/dev/null | sed 's|/$||')"

# And the phase NAMES, from the same listing. Three claims survived the first
# version of this check because they named the phase instead of the path:
# `Define does not exist` carries no `process/03-define` for a path match to find.
# The list is derived, not written out, so a sixth phase is covered by existing.
phase_names="$(ls -d process/*/ 2>/dev/null | sed -e 's|/$||' -e 's|.*/||' -e 's|^[0-9]*-||')"

# The subject of an absence claim sits next to it. This takes the text up to the
# absence phrase and keeps the tail of it, so a line that names a phase and then
# says something ELSE is absent is not read as a claim about the phase.
#
# `README.md`'s note that the **Update** stage "was never built" is the case that
# needs this and it is a true sentence: it lists `Scan` among four old stage names
# forty characters earlier, and `Update` is not a phase this repository has. A
# window keeps that out without an exemption for the line.
#
# The honest limit: a claim with a long qualifier between the phase and the verb
# escapes. Recorded in CONTROLS.md under what is not controlled.
SUBJECT_CHARS=40

# Does this line assert that a phase this repository HAS does not exist? One
# predicate, called from the loop below and from the fixtures, so a fixture proves
# the decision the sweep makes rather than a second copy of it.
#
# Deliberately a predicate over one line and not a rewrite of the loop: the loop's
# exemptions and path matching are being reworked separately, and this has to sit
# beside that rather than around it.
names_a_built_phase() {
  local subj p
  subj="$(printf '%s' "$1" | sed -E "s/(${ABSENCE}).*//" | tr 'A-Z' 'a-z' \
          | tail -c "$((SUBJECT_CHARS + 1))")"
  for p in $phase_names; do
    case "$subj" in *"$p"*) return 0 ;; esac
  done
  return 1
}

# A line is a problem when it asserts absence AND names a path that exists.
# `git grep` is used so untracked scratch files cannot fail the suite.
hits=0
offenders=""
# `tests/` is excluded. A test that proves this detection works has to contain a
# line asserting a built path is absent, so including tests/ makes the check flag
# its own fixture — which is exactly what happened, and only in CI.
#
# It passed locally and failed on both CI legs because `git grep` sees TRACKED
# content: the fixture line was not visible until the file was committed, and the
# local run happened before `git add`. "Verify after the last edit" is not enough
# for a check that reads the index — it has to be "verify after staging".
for line in $(git grep -nIE "$ABSENCE" -- '*.md' '*.sh' ':(exclude).devin/*' ':(exclude)tests/*' 2>/dev/null | cut -d: -f1,2 | sort -u); do
  f="${line%%:*}"; n="${line##*:}"
  text="$(sed -n "${n}p" "$f" 2>/dev/null)"

  # Exempt: an annotation saying the claim is historical, and the dangling-ref
  # sentences which are about a ref that genuinely does not exist.
  case "$text" in
    *Annotated*|*"was referenced"*|*"not on a branch"*|*"never did"*) continue ;;
  esac

  # A line that LINKS a path is referencing it, not asserting it is absent. The
  # first version tripped on a README table row reading "Refuses a decision with
  # ... an option that does not exist" next to a link to the gate — the absence
  # phrase was about a chosen option, not about the path. You cannot link
  # something and claim it does not exist in the same breath, and if you did, the
  # link is the stronger signal.
  case "$text" in
    *'](process/'*|*'](bin/'*) continue ;;
  esac

  for p in $paths; do
    case "$text" in
      *"$p"*)
        if [ -e "$p" ]; then
          hits=$((hits + 1)); offenders="$offenders $f:$n"; break
        fi ;;
    esac
  done

  # The same claim made about the phase by NAME rather than by path, appended
  # after the path check rather than folded into it. A line that trips both is
  # reported once.
  case " $offenders " in *" $f:$n "*) continue ;; esac
  if names_a_built_phase "$text"; then
    hits=$((hits + 1)); offenders="$offenders $f:$n"
  fi
done

assert_eq "" "$offenders" "no document says a path or a phase does not exist when it does"

# --- the check must be able to fail ------------------------------------------
# A check that cannot fail is the vacuous-assertion failure this repository has
# shipped twice. Prove the detection works on a constructed line rather than
# trusting that zero hits means it looked.
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
printf 'The phase process/05-deliver does not exist.\n' > "$TMP/bad.md"
found=no
if grep -qE "$ABSENCE" "$TMP/bad.md" && grep -q 'process/05-deliver' "$TMP/bad.md" && [ -e process/05-deliver ]; then
  found=yes
fi
assert_eq "yes" "$found" "the detection fires on a line asserting a built path is absent"

printf 'The phase process/05-deliver does not exist. [Annotated 2026-10-03: it was built.]\n' > "$TMP/ok.md"
exempt=no
case "$(cat "$TMP/ok.md")" in *Annotated*) exempt=yes ;; esac
assert_eq "yes" "$exempt" "an annotated historical claim is exempt"

# --- and on a phase named instead of a path ----------------------------------
# The three survivors of the first version. Driven over every phase in the tree
# rather than the two the survivors happened to name, so widening `process/`
# widens the check without editing the cases.
for p in $phase_names; do
  cap="$(printf '%s' "$p" | cut -c1 | tr 'a-z' 'A-Z')$(printf '%s' "$p" | cut -c2-)"
  if names_a_built_phase "Nothing above says what it means for us — that is $cap, and $cap does not exist."; then
    fires=yes
  else
    fires=no
  fi
  assert_eq "yes" "$fires" "the detection fires on '$cap does not exist'"
done

# A phase this repository does not have may be called absent, because it is.
# `README.md` does exactly this about the Update stage the first diagram drew, and
# it lists `Scan` on the same line — so the window, not an exemption, is what
# keeps a true sentence out.
if names_a_built_phase 'It drew four stages — Scan, Assess, Propose, Update — and the Update stage was never built.'; then
  fires=yes
else
  fires=no
fi
assert_eq "no" "$fires" "a stage this repository never had may be called absent"

# The subject window is load-bearing, so prove it bounds. A phase named away from
# the claim is a mention, not the subject.
if names_a_built_phase 'Deliver chose option F after weighing six of them, and the risk class the rejected option needed does not exist.'; then
  fires=yes
else
  fires=no
fi
assert_eq "no" "$fires" "a phase named away from the claim is a mention, not the subject"

# --- no document claims the whole chain is in git ----------------------------
# `AGENTS.md` said "All of it in git" about the issue → pull request → merge
# chain. Issue and pull request bodies live in GitHub's database, and a merge
# commit carries only the number and title. An external audit caught it.
#
# This is a narrow guard on the specific overclaim rather than a general
# truth-check, because the unqualified form is the one that misleads an assessor
# reading CONTROLS.md and expecting a clone to hold everything.
# `-i`, not just `-I`. The first version used `-nIE`, where `I` means skip
# binary files and NOT ignore case — so the pattern `all of it in git` missed
# `All of it in git`, the exact sentence this check exists to catch. The mutation
# test passed vacuously until that was found.
#
# THE EXEMPTION IS PER PHRASE, NOT PER LINE.
#
# A line quoting the old claim in order to correct it has to be exempt, because the
# correction necessarily contains the phrase. That was four phrases matched anywhere
# on the line — `claimed|until 2026|this said|used to` — which discarded the whole
# line. Appending
#
#   The chain is claimed to be all of it in git.
#
# to README.md passed, because the line contains the word "claimed". Reproduced
# against the shipped suite: 21 assertions, 0 failed, and run-all green over 13
# suites.
#
# This repository had already fixed exactly this shape one file over.
# bin/validate-standards.sh exempted every pointer on a line carrying any of four
# phrases, so SOURCES.md line 5 — naming the dead branch and the live commit in one
# sentence — exempted both, and replacing the live commit with a dead one was
# accepted. It is now an in-band declaration naming the pointer and carrying a
# reason, and so is this:
#
#   <!-- corrected-overclaim: all of it in git — reason -->
#
# A declaration that does not name the phrase on its line does not exempt it, and
# one carrying nothing beyond the phrase does not either, because then no reason is
# recorded. Same three rules as `dead-pointer` and `not-a-claim`.
OVERCLAIM='all of it in git|everything is in git|entirely in git'

# THE PREDICATE MOVED TO tests/lib/retired-claim.sh. It was already parameterised by
# keyword and pattern here, which was the right shape; what it lacked was the display
# question, in both directions. A declaration written inside an inline code span
# retired a live claim, and a document quoting the retired sentence inside a fence was
# reported for making it. tests/test_cycle.sh held a second, looser copy of the same
# three rules — it did not require the declaration to name the phrase — and that copy
# is gone.
#
# `declared` is kept as a one-line alias so the fixtures below read as they did. They
# pass a single line and carry no non-content, so one text answers both questions.
declared() { retired_claim_declared "$1" "$2" "$3"; }

# The real documents, walked per file so the two projections can be read. `git grep`
# was the enumerator and the file list still comes from the index, so an untracked
# scratch file cannot fail the suite.
overclaim=""
for d in $(git -C "$ROOT" ls-files -- '*.md' ':(exclude)tests/*'); do
  overclaim="$overclaim$(retired_claim_offenders corrected-overclaim "$OVERCLAIM" "$ROOT/$d")"
done
assert_eq "" "$overclaim" "no document claims the whole chain is in git"

# --- and the exemption has to be able to refuse -------------------------------
# Five constructed lines. The second is the exploit the whole-line version let
# through, so it is the one that matters.
declared corrected-overclaim "$OVERCLAIM" 'The whole chain is all of it in git.' \
  && r=exempt || r=flagged
assert_eq "flagged" "$r" "a bare overclaim is flagged"

declared corrected-overclaim "$OVERCLAIM" 'The chain is claimed to be all of it in git.' \
  && r=exempt || r=flagged
assert_eq "flagged" "$r" "the word claimed elsewhere on the line does not exempt it"

declared corrected-overclaim "$OVERCLAIM" 'AGENTS.md said *"All of it in git."* <!-- corrected-overclaim: all of it in git — the line is the correction -->' \
  && r=exempt || r=flagged
assert_eq "exempt" "$r" "a declaration naming the phrase and carrying a reason exempts it"

declared corrected-overclaim "$OVERCLAIM" 'AGENTS.md said *"All of it in git."* <!-- corrected-overclaim: all of it in git -->' \
  && r=exempt || r=flagged
assert_eq "flagged" "$r" "a declaration carrying no reason exempts nothing"

declared corrected-overclaim "$OVERCLAIM" 'AGENTS.md said *"All of it in git."* <!-- corrected-overclaim: everything is in git — wrong phrase -->' \
  && r=exempt || r=flagged
assert_eq "flagged" "$r" "a declaration naming a different phrase exempts nothing"

# A line with no overclaim on it is not flagged, or the loop above would report
# every line of every document.
declared corrected-overclaim "$OVERCLAIM" 'The process chain is readable end to end from a clone.' \
  && r=exempt || r=flagged
assert_eq "exempt" "$r" "a line carrying no overclaim is not flagged"

# And the correction has to still be there, or deleting it would silently pass
# the check above.
assert_contains "$(cat "$ROOT/AGENTS.md")" "Two chains, and only one of them is in git" \
  "AGENTS.md distinguishes the two chains"
assert_contains "$(cat "$ROOT/CONTROLS.md")" "live in GitHub" \
  "CONTROLS.md says what the evidence trail does not include"

# --- every script a document names must exist --------------------------------
# `.devin/roadmap.md` was tracked state from the prototype. Nothing referenced
# it, it claimed the repository had no commits and no tracked files, and its
# "Resume instructions" sent a reader to fifteen scripts that do not exist. It
# was the only file named "roadmap" and the only one with a resume section, so
# someone starting there by filename intuition was lost before they began.
#
# Deleted. This is the check that stops the class returning: a document that
# tells a reader to run something must name something runnable.
missing=""
for s in $(git grep -ohIE '[A-Za-z0-9_./-]+\.sh' -- '*.md' 2>/dev/null \
           | grep -oE '[A-Za-z0-9_./-]+\.sh' | sort -u); do
  case "$s" in
    # A bare filename with no directory is prose, not an instruction — e.g. a
    # sentence naming `run-all.sh` while pointing at `tests/` elsewhere.
    */*) ;;
    *) continue ;;
  esac
  [ -e "$s" ] || missing="$missing $s"
done
assert_eq "" "$missing" "every script path a tracked document names exists"

# And the detection must be able to fail, or zero hits means nothing.
printf 'Run `tests/does-not-exist.sh` to begin.\n' > "$TMP/dead.md"
found=no
for s in $(grep -oE '[A-Za-z0-9_./-]+\.sh' "$TMP/dead.md"); do
  [ -e "$s" ] || found=yes
done
assert_eq "yes" "$found" "the detection fires on a script path that does not exist"

# --- a transcribed git measurement carries the command that produces it -------
# Four tracked files hand-transcribed a tally of git author identities — reading
# `71 / 29 / 7` across three variants, 107 commits — and none of them said how it
# was produced. It had been measured in a working tree holding branches that were
# never pushed. A clone measures two variants and 95 commits on `main`, so no
# reader of the public repository could reproduce any of the four numbers, and
# nothing noticed for as long as nobody re-ran it by hand.
#
# The invariant: a transcribed git measurement is immediately preceded by the
# command that produces it. Whether the number is right is the next section, which
# runs that command. This one is only that a reader has a way to find out.
#
# A tally line is a count, then a name, then a bracketed address: the output shape
# of `git log --format='%an <%ae>' | sort | uniq -c`. A markdown table row is not
# one, because it starts with `|`.
TALLY='^[[:space:]]*#?[[:space:]]*[0-9]+[[:space:]]+[^|]*<[^>]*@[^>]*>'
# The command has to ask git for an author identity. `%ae` is the part that cannot
# be left out, whatever else the pipeline does.
COMMAND='git log.*%ae'
# Within the ten lines above, not anywhere in the file. File scope was the first
# version and it was too weak to catch the worst case: `bin/validate-authorship.sh`
# carried the wrong tally in its header comment and a correct `git log --format`
# eighty lines further down, inside the gate's own logic, so a file-wide search
# declared it sourced. The number and the command have to be in the same
# transcript for a reader to connect them.
WINDOW=10

# One implementation, used for the real sweep and for the fixtures below. A
# fixture that re-implements the check proves the re-implementation works, which
# is the vacuous assertion this repository has shipped before.
unsourced_tallies() {
  for hit in $(grep -nE "$TALLY" "$@" /dev/null 2>/dev/null | cut -d: -f1,2 | sort -u); do
    f="${hit%%:*}"; n="${hit##*:}"
    from=$((n - WINDOW)); [ "$from" -lt 1 ] && from=1
    sed -n "${from},${n}p" "$f" | grep -qE "$COMMAND" || printf '%s ' "$hit"
  done
}

# `git grep` to enumerate, because untracked scratch files must not fail the
# suite — and because a check that reads the index has to be verified after
# staging, not after the last edit.
# shellcheck disable=SC2046
unsourced="$(unsourced_tallies $(git grep -lIE "$TALLY" -- '*.md' '*.sh' ':(exclude)tests/*' 2>/dev/null))"
assert_eq "" "${unsourced% }" "a transcribed git author tally is preceded by the command that produces it"

# The detection has to fire, or an empty result means nothing was looked at.
printf '```\n  71 somebody <shared@example.invalid>\n```\n' > "$TMP/tally-bare.md"
assert_eq "$TMP/tally-bare.md:2 " "$(unsourced_tallies "$TMP/tally-bare.md")" \
  "the detection fires on a transcribed tally with no command"

# And it has to stop firing once the command is there, or it is refusing the
# measurement rather than the missing method.
printf '```\n$ git log main --format=%%an <%%ae>\n  71 somebody <shared@example.invalid>\n```\n' \
  > "$TMP/tally-sourced.md"
assert_eq "" "$(unsourced_tallies "$TMP/tally-sourced.md")" \
  "a transcribed tally that names its command passes"

# The window is load-bearing, so prove it bounds. A command far enough above the
# tally is not in the same transcript, and must not exempt it.
{ printf '$ git log main --format=%%an <%%ae>\n'
  i=0; while [ "$i" -lt "$WINDOW" ]; do printf 'filler\n'; i=$((i + 1)); done
  printf '  71 somebody <shared@example.invalid>\n'
} > "$TMP/tally-far.md"
assert_eq "$TMP/tally-far.md:$((WINDOW + 2)) " "$(unsourced_tallies "$TMP/tally-far.md")" \
  "a command outside the window does not exempt the tally"

# The tally pattern must not swallow a markdown table row, or every table of
# people would be demanding a git command.
printf '| Name | git identity |\n| Ada | `Ada <ada@example.invalid>` |\n' > "$TMP/table.md"
assert_eq "" "$(grep -E "$TALLY" "$TMP/table.md" || true)" \
  "a markdown table row naming an address is not read as a tally"

# --- and it agrees with the history at the ref its command names ---------------
# The section above establishes that a reader has a way to find out whether a
# transcribed tally is right. It does not establish that it IS right, and the
# difference cost exactly what it sounds like: `DECIDERS.md` carried `63 / 32` and
# 95 commits under a correct command, and a clone at the same time printed
# `89 / 74 / 43` and 206. The command was sitting right above the numbers. Nobody
# ran it.
#
# The invariant: a transcribed tally equals what git prints at the ref its own
# command names. No count is pinned here — the expected value is read out of the
# history on every run — so this cannot go stale, and it cannot be satisfied by
# editing one literal into agreement with another.
#
# This is also what forces a transcription to name a commit rather than a branch.
# `main` moves, so a tally labelled `main` stops agreeing the next time anybody
# commits and this goes red; a tally labelled with the commit it was measured at
# agrees forever. The document ends up reproducible because the reproducible form
# is the only one that passes.
#
# A ref that does not resolve in this checkout is reported, not skipped. A
# measurement nobody here can reproduce is the defect rather than an excuse to
# look away, and `bin/validate-standards.sh` already takes that line — it exits 2
# in a depth-1 clone instead of reporting the documents clean against history it
# cannot see. Both CI legs check out full history for the same reason.

# the ref a `git log` command names, or empty when it names only options
tally_ref() {
  printf '%s' "$1" \
    | sed -E -e 's/.*git log[[:space:]]+//' -e 's/[[:space:]].*//' -e 's/^-.*//'
}

# a transcribed tally line reduced to what git would print for it. The trailing
# annotation `<- agent-driven commits` is a reader's note, not part of the
# measurement, so it is dropped before comparing.
tally_entry() {
  printf '%s' "$1" \
    | sed -E -e 's/^[[:space:]]*#?[[:space:]]*//' \
             -e 's/^([0-9]+)[[:space:]]+([^<]*<[^>]*>).*/\1 \2/'
}

# One implementation, used for the real documents and for the fixtures below.
stale_tallies() { # <files...> -> `file:line` for each tally that disagrees
  local hit f n from cmd ref want got
  for hit in $(grep -nE "$TALLY" "$@" /dev/null 2>/dev/null | cut -d: -f1,2 | sort -u); do
    f="${hit%%:*}"; n="${hit##*:}"
    from=$((n - WINDOW)); [ "$from" -lt 1 ] && from=1
    cmd="$(sed -n "${from},${n}p" "$f" | grep -E "$COMMAND" | tail -1)"
    # A tally with no command above it is the section above's finding, not this
    # one's. Reporting it twice would say one defect is two.
    [ -n "$cmd" ] || continue
    ref="$(tally_ref "$cmd")"
    if [ -z "$ref" ] || ! git rev-parse --verify --quiet "$ref^{commit}" >/dev/null 2>&1; then
      printf '%s(ref:%s) ' "$hit" "${ref:-none}"
      continue
    fi
    # A failed `git log` must not read as an empty tally, for the same reason
    # `bin/validate-authorship.sh` refuses to run when it cannot read the history.
    if ! want="$(git log "$ref" --format='%an <%ae>' 2>/dev/null)"; then
      printf '%s(git-log-failed-at:%s) ' "$hit" "$ref"
      continue
    fi
    want="$(printf '%s\n' "$want" | sort | uniq -c | sed -E 's/^[[:space:]]*//')"
    got="$(tally_entry "$(sed -n "${n}p" "$f")")"
    printf '%s\n' "$want" | grep -qxF "$got" || printf '%s(doc:%s) ' "$hit" "$got"
  done
}

# shellcheck disable=SC2046
stale="$(stale_tallies $(git grep -lIE "$TALLY" -- '*.md' '*.sh' ':(exclude)tests/*' 2>/dev/null))"
assert_eq "" "${stale% }" \
  "a transcribed git author tally agrees with the history at the ref it names"

# The fixtures are built out of this repository's own history rather than from
# numbers typed here, so they cannot drift into agreement the way the documents
# drifted out of it.
real_top="$(git log HEAD --format='%an <%ae>' | sort | uniq -c | sort -rn \
            | sed -E 's/^[[:space:]]*//' | head -1)"

tally_fixture() { # <file> <ref> <tally line>
  { printf '```\n$ git log %s --format=%%an <%%ae> | sort | uniq -c\n' "$2"
    printf '  %s\n```\n' "$3"
  } > "$1"
}

tally_fixture "$TMP/tally-true.md" HEAD "$real_top"
assert_eq "" "$(stale_tallies "$TMP/tally-true.md")" \
  "a tally that agrees with the history at the ref it names passes"

tally_fixture "$TMP/tally-count.md" HEAD "$(printf '%s' "$real_top" | awk '{ $1 = $1 + 1; print }')"
case "$(stale_tallies "$TMP/tally-count.md")" in
  "$TMP/tally-count.md:3"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "the detection fires on a tally whose count disagrees with the history"

# A right count against the wrong identity is the same defect, so the comparison
# is over the whole line rather than the number alone.
tally_fixture "$TMP/tally-whom.md" HEAD \
  "$(printf '%s' "$real_top" | sed -E 's/<[^>]*>/<nobody@example.invalid>/')"
case "$(stale_tallies "$TMP/tally-whom.md")" in
  "$TMP/tally-whom.md:3"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "the detection fires on a tally attributed to the wrong identity"

# A ref nobody can resolve is reported rather than skipped, or an unreproducible
# measurement would be the one shape that escapes.
tally_fixture "$TMP/tally-deadref.md" no-such-ref-here '7 somebody <shared@example.invalid>'
case "$(stale_tallies "$TMP/tally-deadref.md")" in
  *"(ref:no-such-ref-here)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a tally sourced to a ref that does not resolve is reported"

# And a command that names no ref at all cannot be reproduced either: `git log`
# with only options measures whatever the reader happens to have checked out.
printf '```\n$ git log --format=%%an <%%ae> | sort | uniq -c\n  7 somebody <shared@example.invalid>\n```\n' \
  > "$TMP/tally-noref.md"
case "$(stale_tallies "$TMP/tally-noref.md")" in
  *"(ref:none)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a tally whose command names no ref is reported"

# --- a transcribed signature check agrees with git ----------------------------
# CTRL-1's start date rests on nothing in the history being signed: proof that a
# person recorded a decision begins with the next decision, by commit signature,
# and the two decisions that already exist are recorded as predating that. The
# claim underneath it is a present-tense statement about `git log`, so it is held
# to the same rule as the author tally above — the document transcribes the command
# and its output, and this runs the command.
#
# `N` is not pinned. The expected value is whatever git reports, so the day a
# commit is signed this goes red and the sentences resting on the claim have to be
# revisited. That is the point of the check rather than a side effect of it: the
# start date stops being a start date once something is signed.
#
# A mention of the command in prose is not a transcription. The reasoning is the
# same as the linked-path exemption at the top of this file — you cannot both quote
# a command inline and be transcribing its output on the next line — so only an
# occurrence opening a fenced block is read as one.
#
# WHAT IS COMPARED, AND WHY IT IS PER COMMIT
#
# The transcript's rows are read and each one is checked against git: a row is a
# revision and the status the document says it has. Not the whole command's output,
# because `%G?` over a range is not reproducible — it is a fact about the reader's
# keyring, not about the objects. 74 of the commits here carry GitHub's PGP
# signature on merges it performed, and `%G?` for those reads `E` where the key is
# missing and `N` on a machine with no `gpg` at all. That is how a claim that
# nothing in this repository is signed came to be written down: it was measured
# where `gpg` was not installed, and the first version of this check went green
# locally and red on both CI legs for exactly that reason.
#
# A row naming an unsigned commit is reproducible everywhere, because a commit with
# no signature header reads `N` with or without `gpg`. So the document transcribes
# the commits the control is about, and this checks those.
SIG_COMMAND="--format='%h %G?'"

# Does this object carry a signature header? A fact about the object, readable with
# no keyring and no `gpg` binary, unlike the status. Only the commit headers are
# read, so a message line starting with the word cannot be mistaken for one.
carries_signature() { # <rev> -> 0 when it does
  git cat-file -p "$1" 2>/dev/null \
    | awk '/^$/ { exit } /^gpgsig/ { found = 1 } END { exit !found }'
}

sig_transcripts() { # <files...> -> `file:line(...)` for each row git disagrees with
  local hit f n prev row rev said want rows
  for hit in $(grep -nF -- "$SIG_COMMAND" "$@" /dev/null 2>/dev/null | cut -d: -f1,2 | sort -u); do
    f="${hit%%:*}"; n="${hit##*:}"
    [ "$n" -gt 1 ] || continue
    prev="$(sed -n "$((n - 1))p" "$f")"
    case "$prev" in '```'*) ;; *) continue ;; esac
    rows=0
    while IFS= read -r row; do
      [ -n "$row" ] || continue
      rev="${row%% *}"; said="${row##* }"
      rows=$((rows + 1))
      if ! git cat-file -e "$rev^{commit}" 2>/dev/null; then
        printf '%s(unreadable:%s) ' "$hit" "$rev"
        continue
      fi
      # A row naming a commit that DOES carry a signature is refused outright,
      # whatever status it claims. That status is a fact about the reader's keyring,
      # so the row would be true on one machine and false on the next — which is the
      # defect this check was built after walking into. Transcribe the commits the
      # control is about; they have no signature and read `N` everywhere.
      if carries_signature "$rev"; then
        printf '%s(%s carries a signature, so its status depends on the reader) ' "$hit" "$rev"
        continue
      fi
      # A FAILED `git log` MUST NOT READ AS A STATUS. `bin/validate-authorship.sh`
      # carries the same rule after a mistyped ref turned that gate off and reported
      # the thing it exists to refuse.
      if ! want="$(git log -1 --format='%G?' "$rev" 2>/dev/null)"; then
        printf '%s(unreadable:%s) ' "$hit" "$rev"
        continue
      fi
      # Both sides in the message. A failure naming only the transcript makes the
      # reader rerun the command by hand to find out what it disagreed with.
      [ "$said" = "$want" ] || printf '%s(%s doc:%s|git:%s) ' "$hit" "$rev" "$said" "$want"
    done <<EOF
$(sed -n "$((n + 1)),\$p" "$f" | awk '/^```/ { exit } { print }')
EOF
    # A fenced block with no rows in it is a claim with nothing under it.
    [ "$rows" -gt 0 ] || printf '%s(no-rows) ' "$hit"
  done
}

# shellcheck disable=SC2046
sigfiles="$(git grep -lF -- "$SIG_COMMAND" -- '*.md' ':(exclude)tests/*' 2>/dev/null)"
sigbad="$(sig_transcripts $sigfiles)"
assert_eq "" "${sigbad% }" "a transcribed signature check agrees with what git reports"

# And a document actually transcribes it, or the sweep above walked nothing. The
# claim CTRL-1's start date rests on has to be somewhere a reader can check.
nsig=0
for f in $sigfiles; do
  nsig=$((nsig + $(grep -cF -- "$SIG_COMMAND" "$f" || true)))
done
[ "$nsig" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "a document carries the signature check CTRL-1 rests on (found $nsig)"

# The detection has to fire. The expected transcript is built from what git reports
# for this checkout, never from `N` typed here, so it cannot drift into agreement.
# The fixtures name a commit found in this history rather than `HEAD`. `HEAD` on a
# pull-request checkout is the merge commit the forge made, which the forge signs —
# so fixtures built on it were refused as signed on both CI legs while passing
# locally. A fixture pinned to a property of the current checkout is the same defect
# as a document pinned to the reader's keyring, one layer down.
sig_unsigned=""
for c in $(git rev-list -n 300 HEAD); do
  if ! carries_signature "$c"; then sig_unsigned="$c"; break; fi
done
[ -n "$sig_unsigned" ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the history holds an unsigned commit to build fixtures on"
sig_status="$(git log -1 --format='%G?' "$sig_unsigned" 2>/dev/null)"
assert_eq "N" "$sig_status" "an unsigned commit reports N, on any machine"

sig_fixture() { # <file> <row...>
  local out="$1"; shift
  { printf '```\n$ git log --no-walk %s %s\n' "$SIG_COMMAND" "$sig_unsigned"
    printf '%s\n' "$@"
    printf '```\n'
  } > "$out"
}

sig_fixture "$TMP/sig-true.md" "$sig_unsigned $sig_status"
assert_eq "" "$(sig_transcripts "$TMP/sig-true.md")" \
  "a transcript that agrees with git on every row passes"

sig_fixture "$TMP/sig-wrong.md" "$sig_unsigned G"
case "$(sig_transcripts "$TMP/sig-wrong.md")" in
  "$TMP/sig-wrong.md:2($sig_unsigned doc:G|git:$sig_status)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "the detection fires on a row git does not agree with"

# One true row must not cover a false one, or a transcript could be padded into
# passing.
sig_fixture "$TMP/sig-mixed.md" "$sig_unsigned $sig_status" "$sig_unsigned G"
case "$(sig_transcripts "$TMP/sig-mixed.md")" in
  *"($sig_unsigned doc:G|git:$sig_status)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a true row does not cover a false one in the same transcript"

sig_fixture "$TMP/sig-deadrev.md" "no-such-rev-here N"
case "$(sig_transcripts "$TMP/sig-deadrev.md")" in
  *"(unreadable:no-such-rev-here)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a row naming a revision git cannot read is reported, not skipped"

# And a row naming a commit that carries a signature is refused however it reads.
# Found from the history rather than named here: the web merges carry GitHub's PGP
# key, and a status for one of them is true on a machine with that key and false on
# a machine without it.
sig_signed=""
for c in $(git rev-list -n 300 HEAD); do
  if carries_signature "$c"; then sig_signed="$c"; break; fi
done
[ -n "$sig_signed" ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the history holds a signed commit to test the refusal against"
sig_fixture "$TMP/sig-signed.md" "$sig_signed N"
case "$(sig_transcripts "$TMP/sig-signed.md")" in
  *"carries a signature"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a row naming a signed commit is refused whatever status it claims"

# An empty fence is a claim with nothing under it.
printf '```\n$ git log --no-walk %s HEAD\n```\n' "$SIG_COMMAND" > "$TMP/sig-empty.md"
case "$(sig_transcripts "$TMP/sig-empty.md")" in
  *"(no-rows)"*) fires=yes ;; *) fires=no ;;
esac
assert_eq "yes" "$fires" "a transcript with no rows is reported"

# A mention in prose is not a transcript, or every sentence naming the command
# would be demanding that the next line be its output.
printf 'Run `git log --no-walk %s 59b7cd2` to check it yourself.\nThe start date is in CTRL-1.\n' \
  "$SIG_COMMAND" > "$TMP/sig-mention.md"
assert_eq "" "$(sig_transcripts "$TMP/sig-mention.md")" \
  "a command mentioned in prose is not read as a transcript"

# --- a present-tense claim about `git log` agrees with what the gate prints -----
# Three documents said, in the present tense, that every commit on `main` was
# authored under one address, and named `bin/validate-authorship.sh` in the same
# breath as the way to check. A distinct agent identity was configured on
# 2026-10-03 and all three sentences stayed. The gate had been printing the
# contradiction on every run since, and the documents telling a reader to run it
# were the documents it contradicted.
#
# The invariant: a document may assert the live author-identity state of the
# history only while the gate agrees. The expected answer is read out of the
# gate's own output rather than re-derived from `git log` here, because a second
# derivation is a second thing to go stale — and because the claim being checked
# is literally what the gate prints.
#
# No count is pinned. Both predicates are recomputed on every run, so on the day
# the history does come back to one address that sentence becomes legal again
# without this check being touched.
#
# A correction has to quote the sentence it corrects, so it needs the same in-band
# declaration the overclaim above uses, with the same three rules: name the phrase,
# carry a reason, and be a declaration rather than a word somewhere on the line.
#
#   <!-- corrected-claim: under one address — reason -->
#
# The honest limit: this reads a frame, not a sentence. `under one address` and the
# near-forms of it are covered because they are tied to the frame; a document that
# says the same thing some other way escapes, and widening the list further would
# be chasing phrasings — which `AGENTS.md` already says is not how to fix a
# denylist. It is narrow the same way the absence phrases at the top of this file
# are narrow. What does not escape is the transcribed tally, which is checked
# against git exactly, so the numbers a reader would act on are covered by the
# section above whatever the prose does.
#
# Attacked before shipping: a fresh one-address sentence appended to `README.md` is
# caught, a fresh tally with a correct command and wrong numbers appended to
# `intent.md` is caught, and `the whole history sits on a single email` was not
# until the frame was widened to the one below.
GATE='bin/validate-authorship.sh'
# The gate refuses today — that refusal is its finding, not a failure to run — so a
# non-zero exit here is expected and the output is what is wanted.
gate_out="$(/bin/bash "$GATE" 2>/dev/null || true)"

# `    89 imagineux <imagineux@gmail.com>` -> the address
gate_addresses="$(printf '%s\n' "$gate_out" \
  | sed -n -E 's/^[[:space:]]+[0-9]+[[:space:]]+[^<]*<([^>]*)>.*/\1/p' \
  | sort -u | grep -c . || true)"
# `  declared identity Name <addr> authors N commit(s) on main`
gate_declared="$(printf '%s\n' "$gate_out" | grep -c 'declared identity' || true)"
gate_declared_idle=yes
printf '%s\n' "$gate_out" | grep -qE 'declared identity .* authors [1-9]' && gate_declared_idle=no

# The gate's output is the denominator for everything below, so an empty one is a
# failure rather than a quiet pass over nothing.
[ "$gate_addresses" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the gate prints the author addresses in the history (found $gate_addresses)"
[ "$gate_declared" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the gate prints what each declared identity authors (found $gate_declared)"

# The history sits on one address. A frame — a preposition, a singular quantity, a
# noun — rather than the three sentences verbatim, so a paraphrase of the claim
# does not walk past it. `One address per party` in DECIDERS.md is a plan for the
# future rather than a claim about the history, and the preposition is what keeps
# it out.
#
# `[ *_]+` rather than a space between the words, because markdown emphasis sits
# inside a sentence. `authors **no commits** at all` in this repository's own
# DECIDERS.md is the live case: a plain-space pattern reads it as `authors **no`
# and walks past the claim.
ONE_ADDRESS='(under|on)[ *_]+(one|a[ *_]+single)[ *_]+(address|e-?mail)'
# No declared decider identity has authored anything.
IDLE_IDENTITY='authors[ *_]+(nothing|no[ *_]+commits)'

claim_hits() { # <pattern> [files...] -> file:line:text
  local pat="$1"; shift
  if [ "$#" -gt 0 ]; then
    grep -niIE "$pat" "$@" /dev/null 2>/dev/null || true
  else
    # `git grep`, so untracked scratch files cannot fail the suite — and so this
    # has to be verified after staging rather than after the last edit.
    git grep -niIE "$pat" -- '*.md' ':(exclude)tests/*' 2>/dev/null || true
  fi
}

# false_claims <keyword> <pattern> <the claim is false: yes|no> [files...]
#   -> `file:line` for every undeclared line carrying a claim that is false
#
# The same reading as the overclaim sweep above: the CLAIM has to be on a line a reader
# sees, and the DECLARATION has to be outside an inline code span. Without that, a
# document quoting the retired sentence inside a fence was reported for making it, and
# a document illustrating the declaration retired a claim that is still false.
false_claims() {
  local kw="$1" pat="$2" is_false="$3" out="" d
  shift 3
  [ "$is_false" = yes ] || return 0
  if [ "$#" -gt 0 ]; then
    out="$(retired_claim_offenders "$kw" "$pat" "$@")"
  else
    for d in $(git -C "$ROOT" ls-files -- '*.md' ':(exclude)tests/*'); do
      out="$out$(retired_claim_offenders "$kw" "$pat" "$ROOT/$d")"
    done
  fi
  printf '%s' "${out# }"
}

[ "$gate_addresses" -gt 1 ] && one_address_false=yes || one_address_false=no
assert_eq "" "$(false_claims corrected-claim "$ONE_ADDRESS" "$one_address_false")" \
  "no document says the history is under one address while the gate prints more"

[ "$gate_declared_idle" = no ] && idle_false=yes || idle_false=no
assert_eq "" "$(false_claims corrected-claim "$IDLE_IDENTITY" "$idle_false")" \
  "no document says a declared identity authors nothing while the gate prints commits for it"

# --- and the detection has to be able to fire ---------------------------------
# Driven through the same sweep over a fixture file, not through a second copy of
# the predicate, so these prove the decision the sweep makes.
printf 'Every commit on `main` is authored under one address.\n' > "$TMP/claim-bare.md"
assert_eq "$TMP/claim-bare.md:1" \
  "$(false_claims corrected-claim "$ONE_ADDRESS" yes "$TMP/claim-bare.md")" \
  "the detection fires on an undeclared one-address claim"

printf 'This said *"authored under one address"* until 2026-10-04. <!-- corrected-claim: under one address — the line is the correction, so it quotes what it corrects -->\n' \
  > "$TMP/claim-declared.md"
assert_eq "" "$(false_claims corrected-claim "$ONE_ADDRESS" yes "$TMP/claim-declared.md")" \
  "a declaration naming the phrase and carrying a reason exempts it"

printf 'This said *"authored under one address"* until 2026-10-04. <!-- corrected-claim: under one address -->\n' \
  > "$TMP/claim-noreason.md"
assert_eq "$TMP/claim-noreason.md:1" \
  "$(false_claims corrected-claim "$ONE_ADDRESS" yes "$TMP/claim-noreason.md")" \
  "a declaration carrying no reason exempts nothing"

printf 'This said *"authored under one address"* once. <!-- corrected-claim: all of it in git — wrong phrase -->\n' \
  > "$TMP/claim-wrongphrase.md"
assert_eq "$TMP/claim-wrongphrase.md:1" \
  "$(false_claims corrected-claim "$ONE_ADDRESS" yes "$TMP/claim-wrongphrase.md")" \
  "a declaration naming a different phrase exempts nothing"

# A whole-line word exemption is the exploit the overclaim check shipped with, and
# it must not come back through a second copy of the rule.
printf 'The corrected claim said every commit is authored under one address.\n' \
  > "$TMP/claim-word.md"
assert_eq "$TMP/claim-word.md:1" \
  "$(false_claims corrected-claim "$ONE_ADDRESS" yes "$TMP/claim-word.md")" \
  "the words corrected and claim elsewhere on the line do not exempt it"

# And while the gate agrees with the sentence, the sentence is not flagged — or
# this would be refusing a document for describing the state it is in.
assert_eq "" "$(false_claims corrected-claim "$ONE_ADDRESS" no "$TMP/claim-bare.md")" \
  "the claim is not flagged while the gate agrees with it"

# The idle-identity half is true today, so a fixture is the only thing that can
# show it is able to fail at all.
printf 'The identity `DECIDERS.md` declares authors nothing at all.\n' > "$TMP/claim-idle.md"
assert_eq "$TMP/claim-idle.md:1" \
  "$(false_claims corrected-claim "$IDLE_IDENTITY" yes "$TMP/claim-idle.md")" \
  "the detection fires on an undeclared idle-identity claim"

# --- a document a gate cites as authority does not declare itself unaccepted ---
# A gate that refuses names the document whose rule it is enforcing, so a reader
# asking what authorized the refusal is sent there. If that document's own status
# line says nobody accepted it, the refusal rests on nothing and the reader is
# told so by the document itself. This was `CONTROLS.md` item 12 until the owner
# accepted `intent.md`, and that item named this as the check that closes it.
#
# Scoped to the documents the gates actually name. Every other file in the
# repository is free to be a draft; what a gate points at is not.
gate_scripts="$(ls bin/validate-*.sh process/*/validate-*.sh 2>/dev/null)"

# The documents those gates name, resolved to real paths. A gate writes a
# document three ways — repo-relative, relative to itself, or through a variable
# — so each token is tried as a path from the root and as one from the gate's own
# directory. A variable prefix such as `$ROOT/` or `$SCRIPT_DIR/` survives the
# token pattern as an upper-case first component and is not part of the path.
#
# `\n` in a refusal message is glued to the filename after it, which is how
# `bin/validate-claims.sh` names its authority: `printf '\nintent.md: ...'`. The
# escape is separated before tokens are read, or the one citation this check
# exists for reads as `nintent.md` and resolves to nothing.
#
# A token that resolves to no file is dropped rather than reported. Whether every
# path a gate mentions exists is a different check and the suite already has it.
gate_documents() {
  local g gdir t p
  for g in $gate_scripts; do
    gdir="$(dirname "$g")"
    for t in $(sed 's/\\n/ /g' "$g" \
               | grep -oE '[A-Za-z0-9_./-]+\.md' \
               | sed -E 's|^[A-Z][A-Z_]*/||' | sort -u); do
      for p in "$t" "$gdir/$t"; do
        [ -f "$p" ] && { printf '%s\n' "$p"; break; }
      done
    done
  done | sort -u
}

# The forms that declare a document unaccepted. Narrow on purpose, like the
# absence phrases above: a status line is a short declaration, not free prose.
UNACCEPTED='unaccepted|not accepted|nobody accepted|awaiting acceptance'

# One predicate, used for the sweep and for the fixtures, so a fixture proves the
# decision the sweep makes rather than a second copy of it.
#
# A quoted span is dropped before matching. Quoting a superseded status in order
# to retire it is not declaring it, and `spec.md` does exactly that: its status
# line carries *"draft, unaccepted. Nothing downstream of this is authorized."*
# and then says that stopped being true. Same shape as the Annotated exemption.
#
# Only the status line is read. A document that discusses acceptance in its body
# is describing something; the status line is where it declares its own state.
declares_itself_unaccepted() { # <document> -> 0 when it does
  grep -m1 -E '^\*\*Status:\*\*' "$1" 2>/dev/null \
    | sed 's/"[^"]*"//g' | grep -qiE "$UNACCEPTED"
}

unaccepted_authorities=""
for d in $(gate_documents); do
  declares_itself_unaccepted "$d" && unaccepted_authorities="$unaccepted_authorities $d"
done
assert_eq "" "${unaccepted_authorities# }" \
  "no document a gate cites as authority declares itself unaccepted"

# --- the check must be able to fail ------------------------------------------
printf '# D\n\n**Status:** draft, unaccepted. Nothing downstream is authorized.\n' \
  > "$TMP/unaccepted.md"
declares_itself_unaccepted "$TMP/unaccepted.md" && fires=yes || fires=no
assert_eq "yes" "$fires" "the detection fires on a status line declaring itself unaccepted"

printf '# D\n\n**Status:** accepted 2026-10-03 by Someone Named.\n' > "$TMP/accepted.md"
declares_itself_unaccepted "$TMP/accepted.md" && fires=yes || fires=no
assert_eq "no" "$fires" "an accepted status line passes"

# The quoting exemption is load-bearing, so prove it bounds in both directions.
printf '# D\n\n**Status:** this said "draft, unaccepted" once. That stopped being true.\n' \
  > "$TMP/quoted.md"
declares_itself_unaccepted "$TMP/quoted.md" && fires=yes || fires=no
assert_eq "no" "$fires" "a status line quoting a superseded declaration is not making one"

printf '# D\n\n**Status:** "derived from one artifact", and unaccepted.\n' \
  > "$TMP/quoted-and-declared.md"
declares_itself_unaccepted "$TMP/quoted-and-declared.md" && fires=yes || fires=no
assert_eq "yes" "$fires" "a quote elsewhere on the line does not exempt a declaration"

# --- and the enumeration is not empty ----------------------------------------
# If no document resolved, the sweep above would pass without looking at one.
nd="$(gate_documents | grep -c .)"
[ "$nd" -ge 5 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the gates resolve to documents to check (found $nd)"

# --- the paths list is not empty ---------------------------------------------
# If the enumeration returned nothing the loop above would pass everything.
np="$(printf '%s\n' "$paths" | grep -c .)"
[ "$np" -ge 5 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the path enumeration found the phases (found $np)"

# --- a transcribed `list-refusals` run agrees with what the command prints -----
# `CONTROLS.md` item 16 is the one section a reader is invited to verify by running,
# and its transcript had drifted: it showed `bin/next.sh:149:?` where the command
# prints `bin/next.sh:163:?`. Line 149 is `wrap_ids "$5"`; 163 is the `refuse` call
# the item is about. An auditor found it, which is the wrong way round — the same
# shape as a transcribed git tally nobody re-ran, and this suite already holds that
# one.
#
# So the invariant is the same here: a transcript equals what its own command prints.
# No output is pinned in this file; the expected value is produced by running the
# command on every run, so this cannot go stale and cannot be satisfied by editing
# one literal into agreement with another.
#
# ONLY `bash bin/list-refusals.sh` IS RUN. A test that executed whatever a document
# put after a `$` would be a document deciding what the suite does, so the one
# command this reads is a read-only enumerator over tracked files. Widening that is
# its own change.
TABX="$(printf '\t')"

# refusal_transcript_rows <files...> -> file, line, command, expected (tab separated,
# expected lines joined by `~`)
refusal_transcript_rows() {
  awk -v T="$TABX" '
    function flush() { if (have) { printf "%s%s%s%s%s%s%s\n", FILENAME, T, ln, T, cmd, T, ex; have = 0 } }
    FNR == 1 { fence = 0; have = 0 }
    /^[ \t]*```/ { flush(); fence = !fence; next }
    !fence { next }
    /^\$ / {
      flush()
      c = substr($0, 3)
      # A continued command is one command. deliver-contract.md writes one across
      # two lines, and reading only the first would run a different thing.
      while (c ~ /\\[ \t]*$/) {
        sub(/\\[ \t]*$/, "", c)
        if ((getline nxt) <= 0) break
        sub(/^[ \t]+/, "", nxt); c = c nxt
      }
      if (c ~ /^bash bin\/list-refusals\.sh/) { have = 1; ln = FNR; cmd = c; ex = "" }
      next
    }
    have { ex = ex (ex == "" ? "" : "~") $0 }
    END { flush() }
  ' "$@"
}

# trim each `~`-joined line and drop empties, so a transcript is compared on its
# content rather than on how the document indents it
norm() { printf '%s' "$1" | tr '~' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | grep -v '^$' | tr '\n' '~' | sed 's/~$//'; }

# refusal_transcripts <files...> -> one line per transcript the command disagrees with
refusal_transcripts() {
  local f ln cmd ex got want
  refusal_transcript_rows "$@" | while IFS="$TABX" read -r f ln cmd ex; do
    [ -n "${cmd:-}" ] || continue
    got="$(norm "$(bash -c "$cmd" 2>&1 | tr '\n' '~')")"
    want="$(norm "$ex")"
    [ "$got" = "$want" ] && continue
    printf '%s:%s(%s printed "%s", the document says "%s")\n' "$f" "$ln" "$cmd" "$got" "$want"
  done
}

transcript_files="$(git ls-files -- '*.md' 2>/dev/null)"
ntr="$(refusal_transcript_rows $transcript_files | grep -c .)"
[ "${ntr:-0}" -ge 2 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the documents carry list-refusals transcripts to check (found ${ntr:-0})"

assert_eq "" "$(refusal_transcripts $transcript_files)" \
  "every transcribed list-refusals run prints what its document says it prints"

# And the detection has to be able to fire, or the assertion above is a check that
# cannot fail. Same shape as the git-tally fixtures: a true transcript passes and a
# wrong one is reported.
mkdir -p "$TMP"
{
  printf 'A document showing what the lister prints.\n\n'
  printf '```\n$ bash bin/list-refusals.sh bin/next.sh\n'
  bash bin/list-refusals.sh bin/next.sh
  printf '```\n'
} > "$TMP/tr-true.md"
assert_eq "" "$(refusal_transcripts "$TMP/tr-true.md")" \
  "a transcript that agrees with the command passes"

sed 's/:[0-9][0-9]*:?/:149:?/' "$TMP/tr-true.md" > "$TMP/tr-drifted.md"
assert_eq "1" "$(( $(cksum < "$TMP/tr-true.md" | cut -d' ' -f1) == $(cksum < "$TMP/tr-drifted.md" | cut -d' ' -f1) ? 0 : 1 ))" \
  "the drifted fixture really differs from the true one"
case "$(refusal_transcripts "$TMP/tr-drifted.md")" in
  *tr-drifted.md:*) fires=yes ;;
  *) fires=no ;;
esac
assert_eq "yes" "$fires" "a transcript showing a line number the command does not print is reported"

# A command mentioned in prose is not a transcript, or every sentence naming the
# lister would be read as a claim about its output.
printf 'Run `bash bin/list-refusals.sh bin/next.sh` to see the unreadable site.\n' > "$TMP/tr-mention.md"
assert_eq "" "$(refusal_transcripts "$TMP/tr-mention.md")" \
  "a command mentioned in prose is not read as a transcript"

assert_done
