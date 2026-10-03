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

# A name is a person — and the only way to check that mechanically is to
# enumerate the people. DECIDERS.md is that list.
#
# This replaced a DENYLIST: an anchored exact match against twenty words like
# `team`, `reviewer`, `claude`, `bot`. An external audit walked through it:
#
#   decided_by: the Platform Engineering Team  ->  within the contract
#   decided_by: Claude Opus 5                  ->  within the contract
#
# Any multi-word role and any model with a version number passed. Widening the
# list would not have fixed it — the set of things that are not a person is
# unbounded, so a denylist fails OPEN and every miss is silent.
#
# The tests that were supposed to catch this asserted the three literal strings
# the regex was written for. They proved the list contained three words; they
# never pinned the invariant. That is the finding this change exists for, and it
# is why the new tests use inputs chosen to sit outside the implementation.
#
# The denylist is kept only to give a clearer message for the obvious cases. It
# is advisory: the allowlist is what decides.
DECIDERS="${DECIDERS_FILE:-$ROOT/DECIDERS.md}"
OBVIOUSLY_NOT_A_PERSON='(^|[^a-z])(team|group|everyone|owner|reviewer|maintainer|claude|gpt|codex|copilot|agent|bot|assistant|automation|llm|model)([^a-z]|$)'

# authorized <name> -> 0 if the name is a listed decider
authorized() {
  [ -f "$DECIDERS" ] || return 1
  grep -oE '^\| [^|]+ \|' "$DECIDERS" 2>/dev/null \
    | sed -e 's/^| *//' -e 's/ *|$//' \
    | grep -qxF "$1"
}

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
  elif ! authorized "$decided"; then
    # Two messages for one refusal code, because the fix differs. A role or a
    # model name is wrong and needs replacing; a real person's name just is not
    # on the list yet, and adding them is a reviewable change to DECIDERS.md.
    if printf '%s' "$decided" | tr 'A-Z' 'a-z' | grep -Eq "$OBVIOUSLY_NOT_A_PERSON"; then
      refuse "$f" "${ln:--}" "not-a-person" \
        "decided_by is \"$decided\", which is a role or a machine, not a named person. A decision is made by someone listed in DECIDERS.md"
    else
      refuse "$f" "${ln:--}" "not-a-person" \
        "decided_by is \"$decided\", who is not listed in DECIDERS.md: if that is a real person authorized to decide, add them there — the list is the control, and adding to it is meant to be an explicit change"
    fi
  fi

  ln="$(line_of "$f" dated)"
  [ -n "$dated" ] || refuse "$f" "${ln:--}" "undated-decision" \
    "chosen is '$chosen' but dated is empty: when a person decided is part of the record"

  # --- the stated problem must be linked ---------------------------------
  # deliver-contract.md requires `problem:` and nothing read it. Deleting the
  # line from a decision record left the gate reporting the file within the
  # contract — the decision-to-problem edge of the chain had no check at all,
  # and CONTROLS.md did not disclose that. Found by the external audit in #22.
  local prob prob_path prob_resolved
  prob="$(field "$f" problem)"
  if [ -z "$prob" ]; then
    refuse "$f" "-" "no-problem-link" \
      "no problem: field — a decision records the problem it decided, or it is an answer with no question"
  else
    prob_path="$(printf '%s' "$prob" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
    if [ -z "$prob_path" ]; then
      refuse "$f" "-" "problem-not-linked" \
        "problem: names something but does not link it, so the problem cannot be read from the decision"
    else
      prob_resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$prob_path")" 2>/dev/null && pwd)/$(basename "$prob_path")"
      [ -f "$prob_resolved" ] || refuse "$f" "-" "problem-unresolved" \
        "the declared problem does not resolve: $prob_path"
    fi
  fi

  # --- the chosen option must exist --------------------------------------
  #
  # These used to `return` on their own refusals, which made check_amends
  # unreachable for any record with no resolvable options link — a record could
  # be missing both and only hear about one. The amends check is independent of
  # the options check, so it runs either way now.
  local opts_ok=1 opts_path=""
  case "$opts" in
    *"]("*) opts_path="$(printf '%s' "$opts" | sed -n 's/.*](\([^)]*\)).*/\1/p')" ;;
    "") : ;;
    *) opts_path="$opts" ;;
  esac
  if [ -z "$opts_path" ]; then
    refuse "$f" "-" "no-options-link" "chosen is '$chosen' but no options set is declared to have chosen from"
    opts_ok=0
  fi
  if [ "$opts_ok" -eq 1 ]; then
    local resolved; resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$opts_path")" 2>/dev/null && pwd)/$(basename "$opts_path")"
    if [ ! -f "$resolved" ]; then
      refuse "$f" "-" "options-unresolved" "the declared option set does not resolve: $opts_path"
    elif ! grep -qE "^## $chosen · " "$resolved"; then
      refuse "$f" "-" "chosen-not-an-option" \
        "chosen is '$chosen', which is not an option in $(basename "$resolved"): if the right answer was not developed, go back to Develop"
    fi
  fi

  check_amends "$f"
}

