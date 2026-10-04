#!/usr/bin/env bash
# Bind every control in CONTROLS.md to the enforcement that control names.
#
# usage: bin/validate-controls.sh [<controls document>]
#
# WHY THIS IS A GATE AND NOT A GREP IN A TEST
#
# `CONTROLS.md` told an assessor that `tests/test_controls.sh` "fails if a cited
# refusal is not in the named script — so a control cannot drift from its
# enforcement". Both halves were false:
#
#   * The named script was never used. The suite collected every gate path in the
#     document into one set and asked whether a cited code appeared in ANY of
#     them. Pointing CTRL-1 at the scan gate, which emits none of its four codes,
#     passed 18 assertions out of 18.
#   * The match was a plain substring over the whole file. Adding
#     `# never-emitted-code` as a comment to any gate made a fabricated refusal
#     code pass.
#
# And two things were outside the check altogether: CTRL-9's five hook and CI
# controls, because its table has no code column, and the hooks themselves,
# because the gate pattern only matched `validate-*.sh`.
#
# A check embedded in its own test cannot be driven against a document built to
# break it, which is why this is a script and `tests/test_controls.sh` drives it —
# the same move `bin/validate-claims.sh` made out of `ci.yml`.
#
# WHAT THIS CHECKS
#
# Per control: every refusal code a control cites is emitted at an emission site
# in a script that control's own `**Enforced by**` line names, and every path and
# CI job on that line resolves. `bin/list-refusals.sh` decides what an emission
# site is, so a comment cannot satisfy it.
#
# WHAT THIS DOES NOT CHECK, YET
#
# The other direction: a gate emitting a refusal code no control claims. That is
# the second half of the same defect and goes up separately.
#
# WHAT THIS DOES NOT CHECK AT ALL
#
# That a control's prose describes what its refusal does. This establishes the
# wiring — the code is cited, and the gate the control names emits it — and
# nothing about whether the condition behind the code is the condition the
# control claims.
#
# exit 0  every control resolves against the enforcement it names
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOC="${1:-$ROOT/CONTROLS.md}"
CI_FILE="$ROOT/.github/workflows/ci.yml"
LISTER="$ROOT/bin/list-refusals.sh"
TAB="$(printf '\t')"

[ -f "$DOC" ] || { printf 'validate-controls: no controls document at %s\n' "$DOC" >&2; exit 2; }
[ -x "$LISTER" ] || { printf 'validate-controls: cannot run %s\n' "$LISTER" >&2; exit 2; }
[ -f "$CI_FILE" ] || { printf 'validate-controls: no workflow at %s\n' "$CI_FILE" >&2; exit 2; }

refusals=0
refuse() { printf '%s: refuse[%s]: %s\n' "${1#$ROOT/}" "$2" "$3" >&2; refusals=$((refusals + 1)); }

# --- the enforcement surface --------------------------------------------------
# Enumerated from the tree, not from the document, so a gate the document forgets
# is still read. The two hooks were missing from CONTROLS.md until an external
# audit found them, and a check that reads only the document cannot notice an
# omission.
gates="$(cd "$ROOT" && ls process/*/validate-*.sh bin/validate-*.sh 2>/dev/null)"

