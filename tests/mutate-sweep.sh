#!/usr/bin/env bash
# Mutate every guard in every gate and both hooks, by line number, and report which
# mutations no suite catches.
#
# usage: tests/mutate-sweep.sh [--list] [--operator D|A|T|X|E|P] [--target <path>]
#
#   --list       print the denominator and exit without running anything
#   --operator   run one operator instead of all six
#   --target     restrict to one gate or hook
#
# Not named test_*.sh, so tests/run-all.sh does not pick it up. A full sweep takes
# tens of minutes; this is a tool you run deliberately, not a suite.
#
# WHY THIS EXISTS
#
# `AGENTS.md` said "A sweep of all five gates found two more instances of this the
# first way had missed." That sweep was pattern-based, and it missed a whole guard:
# the `id` refusal in `process/01-scan/validate-findings.sh` had no test at all, and
# replacing its condition with `if false` left twelve suites green over 82
# assertions. A sweep with no enumerated denominator is an early stop wearing a
# result.
#
# So the denominator is enumerated from the files, printed, and the report names
# every site nothing caught. `--list` is there so the denominator can be read and
# argued with before anyone trusts a sweep built on it.
#
# THE TWO KINDS OF MUTATION, AND WHY BOTH
#
# Deleting a check proves it is REACHABLE. Loosening it proves it is SUFFICIENT.
# The repository has been caught by the second where the first found nothing — an
# `[E]` marker check that passed a claim citing the bare string `S-`, and a coverage
# part check satisfied by two added commas. Five of the six operators loosen.
#
#   D  delete      replace the refuse call at this site with `:`
#   A  anchors     drop `^` and `$` from an ERE on this line
#   T  threshold   make a numeric comparison on this line always true
#   X  exact       `grep -qx` becomes `grep -q`, so a whole-line match becomes a
#                  substring match
#   E  enum        a `case` pattern listing alternatives becomes `*`
#   P  pattern     one alternative of a built-up regular expression stops matching
#
# P exists because `.githooks/pre-push` and `bin/validate-claims.sh` do not refuse by
# code at all. They refuse by exit status over a pattern assembled across several
# lines, and no other operator here reaches a single clause of one — which is how the
# claims gate shipped with no entry for `quicker`, the word AGENTS.md uses as its own
# example.
#
# WHAT A RESULT MEANS
#
#   caught        some suite exited non-zero with the mutation in place
#   NOT CAUGHT    every suite passed. Either the guard has no test, or the test
#                 does not distinguish the mutation from the original
#   inconclusive  the operator did not change the line, its postcondition did not hold,
#                 or the mutated file failed `bash -n`. Reported, never counted as a result
#
# WHERE THIS STOOD ON 2026-10-04, AND WHAT IS STILL OPEN
#
# 215 mutations. Thirty-two were not caught, and the run that found them is what this
# script is for. The tests that close them are a change per gate, each one stacked on
# this script, because the result has to exist before the coverage it justifies —
# re-run `tests/mutate-sweep.sh` here and it reports them.
#
# Every D, T, X, E and P site is closed by those changes. Operator A — dropping a
# regular expression's anchors — is the one nothing in this repository had ever applied,
# and it is where the uncovered sites are. Of the 43 it found, twelve are closed, and
# the rest fall into two groups:
#
# NOT A HOLE, and the reason, so they are not re-reported as findings:
#
#   bin/validate-controls.sh 145 163 189 224 324   `grep "^KIND<tab>"` over this gate's
#     own parsed stream. Dropping the anchor cannot match a different kind, because no
#     kind prefix is a substring of another and values carry no tabs. Plumbing, not a
#     guard.
#   .githooks/commit-msg 61, .githooks/pre-push 102   dropping `^` from the
#     Co-Authored-By expression only widens what it matches, so it opens nothing.
#   .githooks/pre-push 58   dropping `^` from `grep -n '^+'` makes the secret scan read
#     removed lines too. More refusals, not fewer.
#   process/05-deliver/validate-decision.sh 42   `line_of` decides a reported line
#     number, not whether anything is refused.
#   process/01-scan/validate-findings.sh 148   a separator row is a row of nothing but
#     dashes, colons and spaces between pipes. No findings row can be read as one.
#
# A REAL HOLE, not closed here. Fifteen sites across three gates, each one a detection
# that would accept a mention of the thing instead of the thing: register ids and rows
# in bin/validate-standards.sh (73, 82, 213), section and heading detection in the scan
# gate (168, 231, 236, 345), and referent and coverage-part detection in the discovery
# gate (99, 141, 145, 213, 214, 215, 250, 268). Three plus four plus eight.
#
# That is a body of work comparable to the change that produced this script, across
# gates it does not otherwise touch, so it is not bundled in here. It is recorded as
# issue #79: fifteen anchored expressions with no test, each of which would accept a
# mention of the thing instead of the thing — which a clone cannot read, hence the
# sentence rather than the number alone.
#
# The define gate's four are closed. Line numbers rather than identities, because they have
# moved twice already: this listed them as 49, 53, 85 and 109, the problem gate's change
# reported the three still bare as 88, 124 and 148, and in the tree you are reading them
# they are 128, 129 and 235. What each one is, is the stable part:
#
#   the outlier section's existence         `grep -q '^## Outliers'`
#   the outlier count                       `grep -cE '^- \*\*'`, one copy now, two before
#   the theme counts that are summed        `grep -oE '^\*\*[0-9]+ findings'`
#   the source's id harvest                 `grep -oE '^\| F[0-9]+ \|'`
#
# The first three are covered by `tests/test_validate_define.sh`, against a fixture built
# by `tests/lib/define-fixture.sh` rather than against the shipped record, and this sweep
# reports 3 of 3 caught for that target. The fourth no longer exists here: it moved into
# `process/01-scan/findings-ids.sh`, where it also became scoped to the source's
# `## Findings` section, and `tests/test_findings_ids.sh` covers it.
#
# **That file is outside the denominator below**, which enumerates `validate-*.sh`,
# `bin/list-refusals.sh` and the two hooks. It is a gate's input rather than a gate, it
# refuses nothing by code, and the D, T, X and E operators have nothing to act on in it
# — but operator A does, and a sweep that cannot reach it is a denominator with a hole
# in it. Whether to widen the surface is a decision about what this script enumerates,
# which is why it is stated here rather than changed in passing. Its anchors were
# loosened by hand instead: scoped to unscoped, whole-cell to substring, id cell to any
# cell, contract-read column to a hardcoded one, and the section exit removed. All five
# go red.
# Re-run `tests/mutate-sweep.sh --operator A` to get the current list.
#
# exit 0  every mutation was caught
# exit 1  at least one was not caught, or at least one was inconclusive
set -u

TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$TEST_DIR/.." && pwd)"

only_list=no
only_op=""
only_target=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --list) only_list=yes ;;
    --operator) shift; only_op="${1:-}" ;;
    --target) shift; only_target="${1:-}" ;;
    *) printf 'mutate-sweep: unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

# --- the surface --------------------------------------------------------------
# Enumerated from the tree. A gate added without a suite is in the denominator by
# existing, which is the property the old pattern-based sweep did not have.
targets="$(cd "$ROOT" && ls process/*/validate-*.sh bin/validate-*.sh bin/list-refusals.sh 2>/dev/null) .githooks/commit-msg .githooks/pre-push"
if [ -n "$only_target" ]; then targets="$only_target"; fi

for t in $targets; do
  [ -f "$ROOT/$t" ] || { printf 'mutate-sweep: no such file: %s\n' "$t" >&2; exit 2; }
done

SITE_SRC="$ROOT"   # replaced by the pristine copy once there is one, so a sweep
                     # is not affected by the live tree changing underneath it

# --- site enumeration, one function per operator ------------------------------
# Each prints the line numbers it would mutate in the file named by $1. An operator
# that finds nothing in a file contributes nothing to the denominator, which is
# correct and visible in the report.

# Every enumerator ends in `sort -un`. A line counted twice is a mutation run twice
# and a denominator that overstates itself.

sites_D() { # refusal emission sites, from the one definition of what that is
  /bin/bash "$ROOT/bin/list-refusals.sh" "$SITE_SRC/$1" 2>/dev/null \
    | awk -F: '{ print $2 }' | sort -un
}

