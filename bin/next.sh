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
#
# A FENCED BLOCK IS LITERAL CONTENT, NOT A DECLARATION. A section's skeleton is
# declared in a fence, and a theme is a `### ` heading — so the moment the Themes
# section declared the shape of a theme, the heading inside that fence was read
# here as the name of another required section, and the scaffold emitted
# `## N · a name that is a claim` as a section of its own. Same class as the
# fenced `rests on:` example that donated its value to the Define gate's field
# reader, and the fence-skipping is written the same way it is there.
sections() {
  sed -n '/^## Required sections/,/^## What/p' "$1" 2>/dev/null \
    | awk '/^[ \t]*(```|~~~)/ { fence = !fence; next } !fence' \
    | sed -n 's/^### //p'
}

# skeleton <contract> <section> -> the first fenced block that section declares.
#
# Some sections have a literal shape a reader cannot be expected to retype, and
# one of them is the Define gate's most load-bearing input. The accounting block
# was declared as a worked example inside a prose section instead, so the scaffold
# — which reads fields and sections — never saw it, and the gate refused its own
# skeleton with `no-accounting`. A section that declares a skeleton now gets it;
# one that does not still gets *To be written.*
skeleton() {
  awk -v h="### $2" '
    $0 == h { inside = 1; next }
    # The fence is read FIRST, and the heading test only applies outside one. A
    # heading inside a fence is literal content: the section that declares the
    # shape of a theme has to put a `### ` line in its skeleton, and testing the
    # heading first truncated that skeleton at the heading — emitting the heading
    # and nothing under it.
    inside && substr($0, 1, 3) == "```" {
      if (fenced) exit
      fenced = 1; next
    }
    # The NEXT heading of either level ends the section. Resetting only on `## `
    # let every section read the next one: asking for "Themes" returned the
    # accounting block, because that is the first fence below it, and the skeleton
    # was written into three sections.
    inside && !fenced && (substr($0, 1, 3) == "## " || substr($0, 1, 4) == "### ") { exit }
    inside && fenced { print }
  ' "$1"
}

# wrap_ids <ids, one per line> -> the same ids, sixteen to a line.
# Sixty-four on one line is a line nobody reads, and the shipped cycle wraps them.
wrap_ids() {
  printf '%s\n' "$1" | awk '
    NF { printf "%s%s", (n % 16 == 0 ? (n == 0 ? "" : "\n") : " "), $1; n++ }
    END { if (n) printf "\n" }'
}

emit() { # contract title extra-frontmatter [fields-heading] [source-ids]
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
  local s body
  # A `while` loop reading from a pipe runs in a subshell, so the body cannot be
  # a function that sets a variable the loop needs. Everything here is printed.
  sections "$c" | while IFS= read -r s; do
    [ -n "$s" ] || continue
    printf '\n## %s\n\n' "$s"
    body="$(skeleton "$c" "$s")"
    if [ -z "$body" ]; then
      printf '*To be written.*\n'
      continue
    fi
    case "$body" in
      *'<!-- scaffold:source-ids -->'*)
        # Declared by the contract, substituted here. The literal token is never
        # written through: a cycle carrying it would be refused by the gate for an
        # accounting block that looks present and lists nothing.
        #
        # No ids is a real state in two ways — a cycle that found nothing, and an
        # artifact this contract declares that is not a cycle, because the section
        # list is not yet per-artifact the way the field table now is. Both get a
        # note saying what belongs here, which is what a skeleton is.
        printf '%s\n' "$body" | while IFS= read -r line; do
          case "$line" in
            '<!-- scaffold:source-ids -->')
              if [ -n "${5:-}" ]; then
                wrap_ids "$5"
              else
                printf '%s\n' '<!-- every id the source records. None were available to scaffold. -->'
              fi ;;
            *) printf '%s\n' "$line" ;;
          esac
        done ;;
      *) printf '%s\n' "$body" ;;
    esac
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

# A COMPARISON CYCLE reads the same scan as the record it is compared against, so
# the source is the part of the name before the first dot:
# `bin/next.sh 2026-09-29.by-model` writes cycles/2026-09-29.by-model.md from
# findings/2026-09-29.md. Declared in define-contract.md under "A comparison
# cycle"; the cross-cutting test the producing-themes decision commissioned had no
# place to land, and the whole value of putting it in cycles/ is that the Define
# gate's accounting check then applies to the model's grouping too.
#
# `${cycle%%.*}` and not a regex: a cycle id is a name, not a pattern. With no dot
# the two are the same string, so an ordinary cycle is unchanged.
scan="${cycle%%.*}"

