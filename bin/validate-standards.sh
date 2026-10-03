#!/usr/bin/env bash
# STANDARDS.md must cite something a reader of this repository can open.
#
# usage: bin/validate-standards.sh
#
# WHY THIS EXISTS
#
# STANDARDS.md is the document the whole loop exists to keep true, and it was
# the only artifact with no gate. An external audit found it carrying 31 graded
# claims and zero citations, with its single route to evidence being a reference
# to a branch — `experiment/0.0.0` — that does not exist on origin and never
# did. Every `[E]` claim was, from inside the repository, an assertion.
#
# The audit's verdict named this as the single biggest difference between a
# reviewer being able to follow the chain and not.
#
# WHERE THIS LIVES, AND WHY NOT IN process/
#
# The other gates sit beside the phase whose artifact they check. STANDARDS.md
# is not a phase artifact — it is the loop's output, amended by a decision
# rather than produced by a stage. #18 established that applying a decision is a
# field plus a link, not a sixth phase, so there is no phase directory for this
# to belong to. It sits in bin/ with the other repository-level tools.
#
# exit 0  every graded claim resolves
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DOC="${STANDARDS_DOC:-$ROOT/STANDARDS.md}"
REG="${SOURCES_DOC:-$ROOT/SOURCES.md}"

refusals=0
refuse() { printf '%s: refuse[%s]: %s\n' "${1#$ROOT/}" "$2" "$3" >&2; refusals=$((refusals + 1)); }

[ -f "$DOC" ] || { printf 'validate-standards: no such file: %s\n' "$DOC" >&2; exit 2; }
if [ ! -f "$REG" ]; then
  refuse "$REG" "no-register" "there is no source register, so no graded claim can resolve to anything"
  printf 'validate-standards: 1 refusal(s)\n' >&2; exit 1
fi

# --- the register's own shape -------------------------------------------------
# An entry with no link is not a source. This is the check that stops the
# register becoming a list of names, which is what it would decay into first.
ids="$(grep -oE '^\| `S-[A-Z0-9-]+`' "$REG" | tr -d '|` ' | sort -u)"
if [ -z "$ids" ]; then
  refuse "$REG" "empty-register" "the register declares no source IDs"
else
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    # Anchored at line start. An unanchored match found the id inside the
    # defects table at the top of the register and reported the entry as
    # linkless — the gate's own false positive, caught by running it.
    row="$(grep -E "^\| \`$id\` \|" "$REG" | head -1)"
    case "$row" in
      *http*|*doi*) ;;
      *"](process/"*|*"](.."*) ;;   # one of our own artifacts is a valid source
      *) refuse "$REG" "source-no-link" "$id has no URL, DOI or path: a register entry without something to open is a name, not a source" ;;
    esac
  done <<EOF
$ids
EOF
fi

# --- every graded claim cites an ID ------------------------------------------
# A line GRADES a claim when it carries an [E] or [S] marker, wherever on the
# line that marker appears and whatever markdown is around it.
#
# The previous version skipped any line beginning `|` or `> `, and matched only
# four marker forms: `**[E]`, `**[S]`, `[E]/[S]`, `[S]/[P]`. So a bare `[E]`, a
# table row and a blockquote all passed uncited — and a bare marker is this
# repository's own house style for a graded claim. AGENTS.md writes it that way
# and so do both discovery topics. The gate was reading markup, not grades.
#
# There is no markup stripping here, and that is deliberate. The first version of
# this fix stripped emphasis, table pipes and the blockquote marker before
# testing the line, which reads as thorough and does nothing: `[E]`, `**[E]**`,
# `| **[E]** |` and `> - [E]` all contain the marker already. Mutating each strip
# out failed no test, which is how the dead code was found. What was actually
# wrong was the first-character exemption and the four-form pattern, and both are
# gone.
#
# A line is exempt only when it SAYS it is not a claim, in band, with a reason:
#
#   <!-- not-a-claim: reason -->          exempts the line it is on
#   <!-- not-a-claim-block: reason -->    exempts every line until
#   <!-- end-not-a-claim-block -->
#
# This document declares three: the table that defines what each grade means,
# and two sentences that are about the grading scheme rather than graded by it.
# Each declaration sits where it applies, carries its reason, greps in one line,
# and is counted in this gate's summary. The first-character skip it replaces was
# unconditional, silent and uncounted. A marker carrying no reason does not
# exempt anything, so a careless one produces a refusal rather than a hole.
scan="$(awk '
  /<!--[ \t]*end-not-a-claim-block[ \t]*-->/ { inblock = 0; next }
  /<!--[ \t]*not-a-claim-block:[^>]*[A-Za-z][^>]*-->/ { inblock = 1; x++; next }
  inblock { next }
  /<!--[ \t]*not-a-claim:[^>]*[A-Za-z][^>]*-->/ { x++; next }
  /\[E\]|\[S\]/ { printf "C%d:%s\n", FNR, $0 }
  END { printf "X%d\n", x + 0 }
' "$DOC")"
exemptions="$(printf '%s\n' "$scan" | sed -n 's/^X//p')"

while IFS= read -r ln; do
  [ -n "$ln" ] || continue
  n="${ln%%:*}"; text="${ln#*:}"
  # Must be a WELL-FORMED id, matched with the same pattern used to extract
  # citations below. A substring test for '`S-' passed a claim citing `S-`,
  # which satisfied "has a citation" while being extracted as none — so neither
  # uncited-claim nor unknown-source fired and the hole was silent. Found by the
  # #29 mutation sweep.
  if printf '%s' "$text" | grep -qE '`S-[A-Z0-9]+[A-Z0-9-]*`'; then :; else
    refuse "$DOC" "uncited-claim" "line $n carries an [E] or [S] grade and cites no well-formed source ID: the grade is the point of this document, and an uncited grade is an assertion wearing a label. A line that names a grade without using one declares that in band — <!-- not-a-claim: reason -->"
  fi