sites_A() { # lines carrying an ERE anchor
  awk '!/^[ \t]*#/ && (/["'"'"'(|]\^/ || /\$["'"'"')|]/) { print FNR }' "$SITE_SRC/$1" | sort -un
}

sites_T() { # lines carrying a numeric comparison against a literal
  awk '!/^[ \t]*#/ && /-(ge|gt|eq|le|lt)[ \t]+[0-9]+/ { print FNR }' "$SITE_SRC/$1" | sort -un
}

sites_X() { # lines matching a whole line rather than a substring
  awk '!/^[ \t]*#/ && /grep[ \t]+-[A-Za-z]*x/ { print FNR }' "$SITE_SRC/$1" | sort -un
}

NOMATCH='zzzzz-no-such-thing'

sites_P() { # one clause of a regular expression built up across lines
  awk '
    /^[ \t]*#/ { next }
    # A command substitution is not a regular expression. `files="$(git diff ... |
    # sort -u)"` has a shell pipe in it and matched the third shape below, which put
    # two lines of .githooks/pre-push in the denominator as pattern clauses they are
    # not. The failure was loud rather than silent — they reported NOT CAUGHT — but a
    # denominator with invented entries in it is not a denominator.
    /\$\(/ { next }
    # A shell pipeline continuation is not a regular expression either. Four lines
    # across the hooks and two gates are `| grep ...` on their own line, and replacing
    # one with a pattern clause destroys the command — those came back as
    # inconclusive(syntax), which is loud but still noise in the denominator. The list
    # is the commands this repository actually pipes into, enumerated rather than
    # guessed at, so a new one shows up as an inconclusive result instead of silently.
    /^[ \t]*\|[ \t]*(grep|sed|awk|cut|sort|head|tail|tr|wc|xargs|git|printf)([ \t]|$)/ { next }
    # VAR="$VAR|<clause>"  — a pattern extended one alternative at a time
    /^[ \t]*[A-Za-z_][A-Za-z_0-9]*="\$[A-Za-z_][A-Za-z_0-9]*\|/ { print FNR; next }
    # a continuation line that is itself one alternative
    /^[ \t]*\|/ { print FNR; next }
    # VAR=<quoted ERE containing an alternation>
    /^[ \t]*(local[ \t]+)?[A-Za-z_][A-Za-z_0-9]*=['"'"'"][^'"'"'"]*\|/ { print FNR; next }
  ' "$SITE_SRC/$1" | sort -un
}

sites_E() { # case patterns listing alternatives
  awk '!/^[ \t]*#/ && /^[ \t]*([A-Za-z0-9_.*-]+\|)+[A-Za-z0-9_.*-]+\)/ { print FNR }
       !/^[ \t]*#/ && /[Cc]ase[^;]*in[ \t]+([A-Za-z0-9_.*-]+\|)+[A-Za-z0-9_.*-]+\)/ { print FNR }' \
    "$SITE_SRC/$1" | sort -un
}

# --- the mutations ------------------------------------------------------------
# Each reads the original file on stdin and writes the mutated one, acting only on
# line L. By line number, never by pattern: a pattern-based sweep is what produced
# the `id` hole, because the pattern decided which sites existed.

mutate_D() { # the refuse call becomes a no-op, with the surrounding syntax kept
  awk -v L="$1" '
    FNR == L {
      s = " " $0
      if (match(s, /[ \t;&|{)(]refuse[ \t]/)) {
        pre = substr($0, 1, RSTART - 1)
        suf = ""
        if ($0 ~ /\\[ \t]*$/)        suf = " \\"
        else if ($0 ~ /;;[ \t]*$/)   suf = " ;;"
        else if ($0 ~ /; fi[ \t]*$/) suf = " ; fi"
        else if ($0 ~ /; \}[ \t]*$/) suf = " ; }"
        print pre ": " suf
        next
      }
    }
    { print }'
}

mutate_A() { # anchored becomes unanchored
  # A character scan, not a gsub with a backreference. awk has no backreferences in
  # a replacement: `gsub(/(["'(|])\^/, "\\1")` inserts a literal `\1`, so
  # `grep -v '^$'` became `grep -v \1\1` — a pattern matching nothing, which
  # inverted keeps every line, which is what the original did. Fifty A mutations
  # reported NOT CAUGHT or broke the shell while changing no behaviour at all.
  #
  # A mutation operator that silently does nothing is the same defect as a check
  # that silently passes, which is what this whole sweep exists to find. That is why
  # every operator now has a postcondition below.
  awk -v L="$1" -v PRE="\"'(|" -v POST="\"')|" '
    FNR == L {
      line = $0; out = ""; n = length(line)
      for (i = 1; i <= n; i++) {
        c = substr(line, i, 1)
        p = (i > 1) ? substr(line, i - 1, 1) : ""
        q = (i < n) ? substr(line, i + 1, 1) : ""
        if (c == "^" && p != "" && index(PRE, p) > 0) continue
        if (c == "$" && q != "" && index(POST, q) > 0) continue
        out = out c
      }
      print out
      next
    }
    { print }'
}

mutate_T() { # the threshold becomes zero and the comparison becomes always-true
  awk -v L="$1" '
    FNR == L {
      line = $0
      gsub(/-(ge|gt|eq|le|lt)[ \t]+[0-9]+/, "-ge 0", line)
      print line
      next
    }
    { print }'
}

mutate_X() { # a whole-line match becomes a substring match
  awk -v L="$1" '
    FNR == L {
      line = $0
      while (match(line, /grep[ \t]+-[A-Za-z]*x/)) {
        flag = substr(line, RSTART, RLENGTH)
        sub(/x/, "", flag)
        line = substr(line, 1, RSTART - 1) flag substr(line, RSTART + RLENGTH)
      }
      print line
      next
    }
    { print }'
}

mutate_P() { # the clause on this line stops matching anything
  awk -v L="$1" -v N="$NOMATCH" '
    FNR == L {
      line = $0
      if (line ~ /^[ \t]*[A-Za-z_][A-Za-z_0-9]*="\$[A-Za-z_][A-Za-z_0-9]*\|/) {
        # VAR="$VAR|clause"  ->  VAR="$VAR"
        sub(/\|.*$/, "\"", line)
        print line; next
      }
      if (line ~ /^[ \t]*\|/) {
        # one alternative on its own line, continuation backslash kept
        suf = (line ~ /\\[ \t]*$/) ? "\\" : ""
        match(line, /^[ \t]*/)
        print substr(line, 1, RLENGTH) "|" N suf
        next
      }
      # VAR=<quoted ERE>  ->  VAR=<a literal nothing matches>
      #
      # The continuation backslash has to survive. Without it the lines that
      # continued the assignment became stray commands, and eight P mutations were
      # reported inconclusive for a syntax error this operator had introduced rather
      # than for anything about the gate.
      if (match(line, /=['"'"'"]/)) {
        q = substr(line, RSTART + 1, 1)
        suf = (line ~ /\\[ \t]*$/) ? "\\" : ""
        print substr(line, 1, RSTART) q N q suf
        next
      }
    }
    { print }'
}

mutate_E() { # the enumerated alternatives become anything
  awk -v L="$1" '
    FNR == L {
      line = $0
      sub(/([A-Za-z0-9_.*-]+\|)+[A-Za-z0-9_.*-]+\)/, "*)", line)
      print line
      next
    }
    { print }'
}

