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

# A document that DISPLAYS a declaration must not thereby SATISFY it. This gate
# tracked fences for exactly one of its four declaration forms; the other three and
# the other four display forms were open, and one of them switched CTRL-8 off.
# bin/lib-rendering.sh holds the rule, the two projections and the cost of sharing it.
RENDERING="${RENDERING_LIB:-$ROOT/bin/lib-rendering.sh}"
if [ ! -f "$RENDERING" ]; then
  printf 'validate-standards: no rendering library at %s — without it a declaration shown to a reader would exempt the claims it illustrates, so this gate will not run\n' "$RENDERING" >&2
  exit 2
fi
. "$RENDERING"

# documents -> every document whose graded claims and evidence pointers this gate
# reads, relative to ROOT
#
# WHY THIS IS NOT JUST STANDARDS.md ANY MORE
#
# It was, and the rule it implements is not about one file. `AGENTS.md:156` says
# "grade every claim", and `AGENTS.md` carried four `[E]` claims with no source ID
# and none of their sources in the register — the exact failure this gate was built
# for, "31 graded claims, zero citations", reproduced in a second document because
# the gate was keyed to a FILENAME rather than to the marker.
#
# The pointer half was keyed to a hand-written list of four documents, and
# `CONTROLS.md` was not one of them while carrying the heaviest commit-citation load
# in the repository. Replacing one of its SHAs with a dead one passed every gate.
#
# ENUMERATED POSITIVELY, which is the point. A list of excludes is a denylist and
# `AGENTS.md` rules against one for a gate: every miss is silent and the set of
# things that should have been in scope is unbounded. These four globs say what IS
# in scope, so a new document at one of those depths is read by existing rather than
# by someone remembering to add it.
#
# WHAT IS OUT, AND WHY. The dated records — `process/*/findings/*`,
# `process/*/topics/*`, `process/*/problems/*`, `process/*/options/*`,
# `process/*/cycles/*`, `process/*/decisions/*` — are one level deeper than
# `process/*/*.md` and so are outside these globs. Their contracts require a
# resolving source IN THE ROW for every claim, which is a different and stricter
# mechanism than a register ID; asking them for `S-` ids would refuse every one of
# the 26 graded claims they carry correctly. `tests/` is out because a fixture
# exists to be refused by a gate, and a document built to fail a check is not a
# document making a claim to a reader.
#
# From the filesystem rather than from `git ls-files`, because
# tests/test_validate_standards.sh drives this gate against a copied tree whose
# index is empty — an enumeration from the index would read nothing there and the
# suite would prove the opposite of what it is for.
documents() {
  ( cd "$ROOT" && ls *.md .github/*.md .github/*/*.md process/*/*.md 2>/dev/null )
}

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
#
# Each declaration sits where it applies, carries its reason, greps in one line, and
# is counted in this gate's summary. The first-character skip it replaces was
# unconditional, silent and uncounted. A marker carrying no reason does not exempt
# anything, so a careless one produces a refusal rather than a hole.
#
# THE SPAN FORM IS GONE, AND IT WAS A CRITICAL. There was a second form:
#
#   <!-- not-a-claim-block: reason -->    exempted every line until
#   <!-- end-not-a-claim-block -->
#
# The terminator was not required and the opener was honoured inside a fenced block.
# Issue #116 reproduced the consequence: delete the one `end-not-a-claim-block` line
# from STANDARDS.md and strip every `S-` citation, and this gate reported *20 not
# currently cited* and EXITED 0. Twenty uncited graded claims, CTRL-8 switched off by
# deleting one line. The form was disclosed nowhere — `grep -c not-a-claim-block
# CONTROLS.md` returned 0 — while CONTROLS.md praised the per-line form against
# *"what it replaced, which exempted every table row and every blockquote in the
# document."* An unterminated span exemption is that, with a reason attached.
#
# IT IS DROPPED RATHER THAN REPAIRED, and the alternative was real: make the
# terminator mandatory and read the opener in a rendering context. Dropped because
# the span bought nothing the per-line form does not. It covered one thing — the five
# rows of the grade table in STANDARDS.md, of which two carry a marker this gate
# reads — and it cost three properties the per-line form has: each exempted line
# carries its own reason, each is counted in the summary, and an exemption cannot
# outrun the thing it was written for. The summary said *9 line(s) declared not a
# claim* while the span was exempting eleven, which is why the reproduction was
# invisible in the output. Fewer forms honestly enforced is this repository's standing
# trade and this is the second time it has been the right answer.
#
# A document still carrying the retired form gets `uncited-claim` on the lines it
# meant to exempt, and that refusal names the per-line form. tests/test_rendering.sh
# pins that the retired opener exempts nothing, displayed or not.
#
# ONE DOCUMENT MAY DECLARE THAT ITS GRADED CLAIMS RESOLVE INLINE, with a reason:
#
#   <!-- graded-claims-cite-inline: reason -->
#
# That exempts the document from `uncited-claim` and from nothing else. It exists
# because `AGENTS.md` carries four `[E]` claims whose sources — a Kubernetes release
# audit, a repository, an ICSE 2013 paper, an arXiv id — are named in the prose and
# are in no register entry. The two ways to make it pass were to invent four register
# rows, which means guessing a publication date and a limitations field for sources
# nobody here opened and is the defect `SOURCES.md` exists to prevent, or to declare
# the weaker state and check that the declaration is there. The second is honest; the
# first reads as evidence.
#
# It is DECLARED rather than hardcoded so a reader sees it in the document making the
# claim, it carries a reason, it is counted in the summary, and `CONTROLS.md` names
# every document that carries one. Promoting those claims to register entries is the
# owner's: it needs the four sources opened.
exemptions=0
inline_docs=""
for d in $(documents); do
  f="$ROOT/$d"
  [ -f "$f" ] || continue
  # TWO READINGS OF THE SAME FILE, AND THE ASYMMETRY IS THE POINT.
  #
  # The EXEMPTIONS are read from the span projection: a declaration is an HTML comment,
  # a whole HTML comment fits inside an inline code span, and a document showing a
  # reader the form must not thereby exempt its own claims. This gate already tracked
  # fences for `graded-claims-cite-inline` alone, which was the fifth time this
  # repository paid for a fenced example being read as the real thing; the other four
  # display forms were not known to it.
  #
  # The CLAIMS are read from the RAW file, and that is measured rather than assumed.
  # A grade marker is written in backticks here — it is the house style, and
  # AGENTS.md's four `[E]` claims are written that way — so sixteen lines carrying a
  # real grade disappear from the span projection. Reading claims through it would
  # hide four real claims in the one document this gate was widened to cover, which is
  # a loosening of a check that works made as a side effect of closing something else.
  #
  # The consequence is stated rather than hidden: a graded claim written inside a fence
  # is still read, and a `not-a-claim` written inside the same fence does not exempt
  # it. A document wanting to show a reader an example graded claim cites it, or
  # declares it on a line outside the fence.
  #
  # Both projections preserve line numbers, so the two are joined by FNR: the span
  # projection is read first into E, then the raw file is read against it.
  #
  # Fed to awk through a here-document rather than `-v`, which runs backslash escape
  # processing over the value — these documents carry `\b` and `\?` in prose, and an
  # exemption line is not a place to be mangling text. Rather than a temp file, for the
  # reason this gate's neighbour records: scratch state the verdict depends on is a
  # failure mode, not a mechanism.
  #
  # THE VIEW IS CAPTURED AND ITS STATUS CHECKED BEFORE awk SEES IT. Written first as
  # `<(rendered_spans_file "$f")`, whose failure is invisible: the first input came
  # back empty, `NR == FNR` was then true for the FIRST LINE OF THE REAL FILE, and
  # every exemption in that document vanished while the gate exited 0. A here-document
  # always carries at least one line, so the join cannot slip.
  exempt_view="$(rendered_spans_file "$f")" || {
    printf 'validate-standards: could not read %s as rendered text\n' "$f" >&2; exit 2; }
  scan="$(awk '
    NR == FNR { E[FNR] = $0; next }
    E[FNR] ~ /<!--[ \t]*graded-claims-cite-inline:[^>]*[A-Za-z][^>]*-->/ { inline = 1; next }
    E[FNR] ~ /<!--[ \t]*not-a-claim:[^>]*[A-Za-z][^>]*-->/ { x++; next }
    /\[E\]|\[S\]/ { printf "C%d:%s\n", FNR, $0 }
    END { printf "X%d\nI%d\n", x + 0, inline + 0 }
  ' /dev/stdin "$f" <<SPANVIEW
$exempt_view
SPANVIEW
)"
  exemptions=$((exemptions + $(printf '%s\n' "$scan" | sed -n 's/^X//p')))
  if [ "$(printf '%s\n' "$scan" | sed -n 's/^I//p')" = 1 ]; then
    inline_docs="${inline_docs:+$inline_docs }$d"
  else
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
        refuse "$f" "uncited-claim" "line $n carries an [E] or [S] grade and cites no well-formed source ID: a grade is the claim's evidence, and an uncited grade is an assertion wearing a label. A line that names a grade without using one declares that in band — <!-- not-a-claim: reason -->. A document whose graded claims resolve in their own prose rather than through the register declares that once, <!-- graded-claims-cite-inline: reason -->, and CONTROLS.md names it"
      fi
    done <<EOF
$(printf '%s\n' "$scan" | sed -n 's/^C//p')
EOF
  fi
done

# --- every cited ID is in the register ---------------------------------------
# Over every document in the surface, not just the one: a citation that resolves to
# nothing reads as evidence wherever it is written.
#
# THE REGISTER ITSELF IS NOT A CITATION OF ITS OWN ENTRIES. Found by this gate's own
# suite the moment the surface widened: every register row names its id in backticks,
# so reading citations out of SOURCES.md made all 22 entries self-cited, and
# "register entries nothing cites" — the number DECIDERS.md and SOURCES.md have both
# been corrected against — collapsed to zero. A row declaring an id is a definition,
# not a reference to one.
cited="$(for d in $(documents); do
  [ "$ROOT/$d" = "$REG" ] && continue
  grep -oE '`S-[A-Z0-9-]+`' "$ROOT/$d" 2>/dev/null
done | tr -d '`' | sort -u)"
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
# SEVEN MORE SHAPES ARE NOT POINTERS, added when the surface stopped being a list of
# four. Each is a narrowing of the check and each is here because the token cannot be
# a place, not because refusing it was inconvenient:
#
#   a glob          `bin/validate-*.sh` is a pattern over paths, not one path
#   a bracket       `[E]/[S]` is a pair of grade markers
#   a variable      `cycles/$c.md` is a path a script computes, not one that exists
#   a locator       `bin/next.sh:163:?` is file:line:code output, not an object name
#   absolute        `/bin/bash` is on the machine, not in the repository
#   `scheme:`       `doi:10.1145/3597503` resolves through a registrar
#   a namespace     `experiment/` and `findings/` name a namespace and not a place,
#                   so a token whose only `/` is its last character is a fragment
#
# The seventh is the one worth arguing with: it means a dead ref written as `foo/`
# passes. That is the same class as the one-level branch name CTRL-8 already records
# as not covered, and the alternative was refusing every prose mention of a directory.
is_pointer() { # token -> 0 if the document is pointing at something
  case "$1" in
    *' '*|*'<'*|*'>'*) return 1 ;;   # a phrase or an identity, not a pointer
    *'://'*) return 1 ;;             # a URL resolves on the web, not in here
    *'*'*|*'['*|*']'*|*'$'*|*'?'*) return 1 ;;
    /*) return 1 ;;
  esac
  printf '%s' "$1" | grep -qE '^[0-9a-f]{7,40}(:.+)?$' && return 0
  # `scheme:` ahead of any `/`. The object-name form above is checked first, so
  # `fa7538a:research/...` is already accepted and only a real scheme reaches here.
  case "${1%%/*}" in *:*) return 1 ;; esac
  case "$1" in
    */*/*) return 0 ;;               # two or more segments: a place
    */) return 1 ;;                  # one segment and a trailing slash: a namespace
    */*) return 0 ;;
  esac
  return 1
}

# A path is resolved FROM THE REPOSITORY ROOT ONLY.
#
# A document-relative fallback was written here first, because widening the surface to
# all seventeen documents refused eleven correct relative paths — a contract beside its
# records writes `cycles/2026-09-29.md`. Then the surface became the six documents that
# cite an object name, every one of them at the top level, and removing the fallback
# broke nothing: measured, zero refusals and no suite failure. So it was a fix for a
# problem the final shape does not have, and it is gone rather than kept in case.
#
# What that costs: if a document under `process/` later cites an object name it joins
# this surface, and its relative paths would be refused until the fallback comes back.
# Written down rather than guarded against.
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

# DERIVED, not a hand-written list. This was `"$DOC" "$REG" README.md DECIDERS.md` —
# four documents chosen by whoever last edited the line. `CONTROLS.md` was not among
# them while carrying more commit citations than any of the four, so replacing one of
# its SHAs with a dead one passed this gate, validate-controls, test_doc_claims and
# test_controls. `spec.md` was missing too, with two.
#
# A document is in this surface when it CITES AN OBJECT NAME — a 7-to-40 character
# hexadecimal token in backticks, optionally with `:<path>`. That is the shape of an
# evidence route in this repository: the research corpus is in history at a commit and
# not on any branch, so a document that says "the evidence is at X" says it with an
# object name. Six documents qualify today and the list is read off the tree, so a
# seventh is covered by existing rather than by someone remembering this line.
#
# WHY NOT EVERY DOCUMENT. `is_pointer` below treats a backticked token containing `/`
# as a repository path, which is close to true in a document whose backticks are
# mostly paths and badly false elsewhere: run over all seventeen documents it refuses
# twenty-nine tokens, almost all of them globs, grade pairs, DOIs and third-party
# repository slugs. Widening further means recalibrating that heuristic, which is its
# own change with prose churn in ten files. The surface is derived from the thing the
# check is for instead.
# A POINTER IS READ FROM THE RAW FILE AND ITS DECLARATION FROM THE SPAN PROJECTION,
# which is the same split the claim scan above makes and for the same reason: a pointer
# IS a backticked token, so the span projection does not contain one.
#
# READING THE POINTER SET FROM A PROJECTION WAS TRIED AND REVERTED, and the reason is
# worth keeping. `grep -oE` pairs backticks left to right across the whole file, so
# blanking fenced transcripts changes which tokens pair up: over CONTROLS.md the line
# projection extracted `experiment/0.0.0` where the raw file did not, and line 272
# then drew `dangling-ref` for naming it without a declaration. That is a real gap in
# the extraction and it is NOT this change — nothing on #116 is evidence for it, and
# closing it refuses a shipped document. It is reported to the owner instead.
#
# What stays open as a consequence: a dead pointer named only inside a fenced
# transcript is still refused. No document does that today.
pointer_docs="$(for d in $(documents); do
  grep -qE '`[0-9a-f]{7,40}(:[^` ]+)?`' "$ROOT/$d" 2>/dev/null && printf '%s\n' "$d"
done)"
for d in $pointer_docs; do
  f="$ROOT/$d"
  [ -f "$f" ] || continue
  spanview="$(rendered_spans_file "$f")" || {
    printf 'validate-standards: could not read %s as rendered text\n' "$f" >&2; exit 2; }
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
    # WHICH LINES CARRY THE POINTER CLAIM, and the DECLARATION read from the span
    # projection at the same line number — both projections preserve them.
    #
    # The lines are the ones carrying the token as a COMPLETE BACKTICKED TOKEN, which
    # is the shape `refs` extracted it with. It was every line containing the token as
    # a substring, and that was wrong in both directions at once:
    #
    #   a hole — CONTROLS.md shows a reader the form, `<!-- dead-pointer:
    #   experiment/0.0.0 — reason -->` inside a code span, and the raw line was read,
    #   so an illustration retired the pointer it was illustrating. Any document could
    #   retire any pointer by showing what retiring one looks like.
    #
    #   a false refusal — reading the declaration from the span projection and the
    #   mention as a substring then refuses that same illustration line, because the
    #   mention survives and the declaration does not. Documenting the form would
    #   break the build, which is the other half of #116.
    #
    # A mention inside a longer code span, or inside an HTML comment, is not a pointer
    # a reader is being sent to. A bare `experiment/0.0.0` is, and that is the shape
    # the three files that caused this check used.
    while IFS= read -r hit; do
      line="$(printf '%s\n' "$spanview" | sed -n "${hit%%:*}p")"
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
$(grep -nF "\`$r\`" "$f")
INNER
  done <<EOF
$refs
EOF
done

if [ "$refusals" -gt 0 ]; then
  printf 'validate-standards: %s refusal(s)\n' "$refusals" >&2
  exit 1
fi
printf 'validate-standards: %s source(s) cited and resolving, %s in the register, %s not currently cited, %s line(s) declared not a claim, %s document(s) read%s\n' \
  "$(printf '%s\n' "$cited" | grep -c . )" "$(printf '%s\n' "$ids" | grep -c .)" "$uncited" "$exemptions" \
  "$(documents | grep -c .)" \
  "${inline_docs:+, graded claims cite inline in: $inline_docs}"
