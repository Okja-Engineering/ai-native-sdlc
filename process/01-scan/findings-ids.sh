#!/usr/bin/env bash
# The ids a findings file records, one per line, in table order.
#
# usage: process/01-scan/findings-ids.sh <findings file>
#
# WHY THIS IS A SCRIPT AND NOT A LINE IN EACH CALLER
#
# Three places counted the rows of a findings file, and none of the three agreed
# with the others:
#
#   bin/next.sh                        grep -cE '^\| [A-Z]'
#   bin/cycle.sh                       grep -cE '^\| F[0-9]+ \|'
#   process/03-define/validate-define.sh  grep -oE '^\| F[0-9]+ \|'
#
# The first is the expression findings-contract.md names as the one an external
# audit defeated: lowercasing a finding's first letter removed the row from the
# denominator. The other two are anchored, so they survive that, and both still
# read the WHOLE FILE — a markdown table anywhere else in it, which the findings
# contract permits inside `## Looked at`, is counted as findings. A file with two
# findings and one decoy table reported five.
#
# So the denominator is harvested in one place, read by everything that needs it.
# A caller that counts rows with its own regular expression is a second
# declaration of what a finding is, and this repository keeps being burnt by
# those.
#
# WHAT A FINDING IS, HERE
#
# A row inside the `## Findings` section whose `id` cell is exactly `F` plus a
# number. Three things that follow, each of them a way the old counters could be
# fooled:
#
#   * a table outside `## Findings` is not findings, however it is shaped
#   * an id in any cell other than `id` is a mention, not a row
#   * an id that is part of a larger cell — `see F03` — is a mention too
#
# The POSITION of the `id` cell is read from `findings-contract.md`, not fixed
# here. Adding `id` as the first column once shifted every index by one and the
# positional checks in validate-findings.sh then read the wrong cell for every
# check, producing four confident refusals that each named the wrong problem. The
# contract declares the column order; this asks it.
#
# WHAT THIS DOES NOT DO
#
# It does not validate anything. A row whose id cell is `f03`, or empty, is simply
# not an id and is not printed — `process/01-scan/validate-findings.sh` is what
# refuses that row, and it names the id cell when it does. Printing zero ids for a
# file full of malformed rows is the correct answer here and a refusal there.
#
# It also does not establish that the scan recorded everything that happened. The
# denominator is what the scan wrote down; nothing anchors it to the world.
#
# exit 0  printed the ids the file records — zero of them is a valid answer
# exit 2  could not run: no file, or the contract does not declare an id column
#
# Portability: bash 3.2, BSD and GNU userland. No -P, no in-place sed.
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTRACT="${FINDINGS_CONTRACT:-$SCRIPT_DIR/findings-contract.md}"

cannot_run() { printf 'findings-ids: %s\n' "$1" >&2; exit 2; }

[ "$#" -eq 1 ] || cannot_run "usage: findings-ids.sh <findings file>"
[ -f "$1" ] || cannot_run "no such findings file: $1"
[ -f "$CONTRACT" ] || cannot_run "the findings contract is missing at $CONTRACT, so the column order cannot be read — refusing to run rather than printing no ids"

# The 1-based position the CONTRACT gives a column. Empty when it declares none.
column_index() { # <column name>
  awk -v want="$1" '
    $0 == "<!-- contract:columns -->" { inside = 1; n = 0; next }
    $0 == "<!-- /contract:columns -->" { inside = 0 }
    inside && substr($0, 1, 2) == "- " {
      item = substr($0, 3)
      gsub(/`/, "", item)
      sub(/[[:space:]]+$/, "", item)
      if (item == "") next
      n++
      if (item == want) { print n; exit }
    }
  ' "$CONTRACT"
}

ID_COL="$(column_index id)"
[ -n "$ID_COL" ] || cannot_run "the contract's columns list declares no \`id\` column, so a finding cannot be identified — refusing to run rather than printing no ids"

# Cells are split the same way validate-findings.sh splits them, so the two
# cannot disagree about which cell is which: strip the leading and trailing pipe,
# then split on the remaining ones.
awk -v col="$ID_COL" '
  $0 ~ /^## Findings[[:space:]]*$/ { inside = 1; next }
  substr($0, 1, 3) == "## " { inside = 0 }
  inside && substr($0, 1, 1) == "|" {
    line = $0
    sub(/^[[:space:]]*\|/, "", line)
    sub(/\|[[:space:]]*$/, "", line)
    n = split(line, c, "|")
    if (col > n) next
    v = c[col]
    sub(/^[[:space:]]+/, "", v)
    sub(/[[:space:]]+$/, "", v)
    if (v ~ /^F[0-9]+$/) print v
  }
' "$1"
