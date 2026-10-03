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
# rather than produced by a stage.
#
# Applying a decision is a FIELD PLUS A LINK, not a sixth phase: the decision
# carries `amends:` naming and linking the document it changes, the amended claim
# carries `decided:` linking back, and validate-decision.sh refuses either half
# missing. A `process/06-update/` phase would have had one artifact — a diff to a
# file that already exists — and a contract describing how to edit Markdown. So
# there is no phase directory for this gate to belong to, and it sits in bin/ with
# the other repository-level tools.
#
# The full reasoning is in process/05-deliver/deliver-contract.md, section
# "`amends`, and why Update is not a sixth phase", and in that contract's open
# question 3, struck through where it was settled. Decided in issue #18, which a
# clone cannot read — hence the summary here.
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

# This gate resolves evidence pointers against the repository it is run in, so it
# needs a repository with the history in it. Neither of these can be reported as
# a clean document: a gate that cannot check must say so rather than pass. Same
# failure as the one AGENTS.md records for validate-claims.sh, where a pattern
# that would not compile was read as "nothing found" and the tree was reported
# clean having been evaluated not at all.
if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  printf 'validate-standards: %s is not a git repository, so an evidence pointer cannot be resolved\n' "$ROOT" >&2
  exit 2
fi
if [ "$(git -C "$ROOT" rev-parse --is-shallow-repository 2>/dev/null)" = true ]; then
  printf 'validate-standards: this is a shallow clone, so a pointer into history cannot be resolved. Fetch the full history — in Actions that is actions/checkout with fetch-depth: 0\n' >&2
  exit 2
fi

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
  # uncited-claim nor unknown-source fired and the hole was silent.
  #
  # Found by LOOSENING the comparison rather than deleting it: swapping the exact
  # match for a substring match broke no test, which showed the suite pinned that
  # the check was reachable and not that it was sufficient. The method is in
  # AGENTS.md, "Tests: pin the invariant, not the literals"; it came out of issue
  # #29, which a clone cannot read.
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

# --- no document points at something git cannot find -------------------------
# The specific defect that left this document unevidenced: three files pointed
# at `experiment/0.0.0` as the route to the sources, and it was never a ref.
#
# The check used to match backtick-quoted strings beginning `experiment/` or
# `branch/`. That enumerated the two namespaces the one known defect happened to
# use, and left out the pointer the repository now actually depends on — the
# commit `fa7538a`, which is the only route to the evidence corpus because the
# corpus is in history and not on any branch. Replacing it with a dead commit
# left this gate reporting every document clean. `DECIDERS.md` records that the
# planned identity cleanup is a force-push rewriting every SHA, so the documented
# next step creates exactly that condition.
#
# A backticked token is a pointer — something the document says a reader can go
# and find — when it is one of two things:
#
#   it contains a `/`, so it names a place: a path in the working tree, or a ref
#
#   it is 7 to 40 hexadecimal characters, optionally followed by `:<path>` — an
#   object name, which is how a commit and a file inside a commit are cited here
#
# A pointer resolves if the working tree has it as a path OR git has it as an
# object or a ref. Which of the two it was meant to be does not matter: either
# way a reader can open it. `github/docs` and `experiment/0.0.0` are the same
# shape and only one of them needs to be a ref.
#
# What this does NOT cover is a one-level branch or tag name. `main` and `v0.1`
# in backticks are not distinguishable from an ordinary word or a version number
# in prose, and guessing would refuse `v4.0.1` in a sentence about PCI DSS.
# CONTROLS.md carries that under what is not controlled.
is_pointer() { # token -> 0 if the document is pointing at something
  case "$1" in
    *' '*|*'<'*|*'>'*) return 1 ;;   # a phrase or an identity, not a pointer
    *'://'*) return 1 ;;             # a URL resolves on the web, not in here
  esac
  printf '%s' "$1" | grep -qE '^[0-9a-f]{7,40}(:.+)?$' && return 0
  case "$1" in */*) return 0 ;; esac
  return 1
}

resolves() { # pointer -> 0 if this repository has it, as a path or in git
  [ -e "$ROOT/$1" ] && return 0
  # `^{object}` rather than a bare --verify, and that is load-bearing:
  # `git rev-parse --verify <40 hex digits>` succeeds on a full-length name
  # whether or not the object is present, so without the peel a fabricated SHA
  # resolves. Checked on git 2.50.1.
  git -C "$ROOT" rev-parse --verify --quiet "$1^{object}" >/dev/null 2>&1 && return 0
  # The peel does not apply to the `<commit>:<path>` form, which is how a file
  # inside a commit is cited here. That form proves existence by reading the
  # tree, so a bare --verify is sound for it and only for it.
  case "$1" in
    *:*) git -C "$ROOT" rev-parse --verify --quiet "$1" >/dev/null 2>&1 && return 0 ;;
  esac
  git -C "$ROOT" rev-parse --verify --quiet "refs/remotes/origin/$1" >/dev/null 2>&1 && return 0
  git -C "$ROOT" rev-parse --verify --quiet "refs/heads/$1" >/dev/null 2>&1 && return 0
  git -C "$ROOT" rev-parse --verify --quiet "refs/tags/$1" >/dev/null 2>&1 && return 0
  return 1
}

for f in "$DOC" "$REG" "$ROOT/README.md" "$ROOT/DECIDERS.md"; do
  [ -f "$f" ] || continue
  refs="$(grep -oE '`[^` ]+`' "$f" 2>/dev/null | tr -d '`' | sort -u)"
  while IFS= read -r r; do
    [ -n "$r" ] || continue
    is_pointer "$r" || continue
    resolves "$r" && continue

    # A document is allowed to name a dead pointer in order to record that it is
    # dead. The exemption has to be scoped as tightly as the thing it exempts,
    # and it has taken two goes to get there:
    #
    #   per FILE — one sentence saying a ref was dead exempted every mention of
    #   it in the file, including a new one presenting it as a live route to
    #   evidence. Caught by a test.
    #
    #   per LINE, by phrase — any of four phrases anywhere on the line exempted
    #   every pointer on that line. `SOURCES.md` line 5 names the dead branch and
    #   the live commit in one sentence, so replacing the commit with a dead one
    #   was accepted. Caught by the #55 work, by mutating the commit rather than
    #   the branch.
    #
    # It is now per POINTER, declared in band and naming the pointer it exempts:
    #
    #   <!-- dead-pointer: experiment/0.0.0 — never existed on origin -->
    #
    # A declaration that does not name this pointer does not exempt it, and one
    # carrying nothing but the pointer does not exempt it either, because then
    # there is no reason recorded. Same shape as the not-a-claim declarations
    # above: explicit, greppable, and reviewable where a phrase match was a guess.
    while IFS= read -r line; do
      decl="$(printf '%s' "$line" | sed -n 's/.*<!--[[:space:]]*dead-pointer:\([^>]*\)-->.*/\1/p')"
      case "$decl" in
        *"$r"*)
          case "${decl/$r/}" in
            *[A-Za-z]*) continue ;;
          esac
          ;;
      esac
      refuse "$f" "dangling-ref" \
        "points at \`$r\`, which this repository has neither as a path nor in git history: this is the defect that left STANDARDS.md with no reachable evidence. If it is somewhere else — another repository, a URL — link it rather than writing it in backticks, because a reader cannot open this. If it is named in order to record that it is dead, say so in band: <!-- dead-pointer: $r — reason -->"
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
