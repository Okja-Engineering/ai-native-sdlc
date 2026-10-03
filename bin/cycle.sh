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

count_rows()   { grep -cE '^\| F[0-9]+ \|' "$1" 2>/dev/null || echo 0; }
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
  local probs; probs=$(ls process/03-define/problems/*.md 2>/dev/null | wc -l | tr -d ' ')
  printf '%s   problems  %s stated\n' "$no" "$probs"

  local any=0
  for p in process/03-define/problems/*.md; do
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

  for f in process/01-scan/findings/*.md; do
    [ -f "$f" ] || continue
    local c; c=$(basename "$f" .md)
    grep -q '^example: yes' "$f" 2>/dev/null && continue
    [ -n "$want" ] && [ "$want" != "$c" ] && continue
    found=1
    cycle_report "$c"
  done

  if [ -n "$want" ] && [ "$found" -eq 0 ]; then
    printf 'no cycle %s\n' "$want" >&2; exit 1
  fi

  [ -n "$want" ] && return 0

  local topics=0
  for t in process/02-discover/topics/*.md; do
    [ -f "$t" ] || continue
    [ "$topics" -eq 0 ] && printf '\ntopics\n'
    topics=1
    printf '%s02 discover  %s\n' "$ok" "$(basename "$t" .md)"
  done

  printf '\n'
}

main "$@"
