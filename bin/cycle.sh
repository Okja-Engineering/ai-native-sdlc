#!/usr/bin/env bash
# Where is everything, and what is missing.
#
# usage: bin/cycle.sh            # every cycle and topic
#        bin/cycle.sh <cycle>    # one cycle, e.g. 2026-09-29
#
# Reads the tree. Writes nothing. Infers nothing that is not on disk — a phase
# is present because its file exists, not because a register says so, so this
# cannot drift from the thing it describes.
#
# Portability: bash 3.2, BSD and GNU userland.
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT" || exit 2

ok="  ok "; no="  -- "; miss="  !! "

# What a finding is, is stage 1's declaration, and this used to carry its own copy
# of it: `grep -cE '^\| F[0-9]+ \|'`. Anchored, so it survived the lowercasing
# exploit, and it read the WHOLE file — so a markdown table anywhere in a findings
# file was reported as findings. findings-contract.md permits content in
# `## Looked at`, and a contract-valid file with two findings and one table of
# unreached ground there was reported as four. The report and the Define gate now
# read the same harvester, so they cannot disagree about a cycle's size.
IDS="process/01-scan/findings-ids.sh"
[ -f "$IDS" ] || {
  printf 'cycle: no findings id harvester at %s — a report with its own idea of what a finding is was how this over-counted, so it will not run without it\n' "$IDS" >&2
  exit 2
}

# `?`, not 0, when the harvester cannot answer. Zero is a real and valid count — a
# cycle that found nothing — so reporting it for a cycle nobody could read would
# say the scan was quiet when the truth is that nothing was measured. That is the
# same shape as a gate reporting a clean tree having evaluated nothing.
count_rows() {
  local ids
  ids=$(bash "$IDS" "$1" 2>/dev/null) || { printf '%s\n' '?'; return; }
  printf '%s\n' "$ids" | grep -c .
}
count_themes() { grep -cE '^### [0-9]+ · ' "$1" 2>/dev/null || echo 0; }
count_opts()   { grep -cE '^## [A-F] · ' "$1" 2>/dev/null || echo 0; }
count_outl()   { sed -n '/## Outliers/,/^---/p' "$1" 2>/dev/null | grep -cE '^- \*\*' || echo 0; }

cycle_report() {
  local c="$1" f d dv dl n t o
  printf '\n%s\n' "$c"

  f="process/01-scan/findings/$c.md"
  if [ -f "$f" ]; then
    n=$(count_rows "$f")
    printf '%s01 scan      %s findings\n' "$ok" "$n"
  else
    printf '%s01 scan      no findings file\n' "$miss"; return
  fi

  d="process/03-define/cycles/$c.md"
  if [ -f "$d" ]; then
    t=$(count_themes "$d"); o=$(count_outl "$d")
    printf '%s03 define    %s themes, %s outliers\n' "$ok" "$t" "$o"
  else
    printf '%s03 define    not converged — %s findings unread\n' "$miss" "$n"
    return
  fi

  # A problem is the bridge from a theme to Develop. Zero is a valid state:
  # it means the human has not picked a theme to pursue yet.
  # Problems are filtered by the cycle their own `from:` field names. The first
  # version globbed every problem into every cycle's report, so with two cycles
  # it would have attributed both problems to both — a defect the code had never
  # run against, since only one cycle exists. Derived from the artifact rather
  # than from a new field: `problems/*.md` already carry
  # `from: [../cycles/<cycle>.md]`.
  local mine="" probs=0
  for p in process/03-define/problems/*.md; do
    [ -f "$p" ] || continue
    if grep -q "cycles/$c\.md" "$p" 2>/dev/null; then
      mine="$mine $p"; probs=$((probs + 1))
    fi
  done
  printf '%s   problems  %s stated\n' "$no" "$probs"

  local any=0
  for p in $mine; do
    [ -f "$p" ] || continue
    any=1
    local slug; slug=$(basename "$p" .md)
    dv="process/04-develop/options/$slug.md"
    dl="process/05-deliver/decisions/$slug.md"
    if [ -f "$dv" ]; then
      printf '%s04 develop   %s: %s options\n' "$ok" "$slug" "$(count_opts "$dv")"
    else
      printf '%s04 develop   %s: no options\n' "$miss" "$slug"
      continue
    fi
    if [ -f "$dl" ]; then
      local chosen; chosen=$(grep -m1 '^chosen:' "$dl" 2>/dev/null | sed 's/^chosen: *//')
      case "$chosen" in
        ""|"none"|"pending")
          printf '%s05 deliver   %s: AWAITING A HUMAN — %s options open\n' "$miss" "$slug" "$(count_opts "$dv")" ;;
        *) printf '%s05 deliver   %s: chose %s\n' "$ok" "$slug" "$chosen" ;;
      esac
    else
      printf '%s05 deliver   %s: no decision record\n' "$miss" "$slug"
    fi
  done
  [ "$any" -eq 1 ] || printf '%s04 develop   nothing to develop until a theme is picked\n' "$no"
}

