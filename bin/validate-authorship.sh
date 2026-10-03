#!/usr/bin/env bash
# The commit that records a decision must be authored by a decider.
#
# usage: bin/validate-authorship.sh [since-ref]
#
# WHY
#
# CONTROLS.md gives CTRL-1's evidence as "the decision record, the git commit
# author, the commit date, and the merge". An external audit found that evidence
# does not distinguish the parties:
#
#   71  imagineux <imagineux@gmail.com>          <- agent-driven commits
#   29  Matthew Van Dusen <imagineux@gmail.com>  <- the web merges
#    7  imagineux <matt.vandusen@okja.io>
#
# Every commit that wrote a decision record was authored by the first of those.
# DECIDERS.md names "Matthew Van Dusen". So the record says a human decided, and
# the commit that wrote that name is indistinguishable from an agent's.
#
# STANDARDS.md 3 convicts a vendor of exactly this: "Two accounts belonging to
# one vendor's one product is a separation of identity, not of duties." Here it
# is one account with two display names.
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

commits="$(git log --format='%H' "$range" -- 'process/05-deliver/decisions/*.md' 2>/dev/null)"
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

if [ "$refusals" -gt 0 ]; then
  printf '\nvalidate-authorship: %s refusal(s) across %s decision-setting commit(s)\n' "$refusals" "$checked" >&2
  printf 'CONTROLS.md: this control is stated and not yet enforced. See what is not controlled, item 10.\n' >&2
  exit 1
fi
printf 'validate-authorship: %s decision-setting commit(s), each attributable to a declared decider\n' "$checked"
