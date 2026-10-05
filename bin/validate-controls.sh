#!/usr/bin/env bash
# Bind every control in CONTROLS.md to the enforcement that control names, and
# every refusal the gates emit back to a control, with no silent exclusions.
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
# Forward, per control: every refusal code a control cites is emitted at an
# emission site in a script that control's own `**Enforced by**` line names, and
# every path and CI job on that line resolves. `bin/list-refusals.sh` decides what
# an emission site is, so a comment cannot satisfy it.
#
# Backward, per gate: every refusal code a gate emits is cited by a control that
# names that gate, or is listed in the exception table with a reason. A code
# nothing claims has no control and usually no test, which is how
# `validate-decision.sh`'s `no-chosen-field` shipped with neither, along with seven
# of the scan gate's fifteen.
#
# Sideways: every script whose FILENAME matches `process/*/validate-*.sh` or
# `bin/validate-*.sh`, and the two hooks named literally below, is either named by
# a control or in the exception table. The surface is that pattern over the tree,
# NOT the tree: a gate the document forgets is refused if it is named like one,
# and a script that refuses things under any other name is read by nothing here.
# `bin/next.sh` is the standing proof in this repository. CONTROLS.md item 16 holds
# it; widening the pattern is its own change and is not this one.
#
# Declared but unenforced: every `<!-- declared-not-enforced: name — reason -->` in
# a contract is disclosed by a row in CONTROLS.md, and every row corresponds to a
# declaration that still exists.
#
# WHY THIS FOURTH DIRECTION IS NOT LIKE THE OTHER THREE
#
# The three above all run through REFUSAL CODES. A field that is declared and
# deliberately unenforced emits no code, so it was invisible to every one of them by
# construction — not missed, unrepresentable. Four landed that way: `expires` on a
# decision, `pass took` and a theme's own ids on a cycle, `compares:`/`criterion:` on
# a comparison record. None appeared in CONTROLS.md, so the document got LESS
# complete as the repository got more honest, and an assessor starting there could
# not learn that those fields exist and are unguarded.
#
# The set is read from the contracts rather than kept here or kept in the document.
# A hand-maintained list is what this repository keeps deleting, and this one was
# already short before anybody maintained it: the issue that asked for this named
# three of the four.
#
# A malformed declaration is REFUSED rather than ignored. The other in-band
# declarations in this repository fail closed when malformed because a bad
# declaration leaves the thing it would have exempted unexempted. This one is the
# other way round — a marker the gate cannot parse would be a declaration with
# nothing to disclose — so the marker is detected loosely and then checked, which is
# what keeps it closed.
#
# NO NEW SCRIPT, DELIBERATELY. The issue behind this expected an enumerating script
# and warned that it would itself be a load-bearing script outside the surface
# `Sideways` builds — the gap CONTROLS.md item 16 records. There is no such script:
# this is a fourth direction in the gate that already binds this document to the
# tree, which is already in that surface and already in the exception table. The
# surface is not widened, so nothing here touches that decision.
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
# Overridable so tests/test_controls.sh can add a declaration to a copy of the
# contract tree and prove the set is read from there rather than written here.
CONTRACT_ROOT="${CONTRACT_ROOT:-$ROOT}"

[ -f "$DOC" ] || { printf 'validate-controls: no controls document at %s\n' "$DOC" >&2; exit 2; }
[ -x "$LISTER" ] || { printf 'validate-controls: cannot run %s\n' "$LISTER" >&2; exit 2; }
[ -f "$CI_FILE" ] || { printf 'validate-controls: no workflow at %s\n' "$CI_FILE" >&2; exit 2; }

refusals=0
refuse() { printf '%s: refuse[%s]: %s\n' "${1#$ROOT/}" "$2" "$3" >&2; refusals=$((refusals + 1)); }