# --- the denominator, on its own ---------------------------------------------
# Printed before anything is copied or run, so it can be read and argued with
# cheaply. A sweep is only worth as much as the list of sites it claims to cover.
ops="D A T X E P"
[ -n "$only_op" ] && ops="$only_op"

if [ "$only_list" = yes ]; then
  for op in $ops; do
    for t in $targets; do
      for L in $("sites_$op" "$t"); do printf '%s %s:%s\n' "$op" "$t" "$L"; done
    done
  done > "${TMPDIR:-/tmp}/mutate-sweep-denominator.$$"
  n="$(grep -c . "${TMPDIR:-/tmp}/mutate-sweep-denominator.$$" | tr -d ' ')"
  printf '# denominator: %s mutations\n' "$n"
  awk '{ split($2, a, ":"); print $1, a[1] }' "${TMPDIR:-/tmp}/mutate-sweep-denominator.$$" \
    | sort | uniq -c | awk '{ printf "  %-3s %-45s %s\n", $2, $3, $1 }'
  printf '\n'
  cat "${TMPDIR:-/tmp}/mutate-sweep-denominator.$$"
  rm -f "${TMPDIR:-/tmp}/mutate-sweep-denominator.$$"
  exit 0
fi

# --- the throwaway copy ------------------------------------------------------
# A full copy including .git, because bin/validate-standards.sh resolves the
# evidence pointers the documents cite into history and a fresh repository does not
# have them. This clone has its own .git directory, so the copy is independent and
# nothing here can reach the real refs.
LAB="$(mktemp -d)"
trap 'rm -rf "$LAB"' EXIT
cp -R "$ROOT" "$LAB/repo" || exit 2
REPO="$LAB/repo"
SITE_SRC="$LAB/pristine"
mkdir -p "$LAB/pristine"
for t in $targets; do
  mkdir -p "$LAB/pristine/$(dirname "$t")"
  cp "$ROOT/$t" "$LAB/pristine/$t"
