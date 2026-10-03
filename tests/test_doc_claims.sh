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
# Lines QUOTING the old claim in order to correct it are exempt — the correction
# necessarily contains the phrase, and the first version of this check fired on
# it. Same shape as the Annotated exemption above.
# `-i`, not just `-I`. The first version used `-nIE`, where `I` means skip
# binary files and NOT ignore case — so the pattern `all of it in git` missed
# `All of it in git`, the exact sentence this check exists to catch. The mutation
# test passed vacuously until that was found.
overclaim="$(git grep -niIE 'all of it in git|everything is in git|entirely in git' \
  -- '*.md' ':(exclude)tests/*' 2>/dev/null \
  | grep -viE 'claimed|until 2026|this said|used to' || true)"
assert_eq "" "$overclaim" "no document claims the whole chain is in git"

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
# command that produces it. Not that the number is right — that is below, under
# what this does not establish — but that a reader has a way to find out.
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

# --- the paths list is not empty ---------------------------------------------
# If the enumeration returned nothing the loop above would pass everything.
np="$(printf '%s\n' "$paths" | grep -c .)"
[ "$np" -ge 5 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the path enumeration found the phases (found $np)"

assert_done