# --- the enforcement surface --------------------------------------------------
# Enumerated from the tree rather than from the document, so a gate the document
# forgets is still read. The two hooks were missing from CONTROLS.md until an
# external audit found them, and a check that reads only the document cannot notice
# an omission.
#
# It is enumerated BY FILENAME, which is the limit and is not obvious from reading
# the line. These two globs and the two literal hooks are the whole surface, so a
# script that refuses things under any other name is outside all three directions —
# `bin/next.sh` is in the tree and outside this list today. CONTROLS.md said "the
# surface comes from the tree" until 2026-10-04 and now says what this does.
gates="$(cd "$ROOT" && ls process/*/validate-*.sh bin/validate-*.sh 2>/dev/null)"
hooks=".githooks/commit-msg .githooks/pre-push"
surface="$gates $hooks"

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
    } else if ($0 ~ /^## Refusals and gates no control covers/) {
      sec = "exc"; id = ""
    } else if ($0 ~ /^## Declarations no gate enforces/) {
      sec = "dne"; id = ""
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

  # The disclosure table. Three cells: the declaration, the contract declaring it,
  # and what is not checked. The separator row has no backtick in its first cell, so
  # the same guard that keeps it out of the exception table keeps it out of this one.
  sec == "dne" && /^\|[ \t]*`/ {
    n = split($0, cell, "|")
    if (n < 4) next
    d = trim(cell[2]); gsub(/`/, "", d)
    p = trim(cell[3]); gsub(/`/, "", p)
    r = trim(cell[4])
    printf "DNE%s%s%s%s%s%s\n", T, d, T, p, T, (r ~ /[A-Za-z]/ ? "1" : "0")
    next
  }

  # The exception table. Three cells: the gate, what is excepted, and the reason.
  sec == "exc" && /^\|[ \t]*`/ {
    n = split($0, cell, "|")
    if (n < 4) next
    g = trim(cell[2]); gsub(/`/, "", g)
    w = trim(cell[3]); gsub(/`/, "", w)
    r = trim(cell[4])
    printf "EXC%s%s%s%s%s%s\n", T, g, T, w, T, (r ~ /[A-Za-z]/ ? "1" : "0")
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
read_me="$surface"
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

# --- the exception table ------------------------------------------------------
# The backward and sideways checks below have no silent exclusions. Anything a gate
# refuses that no control claims has to be in this table with a reason, and a gate
# no control names has to be too.
#
# Two shapes of row. `the gate itself` exempts a gate from needing a control and
# exempts every code it emits; a backticked code exempts that one code. The breadth
# of the first is deliberate and visible in the document rather than hidden here.
exceptions="$(field EXC)"
while IFS="$TAB" read -r g w r; do
  [ -n "${g:-}" ] || continue
  [ -e "$ROOT/$g" ] || refuse "$DOC" "enforcement-unresolved" \
    "the exception table names \`$g\`, which is not in this repository"
  [ "${r:-0}" = 1 ] || refuse "$DOC" "exception-no-reason" \
    "the exception for \`$g\` ($w) carries no reason: an exception with none is the silent exclusion this table exists to replace"
done <<EOF
$exceptions
EOF

excepted_gate() { printf '%s\n' "$exceptions" | awk -F"$TAB" -v g="$1" '$1 == g && $2 == "the gate itself" { f = 1 } END { exit !f }'; }
excepted_code() { printf '%s\n' "$exceptions" | awk -F"$TAB" -v g="$1" -v c="$2" '$1 == g && ($2 == c || $2 == "the gate itself") { f = 1 } END { exit !f }'; }

# --- sideways: every gate and both hooks are named by a control or excepted ----
# The surface is a filename pattern over the tree, so a gate the document forgets is
# refused rather than absent as long as it is NAMED like a gate. Both hooks were
# missing from CONTROLS.md until an external audit found them, and no check that
# reads only the document could have noticed. What this still cannot notice is a
# script that refuses things under another name: CONTROLS.md item 16.
for g in $surface; do
  if printf '%s\n' "$parsed" | awk -F"$TAB" -v g="$g" '$1 == "ENF" && $3 == g { f = 1 } END { exit !f }'; then
    continue
  fi
  excepted_gate "$g" && continue
  refuse "$DOC" "uncontrolled-gate" \
    "\`$g\` refuses things and no control names it. Add a control, or list it in the exception table with a reason."
done

# --- backward: every code a gate emits is cited by a control naming that gate --
# A refusal nothing claims has no control and usually no test. validate-decision.sh
# emitted `no-chosen-field` with neither, and the scan gate emitted seven more.
while IFS= read -r s; do
  [ -n "$s" ] || continue
  g="${s%%:*}"; c="${s##*:}"
  [ "$c" = '?' ] && continue
  if printf '%s\n' "$parsed" | awk -F"$TAB" -v g="$g" -v c="$c" '
      $1 == "ENF" && $3 == g { enf[$2] = 1 }
      $1 == "TAB" && $3 == c { tab[$2] = 1 }
      END { for (k in enf) if (k in tab) { f = 1 } exit !f }'; then
    continue
  fi
  excepted_code "$g" "$c" && continue
  refuse "$DOC" "uncited-refusal" \
    "$g emits refusal \`$c\` and no control that names $g cites it. Cite it, or list it in the exception table with a reason."
done <<EOF
$(printf '%s\n' "$sites" | awk -F: '{ print $1 ":" $3 }' | sort -u)
EOF

# --- declared but unenforced: the contracts' set reaches this document ---------
# Enumerated from the contracts in the tree, the same way the gate surface is, so a
# declaration added to a contract is read without editing anything here.
contracts="$(cd "$CONTRACT_ROOT" && ls process/*/*-contract.md 2>/dev/null)"
if [ -z "$contracts" ]; then
  printf 'validate-controls: no contracts under %s/process, so the declared-not-enforced set could not be read\n' \
    "${CONTRACT_ROOT#$ROOT/}" >&2
  exit 2
fi

# declared -> one `name<TAB>contract path` per declaration, plus MALFORMED rows
#
# A fenced block declares nothing, for the fourth time in this repository: a fenced
# `rests on: none`, a fenced `DECIDERS.md` row and a fenced `declared-empty` each
# cost it a defect first. A contract showing a reader the form must not thereby
# require a disclosure row.
declared="$(cd "$CONTRACT_ROOT" && awk -v T="$TAB" '
  FNR == 1 { fence = 0 }
  /^[ \t]*(```|~~~)/ { fence = !fence; next }
  fence { next }
  /<!--[ \t]*declared-not-enforced:/ {
    line = $0
    while (match(line, /<!--[ \t]*declared-not-enforced:[^>]*-->/)) {
      body = substr(line, RSTART, RLENGTH)
      line = substr(line, RSTART + RLENGTH)
      sub(/^<!--[ \t]*declared-not-enforced:[ \t]*/, "", body)
      sub(/[ \t]*-->$/, "", body)
      # name — reason. The em dash is the separator the dead-pointer and
      # corrected-claim declarations already use.
      i = index(body, "—")
      if (i == 0) { printf "MALFORMED%s%s%s%d%sno separator\n", T, FILENAME, T, FNR, T; continue }
      name = substr(body, 1, i - 1); reason = substr(body, i + 3)
      gsub(/^[ \t`]+|[ \t`]+$/, "", name)
      if (name == "")             { printf "MALFORMED%s%s%s%d%sno name\n", T, FILENAME, T, FNR, T; continue }
      if (reason !~ /[A-Za-z]/)   { printf "MALFORMED%s%s%s%d%sno reason\n", T, FILENAME, T, FNR, T; continue }
      printf "OK%s%s%s%s\n", T, name, T, FILENAME
    }
    next
  }
' $contracts)"

while IFS="$TAB" read -r kind a b c; do
  [ "${kind:-}" = MALFORMED ] || continue
  refuse "$DOC" "declaration-malformed" \
    "$a line $b carries a declared-not-enforced marker this gate cannot read ($c): the form is <!-- declared-not-enforced: name — why nothing enforces it -->, and a marker that cannot be read would be a declaration with nothing to disclose"
done <<EOF
$declared
EOF

disclosed="$(field DNE)"

# Forward: a declaration in a contract is disclosed here, against the contract that
# declares it. A row naming a different contract is reported as that, because the
# fix differs from a missing row.
while IFS="$TAB" read -r kind name path; do
  [ "${kind:-}" = OK ] || continue
  if printf '%s\n' "$disclosed" | awk -F"$TAB" -v n="$name" -v p="$path" '$1 == n && $2 == p { f = 1 } END { exit !f }'; then
    continue
  fi
  if printf '%s\n' "$disclosed" | awk -F"$TAB" -v n="$name" '$1 == n { f = 1 } END { exit !f }'; then
    refuse "$DOC" "declaration-undisclosed" \
      "\`$name\` is declared not-enforced in $path, and the row disclosing it names a different contract: an assessor following the row reads the wrong file"
  else
    refuse "$DOC" "declaration-undisclosed" \
      "$path declares \`$name\` not enforced and this document does not disclose it. A declared field emits no refusal code, so the other three directions cannot see it — add a row under 'Declarations no gate enforces' naming the declaration, the contract and what is not checked"
  fi
done <<EOF
$declared
EOF

# Backward: a row here corresponds to a declaration that still exists. This is the
# failure a hand-maintained list has — it outlives the thing it describes, and a
# reader cannot tell a stale gap from a real one.
while IFS="$TAB" read -r name path hasreason; do
  [ -n "${name:-}" ] || continue
  [ "${hasreason:-0}" = 1 ] || refuse "$DOC" "declaration-no-reason" \
    "the row disclosing \`$name\` says nothing about what is not checked: a gap listed without that is the silent exclusion this table exists to replace"
  printf '%s\n' "$declared" | awk -F"$TAB" -v n="$name" -v p="$path" '$1 == "OK" && $2 == n && $3 == p { f = 1 } END { exit !f }' && continue
  if [ ! -f "$CONTRACT_ROOT/$path" ]; then
    refuse "$DOC" "declaration-stale" \
      "the row disclosing \`$name\` names \`$path\`, which is not a contract in this repository"
  else
    refuse "$DOC" "declaration-stale" \
      "the row disclosing \`$name\` names \`$path\`, and that contract carries no declared-not-enforced marker for it: either the declaration was removed, the field is now enforced, or the name drifted"
  fi
done <<EOF
$disclosed
EOF

# --- summary ------------------------------------------------------------------
# The denominator, printed. A gate that checked nothing would also exit 0, and this
# whole repair is about a check that could not fail.
nsites="$(printf '%s\n' "$sites" | grep -c .)"
ncited="$(printf '%s\n' "$parsed" | grep -c "^TAB$TAB")"
nctrl="$(printf '%s\n' "$controls" | grep -c .)"
nexc="$(printf '%s\n' "$exceptions" | grep -c .)"
ndne="$(printf '%s\n' "$declared" | awk -F"$TAB" '$1 == "OK"' | grep -c .)"

if [ "$refusals" -ne 0 ]; then
  printf 'validate-controls: %d refusal(s) across %d controls\n' "$refusals" "$nctrl" >&2
  exit 1
fi

printf 'validate-controls: %d controls, %d cited refusals, %d emission sites read, %d exception(s), %d declared-not-enforced across %d contract(s)\n' \
  "$nctrl" "$ncited" "$nsites" "$nexc" "$ndne" "$(printf '%s\n' $contracts | grep -c .)"