findings="process/01-scan/findings/$scan.md"
[ -f "$findings" ] || die "no findings for $scan — a cycle starts with a scan"

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

# --- a comparison cycle -------------------------------------------------------
# A second grouping of the same findings, with its own field table because it
# carries two fields a cycle does not: what it is compared against, and the
# criterion its result is read against.
#
# It stops here rather than falling into the problem chain below. A problem is
# stated from the hand pass; offering to continue one from the model's grouping
# would be offering to state a problem from the thing under test.
if [ "$scan" != "$cycle" ]; then
  c="process/03-define/define-contract.md"
  if [ ! -f "$define" ]; then
    write_once "$define" emit "$c" "Define — cycle $scan, $(printf '%s' "${cycle#*.}" | tr '-' ' ')" \
"from: [\`$findings\`](../../01-scan/findings/$scan.md), $rows findings
compares: [\`process/03-define/cycles/$scan.md\`]($scan.md)
status: defined, not decided" \
      '## Required fields — a comparison cycle' "$ids"
    # Said, not refused. Nothing reads `compares:` yet, so a link to a record that
    # is not there would otherwise sit in the skeleton looking resolved. A
    # comparison with nothing to compare against is still a grouping of the scan,
    # which is why this is a note rather than a refusal.
    # Worded without the phrase "does not exist": tests/test_doc_claims.sh refuses
    # a line asserting that a path under a built phase is absent, and it reads a
    # window around the phrase rather than resolving the path. The rule is right
    # and the sentence was the thing to change.
    [ -f "process/03-define/cycles/$scan.md" ] || \
      printf '\nNote: compares: names process/03-define/cycles/%s.md, and there is no such record yet.\n' "$scan"
  else
    printf 'Nothing missing for the comparison %s over %s.\n' "${cycle#*.}" "$scan"
    printf '\n%s is AWAITING A PERSON: `criterion:` is what result counts as which\n' "$define"
    printf 'reading, and define-contract.md states it unset on purpose.\n'
  fi
  exit 0
fi

# --- define -------------------------------------------------------------------
if [ ! -f "$define" ]; then
  c="process/03-define/define-contract.md"
  write_once "$define" emit "$c" "Define — cycle $cycle" \
"from: [\`$findings\`](../../01-scan/findings/$cycle.md), $rows findings
status: defined, not decided" \
    '' "$ids"
  exit 0
fi

# --- a problem is a human's pick, not something to scaffold blind --------------
# Problems are counted for THIS cycle, read from the cycle their own `from:` field
# names. The count was `ls process/03-define/problems/*.md | wc -l`, across every
# cycle, so from the second cycle onward it was never zero: the hand-back below
# could not be reached, and a new cycle was offered the previous cycle's problems
# to continue — a different cycle's work. bin/cycle.sh already filters problems
# this way, and that filter was written for the same defect in the same shape.
mine=""
probs=0
for p in process/03-define/problems/*.md; do
  [ -f "$p" ] || continue
  if grep -q "cycles/$cycle\.md" "$p" 2>/dev/null; then
    mine="$mine $p"
    probs=$((probs + 1))
  fi
done

if [ "$probs" -eq 0 ] && [ -z "$slug" ]; then
  printf 'Define is done for %s. The next step is yours:\n' "$cycle"
  printf '  pick a theme, then: bin/next.sh %s <slug>\n' "$cycle"
  printf '\nA problem names which theme is being pursued. Scaffolding one without\n'
  printf 'that choice would be inventing the pick, which is the human gate.\n'
  exit 0
fi

if [ -z "$slug" ]; then
  printf 'Several problems exist. Say which: bin/next.sh %s <slug>\n' "$cycle"
  for p in $mine; do printf '%s\n' "$p" | sed 's|.*/|  |;s|\.md$||'; done
  exit 0
fi

# --- AN ARTIFACT BELONGS TO A (CYCLE, SLUG), NOT TO A SLUG ---------------------
#
# These three paths were `problems/$slug.md`, `options/$slug.md` and
# `decisions/$slug.md`. With a second cycle on disk, `bin/next.sh <new-cycle>
# <existing-slug>` reported "Nothing missing" because cycle one's three artifacts
# satisfied the chain — while `bin/cycle.sh` reported `problems 0 stated` for the same
# cycle at the same moment. Two tools contradicting each other, and the one a person
# follows was the wrong one.
#
# It is the normal path rather than a contrivance. `define-contract.md` open question 2
# contemplates a theme recurring next month as the same theme, and the
# `producing-themes` decision schedules a successor for 2026-11-30 — which was
# unrepresentable for the same reason. Neither is reachable at n=1.
#
# RESOLVED BY THE DECLARED LINKS, NOT BY A NAME. A problem belongs to this cycle when
# its `from:` names this cycle — the test the problem count above already uses, and the
# one bin/cycle.sh uses. Options belong to that problem when their `problem:` links
# that file, and a decision likewise. So the chain is followed rather than guessed from
# a filename, which is what makes the two tools agree.
#
# A RECURRENCE IS WRITTEN CYCLE-QUALIFIED. The first occurrence of a slug keeps the
# plain name, so the two shipped problems are untouched and nothing changes until a
# theme actually recurs; a second one is `<cycle>.<slug>.md`. That is the same
# qualifier `cycles/<cycle>.<method>.md` already uses for a comparison cycle: added
# only when it is needed to say which of two things this is.

# belongs_to <artifact> <field> <target> -> 0 if the field's link names the target
#
# Matched on the path fragment rather than on the bare basename, because a mention is
# not a link — the lesson the `amends` check paid for twice.
belongs_to() { grep -q "$2: .*$3" "$1" 2>/dev/null; }

# find_for <dir> <field> <target fragment> -> the one artifact in dir that links it
find_for() {
  local a
  for a in "$1"/*.md; do
    [ -f "$a" ] || continue
    belongs_to "$a" "$2" "$3" && { printf '%s' "$a"; return 0; }
  done
  return 1
}

# problem_for <cycle> <slug> -> the problem belonging to that PAIR
#
# Both halves are required. Matching the cycle alone returns whichever problem is
# alphabetically first among that cycle's — `agent-pr-approval` for a request about
# `producing-themes` — and matching the slug alone is the defect this replaces.
problem_for() {
  local a b
  for a in process/03-define/problems/*.md; do
    [ -f "$a" ] || continue
    b="$(basename "$a" .md)"
    [ "$b" = "$2" ] || [ "$b" = "$1.$2" ] || continue
    belongs_to "$a" from "cycles/$1.md" && { printf '%s' "$a"; return 0; }
  done
  return 1
}

# new_path <dir> <slug> -> where a new artifact for this cycle goes
new_path() {
  if [ -e "$1/$2.md" ]; then printf '%s/%s.%s.md' "$1" "$cycle" "$2"
  else printf '%s/%s.md' "$1" "$2"; fi
}

problem="$(problem_for "$cycle" "$slug" || true)"
if [ -z "$problem" ]; then
  c="process/03-define/define-contract.md"
  problem="$(new_path process/03-define/problems "$slug")"
  write_once "$problem" emit "$c" "Problem — $slug" \
"from: [\`$define\`](../cycles/$cycle.md)
status: defined, not solved" \
    '## Required fields — a problem'
  exit 0
fi

# --- develop ------------------------------------------------------------------
pbase="$(basename "$problem")"
options="$(find_for process/04-develop/options problem "problems/$pbase" || true)"
if [ -z "$options" ]; then
  c="process/04-develop/develop-contract.md"
  options="$(new_path process/04-develop/options "$slug")"
  write_once "$options" emit "$c" "Develop — $slug" \
"problem: [\`$problem\`](../../03-define/problems/$pbase)
status: options developed, none chosen"
  exit 0
fi

# --- deliver ------------------------------------------------------------------
obase="$(basename "$options")"
decision="$(find_for process/05-deliver/decisions problem "problems/$pbase" || true)"
if [ -z "$decision" ]; then
  c="process/05-deliver/deliver-contract.md"
  decision="$(new_path process/05-deliver/decisions "$slug")"
  write_once "$decision" emit "$c" "Decision — $slug" \
"problem: [\`$problem\`](../../03-define/problems/$pbase)
options: [\`$options\`](../../04-develop/options/$obase)
chosen: pending"
  exit 0
fi

# The files are NAMED, because "Nothing missing" over another cycle's artifacts is
# exactly the failure this section exists to stop, and a reader could not see it.
printf 'Nothing missing for %s/%s:\n' "$cycle" "$slug"
printf '  %s\n  %s\n  %s\n' "$problem" "$options" "$decision"
chosen=$(sed -n 's/^chosen:[[:space:]]*//p' "$decision" | head -1)
case "$chosen" in
  ""|pending|none) printf '\n%s is AWAITING A HUMAN. That one is not mine to write.\n' "$decision" ;;
esac
