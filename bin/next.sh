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

# fields <contract> -> one field name per line, from the Required fields table
fields() {
  sed -n '/^## Required fields/,/^## /p' "$1" 2>/dev/null \
    | sed -n 's/^| `\([a-z_]*\)` *|.*/\1/p'
}

# hint <contract> <field> -> the contract's own description of that field
hint() {
  sed -n '/^## Required fields/,/^## /p' "$1" 2>/dev/null \
    | sed -n "s/^| \`$2\` *| *\(.*[^ ]\) *|$/\1/p" | head -1 \
    | sed -e 's/\*\*//g' -e 's/`//g'
}

# sections <contract> -> one section heading per line, from Required sections
sections() {
  sed -n '/^## Required sections/,/^## What/p' "$1" 2>/dev/null \
    | sed -n 's/^### //p'
}

emit() { # contract title extra-frontmatter
  local c="$1" f
  printf '# %s\n\n' "$2"
  [ -n "${3:-}" ] && printf '%s\n' "$3"
  for f in $(fields "$c"); do
    case "$3" in *"$f:"*) continue ;; esac
    printf '%s:\n' "$f"
  done
  printf '\n<!-- Fields above are read from %s. Each one, and why:\n' "${c#$ROOT/}"
  for f in $(fields "$c"); do
    printf '     %-12s %s\n' "$f" "$(hint "$c" "$f")"
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
rows=$(grep -cE '^\| [A-Z]' "$findings")

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
status: defined, not solved"
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
