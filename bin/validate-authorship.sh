#!/usr/bin/env bash
# The commit that records a decision must be authored by a decider.
#
# usage: bin/validate-authorship.sh [since-ref]
#
# WHY
#
# CONTROLS.md gives CTRL-1's evidence as "the decision record, the git commit
# author, the commit date, and the merge". An external audit found that evidence
# does not distinguish the parties: every commit on `main` is authored under one
# address, `imagineux@gmail.com`, under two display names.
#
# Every commit that wrote a decision record was authored by the same identity an
# agent uses. DECIDERS.md names "Matthew Van Dusen". So the record says a human
# decided, and the commit that wrote that name is indistinguishable from an
# agent's.
#
# STANDARDS.md 3 convicts a vendor of exactly this: "Two accounts belonging to
# one vendor's one product is a separation of identity, not of duties." Here it
# is one account with two display names.
#
# THE TALLY IS PRINTED, NOT TRANSCRIBED
#
# This comment carried a hand-typed tally until 2026-10-03, and so did
# DECIDERS.md, AGENTS.md and CONTROLS.md. All four were wrong the same way: the
# numbers came from a working tree holding unpushed branches, so nobody reading
# the public repository could reproduce them. A number a script computes does not
# need transcribing, so this gate now prints it and the documents name the
# command. DECIDERS.md carries the one transcribed copy, labelled with the ref
# and the date it was measured.
#
# WHAT THIS CHECKS, AND WHY IT CURRENTLY REFUSES
#
# A commit that sets `chosen:` to anything other than `pending` is the act the
# whole loop exists to gate. Its author must be a declared decider, and that
# identity must not also be in use by anything else.
#
# It refuses today, and the refusal is the finding rather than a bug: the
# identities are not separated, so authorship cannot be verified from git. That
# is one configuration change away, and it is not a change an agent should make.
#
# Not wired into CI for that reason — a gate that cannot pass blocks every
# branch. CONTROLS.md records it as stated and not yet enforced, with the exact
# change that turns it on.
#
# exit 0  every decision-setting commit is attributable to a decider
# exit 1  at least one is not
# exit 2  could not run
#
# env MEASURE_REF  the ref the identity tally is measured against, default `main`
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

DECIDERS="${DECIDERS_FILE:-$ROOT/DECIDERS.md}"
SINCE="${1:-}"

[ -f "$DECIDERS" ] || { printf 'validate-authorship: no decider list at %s\n' "$DECIDERS" >&2; exit 2; }

# Declared git identities, from the third column of the decider table. An entry
# with no identity cannot be matched against a commit, which is itself the gap.
# Backticks are stripped. The column is written as `Name <addr>` in markdown, so
# leaving them on made every comparison fail and the gate refused a correct
# fixture for the wrong reason — which a clean-fixture assertion caught.
identities="$(awk -F'|' '/^\| / { gsub(/^ +| +$/, "", $4); gsub(/`/, "", $4); if ($4 ~ /@/) print $4 }' "$DECIDERS")"

refusals=0
refuse() { printf 'refuse[%s]: %s\n' "$1" "$2" >&2; refusals=$((refusals + 1)); }

if [ -z "$identities" ]; then
  refuse "no-identities" "DECIDERS.md declares no git identity for any decider, so no commit can be attributed to one"
fi

range="HEAD"
[ -n "$SINCE" ] && range="$SINCE..HEAD"

# A FAILED `git log` MUST NOT READ AS "NO COMMITS".
#
# `2>/dev/null` here swallowed the difference between "this range holds no decision
# commit" and "this range does not exist". Measured against the real history, which
# this gate refuses four times when asked properly:
#
#   bin/validate-authorship.sh nosuchref
#     -> validate-authorship: 0 decision-setting commit(s), each attributable to a
#        declared decider                                              exit 0
#
# A typo in the argument turned the gate off and reported the thing it exists to
# refuse. Same shape as validate-claims.sh reading a pattern that would not compile
# as a clean tree, which this repository already fixed once and wrote down.
if ! commits="$(git log --format='%H' "$range" -- 'process/05-deliver/decisions/*.md' 2>/dev/null)"; then
  printf 'validate-authorship: could not read the history for %s, so nothing was checked — is %s a ref in this repository?\n' \
    "$range" "${SINCE:-HEAD}" >&2
  exit 2
fi
checked=0

for c in $commits; do
  # Did this commit SET a decision, as opposed to drafting or editing a pending
  # one? Only the act of choosing is gated.
  added="$(git show --format= --unified=0 "$c" -- 'process/05-deliver/decisions/*.md' 2>/dev/null \
    | grep -E '^\+chosen:' | sed 's/^+chosen:[[:space:]]*//' | head -1)"
  case "$added" in
    ""|pending|none) continue ;;
  esac

  checked=$((checked + 1))
  who="$(git log -1 --format='%an <%ae>' "$c")"
  short="$(git log -1 --format='%h' "$c")"

  if ! printf '%s\n' "$identities" | grep -qxF "$who"; then
    refuse "author-not-a-decider" \
      "$short set chosen: $added, authored by \"$who\", which is not a declared decider identity"
  fi

  # Even a match is not enough if the identity is shared. An email used by more
  # than one author name proves nothing about who made the commit.
  email="$(printf '%s' "$who" | sed -e 's/.*<//' -e 's/>.*//')"
  names="$(git log --all --format='%an <%ae>' | grep -F "<$email>" | sed 's/ <.*//' | sort -u | grep -c . || true)"
  if [ "${names:-0}" -gt 1 ]; then
    refuse "identity-shared" \
      "$short is authored under <$email>, which carries $names different author names — a commit under it is not attributable to one party"
  fi
done

# --- what the history actually carries ---------------------------------------
# Printed, never refused. This is a measurement, not a rule: the tally changes
# every time anyone commits, so holding it to a value would make the gate a
# staleness alarm instead of a control.
#
# Measured against one named ref rather than `--all`, because `--all` also counts
# whatever branches happen to be open when it runs — which is how the transcribed
# version came to say 107 commits where `main` carries 95. `main` where the
# checkout has it, HEAD where it does not, and the ref is printed either way so
# the reader knows which was measured.
MEASURE_REF="${MEASURE_REF:-main}"
git rev-parse --verify --quiet "$MEASURE_REF" >/dev/null 2>&1 || MEASURE_REF=HEAD
printf 'validate-authorship: author identities on %s\n' "$MEASURE_REF"
git log "$MEASURE_REF" --format='%an <%ae>' 2>/dev/null | sort | uniq -c | sort -rn | sed 's/^/  /'

# And whether each declared identity authors anything at all. DECIDERS.md said
# one of them "already appears in this history" while it appeared zero times,
# which is what transcribing instead of measuring buys you.
while IFS= read -r id; do
  [ -n "$id" ] || continue
  n="$(git log "$MEASURE_REF" --format='%an <%ae>' 2>/dev/null | grep -cxF "$id" || true)"
  printf '  declared identity %s authors %s commit(s) on %s\n' "$id" "${n:-0}" "$MEASURE_REF"
done <<EOF
$identities
EOF

if [ "$refusals" -gt 0 ]; then
  printf '\nvalidate-authorship: %s refusal(s) across %s decision-setting commit(s)\n' "$refusals" "$checked" >&2
  printf 'CONTROLS.md: this control is stated and not yet enforced. See what is not controlled, item 10.\n' >&2
  exit 1
fi
printf 'validate-authorship: %s decision-setting commit(s), each attributable to a declared decider\n' "$checked"