done

# The copy has to be green before anything is mutated, or every "caught" result
# below could be the copy being broken rather than the mutation being seen.
if ! (cd "$REPO" && /bin/bash tests/run-all.sh >/dev/null 2>&1); then
  printf 'mutate-sweep: the unmutated copy does not pass. Nothing below would mean anything.\n' >&2
  (cd "$REPO" && /bin/bash tests/run-all.sh 2>&1 | grep -E '^(not ok|FAIL|run-all)' | sed 's/^/  /') >&2
  exit 2
fi

# --- running the suites ------------------------------------------------------
# The suites that name the mutated file run first, so the common case — a guard its
# own suite covers — costs one suite rather than fourteen. Order only; a mutation is
# NOT CAUGHT only when every suite has passed.
suite_order() { # <target> -> suite paths, likeliest and cheapest first
  local t="$1" base own near far s
  base="$(basename "$t")"
  # The suite named after the target, by the convention most of them follow:
  # validate-findings.sh -> test_validate_findings.sh. Two targets do not follow it
  # (the hooks share test_hooks.sh), which is why this is an ordering hint and not
  # a mapping anything depends on.
  own="$REPO/tests/test_$(printf '%s' "${base%.sh}" | tr '-' '_').sh"
  [ -f "$own" ] || own=""
  near=""; far=""
  for s in "$REPO"/tests/test_*.sh; do
    [ "$s" = "$own" ] && continue
    if grep -q -- "$base" "$s" 2>/dev/null; then near="$near $s"; else far="$far $s"; fi
  done
  # Smallest first inside each group. Byte size is a rough stand-in for runtime and
  # it is free; the slowest suite here is thirty seconds and the quickest a tenth of
  # one, so running them in glob order costs more than the mutation itself.
  printf '%s\n' $own $(cheapest_first $near) $(cheapest_first $far)
}

cheapest_first() {
  [ "$#" -eq 0 ] && return 0
  wc -c "$@" 2>/dev/null | awk '$2 != "total" { print $1, $2 }' | sort -n | awk '{ print $2 }'
}

first_red() { # <target> -> prints the suite that refused, or nothing
  local s
  for s in $(suite_order "$1" | grep .); do
    if ! (cd "$REPO" && /bin/bash "$s" >/dev/null 2>&1); then
      basename "$s"
      return 0
    fi
  done
  return 1
}

# --- every operator proves it did what its name says --------------------------
# A mutation that changes the line without changing the behaviour reads as NOT CAUGHT
# and means nothing. `mutate_A` did exactly that for fifty sites, inserting a literal
# `\1` where the anchor had been. So each operator now carries a postcondition over
# the line it rewrote, and a mutation failing its own is reported inconclusive rather
# than as a result. This is the same rule the gates are held to: a check that cannot
# fail is worse than no check, and so is a mutation that cannot bite.
anchors() { printf '%s' "$1" | tr -cd '^$' | wc -c | tr -d ' '; }
xflags() { printf '%s' "$1" | grep -c 'grep[ \t]*-[A-Za-z]*x' | tr -d ' '; }