# --- parse the document -------------------------------------------------------
# One pass, emitting a tab-separated stream the shell can loop over:
#
#   BLK <id>                a control block exists
#   ENF <id> <token>        a backticked token on that control's Enforced by line
#   TAB <id> <code>         a refusal code in that control's refusal table
#   PRO <id> <token>        a backticked token in the block, outside both of those
#
# The convention this relies on is that a control states its refusals in a table
# whose first cell is the backticked code. PRO exists to stop a code drifting out
# of the table into prose, where nothing would check it: CTRL-5 and CTRL-6 both
# listed codes in prose, and all of them were outside the old check.
parsed="$(awk -v T="$TAB" '
  function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

  /^## / {
    if ($0 ~ /^## CTRL-/) {
      id = $0; sub(/^## /, "", id); sub(/[ \t].*$/, "", id)
      sec = "ctrl"; printf "BLK%s%s\n", T, id
    } else {
      sec = ""; id = ""
    }
    next
  }

  sec == "ctrl" && /^\*\*Enforced by\*\*/ {
    line = $0
    while (match(line, /`[^`]+`/)) {
      printf "ENF%s%s%s%s\n", T, id, T, substr(line, RSTART + 1, RLENGTH - 2)
      line = substr(line, RSTART + RLENGTH)
    }
    next
  }

  # A refusal table row: the first cell is the backticked code.
  sec == "ctrl" && /^\|[ \t]*`[a-z][a-z0-9-]*`[ \t]*\|/ {
    n = split($0, cell, "|")
    code = trim(cell[2]); gsub(/`/, "", code)
    printf "TAB%s%s%s%s\n", T, id, T, code
    next
  }

  sec == "ctrl" {
    line = $0
    while (match(line, /`[^`]+`/)) {
      printf "PRO%s%s%s%s\n", T, id, T, substr(line, RSTART + 1, RLENGTH - 2)
      line = substr(line, RSTART + RLENGTH)
    }
    next
  }

' "$DOC")"

field() { printf '%s\n' "$parsed" | grep "^$1$TAB" | cut -f2- ; }

controls="$(field BLK)"
[ -n "$controls" ] || { printf 'validate-controls: %s declares no ## CTRL- blocks, so nothing was checked\n' "${DOC#$ROOT/}" >&2; exit 2; }

# --- the emission sites -------------------------------------------------------
# Over the gates in the tree AND over every script the document names, which are
# not the same set in either direction. A gate the document forgets still has to be
# read, and a script named from somewhere outside process/ or bin/ still has to be
# read too — otherwise its codes resolve to nothing and every control naming it is
# refused for the wrong reason.
read_me="$gates"
while IFS= read -r tok; do
  [ -n "$tok" ] || continue
  case "$tok" in
    */*.sh) [ -f "$ROOT/$tok" ] && read_me="$read_me $tok" ;;
  esac
done <<EOF
$(printf '%s\n' "$parsed" | grep "^ENF$TAB" | cut -f3 | sort -u)
EOF

readable=""
for g in $read_me; do
  case " $readable " in *" $g "*) continue ;; esac
  readable="$readable $g"
done
sites="$(cd "$ROOT" && "$LISTER" $readable)" || exit 2

# A site whose code could not be read is a hole in the denominator, so it is a
# refusal rather than a skip.
while IFS= read -r s; do
  [ -n "$s" ] || continue
  case "$s" in
    *:'?') refuse "$DOC" "site-unreadable" \
      "${s%:*} calls refuse and no refusal code could be read from the call: bin/list-refusals.sh cannot put this site in the denominator, so neither this check nor a mutation sweep by line number can see it" ;;
  esac
done <<EOF
$sites
EOF

# --- forward: a cited code is emitted by a script this control names ----------
while IFS= read -r id; do
  [ -n "$id" ] || continue

  enf="$(printf '%s\n' "$parsed" | grep "^ENF$TAB$id$TAB" | cut -f3)"
  if [ -z "$enf" ]; then
    refuse "$DOC" "no-enforced-by" \
      "$id names no enforcement: a control carries an **Enforced by** line naming the script, hook or CI job that refuses, because a control with nothing behind it is a prose promise"
    continue
  fi

  # A backticked token on the Enforced by line is a path when it contains a
  # slash, and a CI job name otherwise. Both halves are resolved: CTRL-9's
  # enforcement is two hooks and three jobs, and it was outside the old check
  # entirely because its table has no code column.
  named_scripts=""
  has_gate=no
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in
      */*)
        [ -e "$ROOT/$tok" ] || refuse "$DOC" "enforcement-unresolved" \
          "$id is enforced by \`$tok\`, which is not in this repository"
        named_scripts="$named_scripts $tok"
        # "Has a gate" means a named script with at least one emission site, not
        # a script whose name looks like a gate. bin/validate-claims.sh refuses by
        # exit status and emits no code at all, so requiring a refusal table from
        # the control that names it would force an invented one.
        if printf '%s\n' "$sites" | awk -F: -v g="$tok" '$1 == g { f = 1 } END { exit !f }'; then
          has_gate=yes
        fi ;;
      *)
        grep -qE "^  $tok:[ \t]*$" "$CI_FILE" || refuse "$DOC" "job-unresolved" \
          "$id is enforced by the \`$tok\` CI job, which ${CI_FILE#$ROOT/} does not declare" ;;
    esac
  done <<EOF
$enf
EOF

  cited="$(printf '%s\n' "$parsed" | grep "^TAB$TAB$id$TAB" | cut -f3 | sort -u)"

  if [ "$has_gate" = yes ] && [ -z "$cited" ]; then
    refuse "$DOC" "no-refusal-cited" \
      "$id names a gate script and cites no refusal code: the codes go in a table whose first cell is the backticked code, which is the only place this check reads them from"
  fi

  while IFS= read -r c; do
    [ -n "$c" ] || continue
    found=no
    for g in $named_scripts; do
      if printf '%s\n' "$sites" | awk -F: -v g="$g" -v c="$c" '$1 == g && $3 == c { f = 1 } END { exit !f }'; then
        found=yes; break
      fi
    done
    [ "$found" = yes ] || refuse "$DOC" "cited-not-emitted" \
      "$id cites refusal \`$c\`, and no script it names emits it at an emission site. Named:${named_scripts:- none}. A mention in a comment is not an emission site — see bin/list-refusals.sh"
  done <<EOF
$cited
EOF

  # A code that drifted out of the table into prose would be unchecked, because
  # the table is the only place the forward check reads from. CTRL-5 named
  # `no-method` on its Enforced by line and CTRL-6 named eight codes in a
  # sentence; all nine were outside the old check.
  while IFS= read -r tok; do
    [ -n "$tok" ] || continue
    case "$tok" in
      *[!a-z0-9-]*|'') continue ;;
    esac
    printf '%s\n' "$sites" | awk -F: -v c="$tok" '$3 == c { f = 1 } END { exit !f }' || continue
    printf '%s\n' "$cited" | grep -qxF "$tok" && continue
    refuse "$DOC" "code-in-prose" \
      "$id mentions refusal \`$tok\` outside its refusal table, so nothing checks which gate emits it. Put it in the table."
  done <<EOF
$(printf '%s\n' "$parsed" | grep "^PRO$TAB$id$TAB" | cut -f3)
EOF
done <<EOF
$controls
EOF

# --- summary ------------------------------------------------------------------
# The denominator, printed. A gate that checked nothing would also exit 0, and this
# whole repair is about a check that could not fail.
nsites="$(printf '%s\n' "$sites" | grep -c .)"
ncited="$(printf '%s\n' "$parsed" | grep -c "^TAB$TAB")"
nctrl="$(printf '%s\n' "$controls" | grep -c .)"

if [ "$refusals" -ne 0 ]; then
  printf 'validate-controls: %d refusal(s) across %d controls\n' "$refusals" "$nctrl" >&2
  exit 1
fi

printf 'validate-controls: %d controls, %d cited refusals, %d emission sites read\n' \
  "$nctrl" "$ncited" "$nsites"