done <<EOF
$(printf '%s\n' "$scan" | sed -n 's/^C//p')
EOF

# --- every cited ID is in the register ---------------------------------------
cited="$(grep -oE '`S-[A-Z0-9-]+`' "$DOC" | tr -d '`' | sort -u)"
while IFS= read -r c; do
  [ -n "$c" ] || continue
  printf '%s\n' "$ids" | grep -qx "$c" || refuse "$DOC" "unknown-source" \
    "cites $c, which is not in the register: a citation that resolves to nothing is worse than none, because it reads as evidence"
done <<EOF
$cited
EOF

# --- register entries nothing cites ------------------------------------------
# Reported, NOT refused. The first version refused these and it was wrong: the
# register is the corpus the document was derived from, not an index of its
# footnotes. Eight real sources — the security studies, the task-horizon work,
# the practitioner frameworks — are in it because the research used them, and
# refusing them would have pushed someone to either delete real sources or
# attach them to claims they do not support. Both are worse than an uncited row.
uncited=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  printf '%s\n' "$cited" | grep -qx "$id" || uncited=$((uncited + 1))
done <<EOF
$ids
EOF

# --- no document points at a ref that does not exist -------------------------
# The specific defect that left this document unevidenced: three files pointed
# at `experiment/0.0.0` as the route to the sources. Checking a backtick-quoted
# branch-shaped string against the refs actually present catches the class.
for f in "$DOC" "$REG" "$ROOT/README.md"; do
  [ -f "$f" ] || continue
  refs="$(grep -oE '`(experiment|branch)/[A-Za-z0-9._/-]+`' "$f" 2>/dev/null | tr -d '`' | sort -u)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    # Present as a local ref or a remote-tracking ref? Then nothing to check.
    git -C "$ROOT" rev-parse --verify --quiet "$r" >/dev/null 2>&1 && continue
    git -C "$ROOT" rev-parse --verify --quiet "origin/$r" >/dev/null 2>&1 && continue

    # The exemption is PER LINE, not per file. A document is allowed to name a
    # dead ref in order to say it is dead — but checking the whole file for that
    # sentence means one such sentence exempts every other mention, including a
    # new one that points at it as a live route to evidence.
    #
    # The first version did exactly that, and the test caught it. It is the same
    # defect the external audit found in validate-discovery.sh hours earlier:
    # grep over the whole file instead of over the scope the check is about.
    while IFS= read -r line; do
      case "$line" in
        *"does not exist"*|*"not on a branch"*|*"never did"*|*"was referenced"*) continue ;;
      esac
      refuse "$f" "dangling-ref" \
        "points at \`$r\`, which is not a ref in this repository: this is the defect that left STANDARDS.md with no reachable evidence"
      break
    done <<INNER
$(grep -F "$r" "$f")
INNER
  done <<EOF
$refs
EOF
done

if [ "$refusals" -gt 0 ]; then
  printf 'validate-standards: %s refusal(s)\n' "$refusals" >&2
  exit 1
fi
printf 'validate-standards: %s source(s) cited and resolving, %s in the register, %s not currently cited, %s line(s) declared not a claim\n' \
  "$(printf '%s\n' "$cited" | grep -c . )" "$(printf '%s\n' "$ids" | grep -c .)" "$uncited" "$exemptions"