main() {
  local want="${1:-}" found=0

  # An example file is not reported as a cycle, but the skip is ANNOUNCED. The
  # first version skipped silently, and an external audit inserted `example: yes`
  # into the only real findings file: the cycle, its 64 findings, its themes and
  # both decisions vanished from this report with no refusal anywhere, and both
  # gates still passed. A status tool that can lose a cycle to a two-word edit
  # without saying so is worse than none.
  local skipped=""
  for f in process/01-scan/findings/*.md; do
    [ -f "$f" ] || continue
    local c; c=$(basename "$f" .md)
    if grep -q '^example: yes' "$f" 2>/dev/null; then
      skipped="$skipped $c"
      continue
    fi
    [ -n "$want" ] && [ "$want" != "$c" ] && continue
    found=1
    cycle_report "$c"
  done

  # Announcing the skip was the previous repair and it is not enough on its own.
  # What a reader was told is that a file is an example; what actually happened is
  # that a cycle's themes, its problems and its two decisions left the report. So
  # the Define cycles reading the file are named, because that is the
  # contradiction: a worked example cannot be a real cycle's source.
  # process/03-define/validate-define.sh refuses it. This says it.
  for s in $skipped; do
    printf '\n%s\n%sskipped     marked `example: yes`, so not reported as a cycle\n' "$s" "$no"
    local deps=""
    for d in process/03-define/cycles/*.md; do
      [ -f "$d" ] || continue
      grep -q "findings/$s\.md" "$d" 2>/dev/null && deps="$deps $(basename "$d" .md)"
    done
    [ -z "$deps" ] || printf '%s   define    cycle(s)%s reads it — a worked example cannot be a real source\n' \
      "$miss" "$deps"
  done

  if [ -n "$want" ] && [ "$found" -eq 0 ]; then
    printf 'no cycle %s\n' "$want" >&2; exit 1
  fi

  [ -n "$want" ] && return 0

  # Topics are reported by whether anything references them. The first version
  # printed them all under a bare `topics` heading with no linkage, which hid
  # that one of them is referenced by nothing at all — an orphan the status tool
  # listed as though it had a parent.
  #
  # A topic has no `from:` field of its own, so the link is read from the other
  # direction: a problem's `rests on:`. Stated rather than invented — giving
  # topics a parent field is a contract change, and this reports the gap instead
  # of papering over it.
  local topics=0 orphans=""
  for t in process/02-discover/topics/*.md; do
    [ -f "$t" ] || continue
    local slug; slug=$(basename "$t" .md)
    local ref; ref=$(grep -rl "topics/$slug\.md" process/03-define/problems/ 2>/dev/null | head -1)
    if [ -n "$ref" ]; then
      [ "$topics" -eq 0 ] && printf '\ntopics\n'
      topics=1
      printf '%s02 discover  %-22s rests under %s\n' "$ok" "$slug" "$(basename "$ref" .md)"
    else
      orphans="$orphans $slug"
    fi
  done

  for o in $orphans; do
    [ "$topics" -eq 0 ] && printf '\ntopics\n'
    topics=1
    printf '%s02 discover  %-22s referenced by no problem\n' "$miss" "$o"
  done

  printf '\n'
}

main "$@"
