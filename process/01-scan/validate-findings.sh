#!/usr/bin/env bash
# The stage 1 gate: refuse a findings file that breaks the contract.
#
# usage: process/01-scan/validate-findings.sh [file ...]
#        process/01-scan/validate-findings.sh            # every file in findings/
#
# The shape of a findings file is declared in findings-contract.md and read from
# there — the lists below are not restated here, so the contract stays the one
# place the shape lives. If those declarations cannot be read, this script
# refuses to run rather than pass everything.
#
# exit 0  every file checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
#
# Portability: bash 3.2, BSD and GNU userland. No -P, no in-place sed.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTRACT="${FINDINGS_CONTRACT:-$SCRIPT_DIR/findings-contract.md}"
FINDINGS_DIR="${FINDINGS_DIR:-$SCRIPT_DIR/findings}"

# A document that DISPLAYS a declaration must not thereby SATISFY it.
#
# THIS GATE HAD NO FENCE AWARENESS ANYWHERE, across six machine-read contract lists,
# and that is finding 4 on #116. A fenced illustration naming a third section widened
# the closed set and `## What this means` — the heading findings-contract.md:40 says
# the gate refuses — then passed, exit 0. Reproduced before this change.
#
# bin/lib-rendering.sh holds the rule, the two projections and the cost of sharing it.
RENDERING="${RENDERING_LIB:-$SCRIPT_DIR/../../bin/lib-rendering.sh}"
if [ ! -f "$RENDERING" ]; then
  printf 'validate-findings: no rendering library at %s — without it a contract list shown to a reader would be read as a declaration of the rule, so this gate will not run\n' "$RENDERING" >&2
  exit 2
fi
. "$RENDERING"

refusals=0

# refuse <file> <line|-> <code> <message>
refuse() {
  if [ "$2" = "-" ]; then
    printf '%s: refuse[%s]: %s\n' "$1" "$3" "$4" >&2
  else
    printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2
  fi
  refusals=$((refusals + 1))
}

cannot_run() { # <message>
  printf '%s: refuse[contract-unreadable]: %s\n' "$CONTRACT" "$1" >&2
  exit 2
}

# ---------------------------------------------------------------- the contract

[ -f "$CONTRACT" ] || cannot_run "the findings contract is missing, so the gate has nothing to enforce"

# The contract as a reader sees it, read once. A block inside a fenced example, an
# indented block or an HTML comment is an illustration and is not here.
#
# The LINE projection, not the span one: every item in these blocks is written as
# `- `id``, in backticks, and blanking code spans would have emptied all six lists —
# which `require_list` turns into exit 2, so it would have been loud rather than a
# hole, but it would still have been wrong. Measured, not assumed.
CONTRACT_VIEW="$(rendered_lines_file "$CONTRACT")" || \
  cannot_run "the findings contract could not be read as rendered text"

