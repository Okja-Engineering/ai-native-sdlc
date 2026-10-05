#!/usr/bin/env bash
# One rule for what counts as an item, and two gates that cannot disagree about it.
#
# WHY THIS SUITE EXISTS
#
# Two sections in two phases are held to the same shape. The Discover gate's "what
# could not be established" section and the Define gate's "Outliers" section are
# both mandatory, both permitted to be empty, and both have to declare emptiness in
# band rather than assert it in prose. So both have to count items, and both have to
# answer the same question: what is an item.
#
# They answered it differently. Discover counted a bullet, a number OR any line
# beginning `**`, with the grade anywhere after it — so a bold-led sentence of prose
# was an item, including one that denied using the grade. Define counted `^- \*\*`
# and nothing got past it. One stated rule, two implementations, and the looser one
# was behind the audit question about where the process says it could not verify
# something.
#
# The rule is now stated once, in process/02-discover/discovery-contract.md, and
# process/03-define/define-contract.md cites it. The two gates still hold their own
# copies of the check rather than sharing a library, for the reason #104 records: a
# shared helper would be a load-bearing script outside the enumeration in
# CONTROLS.md, which is the gap #95 owns. Until that is settled, what stops the two
# copies drifting is this suite — the same candidate line driven through both gates,
# asserting they reach the same verdict.
#
# WHAT IS ASSERTED, AND WHAT IS NOT
#
# Not the pattern. No case here knows either gate's expression, so a different
# implementation of the same rule still passes. What is asserted is the verdict on a
# line, per gate, and that the two verdicts are equal.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"
. "$TEST_DIR/lib/topic-fixture.sh"
. "$TEST_DIR/lib/define-fixture.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
DISCOVER="$ROOT/process/02-discover/validate-discovery.sh"
DEFINE="$ROOT/process/03-define/validate-define.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

n=0

# discover_counts <line> -> prints "item" or "not an item"
#
# Read from the refusal CODE rather than from the exit status, so an unrelated
# refusal in the fixture cannot be mistaken for a verdict about the line.
discover_counts() { # <line>
  local p out
  p="$(topic_fixture "$TMP/topic$n.md" "$1")"
  out="$(bash "$DISCOVER" "$p" 2>&1)"
  case "$out" in
    *'refuse[silent-empty-open]'*) printf 'not an item' ;;
    *) printf 'item' ;;
  esac
}

# define_counts <line> -> prints "item" or "not an item"
#
# The fixture declares one outlier. Replacing it with the candidate line leaves the
# section empty unless the line counts, so `silent-empty-outliers` is the verdict.
define_counts() { # <line>
  local dir cyc out
  dir="$TMP/cycle$n"
  cyc="$(define_fixture "$dir" "3 2" 1)"
  # Rewritten with awk rather than a pattern match, because a pattern matched out of
  # the fixture is the mutation-matched-nothing failure tests/lib/mutate.sh exists
  # for, and here the replacement is the whole point of the case.
  awk -v repl="$1" '
    /^- \*\*An outlier/ { if (!done) { print repl; done = 1 }; next }
    { print }
  ' "$cyc" > "$cyc.new" && mv "$cyc.new" "$cyc"
  out="$(bash "$DEFINE" "$cyc" 2>&1)"
  case "$out" in
    *'refuse[silent-empty-outliers]'*) printf 'not an item' ;;
    *) printf 'item' ;;
  esac
}

# The baselines first. Nothing below means anything if the untouched fixtures do not
# behave as the suite assumes.
assert_eq "item" "$(discover_counts '- **Whether the thing holds. [O]**')" \
  "the Discover fixture with one real item reports an item"
assert_eq "item" "$(define_counts '- **An outlier that clusters with no theme.**')" \
  "the Define fixture with one real item reports an item"

# THE TABLE. One line per candidate form: the expected verdict, then the line.
#
# Every form the two gates could plausibly differ on, including the four the
# contract used to allow and no longer does, so the agreement is asserted across the
# whole boundary rather than at the one point the defect was found.
check() { # <expected> <line>
  local d f
  n=$((n + 1))
  d="$(discover_counts "$2")"
  f="$(define_counts "$2")"
  assert_eq "$d" "$f" "the two gates agree on: $2"
  assert_eq "$1" "$d" "and the verdict is '$1': $2"
}

# Accepted: a hyphen bullet with a bold lead, flush left.
check item        '- **Whether the thing holds. [O]**'
check item        '- **Whether the thing holds.** [O]'

# Refused: a bold label with no list marker. This is the form the Discover gate
# accepted and the Define gate never did, and it is the defect.
check 'not an item' '**Whether the thing holds. [O]**'
check 'not an item' '**Nothing remains open.** The two passes answered every question in scope; the grade [O] is not used in this artifact.'
check 'not an item' '**Nothing remains open** ([O])'

# Refused: the other markers the one rule drops.
check 'not an item' '1. **Whether the thing holds. [O]**'
check 'not an item' '1) **Whether the thing holds. [O]**'
check 'not an item' '* **Whether the thing holds. [O]**'
check 'not an item' '+ **Whether the thing holds. [O]**'
check 'not an item' '- Whether the thing holds. [O]'

# Refused: not flush left. Four spaces is a code block in Markdown, so a reader sees
# no item where a gate would have counted one.
check 'not an item' '    - **Whether the thing holds. [O]**'

# Refused: prose, with and without the grade.
check 'not an item' 'Whether the thing holds. [O]'
check 'not an item' 'The discovery was exhaustive and nothing of consequence remains outstanding.'

# --- the rule is written down once --------------------------------------------
# Two gates agreeing today is worth less if the rule they implement is written in
# two places, because then the words can drift even while the code does not. The
# statement lives in the Discover contract and the Define contract cites it.
RULE="$ROOT/process/02-discover/discovery-contract.md"
CITES="$ROOT/process/03-define/define-contract.md"
assert_contains "$(cat "$RULE")" 'An item is a list item' \
  "the Discover contract states what an item is"
assert_contains "$(cat "$CITES")" 'discovery-contract.md' \
  "the Define contract points at the contract that states it"
assert_contains "$(cat "$CITES")" 'what counts as an item' \
  "and says that is what it is pointing at"

assert_done
