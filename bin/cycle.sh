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
# `grep -c` ALREADY prints 0 and exits 1 when nothing matches, so `|| echo 0`
# printed a SECOND zero and the caller interpolated both: a cycle with no themes
# reported `0\n0 themes, 0\n0 outliers` across four lines. Unreachable while the
# only cycle in the tree had seven themes, and reachable the moment bin/next.sh
# scaffolds a cycle for a new date — which it now does with a Themes skeleton
# nobody has filled in. The count is grep's, and the default is applied to an
# unset value rather than printed alongside one.
count() { local n; n=$(grep -cE "$1" "$2" 2>/dev/null); printf '%s\n' "${n:-0}"; }
count_themes() { count '^### [0-9]+ · ' "$1"; }
count_opts()   { count '^## [A-F] · ' "$1"; }
count_outl()   { local n; n=$(sed -n '/## Outliers/,/^---/p' "$1" 2>/dev/null | grep -cE '^- \*\*'); printf '%s\n' "${n:-0}"; }

# field <file> <key> -> the first value outside a fenced block, trimmed.
#
# Fences are skipped for the reason process/03-define/validate-define.sh gives:
# a document showing what a field looks like donated the example as the value.
# `index` rather than a regex, because a key can contain a space and a key is not
# a pattern.
field() {
  awk -v key="$2" '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v; exit
    }
  ' "$1" 2>/dev/null
}

# The field a cycle records its convergence duration in. The `producing-themes`
# decision commits to recording it over two more cycles and no gate reads it, so
# this report is the only place a person sees it.
#
# The name is written here AND checked against the contract below. A report that
# hardcodes a field name goes on printing "not recorded" after a rename, which is
# a false statement about an artifact that does record one — so the drift is made
# loud rather than left silent.
DEFINE_CONTRACT="process/03-define/define-contract.md"
DURATION_FIELD="pass took"
duration_declared=unknown
if [ -f "$DEFINE_CONTRACT" ]; then
  if sed -n '/^## Required fields$/,/^## /p' "$DEFINE_CONTRACT" \
     | grep -q "^| \`$DURATION_FIELD\` |"; then
    duration_declared=yes
  else
    duration_declared=no
  fi
fi

# pass_duration <cycle file> -> what to print about the duration.
#
# Three states, and all three are said out loud. A blank would read as a pass
# that took no time, and an omitted phrase as a cycle nobody asked about.
pass_duration() {
  local v
  v="$(field "$1" "$DURATION_FIELD")"
  if [ -n "$v" ]; then
    printf '%s %s\n' "$DURATION_FIELD" "$v"
  else
    printf '%s — not recorded\n' "$DURATION_FIELD"
  fi
}

# field <file> <key> -> the first value outside a fenced block, trimmed.
#
# Fences are skipped for the reason process/03-define/validate-define.sh gives:
# a document showing what a field looks like donated the example as the value.
# `index` rather than a regex, because a key can contain a space and a key is not
# a pattern.
field() {
  awk -v key="$2" '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v; exit
    }
  ' "$1" 2>/dev/null
}