# A decision that changes how we work has to land somewhere. This repository's
# stated output is a change to our standards, and for five phases nothing
# carried a decision to the document — the link lived in the head of whoever
# had just made the call.
#
# `amends:` is that link, checked in BOTH directions. A one-way pointer is the
# same duplicated-declaration failure this repository keeps finding: the
# standard would say one thing, the decision another, and nothing would notice.
#
# `amends: none` is valid and expected. A decision to measure rather than act
# changes nothing about how we work, and saying so is what makes the absence
# visible instead of indistinguishable from an omission.
check_amends() { # file
  local f="$1" amends target resolved first rest back back_target back_resolved
  amends="$(field "$f" amends)"

  if [ -z "$amends" ]; then
    refuse "$f" "-" "no-amends" \
      "a decided record declares amends: — the document it changes, or 'none' with the reason nothing changed. The stated output of this repository is a change to our standards, and an unlinked decision never reaches one"
    return
  fi

  # `none` has to be the WHOLE first word, followed by a reason. The previous
  # version matched the prefix `none*`, so `amends: nonetheless, we decided not
  # to say where this lands` was accepted as a declaration that nothing changed.
  # Found by the external audit in #22.
  first="$(printf '%s' "$amends" | awk '{print tolower($1)}' | tr -d '.,;:')"
  if [ "$first" = none ]; then
    rest="$(printf '%s' "$amends" | sed -e 's/^[Nn]one//' -e 's/^[[:punct:][:space:]]*//')"
    if [ "${#rest}" -lt 10 ]; then
      refuse "$f" "-" "bare-none-amends" \
        "amends: none needs the reason nothing changed, otherwise it cannot be told apart from an oversight"
    fi
    return
  fi

  target="$(printf '%s' "$amends" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
  if [ -z "$target" ]; then
    refuse "$f" "-" "amends-not-linked" \
      "amends: names something but does not link it, so nothing can verify the change landed"
    return
  fi

  resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "amends-unresolved" "the amended document does not resolve: $target"
    return
  fi

  # The other direction. Without this the pair is one assertion, not two halves
  # that agree.
  #
  # This was `grep -q "$(basename "$f")"` — a bare filename match anywhere in the
  # file. An external audit replaced the `decided:` link with the sentence "A
  # note: the file agent-pr-approval.md exists somewhere in this repository" and
  # the gate reported the pair reciprocated. A mention is not a link.
  #
  # What is required now is a `decided:` line carrying a markdown link whose
  # target resolves back to THIS record. Same two-way discipline the `from:`
  # check in Define already uses.
  back="$(sed -n 's/^decided:[[:space:]]*//p' "$resolved" | head -1)"
  if [ -z "$back" ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") carries no 'decided:' line: an amended claim links back to the record that changed it, or the grade on that claim is unsupported"
    return
  fi

  back_target="$(printf '%s' "$back" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
  if [ -z "$back_target" ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") mentions a decision but does not link it: a filename in prose is not a link, and the pair cannot be verified from a mention"
    return
  fi

  back_resolved="$(cd "$(dirname "$resolved")" && cd "$(dirname "$back_target")" 2>/dev/null && pwd)/$(basename "$back_target")"
  if [ ! -f "$back_resolved" ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") links a decision that does not resolve: $back_target"
  elif [ "$(cd "$(dirname "$f")" && pwd)/$(basename "$f")" != "$back_resolved" ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") links back to $(basename "$back_resolved"), not to $(basename "$f"): the two halves name different records, which is the disagreement this check exists to catch"
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
