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
# Both moved to meet: Discover lost the bold-label form, which is the defect, and
# Define lost a bold requirement nothing had ever stated. The rule is now "an item
# is a list item", which is a sentence with a reason behind it; `- **` would have
# been narrower and would have made one artifact's markup the rule.
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
. "$TEST_DIR/lib/splice.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
DISCOVER="$ROOT/process/02-discover/validate-discovery.sh"
DEFINE="$ROOT/process/03-define/validate-define.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

n=0
d=""
f=""
form=""

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
  # Through tests/lib/splice.sh, which refuses a substitution that matched nothing —
  # the mutation-matched-nothing failure tests/lib/mutate.sh exists for, and here the
  # replacement is the whole point of the case.
  #
  # It was `awk -v repl="$1"`, which cannot carry a newline. Every single-line case
  # above worked and every multi-line one left the fixture UNMODIFIED, so eight cases
  # asserting the two gates agree about a displayed item were comparing two untouched
  # fixtures. `[*][*]` and not `\*\*` for the same reason: through `-v` the backslashes
  # are consumed.
  splice "$cyc" '^- [*][*]An outlier' "$1" || { printf 'probe failed'; return; }
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

# Accepted: a list marker, flush left. Emphasis plays no part — a bullet is what
# makes the line a list item, which is the whole of the rule.
check item        '- **Whether the thing holds. [O]**'
check item        '- **Whether the thing holds.** [O]'
check item        '- Whether the thing holds. [O]'
check item        '* Whether the thing holds. [O]'
check item        '+ Whether the thing holds. [O]'
check item        '1. Whether the thing holds. [O]'
check item        '1) Whether the thing holds. [O]'

# Refused: a bold label with no list marker. This is the form the Discover gate
# accepted and the Define gate never did, and it is the defect.
check 'not an item' '**Whether the thing holds. [O]**'
check 'not an item' '**Nothing remains open.** The two passes answered every question in scope; the grade [O] is not used in this artifact.'
check 'not an item' '**Nothing remains open** ([O])'
check 'not an item' '**1. Whether the thing holds. [O]**'

# Refused: not flush left. Four spaces is a code block in Markdown, so a reader sees
# no item where a gate would have counted one.
check 'not an item' '    - **Whether the thing holds. [O]**'
check 'not an item' '  - Whether the thing holds. [O]'

# Refused: prose, with and without the grade, and a bare marker character that is
# not a list marker because no space follows it.
check 'not an item' 'Whether the thing holds. [O]'
check 'not an item' 'The discovery was exhaustive and nothing of consequence remains outstanding.'
check 'not an item' '-Whether the thing holds. [O]'

# --- THE DISPLAY FORMS, THROUGH BOTH GATES ------------------------------------
#
# Two gates sharing a rule must not be able to disagree about it, and that now includes
# the display question. Before issue #116 they disagreed about every form but one: both
# knew a fenced DECLARATION, neither knew a fenced ITEM, and neither knew an inline code
# span, an HTML comment or an indented block in either role.
#
# Driven through the same `check` as the item cases above, so the agreement assertion is
# the same one — a form that only one gate can police is how the two came to disagree in
# the first place.
#
# AN ITEM DISPLAYED IS NOT AN ITEM. This is the second half of #116's finding 2: the item
# predicate had no fence awareness at all, so a fenced illustration containing one
# bulleted `[O]` line counted toward the item total and a section emptied of all seven of
# its disclosures passed.
display_item() { # <form> -> a section body whose only item is displayed, not used
  case "$1" in
    backtick-fence)   printf '```\n- **Whether the thing holds. [O]**\n```\n' ;;
    tilde-fence)      printf '~~~\n- **Whether the thing holds. [O]**\n~~~\n' ;;
    html-comment)     printf '<!-- what an item looks like:\n- **Whether the thing holds. [O]**\n-->\n' ;;
    indented-block)   printf '\n    - **Whether the thing holds. [O]**\n\n' ;;
  esac
}

for form in backtick-fence tilde-fence html-comment indented-block; do
  n=$((n + 1))
  d="$(discover_counts "$(display_item "$form")")"
  f="$(define_counts "$(display_item "$form")")"
  assert_eq "$d" "$f" "the two gates agree on an item displayed in a $form"
  assert_eq 'not an item' "$d" "and an item displayed in a $form is not an item"
done

# An inline code span is NOT a display form for an item, and the reason is worth having
# written down rather than inferred: wrapping the line in backticks moves the backtick to
# the first column, so the line no longer begins with a list marker. The cell is closed by
# the shape of the rule. It is asserted because an unwritten cell is how five of these
# survived.
check 'not an item' '`- **Whether the thing holds. [O]**`'

# And a grade marker written in a code span on a real item STILL COUNTS, which is the
# measurement that decided the item rule reads lines rather than spans: this repository
# writes `[E]` in backticks as house style in four places.
check item        '- Whether the thing holds. `[O]`'

# --- THE DECLARATION, THROUGH BOTH GATES --------------------------------------
#
# The other direction: an empty section declaring itself empty. `declares_empty` was two
# copies of a fence skip; it is one reading now, and both gates have to answer all five
# display forms the same way.
#
# The verdict is read from the same refusal code as the item cases — a section that
# declares itself empty draws no `silent-empty` refusal — so "item" here means "the
# section was accepted".
declares_empty_verdicts() { # <body> -> "<discover> <define>"
  n=$((n + 1))
  printf '%s %s' "$(discover_counts "$1")" "$(define_counts "$1")"
}

DECL='<!-- declared-empty: a reason that is written down -->'
assert_eq 'item item' "$(declares_empty_verdicts "$DECL")" \
  'both gates accept a section that declares itself empty'

assert_eq 'not an item not an item' \
  "$(declares_empty_verdicts "$(printf '```\n%s\n```\n' "$DECL")")" \
  'and neither accepts one shown inside a backtick fence'
assert_eq 'not an item not an item' \
  "$(declares_empty_verdicts "$(printf '~~~\n%s\n~~~\n' "$DECL")")" \
  'nor inside a tilde fence'
assert_eq 'not an item not an item' \
  "$(declares_empty_verdicts "$(printf '%s\n' "\`$DECL\`")")" \
  'nor inside an inline code span, which is the critical on #116'
assert_eq 'not an item not an item' \
  "$(declares_empty_verdicts "$(printf '<!-- what the form looks like:\n%s\nand no more. -->\n' "$DECL")")" \
  'nor inside an HTML comment'
assert_eq 'not an item not an item' \
  "$(declares_empty_verdicts "$(printf '\n    %s\n\n' "$DECL")")" \
  'nor inside a four-space indented block'

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
assert_contains "$(cat "$CITES")" 'counts as an item is stated once' \
  "and says that is what it is pointing at"

assert_done