# --- dates --------------------------------------------------------------------
#
# PORTABILITY, WHICH IS THE WHOLE DIFFICULTY HERE. `date -d` is a GNU extension
# and `date -r` means two different things on the two userlands, so neither can
# convert a `YYYY-MM-DD` string to a number on both legs of CI. Nothing below
# asks `date` to parse anything: the only call is `date +%Y-%m-%d`, which POSIX
# specifies, and every comparison is integer arithmetic on the date's own digits.
#
# day_number is Howard Hinnant's days_from_civil. Verified against an independent
# oracle for the dates a naive version gets wrong — leap days, century years, the
# epoch and before it — and the suite drives the same code on both legs.
#
# `10#` forces base ten. Bash reads a leading zero as octal, so without it
# `$((09))` is an error and every date in September would have failed.
day_number() { # YYYY-MM-DD -> days since 1970-01-01, or exit 1 if it is not a date
  case "$1" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
    *) return 1 ;;
  esac
  local s="$1" y m d dim era yoe doy doe rest
  y=$((10#${s%%-*})); rest="${s#*-}"
  m=$((10#${rest%%-*})); d=$((10#${rest#*-}))
  [ "$m" -ge 1 ] && [ "$m" -le 12 ] || return 1
  # The day is checked against the month's own length, leap year included. Without
  # this, `2027-02-31` is three days into March and the report quietly counts from
  # a date that does not exist.
  dim=31
  case "$m" in
    4|6|9|11) dim=30 ;;
    2) dim=28
       if [ $((y % 4)) -eq 0 ] && { [ $((y % 100)) -ne 0 ] || [ $((y % 400)) -eq 0 ]; }; then
         dim=29
       fi ;;
  esac
  [ "$d" -ge 1 ] && [ "$d" -le "$dim" ] || return 1
  y=$((y - (m <= 2 ? 1 : 0)))
  era=$(( (y >= 0 ? y : y - 399) / 400 ))
  yoe=$(( y - era * 400 ))
  doy=$(( (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1 ))
  doe=$(( yoe * 365 + yoe / 4 - yoe / 100 + doy ))
  printf '%s\n' $(( era * 146097 + doe - 719468 ))
}

# `CYCLE_TODAY` is how the suite drives fixed dates through the arithmetic above.
# A report that reads the wall clock is otherwise testable only by hardcoding
# today, which is a test that stops being true tomorrow. An unreadable override
# REFUSES: a wrong today makes every number below it wrong without saying so.
TODAY="${CYCLE_TODAY:-$(date +%Y-%m-%d)}"
TODAY_N="$(day_number "$TODAY")" || {
  printf 'cycle: CYCLE_TODAY=%s is not a YYYY-MM-DD date, and a wrong today makes every day count below it wrong\n' \
    "$TODAY" >&2
  exit 2
}

# how_long <day number> -> "today", "in N days", or "N days ago"
how_long() {
  local delta=$(( $1 - TODAY_N ))
  if [ "$delta" -eq 0 ]; then printf 'today\n'
  elif [ "$delta" -eq 1 ]; then printf 'in 1 day\n'
  elif [ "$delta" -gt 1 ]; then printf 'in %s days\n' "$delta"
  elif [ "$delta" -eq -1 ]; then printf '1 day ago\n'
  else printf '%s days ago\n' $(( -delta ))
  fi
}

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
    printf '%s03 define    %s themes, %s outliers, %s\n' "$ok" "$t" "$o" "$(pass_duration "$d")"
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

  # Said once, and said at all. The duration line below reads "not recorded" for
  # a cycle that omits the field, and that sentence is only true while the
  # contract still declares the field this looks for.
  case "$duration_declared" in
    no) printf '%s%s is no longer declared in %s, so the duration below is read from a field nothing requires\n' \
          "$miss" "$DURATION_FIELD" "$DEFINE_CONTRACT" ;;
    unknown) printf '%sno %s, so the duration field could not be checked against its declaration\n' \
          "$miss" "$DEFINE_CONTRACT" ;;
  esac

  # An example file is not reported as a cycle, but the skip is ANNOUNCED. The
  # first version skipped silently, and an external audit inserted `example: yes`
  # into the only real findings file: the cycle, its 64 findings, its themes and
  # both decisions vanished from this report with no refusal anywhere, and both
  # gates still passed. A status tool that can lose a cycle to a two-word edit
  # without saying so is worse than none.
  local skipped="" last_scan="" last_scan_n="" n
  for f in process/01-scan/findings/*.md; do
    [ -f "$f" ] || continue
    local c; c=$(basename "$f" .md)
    if grep -q '^example: yes' "$f" 2>/dev/null; then
      skipped="$skipped $c"
      continue
    fi
    # The newest REAL scan, collected before the `want` filter so naming one
    # cycle does not change what the tripwire below is measured from. An example
    # cannot be the last scan either — otherwise adding a file would reset a
    # tripwire, which is the two-word edit this report has already been burnt by.
    if n=$(day_number "$c" 2>/dev/null); then
      if [ -z "$last_scan_n" ] || [ "$n" -gt "$last_scan_n" ]; then
        last_scan="$c"; last_scan_n="$n"
      fi
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

  # --- the two numbers a decision's tripwire needs ----------------------------
  #
  # `producing-themes` commits to two more cycles, expires on a date, and names a
  # missed cycle as the condition that ends it early. Nothing in this repository
  # could compute either number, and intent.md says plainly that a cycle which
  # quietly stops happening leaves no trace. This is the trace, in front of
  # whoever runs the report.
  #
  # Reported, NOT refused. Nothing here exits non-zero for an expiry that has
  # passed: that record is the one telling the truth about itself, and a gate is
  # the deliver contract's decision to make when a second record carries the field.
  printf '\ndates\n'
  if [ -n "$last_scan" ]; then
    printf '%slast scan    %s, %s\n' "$no" "$last_scan" "$(how_long "$last_scan_n")"
  else
    printf '%slast scan    no findings file carries a date, so nothing can be counted from one\n' "$miss"
  fi

  local decisions=0 dated=0 nones=0 unreadable=0 near="" near_n="" near_slug="" v first slug e
  for dl in process/05-deliver/decisions/*.md; do
    [ -f "$dl" ] || continue
    decisions=$((decisions + 1))
    slug=$(basename "$dl" .md)
    v="$(field "$dl" expires)"
    [ -n "$v" ] || continue
    # `none` has to be the whole first word. The Deliver gate had the prefix
    # version of this defect: `amends: nonetheless, ...` read as "nothing changed".
    first="$(printf '%s' "$v" | awk '{print tolower($1)}' | tr -d '.,;:')"
    if [ "$first" = none ]; then nones=$((nones + 1)); continue; fi
    dated=$((dated + 1))
    # The date is the first field of the value, so a date followed by a note is
    # read rather than refused.
    e="$(printf '%s' "$v" | awk '{print $1}')"
    if n=$(day_number "$e" 2>/dev/null); then
      if [ -z "$near_n" ] || [ "$n" -lt "$near_n" ]; then
        near="$e"; near_n="$n"; near_slug="$slug"
      fi
    else
      unreadable=$((unreadable + 1))
      printf '%sexpiry       %s declares `%s`, which is not a date\n' "$miss" "$slug" "$v"
    fi
  done

  # The denominator is printed with the answer. A report that evaluates nothing
  # and prints a tidy line reads exactly like one that found nothing to worry
  # about, which is the shape the gates here keep being repaired for. A declared
  # `none` and an absent field are also two different states, and the second is
  # the one nobody chose.
  if [ -n "$near_n" ]; then
    local mark="$no"
    [ "$near_n" -lt "$TODAY_N" ] && mark="$miss"
    printf '%sexpiry       %s, %s, %s — nearest of %s dated, across %s decision(s)\n' \
      "$mark" "$near_slug" "$near" "$(how_long "$near_n")" "$dated" "$decisions"
  elif [ "$unreadable" -gt 0 ]; then
    printf '%sexpiry       no readable expiry, across %s decision(s)\n' "$miss" "$decisions"
  elif [ "$nones" -gt 0 ]; then
    printf '%sexpiry       no date declared; %s of %s decision(s) declare `none`\n' \
      "$no" "$nones" "$decisions"
  else
    printf '%sexpiry       no decision declares one, across %s decision(s)\n' "$no" "$decisions"
  fi

  printf '\n'
}

main "$@"
