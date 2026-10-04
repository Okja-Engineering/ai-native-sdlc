#!/usr/bin/env bash
# Refuse a speed or velocity claim in anything we write.
#
# usage: bin/validate-claims.sh
#
# `intent.md` holds that no claim about speed, throughput or velocity appears in
# this repository. That was a prose promise; this is the check.
#
# WHY THIS IS A SCRIPT AND NOT A LINE IN ci.yml
#
# It lived inline in the workflow, which made it unrunnable locally and
# untestable. An external audit wrote a document containing six explicit speed
# claims and the pattern matched none of them:
#
#   "This loop makes our team quicker. We ship 3x quicker than before, our lead
#    time dropped 40%, throughput is up 60%, and the median cycle time fell from
#    nine days to two. Delivery is accelerated. Engineers are 2x more productive
#    and release 50% sooner."
#
# Nothing for `quicker` — the repository's own preferred word, used as the
# illustrative example in AGENTS.md — nor bare `throughput`, `lead time`,
# `sooner` or `accelerated`, and `[0-9]+x (faster|productivity)` missed both
# `3x quicker` and `2x more productive`.
#
# WHAT THIS IS, AND WHAT IT IS NOT
#
# **A tripwire for the obvious forms, not enforcement of the rule.** The rule is
# categorical and a lexical check cannot be. Nothing here catches "our engineers
# spend less time waiting", and nothing will. AGENTS.md says which of the two
# this is, because calling a tripwire an enforcement is the overclaim that let
# six claims through while the job printed ok.
#
# SCOPE
#
# Everything we write. The record of what other people said is excluded, because
# two of this repository's own rules collide there: no speed claims in documents,
# while the scan and discovery contracts *require* recording a vendor's claim as
# a claim. A findings row reading `TypeSafe states "193.6x Faster"` is the
# repository doing its job.
#
# The exclusion is by directory rather than by phrasing. A lexical rule trying to
# tell "we claim X" from "they claim X" would be guessing at attribution; the
# directory boundary already exists in the design, and those files carry their
# own constraint — every row needs a resolving source, so an unattributed claim
# cannot live there anyway.
#
# exit 0  no speed claim found
# exit 1  at least one found
# exit 2  could not run
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

# No \b anchors. macOS git grep does not honour them and silently matches
# nothing, while Linux git does — so an anchored version fired in CI and did
# nothing on a developer's machine, which is the worst of both.
#
# Grouped by what each clause is for, so a gap is visible rather than buried in
# one long alternation.
SPEED='faster|quicker|speedier|sooner|accelerat(e|es|ed|ing|ion)'
RATE='velocity|throughput|lead time|cycle.time|time.to.market|productivity'
MULT='[0-9]+(\.[0-9]+)? *x +(faster|quicker|more [a-z]+|productiv)'
PCT='[0-9]+ *% +(faster|quicker|more productive|improvement in (velocity|throughput))'

# `OWN` and `LINK` absorb the words that sat between a verb and its object in
# real phrasings. Two claims slipped through without them — "makes **our team**
# quicker" and "throughput **is** up 60%" — and both only showed up once each
# claim was asserted on its own line. In the audit's single document they were
# hidden behind other claims matching on the same line.
#
# That is the one-case-trips-two-guards failure wearing different clothes: when a
# single test input satisfies two guards at once, a passing result proves neither
# of them, and a guard that never fires alone is indistinguishable from a guard
# that does not work. The rule and the sweep that established it are in AGENTS.md,
# section "Tests: pin the invariant, not the literals"; the finding was issue #29,
# which a clone cannot read.
OWN='(our |the |your |my |their )?'
LINK='(is |was |are |were |has |have )?'

PATTERN="((makes?|made|making) ${OWN}(us|it|them|teams?|everyone|delivery|work|engineers?) ${LINK}(${SPEED})\
|(ships?|shipped|shipping|deliver(s|ed|ing)?|releases?|released) ${LINK}(${SPEED})\
|speeds? up (delivery|development|shipping|the team)\
|(${RATE}) ${LINK}(gain|gains|improvement|improvements|increase|up|rose|reduction|dropped|fell|down)\
|(improve[sd]?|increase[sd]?|reduce[sd]?|cut) ${OWN}(${RATE})\
|${MULT}|${PCT}\
|delivery is (${SPEED}))"

# A BROKEN PATTERN MUST NOT READ AS "NOTHING FOUND".
#
# `git grep` exits 0 on a match, 1 on no match, and >1 on an error. The first
# version of this script sent stderr to /dev/null and treated any non-zero exit
# as clean — so when the pattern contained `(our |the |)`, an empty alternative
# and an invalid ERE, git grep failed and the gate printed ok. The pattern was
# never evaluated against anything.
#
# That is the same silent-failure shape as the `\?` in sed and the missing `-i`
# elsewhere in this repository: the check looked like it ran.
# AND A PATHSPEC THAT MATCHES NOTHING MUST NOT READ AS "NOTHING FOUND" EITHER.
#
# That was the other half of the same hole. `git grep` exits 1 both for "no match"
# and for "the pathspec matched no files", so a clean report meant either. Measured
# in a throwaway clone: with every markdown file dropped from the index this printed
# the same line and exited 0, over 32 documents and over none. The excludes below are
# edited whenever a directory of recorded claims appears, and one over-broad entry
# turns the gate off silently.
#
# The pathspec is set ONCE, in the positional parameters, and both commands read it.
# Written twice it would be the duplicated rule this repository keeps being burnt by:
# a count taken over a different set than the scan is not a denominator.
set -- '*.md' \
  ':(exclude)process/*/findings/*' \
  ':(exclude)process/*/topics/*' \
  ':(exclude)bin/validate-claims.sh' \
  ':(exclude)tests/*'

scanned="$(git ls-files -- "$@" 2>/dev/null | grep -c .)"
if [ "$scanned" -eq 0 ]; then
  printf 'validate-claims: the pathspec matched no tracked document, so nothing was checked\n' >&2
  exit 2
fi

out="$(git grep -nIiE "$PATTERN" -- "$@" 2>&1)"
status=$?

if [ "$status" -gt 1 ]; then
  printf 'validate-claims: the pattern did not evaluate, so nothing was checked:\n' >&2
  printf '%s\n' "$out" | sed 's/^/  /' >&2
  exit 2
fi

if [ "$status" -eq 0 ]; then
  printf 'a speed or velocity claim appears in a tracked document:\n' >&2
  printf '%s\n' "$out" | sed 's/^/  /' >&2
  printf '\nintent.md: the north star is better software, not faster.\n' >&2
  printf 'If this is a record of what someone else claimed, it belongs in a findings or topic file.\n' >&2
  exit 1
fi

printf 'validate-claims: no speed claims in %s tracked document(s)\n' "$scanned"