# contract_list <block name> — the items declared in THE ONE machine-readable block.
#
# EXACTLY ONE BLOCK, IN A RENDERING CONTEXT. A second block used to be unioned with
# the first, silently: `inside` was simply set again, so two blocks declaring the same
# rule produced the union of them and nobody could tell which was the declaration.
# Combined with no fence awareness that was finding 4 on #116 — a fenced illustration
# naming a third section widened the closed set and the heading this contract says the
# gate refuses then passed.
#
# A rule declared twice is a rule that can drift, which is the duplicated-declaration
# failure this repository keeps finding. So two openers is a refusal to run rather
# than a merge: a gate that cannot tell which block is the declaration must say so.
contract_list() {
  printf '%s\n' "$CONTRACT_VIEW" | awk -v begins="<!-- contract:$1 -->" -v ends="<!-- /contract:$1 -->" '
    $0 == begins { seen++; inside = 1; next }
    $0 == ends { inside = 0 }
    inside && substr($0, 1, 2) == "- " {
      item = substr($0, 3)
      gsub(/`/, "", item)
      sub(/[[:space:]]+$/, "", item)
      if (item != "") print item
    }
    END { if (seen > 1) printf "!MORE-THAN-ONE-BLOCK %d\n", seen }
  '
}

require_list() { # <block name> <value>
  case "$2" in
    *'!MORE-THAN-ONE-BLOCK'*)
      cannot_run "the \"$1\" list is declared in more than one block, so the gate cannot tell which one is the rule — a rule declared twice is a rule that can drift, and the union of two is nobody's declaration. Delete the duplicate, or if one of them is showing a reader what the form looks like, put it inside a fenced block" ;;
  esac
  [ -n "$2" ] || cannot_run "the \"$1\" list is empty or missing, so the gate would pass everything — refusing to run"
}

COLUMNS_L="$(contract_list columns)"
KIND_L="$(contract_list kind)"
CONSEQUENCE_L="$(contract_list consequence)"
SOURCES_L="$(contract_list sources)"
SECTIONS_L="$(contract_list sections)"
VOCABULARY_L="$(contract_list assessment-vocabulary)"

require_list columns "$COLUMNS_L"
require_list kind "$KIND_L"
require_list consequence "$CONSEQUENCE_L"
require_list sources "$SOURCES_L"
require_list sections "$SECTIONS_L"
require_list assessment-vocabulary "$VOCABULARY_L"

# ------------------------------------------------------------------- utilities

trim() { printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'; }

in_list() { printf '%s\n' "$2" | grep -Fxq -- "$1"; }

list_item() { printf '%s\n' "$2" | sed -n "${1}p"; }

list_count() { printf '%s\n' "$1" | grep -c '' ; }

list_inline() { printf '%s\n' "$1" | tr '\n' ' ' | sed -e 's/[[:space:]]*$//'; }

# A real calendar date in YYYY-MM-DD, leap years included.
is_date() {
  [ -n "$1" ] || return 1
  printf '%s\n' "$1" | awk '
    {
      if ($0 !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) exit 1
      y = substr($0, 1, 4) + 0; m = substr($0, 6, 2) + 0; d = substr($0, 9, 2) + 0
      if (m < 1 || m > 12 || d < 1) exit 1
      split("31 28 31 30 31 30 31 31 30 31 30 31", len, " ")
      last = len[m] + 0
      if (m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)) last = 29
      if (d > last) exit 1
      exit 0
    }'
}

# VIEW is the findings file as a reader sees it, set once per file in validate_file.
# A field, a heading or a table row shown inside a fenced example is not one.
VIEW=""

# field_value <key> <file> — the first value of a `key: value` line.
field_value() {
  trim "$(printf '%s\n' "$VIEW" | sed -n "s/^$1:[[:space:]]*//p" | head -1)"
}

field_count() { printf '%s\n' "$VIEW" | grep -c "^$1:"; }

section_body() { # <file> <section name>
  printf '%s\n' "$VIEW" | awk -v h="## $2" '
    $0 == h { inside = 1; next }
    substr($0, 1, 3) == "## " { inside = 0 }
    inside { print }
  '
}

# cells_of <table row> — one `<index><tab><trimmed cell>` line per cell, so a
# trailing empty cell still occupies a line.
cells_of() {
  printf '%s\n' "$1" | awk '
    {
      line = $0
      sub(/^[[:space:]]*\|/, "", line)
      sub(/\|[[:space:]]*$/, "", line)
      n = split(line, c, "|")
      for (i = 1; i <= n; i++) {
        v = c[i]
        sub(/^[[:space:]]+/, "", v); sub(/[[:space:]]+$/, "", v)
        print i "\t" v
      }
    }'
}

cell() { printf '%s\n' "$2" | sed -n "${1}p" | cut -f2-; }

# col_index <column name> — the 1-based position the CONTRACT gives that column.
# Keeps the gate from carrying a second copy of the column order, which is the
# duplicate-declaration failure this repository keeps finding. A name the
# contract does not declare yields 0, and `cell 0` is empty, so a typo here
# surfaces as an empty-cell refusal rather than silently reading a neighbour.
col_index() { printf '%s\n' "$COLUMNS_L" | grep -nxF -- "$1" | cut -d: -f1; }

cell_count() { printf '%s\n' "$1" | grep -c ''; }

is_separator_row() {
  printf '%s\n' "$1" | grep -Eq '^[[:space:]]*\|([[:space:]]*:?-+:?[[:space:]]*\|)+[[:space:]]*$'
}

# A locator someone else could follow. Form only — nothing here resolves it.
source_ok() {
  printf '%s\n' "$1" | grep -Eq '^https?://[^[:space:]/]+\.[^[:space:]/]+' && return 0
  printf '%s\n' "$1" | grep -Eq '^doi:10\.[0-9]{4,}/[^[:space:]]+' && return 0
  printf '%s\n' "$1" | grep -Eiq '^arxiv:[0-9]{4}\.[0-9]{4,}' && return 0
  if printf '%s\n' "$1" | grep -Eq '^cite: .{12,}' &&
     printf '%s\n' "$1" | grep -Eq '[0-9]{4}'; then
    return 0
  fi
  return 1
}

# ----------------------------------------------------------------- file checks

check_filename() {
  local file="$1" base
  base="$(basename "$file")"
  if ! printf '%s\n' "$base" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$'; then
    refuse "$file" - filename "the name \"$base\" is not a cycle date: a findings file is <YYYY-MM-DD>.md, and the next cycle reads that name to find its anchor"
  elif ! is_date "${base%.md}"; then
    refuse "$file" - filename "the name \"$base\" is shaped like a date but is not one"
  fi
}

check_fields() {
  local file="$1" n value
  # since
  n="$(field_count since "$file")"
  if [ "$n" -eq 0 ]; then
    refuse "$file" - since "no \"since\" field: a cycle records the anchor it measured from, as a date or the words first run"
  else
    if [ "$n" -gt 1 ]; then
      refuse "$file" - field "the \"since\" field appears $n times; the contract declares it once"
    fi
    value="$(field_value since "$file")"
    if [ "$value" != "first run" ] && ! is_date "$value"; then
      refuse "$file" - since "since is \"$value\", which is neither a YYYY-MM-DD date nor the words first run"
    fi
  fi

  # nothing found
  n="$(field_count 'nothing found' "$file")"
  NOTHING_FOUND="missing"
  if [ "$n" -eq 0 ]; then
    refuse "$file" - nothing-found "no \"nothing found\" field: a cycle states whether it found nothing, because a silent file and an empty month read the same"
  else
    if [ "$n" -gt 1 ]; then
      refuse "$file" - field "the \"nothing found\" field appears $n times; the contract declares it once"
    fi
    NOTHING_FOUND="$(field_value 'nothing found' "$file")"
    case "$NOTHING_FOUND" in
      yes | no) ;;
      *) refuse "$file" - nothing-found "nothing found is \"$NOTHING_FOUND\"; the contract declares yes or no" ;;
    esac
  fi

  # example
  n="$(field_count example "$file")"
  if [ "$n" -gt 1 ]; then
    refuse "$file" - field "the \"example\" field appears $n times; the contract declares it once"
  fi
  if [ "$n" -ge 1 ]; then
    value="$(field_value example "$file")"
    case "$value" in
      yes | no) ;;
      *) refuse "$file" - field "the \"example\" field is \"$value\"; the contract declares yes or no" ;;
    esac
  fi
}

check_sections() {
  local file="$1" entry lno text
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    lno="${entry%%:*}"
    text="${entry#*:}"
    text="$(trim "${text#\#\# }")"
    if ! in_list "$text" "$SECTIONS_L"; then
      refuse "$file" "$lno" sections "\"$text\" is not a declared section; a stage 1 file carries only these: $(list_inline "$SECTIONS_L")"
    fi
  done < <(printf '%s\n' "$VIEW" | grep -n '^## ')
}

check_looked_at() {
  local file="$1" body src
  if ! printf '%s\n' "$VIEW" | grep -Eq '^## Looked at[[:space:]]*$'; then
    refuse "$file" - looked-at "no \"Looked at\" section: without the ground actually covered, a quiet cycle and a shallow one read the same"
    return
  fi
  body="$(section_body "$file" 'Looked at')"
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    refuse "$file" - looked-at "the \"Looked at\" section is empty: without the ground actually covered, a quiet cycle and a shallow one read the same"
    return
  fi
  while IFS= read -r src; do
    [ -n "$src" ] || continue
    if ! printf '%s\n' "$body" | grep -Eq "^- $src:[[:space:]]*[^[:space:]]"; then
      refuse "$file" - looked-at "the \"Looked at\" section has no line for the $src source; a source with no line hides whether it was covered at all"
    fi
  done < <(printf '%s\n' "$SOURCES_L")
}

check_no_judgment() {
  local file="$1" phrase hit lno
  while IFS= read -r phrase; do
    [ -n "$phrase" ] || continue
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      lno="${hit%%:*}"
      refuse "$file" "$lno" assessment "the words \"$phrase\" appear here: stage 1 records what happened and has no authority to judge what it means — that belongs to Discover, behind a human gate"
    done < <(grep -n -i -F -- "$phrase" "$file")
  done < <(printf '%s\n' "$VOCABULARY_L")
}

check_header_row() {
  local file="$1" lno="$2" row="$3" cells n want i got expected
  cells="$(cells_of "$row")"
  n="$(cell_count "$cells")"
  want="$(list_count "$COLUMNS_L")"
  if [ "$n" -ne "$want" ]; then
    refuse "$file" "$lno" columns "the findings table has $n columns; the contract declares $want: $(list_inline "$COLUMNS_L") — a finding carries those and nothing more"
    return
  fi
  i=1
  while [ "$i" -le "$want" ]; do
    got="$(cell "$i" "$cells")"
    expected="$(list_item "$i" "$COLUMNS_L")"
    if [ "$got" != "$expected" ]; then
      refuse "$file" "$lno" columns "column $i is \"$got\"; the contract declares \"$expected\""
    fi
    i=$((i + 1))
  done
}

check_finding_row() {
  local file="$1" lno="$2" row="$3"
  local cells n want id what src dated kind affect consequence
  cells="$(cells_of "$row")"
  n="$(cell_count "$cells")"
  want="$(list_count "$COLUMNS_L")"
  if [ "$n" -ne "$want" ]; then
    refuse "$file" "$lno" columns "this finding has $n cells; the contract declares $want columns"
    return
  fi
  # Cells are resolved by COLUMN NAME, read from the contract, not by a fixed
  # position. Adding `id` as the first column shifted every index by one, and the
  # positional version then read the wrong cell for every check — `source` got
  # the what text, `dated` got the URL — producing four confident refusals that
  # each named the wrong problem. The contract declares the order; the gate asks
  # it rather than assuming it.
  id="$(cell "$(col_index id)" "$cells")"
  what="$(cell "$(col_index what)" "$cells")"
  src="$(cell "$(col_index source)" "$cells")"
  dated="$(cell "$(col_index dated)" "$cells")"
  kind="$(cell "$(col_index kind)" "$cells")"
  affect="$(cell "$(col_index 'might affect (guess)')" "$cells")"
  consequence="$(cell "$(col_index 'consequence guess')" "$cells")"

  if ! printf '%s' "$id" | grep -qE '^F[0-9]+$'; then
    refuse "$file" "$lno" id "the id cell is \"$id\"; an id is F followed by a number — Define accounts for findings by id, and a row without one cannot be accounted for"
  fi

  if [ -z "$what" ]; then
    refuse "$file" "$lno" field "the what cell is empty; a row that does not say what happened is not a record of anything"
  fi

  if [ -z "$src" ]; then
    refuse "$file" "$lno" no-source "this finding carries no source, so it is not a finding — no source, no finding"
  elif ! source_ok "$src"; then
    refuse "$file" "$lno" no-source "the source \"$src\" is not a resolvable-looking locator, so this is not a finding — no source, no finding. The contract accepts a URL, a doi:, an arXiv id, or cite: with a year"
  fi

  if [ -z "$dated" ]; then
    refuse "$file" "$lno" dated "this finding has no dated cell; when the thing happened is part of the record"
  elif ! is_date "$dated"; then
    refuse "$file" "$lno" dated "dated is \"$dated\", which is not a calendar date in YYYY-MM-DD"
  fi

  if ! in_list "$kind" "$KIND_L"; then
    refuse "$file" "$lno" kind "kind is \"$kind\", which is outside the declared list: $(list_inline "$KIND_L")"
  fi

  if [ -z "$affect" ]; then
    refuse "$file" "$lno" field "the might affect cell is empty; an unlabelled blank is not the same as a stated guess"
  fi

  if ! in_list "$consequence" "$CONSEQUENCE_L"; then
    refuse "$file" "$lno" consequence "consequence guess is \"$consequence\", which is outside the declared list: $(list_inline "$CONSEQUENCE_L")"
  fi
}

check_findings_table() {
  local file="$1" table entry lno row seen_header
  FINDINGS_COUNT=0
  printf '%s\n' "$VIEW" | grep -Eq '^## Findings[[:space:]]*$' || return 0
  table="$(awk '
    $0 ~ /^## Findings[[:space:]]*$/ { inside = 1; next }
    substr($0, 1, 3) == "## " { inside = 0 }
    inside && substr($0, 1, 1) == "|" { printf "%d:%s\n", NR, $0 }
  ' <<EOF
$VIEW
EOF
)"
  seen_header=0
  while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    lno="${entry%%:*}"
    row="${entry#*:}"
    if [ "$seen_header" -eq 0 ]; then
      seen_header=1
      check_header_row "$file" "$lno" "$row"
      continue
    fi
    is_separator_row "$row" && continue
    FINDINGS_COUNT=$((FINDINGS_COUNT + 1))
    check_finding_row "$file" "$lno" "$row"
  done < <(printf '%s\n' "$table")
}

check_outcome() {
  local file="$1"
  if [ "$FINDINGS_COUNT" -eq 0 ] && [ "$NOTHING_FOUND" != "yes" ]; then
    refuse "$file" - empty-cycle "this cycle carries neither a finding nor an explicit \"nothing found: yes\" — a cycle that found nothing has to say so, because a scan that was skipped looks identical"
  fi
  if [ "$FINDINGS_COUNT" -gt 0 ] && [ "$NOTHING_FOUND" = "yes" ]; then
    refuse "$file" - contradiction "\"nothing found: yes\" but the file carries $FINDINGS_COUNT findings"
  fi
}

validate_file() {
  NOTHING_FOUND="missing"
  FINDINGS_COUNT=0
  # Read once, in the LINE projection: everything this gate reads out of a findings
  # file is line-shaped — a field, a heading, a table row — and the cells are written
  # in backticks, so blanking code spans would read every source cell as empty.
  VIEW="$(rendered_lines_file "$1")" || {
    printf 'validate-findings: %s could not be read as rendered text\n' "$1" >&2
    refusals=$((refusals + 1))
    return
  }
  check_filename "$1"
  check_fields "$1"
  check_sections "$1"
  check_looked_at "$1"
  check_findings_table "$1"
  check_outcome "$1"
  check_no_judgment "$1"
}

# ------------------------------------------------------------------------ main

checked=0

if [ "$#" -gt 0 ]; then
  for target in "$@"; do
    if [ ! -f "$target" ]; then
      printf 'validate-findings: no such file: %s\n' "$target" >&2
      refusals=$((refusals + 1))
      continue
    fi
    checked=$((checked + 1))
    validate_file "$target"
  done
else
  if [ ! -d "$FINDINGS_DIR" ]; then
    printf 'validate-findings: no findings directory at %s\n' "$FINDINGS_DIR" >&2
    exit 2
  fi
  for target in "$FINDINGS_DIR"/*.md; do
    [ -f "$target" ] || continue
    checked=$((checked + 1))
    validate_file "$target"
  done
  if [ "$checked" -eq 0 ]; then
    printf 'validate-findings: %s holds no cycle files — this would be a first run\n' "$FINDINGS_DIR"
  fi
fi

plural() { # <count> <singular> <plural>
  if [ "$1" -eq 1 ]; then printf '%s' "$2"; else printf '%s' "$3"; fi
}

if [ "$refusals" -ne 0 ]; then
  printf 'validate-findings: %d %s across %d %s\n' \
    "$refusals" "$(plural "$refusals" refusal refusals)" \
    "$checked" "$(plural "$checked" file files)" >&2
  exit 1
fi

# A run that read no file does not get to report conformance. This printed the
# first-run note AND "0 files within the contract" on the same run, and the second
# line declares every file it never read to be within the contract. The note is the
# honest half and stays; the claim goes. The other three process gates made the
# same claim with no note at all.
if [ "$checked" -eq 0 ]; then
  printf 'validate-findings: nothing was checked\n'
  exit 0
fi

printf 'validate-findings: %d %s within the contract\n' \
  "$checked" "$(plural "$checked" file files)"
exit 0
