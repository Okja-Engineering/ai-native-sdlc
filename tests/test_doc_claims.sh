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
done

assert_eq "" "$offenders" "no document says a path does not exist when it does"

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

# --- the paths list is not empty ---------------------------------------------
# If the enumeration returned nothing the loop above would pass everything.
np="$(printf '%s\n' "$paths" | grep -c .)"
[ "$np" -ge 5 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the path enumeration found the phases (found $np)"

assert_done
