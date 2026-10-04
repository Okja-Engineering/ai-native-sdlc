#!/usr/bin/env bash
# Start the next artifact a cycle needs, from the contract that declares it.
#
# usage: bin/next.sh <cycle>              # scaffold whatever is missing next
#        bin/next.sh <cycle> <slug>       # for phases that work per problem
#
# The fields and sections it writes are READ FROM THE CONTRACT, not carried
# here — add a field to a contract's `## Required fields` table and the next
# scaffold produces it, with no edit to this script. That property is the whole
# point: the contract stays the single declaration of a phase's shape, and this
# cannot drift from it.
#
# Refuses to overwrite. Writes a skeleton; filling it in is the work.
#
# exit 0  wrote a skeleton, or nothing was missing
# exit 1  refused
# exit 2  could not run
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

die()    { printf '%s\n' "$*" >&2; exit 2; }
refuse() { printf 'refuse: %s\n' "$*" >&2; exit 1; }

# A contract may declare fields for MORE THAN ONE artifact. Define does: a cycle
# and a problem are both Define's output and they do not have the same shape.
# Which table to read is therefore named by the caller rather than assumed, and
# the heading is matched EXACTLY — a prefix match would make `## Required fields`
# re-open at `## Required fields — a problem` and hand the cycle a problem's
# fields.
#
# A field name may contain a space (`rests on`), so a field list is read a line at
# a time. Word splitting would turn one field into two.
FIELDS_HEADING='## Required fields'

# declared <contract> <heading> -> that heading's table, one `| field | hint |` row per line
declared() {
  sed -n "/^$2\$/,/^## /p" "$1" 2>/dev/null | sed -n 's/^| `\([a-z_ ]*\)` *|\(.*\)$/\1|\2/p'
}

# fields <contract> [heading] -> one field name per line
fields() {
  declared "$1" "${2:-$FIELDS_HEADING}" | sed 's/|.*//'
}

# hint <contract> <field> [heading] -> the contract's own description of that field
hint() {
  declared "$1" "${3:-$FIELDS_HEADING}" \
    | sed -n "s/^$2|[[:space:]]*\(.*[^ ]\)[[:space:]]*|\$/\1/p" | head -1 \
    | sed -e 's/\*\*//g' -e 's/`//g'
}

# sections <contract> -> one section heading per line, from Required sections
sections() {
  sed -n '/^## Required sections/,/^## What/p' "$1" 2>/dev/null \
    | sed -n 's/^### //p'
}

emit() { # contract title extra-frontmatter [fields-heading]
  local c="$1" h="${4:-$FIELDS_HEADING}" f
  printf '# %s\n\n' "$2"
  [ -n "${3:-}" ] && printf '%s\n' "$3"
  fields "$c" "$h" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    case "$3" in *"$f:"*) continue ;; esac
    printf '%s:\n' "$f"
  done
  printf '\n<!-- Fields above are read from %s, under "%s". Each one, and why:\n' \
    "${c#$ROOT/}" "${h#\#\# }"
  fields "$c" "$h" | while IFS= read -r f; do
    [ -n "$f" ] || continue
    printf '     %-12s %s\n' "$f" "$(hint "$c" "$f" "$h")"
  done
  # `--` is not a format string: printf would read it as end-of-options and the
  # comment would never close, swallowing every section below it.
  printf '%s\n' '-->'
  local s
  sections "$c" | while IFS= read -r s; do
    [ -n "$s" ] || continue
    printf '\n## %s\n\n*To be written.*\n' "$s"
  done
}

write_once() { # path content-producer...
  local out="$1"; shift
  [ -e "$out" ] && refuse "$out already exists — this writes skeletons, it does not overwrite"
  mkdir -p "$(dirname "$out")"
  "$@" > "$out" || die "could not write $out"
  printf 'wrote %s\n' "$out"
  printf '\nNext: fill it in. The commented block names every field and what it is for.\n'
}

cycle="${1:-}"; slug="${2:-}"
[ -n "$cycle" ] || die "usage: bin/next.sh <cycle> [slug]"

