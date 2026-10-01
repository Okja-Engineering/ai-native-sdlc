#!/usr/bin/env bash
# The Define checks that do not depend on a cycle's shape.
#
# usage: process/03-define/validate-define.sh [file ...]
#        process/03-define/validate-define.sh          # every cycle file
#
# define-contract.md names five checks and defers them until a second cycle
# shows which parts are shape and which are this cycle's accidents. Three of
# them do not depend on shape at all and are built here:
#
#   1. every item in the source artifact is accounted for — under a theme or
#      in the outliers. This one already caught a real defect by hand: the
#      first draft of cycle 2026-09-29 themed 54 of 64 and reported three wrong
#      counts, and the ten strays included a pattern nobody had named.
#   2. the outlier section exists, and says so explicitly when empty — an
#      empty list and an omitted list look identical otherwise.
#   3. `method` is declared — a reader must know whether themes came from a
#      person, a model or a classifier before trusting the grouping.
#
# Deferred, because they do depend on shape: "every theme carries a name, a
# count and a why" (theme formatting may differ by cycle) and "no decision
# language" (needs a second cycle to know the vocabulary).
#
# exit 0  every file checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CYCLES="${DEFINE_CYCLES_DIR:-$SCRIPT_DIR/cycles}"

refusals=0

refuse() { printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2; refusals=$((refusals + 1)); }
field()  { sed -n "s/^$2:[[:space:]]*//p" "$1" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//'; }

check_cycle() {
  local f="$1" src src_path resolved claimed source_rows themes outliers

  # --- method is declared -------------------------------------------------
  if [ -z "$(field "$f" method)" ]; then
    refuse "$f" "-" "no-method" \
      "method is not declared: a reader must know whether themes came from a person, a model or a classifier before trusting the grouping"
  fi

  # --- the outlier section exists ----------------------------------------
  if ! grep -q '^## Outliers' "$f"; then
    refuse "$f" "-" "no-outlier-section" \
      "no Outliers section: an empty outlier list and an omitted one look identical, so an empty one must say so"
  else
    outliers=$(sed -n '/^## Outliers/,/^---/p' "$f" | grep -cE '^- \*\*')
    if [ "$outliers" -eq 0 ] && ! sed -n '/^## Outliers/,/^---/p' "$f" | grep -qiE 'none|empty|nothing'; then
      refuse "$f" "-" "silent-empty-outliers" \
        "the Outliers section lists nothing and does not say it is empty"
    fi
  fi
  outliers=$(sed -n '/^## Outliers/,/^---/p' "$f" 2>/dev/null | grep -cE '^- \*\*')

  # --- every source item accounted for ------------------------------------
  src="$(field "$f" from)"
  src_path="$(printf '%s' "$src" | sed -n 's/.*](\([^)]*\)).*/\1/p')"
  if [ -z "$src_path" ]; then
    refuse "$f" "-" "no-source" "from: does not link a source artifact, so nothing can be accounted for"
    return
  fi
  resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$src_path")" 2>/dev/null && pwd)/$(basename "$src_path")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "source-unresolved" "the declared source does not resolve: $src_path"
    return
  fi

  source_rows=$(grep -cE '^\| [A-Z]' "$resolved")
  themes=$(grep -oE '^\*\*[0-9]+ findings' "$f" | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')
  claimed=$((themes + outliers))

  if [ "$claimed" -ne "$source_rows" ]; then
    refuse "$f" "-" "unaccounted" \
      "themes ($themes) plus outliers ($outliers) is $claimed, but the source has $source_rows: a theme is a summary, not a filter, and nothing may be dropped"
  fi
}

main() {
  local files=0
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do
      [ -f "$f" ] || { printf 'validate-define: no such file: %s\n' "$f" >&2; exit 2; }
      files=$((files + 1)); check_cycle "$f"
    done
  else
    [ -d "$CYCLES" ] || { printf 'validate-define: no cycles directory: %s\n' "$CYCLES" >&2; exit 2; }
    for f in "$CYCLES"/*.md; do
      [ -f "$f" ] || continue
      files=$((files + 1)); check_cycle "$f"
    done
  fi

  if [ "$refusals" -gt 0 ]; then
    printf 'validate-define: %s refusal(s) across %s file(s)\n' "$refusals" "$files" >&2
    exit 1
  fi
  printf 'validate-define: %s file(s) within the contract\n' "$files"
}

main "$@"
