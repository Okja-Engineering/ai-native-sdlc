#!/usr/bin/env bash
# The one Deliver gate judged worth having on n=1.
#
# usage: process/05-deliver/validate-decision.sh [file ...]
#        process/05-deliver/validate-decision.sh          # every decision record
#
# deliver-contract.md defers most of Deliver's shape to a second decision, and
# names exactly one check that does not depend on shape:
#
#   a record whose `chosen:` is anything but `pending` must carry a
#   `decided_by:` naming a person.
#
# It guards the only thing in this repository that cannot be reconstructed
# afterwards — whether a human actually chose. A machine filling both fields is
# the loop quietly closing itself, which is the failure the whole process
# exists to prevent.
#
# Two companion checks are included because they are equally shape-independent:
# a chosen option must exist in the option set it claims to choose from, and a
# decided record must be dated.
#
# exit 0  every record checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DECISIONS="${DECISIONS_DIR:-$SCRIPT_DIR/decisions}"

refusals=0

refuse() { # file line code message
  printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2
  refusals=$((refusals + 1))
}

field() { # file key -> value, first match, trimmed
  sed -n "s/^$2:[[:space:]]*//p" "$1" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//'
}

line_of() { grep -n "^$2:" "$1" 2>/dev/null | head -1 | cut -d: -f1; }

# A name is a person. Not a role, not a team, not an agent.
NOT_A_PERSON='^(the )?(team|group|us|we|everyone|owner|author|reviewer|maintainer|claude|gpt|codex|copilot|agent|bot|ai|assistant|system|automation)$'

check_record() {
  local f="$1" chosen decided dated opts ln
  chosen="$(field "$f" chosen)"
  decided="$(field "$f" decided_by)"
  dated="$(field "$f" dated)"
  opts="$(field "$f" options)"

  if ! grep -q '^chosen:' "$f"; then
    refuse "$f" "-" "no-chosen-field" "a decision record declares chosen:, even when it is pending"
    return
  fi

  # pending is a valid, expected state: the work is done and the gate is not passed.
  if [ -z "$chosen" ] || [ "$chosen" = "pending" ] || [ "$chosen" = "none" ]; then
    if [ -n "$decided" ]; then
      ln="$(line_of "$f" decided_by)"
      refuse "$f" "${ln:--}" "pending-but-decided" \
        "chosen is '$chosen' but decided_by names \"$decided\": a record cannot be both awaiting a human and decided"
    fi
    return
  fi

  # --- the gate the contract named ---------------------------------------
  ln="$(line_of "$f" decided_by)"
  if [ -z "$decided" ]; then
    refuse "$f" "${ln:--}" "undecided-by" \
      "chosen is '$chosen' but decided_by is empty: a decision is made by a human and the record names which one"
  elif printf '%s' "$decided" | tr 'A-Z' 'a-z' | grep -Eq "$NOT_A_PERSON"; then
    refuse "$f" "${ln:--}" "not-a-person" \
      "decided_by is \"$decided\", which is a role or a machine, not a named person"
  fi

  ln="$(line_of "$f" dated)"
  [ -n "$dated" ] || refuse "$f" "${ln:--}" "undated-decision" \
    "chosen is '$chosen' but dated is empty: when a person decided is part of the record"

  # --- the chosen option must exist --------------------------------------
  local opts_path=""
  case "$opts" in
    *"]("*) opts_path="$(printf '%s' "$opts" | sed -n 's/.*](\([^)]*\)).*/\1/p')" ;;
    "") : ;;
    *) opts_path="$opts" ;;
  esac
  if [ -z "$opts_path" ]; then
    refuse "$f" "-" "no-options-link" "chosen is '$chosen' but no options set is declared to have chosen from"
    return
  fi
  local resolved; resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$opts_path")" 2>/dev/null && pwd)/$(basename "$opts_path")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "options-unresolved" "the declared option set does not resolve: $opts_path"
    return
  fi
  if ! grep -qE "^## $chosen · " "$resolved"; then
    refuse "$f" "-" "chosen-not-an-option" \
      "chosen is '$chosen', which is not an option in $(basename "$resolved"): if the right answer was not developed, go back to Develop"
  fi
}

main() {
  local files=0
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do
      [ -f "$f" ] || { printf 'validate-decision: no such file: %s\n' "$f" >&2; exit 2; }
      files=$((files + 1)); check_record "$f"
    done
  else
    [ -d "$DECISIONS" ] || { printf 'validate-decision: no decisions directory: %s\n' "$DECISIONS" >&2; exit 2; }
    for f in "$DECISIONS"/*.md; do
      [ -f "$f" ] || continue
      files=$((files + 1)); check_record "$f"
    done
  fi

  if [ "$refusals" -gt 0 ]; then
    printf 'validate-decision: %s refusal(s) across %s file(s)\n' "$refusals" "$files" >&2
    exit 1
  fi
  printf 'validate-decision: %s file(s) within the contract\n' "$files"
}

main "$@"