findings="process/01-scan/findings/$cycle.md"
[ -f "$findings" ] || die "no findings for $cycle — a cycle starts with a scan"

define="process/03-define/cycles/$cycle.md"

# The count written into a new cycle's `from:` line, which the Define gate reads
# and compares against the source. This was `grep -cE '^\| [A-Z]'` — the exact
# expression define-contract.md names as the one an external audit defeated, still
# writing the denominator of every new cycle. It counted any table row starting
# with a capital, so a findings file with two findings and one table of unreached
# ground inside `## Looked at`, which findings-contract.md permits, was scaffolded
# as four findings; and the case of a finding's first letter decided whether it
# counted at all.
#
# One harvester, read by this, by bin/cycle.sh and by the gate, so the scaffold
# cannot write a count the gate then refuses.
IDS="process/01-scan/findings-ids.sh"
[ -f "$IDS" ] || die "no findings id harvester at $IDS — the count a cycle declares is read from it, and a wrong denominator is worse than no scaffold"
ids=$(bash "$IDS" "$findings") || die "could not read the ids of $findings"
# Counted in a second step on purpose: `| grep -c .` would make the exit status
# grep's, and grep exits 1 on no match, so a cycle that honestly found nothing
# would be read as a failure to read the file.
rows=$(printf '%s\n' "$ids" | grep -c .)

# --- define -------------------------------------------------------------------
if [ ! -f "$define" ]; then
  c="process/03-define/define-contract.md"
  write_once "$define" emit "$c" "Define — cycle $cycle" \
"from: [\`$findings\`](../../01-scan/findings/$cycle.md), $rows findings
status: defined, not decided"
  exit 0
fi

# --- a problem is a human's pick, not something to scaffold blind --------------
probs=$(ls process/03-define/problems/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$probs" -eq 0 ] && [ -z "$slug" ]; then
  printf 'Define is done for %s. The next step is yours:\n' "$cycle"
  printf '  pick a theme, then: bin/next.sh %s <slug>\n' "$cycle"
  printf '\nA problem names which theme is being pursued. Scaffolding one without\n'
  printf 'that choice would be inventing the pick, which is the human gate.\n'
  exit 0
fi

[ -n "$slug" ] || { printf 'Several problems exist. Say which: bin/next.sh %s <slug>\n' "$cycle"; ls process/03-define/problems/*.md 2>/dev/null | sed 's|.*/|  |;s|\.md$||'; exit 0; }

problem="process/03-define/problems/$slug.md"
options="process/04-develop/options/$slug.md"
decision="process/05-deliver/decisions/$slug.md"

if [ ! -f "$problem" ]; then
  c="process/03-define/define-contract.md"
  write_once "$problem" emit "$c" "Problem — $slug" \
"from: [\`$define\`](../cycles/$cycle.md)
status: defined, not solved" \
    '## Required fields — a problem'
  exit 0
fi

# --- develop ------------------------------------------------------------------
if [ ! -f "$options" ]; then
  c="process/04-develop/develop-contract.md"
  write_once "$options" emit "$c" "Develop — $slug" \
"problem: [\`$problem\`](../../03-define/problems/$slug.md)
status: options developed, none chosen"
  exit 0
fi

# --- deliver ------------------------------------------------------------------
if [ ! -f "$decision" ]; then
  c="process/05-deliver/deliver-contract.md"
  write_once "$decision" emit "$c" "Decision — $slug" \
"problem: [\`$problem\`](../../03-define/problems/$slug.md)
options: [\`$options\`](../../04-develop/options/$slug.md)
chosen: pending"
  exit 0
fi

printf 'Nothing missing for %s/%s.\n' "$cycle" "$slug"
chosen=$(sed -n 's/^chosen:[[:space:]]*//p' "$decision" | head -1)
case "$chosen" in
  ""|pending|none) printf '\n%s is AWAITING A HUMAN. That one is not mine to write.\n' "$decision" ;;
esac