verify_D() { ! printf '%s' "$2" | grep -q 'refuse[ \t]'; }
verify_A() { [ "$(anchors "$2")" -lt "$(anchors "$1")" ]; }
verify_T() { printf '%s' "$2" | grep -q -- '-ge 0'; }
verify_X() { [ "$(xflags "$2")" -lt "$(xflags "$1")" ]; }
verify_E() { printf '%s' "$2" | grep -q '[*])'; }
verify_P() { printf '%s' "$2" | grep -q "$NOMATCH" || [ "${#2}" -lt "${#1}" ]; }

# --- the sweep ---------------------------------------------------------------
enumerated=0
caught=0
uncaught=0
inconclusive=0
uncaught_list=""
inconclusive_list=""

for op in $ops; do
  for t in $targets; do
    for L in $("sites_$op" "$t"); do
      enumerated=$((enumerated + 1))
      "mutate_$op" "$L" < "$LAB/pristine/$t" > "$REPO/$t.mutated"
      if cmp -s "$REPO/$t.mutated" "$LAB/pristine/$t"; then
        rm -f "$REPO/$t.mutated"
        cp "$LAB/pristine/$t" "$REPO/$t"
        inconclusive=$((inconclusive + 1))
        inconclusive_list="$inconclusive_list $op:$t:$L(no-change)"
        continue
      fi
      before="$(sed -n "${L}p" "$LAB/pristine/$t")"
      after="$(sed -n "${L}p" "$REPO/$t.mutated")"
      if ! "verify_$op" "$before" "$after"; then
        rm -f "$REPO/$t.mutated"
        cp "$LAB/pristine/$t" "$REPO/$t"
        chmod +x "$REPO/$t"
        inconclusive=$((inconclusive + 1))
        inconclusive_list="$inconclusive_list $op:$t:$L(operator-did-not-bite)"
        continue
      fi

      mv "$REPO/$t.mutated" "$REPO/$t"
      chmod +x "$REPO/$t"

      if ! /bin/bash -n "$REPO/$t" 2>/dev/null; then
        cp "$LAB/pristine/$t" "$REPO/$t"
        inconclusive=$((inconclusive + 1))
        inconclusive_list="$inconclusive_list $op:$t:$L(syntax)"
        continue
      fi

      if red="$(first_red "$t")"; then
        caught=$((caught + 1))
        printf 'caught       %s %s:%s   by %s\n' "$op" "$t" "$L" "$red"
      else
        uncaught=$((uncaught + 1))
        uncaught_list="$uncaught_list
  $op $t:$L  $(sed -n "${L}p" "$LAB/pristine/$t" | sed 's/^[ \t]*//' | cut -c1-96)"
        printf 'NOT CAUGHT   %s %s:%s\n' "$op" "$t" "$L"
      fi
      cp "$LAB/pristine/$t" "$REPO/$t"
      chmod +x "$REPO/$t"
    done
  done
done

if [ "$only_list" = yes ]; then
  printf '%s\n' "$denominator" | grep -c . | tr -d ' ' | { read -r n; printf '# denominator: %s mutations\n' "$n"; }
  printf '%s\n' "$denominator" | grep . | awk '{ split($2, a, ":"); print $1, a[1] }' | sort | uniq -c \
    | awk '{ printf "  %-3s %-45s %s\n", $2, $3, $1 }'
  printf '\n'
  printf '%s\n' "$denominator" | grep .
  exit 0
fi

printf '\n'
printf 'mutate-sweep: %d mutations enumerated, %d caught, %d NOT caught, %d inconclusive\n' \
  "$enumerated" "$caught" "$uncaught" "$inconclusive"
[ -n "$uncaught_list" ] && printf 'not caught:%s\n' "$uncaught_list"
[ -n "$inconclusive_list" ] && printf 'inconclusive:%s\n' "$inconclusive_list"

[ "$uncaught" -eq 0 ] && [ "$inconclusive" -eq 0 ]
