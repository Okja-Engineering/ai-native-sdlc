#!/usr/bin/env bash
# CONTROLS.md must describe gates that exist and refusals they actually emit.
#
# A control document is the one artifact here with a strong incentive to drift
# optimistic: it is read by people assessing the process, and nothing about
# writing prose forces it to stay true. So every control cites the script that
# enforces it and the refusal codes that script emits, and this suite checks
# both. A control claiming a refusal no gate produces is the failure mode.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
DOC="$ROOT/CONTROLS.md"

assert_file_exists "$DOC" "the controls document exists"

# --- the per-control binding, driven through the gate -------------------------
# This section used to do the checking itself, with two string searches, and both
# were vacuous:
#
#   * It collected every gate path named anywhere in the document into one set and
#     asked whether a cited code appeared in ANY of them. Pointing CTRL-1 at the
#     scan gate, which emits none of its four codes, passed 18 of 18.
#   * The membership test was `grep -q -- "$code" "$gate"` — a plain substring over
#     the whole file. Adding one comment line to any gate made a fabricated refusal
#     code pass.
#
# The checking now lives in bin/validate-controls.sh, for the same reason
# bin/validate-claims.sh stopped being a line in ci.yml: a check embedded in its own
# test cannot be run against a document built to break it. This drives that gate
# against the shipped document and against documents constructed to fail.
#
# Most of the failing documents are DERIVED from the live CONTROLS.md at run time
# rather than checked in. A checked-in copy goes stale the moment someone edits a
# control, and then the drift test is testing an old document.
GATE="$ROOT/bin/validate-controls.sh"
FIX="$TEST_DIR/fixtures/controls"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$GATE" "the gate that checks the document exists"

# run <document> — the gate's output, with its exit status returned.
run() { out="$(/bin/bash "$GATE" "$1" 2>&1)"; st=$?; printf '%s\n' "$out"; return "$st"; }

out="$(run "$DOC")"; st=$?
assert_status 0 "$st" "the shipped document passes the gate"

# A gate that checked nothing would also exit 0, so the denominator is printed and
# asserted. This whole repair is about a check that could not fail.
nsites="$(printf '%s\n' "$out" | sed -n 's/.*refusals, \([0-9]*\) emission sites.*/\1/p')"
[ "${nsites:-0}" -ge 80 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "it read a real denominator of emission sites (reported ${nsites:-none})"
ncited="$(printf '%s\n' "$out" | sed -n 's/.*controls, \([0-9]*\) cited refusals.*/\1/p')"
[ "${ncited:-0}" -ge 40 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "it resolved every refusal the document cites (reported ${ncited:-none})"
nctrl="$(printf '%s\n' "$out" | sed -n 's/validate-controls: \([0-9]*\) controls.*/\1/p')"
[ "${nctrl:-0}" -ge 9 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "it found every control block (reported ${nctrl:-none})"

# --- a code emitted by a DIFFERENT gate does not satisfy the control ----------
# The invariant, stated as the assertion. `undecided-by` is emitted by the deliver
# gate, so the document-wide union this replaces passed the derived document below.
# The per-control binding must not.
awk '{ gsub(/process\/05-deliver\/validate-decision.sh/, "process/01-scan/validate-findings.sh"); print }' \
  "$DOC" > "$TMP/wrong-gate.md"
out="$(run "$TMP/wrong-gate.md")"; st=$?
assert_status 1 "$st" "a control pointed at a gate that emits none of its codes is refused"
assert_contains "$out" "refuse[cited-not-emitted]" "and the refusal says the cited code is not emitted"
assert_contains "$out" 'cites refusal `undecided-by`' "and it names the code that does not resolve"

# The code is still emitted somewhere in the repository, which is what makes this a
# test of the binding rather than of the code's existence.
assert_contains "$(/bin/bash "$ROOT/bin/list-refusals.sh" "$ROOT/process/05-deliver/validate-decision.sh")" \
  "undecided-by" "the code is still emitted by the gate the document stopped naming"

# --- a mention is not an emission site ----------------------------------------
# The two fixture documents differ in one thing: the path on the Enforced by line.
# The two fixture gates differ in one thing: whether the code is in a comment or in
# a call. So the red and green here can only be about that difference.
out="$(run "$FIX/comment-only.md")"; st=$?
assert_status 1 "$st" "a code that appears only in a comment is refused"
assert_contains "$out" "refuse[cited-not-emitted]" "and the refusal is cited-not-emitted"
assert_contains "$out" 'cites refusal `fixture-refusal`' "and it names the code"

assert_contains "$(cat "$FIX/mentions-in-a-comment.sh")" "fixture-refusal" \
  "the comment-only fixture does carry the code as a substring"

out="$(run "$FIX/emission-site.md")"
assert_not_contains "$out" "refuse[cited-not-emitted]" \
  "the same code at a real emission site is accepted"

# --- a code in prose rather than in the table ---------------------------------
# The table is the only place the check reads codes from, so a code that drifts into
# prose would be unchecked. CTRL-5 named `no-method` on its Enforced by line and
# CTRL-6 named eight codes in a sentence; all nine were outside the old check.
awk '{ if ($0 ~ /^\| `not-a-person`/) print "This control also emits `not-a-person`."; else print }' \
  "$DOC" > "$TMP/in-prose.md"
out="$(run "$TMP/in-prose.md")"; st=$?
assert_status 1 "$st" "a code moved out of the table into prose is refused"
assert_contains "$out" "refuse[code-in-prose]" "and the refusal says to put it back in the table"

# --- a control with no enforcement at all -------------------------------------
# CTRL-9 had no Enforced by line, which is how its five hook and CI controls were
# outside the check.
awk 'BEGIN { done = 0 }
     /^\*\*Enforced by\*\*/ && done == 0 { done = 1; next }
     { print }' "$DOC" > "$TMP/no-enforced-by.md"
out="$(run "$TMP/no-enforced-by.md")"; st=$?
assert_status 1 "$st" "a control naming no enforcement is refused"
assert_contains "$out" "refuse[no-enforced-by]" "and the refusal says a control names what refuses"

awk '{ if ($0 ~ /^\| `no-method`/) next; print }' "$DOC" > "$TMP/no-codes.md"
out="$(run "$TMP/no-codes.md")"; st=$?
assert_status 1 "$st" "a control naming a gate and citing no refusal is refused"
assert_contains "$out" "refuse[no-refusal-cited]" "and the refusal says where the codes go"

# --- CTRL-9's enforcement is resolved, not excluded ---------------------------
# Two hooks, a script and three CI jobs, and no refusal table. That put it outside
# the old check twice: codes came from table rows, and the gate pattern matched only
# validate-*.sh so neither hook could be checked even if they had been harvested.
awk '{ gsub(/`commit-messages`/, "`commit-msgs`"); print }' "$DOC" > "$TMP/bad-job.md"
out="$(run "$TMP/bad-job.md")"; st=$?
assert_status 1 "$st" "a CI job a control names and the workflow does not declare is refused"
assert_contains "$out" "refuse[job-unresolved]" "and the refusal says which job"

awk '{ gsub(/`.githooks\/pre-push`/, "`.githooks/pre-pish`"); print }' "$DOC" > "$TMP/bad-hook.md"
out="$(run "$TMP/bad-hook.md")"; st=$?
assert_status 1 "$st" "a hook path a control names and the repository does not have is refused"
assert_contains "$out" "refuse[enforcement-unresolved]" "and the refusal says which path"

# --- backward: a refusal a gate emits and no control claims -------------------
# `validate-decision.sh` emitted `no-chosen-field` with no control and no test, and
# the scan gate emitted seven more the same way. A one-directional check cannot see
# any of them: the document resolves fine, and the gap is in what it does not say.
awk '{ if ($0 ~ /^\| `undated-decision`/) next; print }' "$DOC" > "$TMP/uncited.md"
out="$(run "$TMP/uncited.md")"; st=$?
assert_status 1 "$st" "a refusal a gate emits and no control cites is refused"
assert_contains "$out" "refuse[uncited-refusal]" "and the refusal is uncited-refusal"
assert_contains "$out" 'emits refusal `undated-decision`' "and it names the unclaimed code"

# The forward direction still passes on that document, which is what makes this a
# test of the second direction rather than a second test of the first.
assert_not_contains "$out" "refuse[cited-not-emitted]" \
  "the forward check is satisfied by the same document"

# --- and the citation has to be by a control naming THAT gate -----------------
# A control citing the code is not enough: it has to be a control that names the
# gate emitting it. `no-method` moves from CTRL-5, which names the define gate, to
# CTRL-1, which names the deliver gate. The define gate still emits it and no
# control naming the define gate claims it any more.
#
# Found by loosening the comparison to "some control cites this code", which the
# assertions above did not catch. That is the same defect as the one being repaired,
# one direction over: a document-wide union standing in for a per-control binding.
awk '{
       if ($0 ~ /^\| `no-method`/) next
       print
       if ($0 ~ /^\| `undecided-by`/) print "| `no-method` | moved to a control naming a different gate |"
     }' "$DOC" > "$TMP/wrong-control.md"
out="$(run "$TMP/wrong-control.md")"; st=$?
assert_status 1 "$st" "a code cited by a control naming a different gate is refused"
assert_contains "$out" 'emits refusal `no-method`' "and the gate that emits it is reported as unclaimed"

# --- sideways: a gate no control names ----------------------------------------
# The surface is enumerated from the tree. Both hooks were missing from this
# document until an external audit found them, and nothing reading only the
# document could have noticed.
awk '{ gsub(/`process\/02-discover\/validate-discovery.sh`/, "`process/02-discover/validate-discovery.sh `"); print }' \
  "$DOC" > "$TMP/unnamed-gate.md"
out="$(run "$TMP/unnamed-gate.md")"; st=$?
assert_status 1 "$st" "a gate no control names is refused rather than skipped"
assert_contains "$out" "refuse[uncontrolled-gate]" "and the refusal names the gate with no control"
assert_contains "$out" "validate-discovery.sh" "and says which one"

# Both hooks are in the surface, so the check covers them. Asserted by name,
# because "the surface" is the claim and the hooks are the case that was missing.
for h in .githooks/commit-msg .githooks/pre-push; do
  awk -v h="$h" '{ gsub("`" h "`", "`" h "x`"); print }' "$DOC" > "$TMP/drop-hook.md"
  out="$(run "$TMP/drop-hook.md")"; st=$?
  assert_status 1 "$st" "dropping $h from the document is refused"
  assert_contains "$out" "refuse[uncontrolled-gate]" "and $h is reported as having no control"
done

# --- an exception has to name something real and carry a reason ---------------
# The exception table is the replacement for silent exclusion, so an entry with no
# reason is the thing it was built to stop.
awk '{ if ($0 ~ /^\| `bin\/validate-authorship.sh`/) print "| `bin/validate-authorship.sh` | the gate itself |  |"; else print }' \
  "$DOC" > "$TMP/no-reason-exc.md"
out="$(run "$TMP/no-reason-exc.md")"; st=$?
assert_status 1 "$st" "an exception with no reason is refused"
assert_contains "$out" "refuse[exception-no-reason]" "and the refusal says a reason is required"

awk '{ if ($0 ~ /^\| `bin\/validate-authorship.sh`/) print "| `bin/validate-nothere.sh` | the gate itself | because |"; else print }' \
  "$DOC" > "$TMP/absent-exc.md"
out="$(run "$TMP/absent-exc.md")"; st=$?
assert_status 1 "$st" "an exception naming a script that is not here is refused"
assert_contains "$out" "refuse[enforcement-unresolved]" "and the refusal says the path does not resolve"
assert_contains "$out" "refuse[uncontrolled-gate]" "and the gate it was meant to cover is uncovered again"

# The exception table is not empty, or every assertion about it would be about a
# mechanism nothing uses.
nexc="$(printf '%s\n' "$(run "$DOC")" | sed -n 's/.*read, \([0-9]*\) exception.*/\1/p')"
[ "${nexc:-0}" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the document declares at least one exception (reported ${nexc:-none})"

# --- a document the gate cannot read must not report clean -------------------
# Exit 2 is "could not run". Exit 0 on a document with no controls would make every
# assertion above pass against an empty denominator.
printf '# Not a controls document\n\nNothing here.\n' > "$TMP/empty.md"
run "$TMP/empty.md" >/dev/null 2>&1
assert_status 2 "$?" "a document declaring no controls exits 2 rather than reporting clean"


# --- the other document that makes enforcement claims -------------------------
# This suite read one document. The enforcement claims live in several, and the
# one that drifted was in the other: SOURCES.md said `bin/validate-standards.sh`
# "refuses an ID here that nothing cites". It does not — the gate counts them,
# prints `8 not currently cited` and exits 0, and CONTROLS.md said so correctly.
# Comparing a control to its gate caught nothing, because the false sentence was
# not in the control document.
#
# Two rules, both of them the ones already applied to CONTROLS.md above:
#
#   1. a sentence saying the gate refuses something names which refusal
#   2. the refusal it names is one the gate actually emits
#
# Rule 1 is what lets rule 2 fire at all. A prose claim carrying no code cannot be
# resolved against anything, which is how the false one survived a check written
# to stop exactly this.
#
# A line that mentions a refusal without claiming one — the correction above says
# the gate never refused these, and has to use the word to say so — declares that
# in band and carries a reason, the same shape the standards gate uses for
# `not-a-claim` and `dead-pointer`. The count of honoured declarations is asserted,
# so an exemption cannot be added silently.
REG_DOC="$ROOT/SOURCES.md"
STD_GATE="$ROOT/bin/validate-standards.sh"
assert_file_exists "$REG_DOC" "the source register exists"

# TMP and its trap are declared once, in the section above. A second mktemp -d
# here would leave the first directory behind, because the trap only removes
# whatever TMP points at last.

# A declaration honoured only when it carries a reason. One copy of the pattern,
# used by the sweep and by the count, so the two cannot disagree about what
# counts as declared. An exemption that needs no reason is one nobody justifies.
DECLARED='not-an-enforcement-claim:[[:space:]]*[A-Za-z0-9`]'

# One implementation, run against the register and against fixtures, so a fixture
# proves the decision this makes rather than a second copy of it. Prints the
# offending line numbers and nothing else — a function whose output is captured
# runs in a subshell, so it cannot report a count by setting a variable.
unbacked_enforcement_claims() { # <document> <gate> -> offending line numbers
  local doc="$1" gate="$2" base ln rn text backed c
  base="$(basename "$gate")"
  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    rn="${ln%%:*}"; text="${ln#*:}"
    # Only a sentence naming the gate is a claim about what the gate does.
    case "$text" in
      *"$base"*) ;;
      *) continue ;;
    esac
    if printf '%s' "$text" | grep -q -- '<!-- not-an-enforcement-claim:'; then
      printf '%s' "$text" | grep -qE "$DECLARED" || printf '%s(declared,no-reason) ' "$rn"
      continue
    fi
    # Does it name a refusal the gate emits? The gate writes them as
    # `refuse "$DOC" "code" "..."`, so the QUOTED form is what resolves — a bare
    # match would be satisfied by the code appearing in one of the gate's comments.
    backed=no
    for c in $(printf '%s' "$text" | grep -oE '`[a-z][a-z-]*[a-z]`' | tr -d '`'); do
      grep -q -- "\"$c\"" "$gate" && { backed=yes; break; }
    done
    [ "$backed" = yes ] || printf '%s ' "$rn"
  done <<EOF
$(grep -nE '[Rr]efus(e|es|ed|ing)[^a-z]' "$doc")
EOF
}

out="$(unbacked_enforcement_claims "$REG_DOC" "$STD_GATE")"
assert_eq "" "${out% }" "every enforcement claim in SOURCES.md names a refusal the gate emits"

honoured="$(grep -cE "$DECLARED" "$REG_DOC" || true)"
[ "${honoured:-0}" -ge 1 ] && any=yes || any=no
assert_eq "yes" "$any" "it honoured at least one declared non-claim (honoured ${honoured:-0})"

# --- and the detection must be able to fail -----------------------------------
# Four constructed registers, because a zero result on the real one proves nothing
# about whether it looked. Each names the gate and claims a refusal; only the last
# names a refusal the gate emits.
printf '`bin/validate-standards.sh` refuses an entry whose class column is empty.\n' \
  > "$TMP/no-code.md"
assert_eq "1" "$(unbacked_enforcement_claims "$TMP/no-code.md" "$STD_GATE" | tr -d ' ')" \
  "a prose enforcement claim naming no refusal is flagged"

printf '`bin/validate-standards.sh` refuses an entry with no class — `empty-class`.\n' \
  > "$TMP/invented.md"
assert_eq "1" "$(unbacked_enforcement_claims "$TMP/invented.md" "$STD_GATE" | tr -d ' ')" \
  "a claim naming a refusal the gate does not emit is flagged"

# A code-shaped token the gate CONTAINS but does not emit as a refusal. This is
# the case that makes the quoted form load-bearing: `not-a-claim` is a declaration
# the gate reads and honours, never a refusal it emits, and it appears eight times
# in the script. A bare substring match against the gate accepts it, which is the
# `uncited-claim` versus `S-` defect in a different place — satisfying "resolves"
# while resolving to the wrong kind of thing. Found by loosening the comparison,
# which the fixtures above did not catch.
printf '`bin/validate-standards.sh` refuses a line declared `not-a-claim`.\n' \
  > "$TMP/present-not-emitted.md"
assert_eq "1" "$(unbacked_enforcement_claims "$TMP/present-not-emitted.md" "$STD_GATE" | tr -d ' ')" \
  "a claim naming a token the gate contains but never refuses is flagged"

printf '`bin/validate-standards.sh` refuses it. <!-- not-an-enforcement-claim: -->\n' \
  > "$TMP/no-reason.md"
assert_eq "1(declared,no-reason)" \
  "$(unbacked_enforcement_claims "$TMP/no-reason.md" "$STD_GATE" | tr -d ' ')" \
  "a declaration carrying no reason does not exempt the claim"

printf '`bin/validate-standards.sh` refuses a register entry with no link — `source-no-link`.\n' \
  > "$TMP/good.md"
assert_eq "" "$(unbacked_enforcement_claims "$TMP/good.md" "$STD_GATE" | tr -d ' ')" \
  "a claim naming a refusal the gate emits passes"

# --- the honest section is present and not empty ------------------------------
# The whole document is worth less than nothing if it lists controls and omits
# what is not controlled.
assert_contains "$(cat "$DOC")" "## What is not controlled" "the not-controlled section exists"
notctl="$(sed -n '/^## What is not controlled/,$p' "$DOC" | grep -cE '^\*\*[0-9]+\.')"
[ "$notctl" -ge 6 ] && many=yes || many=no
assert_eq "yes" "$many" "the not-controlled section lists at least 6 gaps (found $notctl)"

# --- and they are in order ----------------------------------------------------
# Item 10 was printed before item 9, in the section this document calls "the
# section an assessor should read first" and the one README.md sends an assessor
# to. Each new gap had been appended at the point in the prose it was most
# related to, rather than at its number, and nothing was reading the numbers.
#
# Non-decreasing rather than strictly increasing, because `1b` is a sub-item of
# `1` and shares its number. The letter is dropped before comparing.
item_numbers() {
  sed -n '/^## What is not controlled/,$p' "$1" \
    | grep -oE '^\*\*[0-9]+[a-z]?\.' | tr -d '*.' | sed 's/[a-z]$//'
}
out_of_order() {
  prev=-1
  for x in $(item_numbers "$1"); do
    [ "$x" -ge "$prev" ] || printf '%s before %s ' "$x" "$prev"
    prev="$x"
  done
}
assert_eq "" "$(out_of_order "$DOC")" "the not-controlled items are numbered in order"

# The detection must be able to fail, or a section in any order passes.
printf '## What is not controlled\n\n**8. Eight.**\n\n**10. Ten.**\n\n**9. Nine.**\n' > "$TMP/jumbled.md"
assert_eq "9 before 10 " "$(out_of_order "$TMP/jumbled.md")" \
  "the detection fires on an item printed out of order"

# A sub-item sharing its parent's number is not out of order.
printf '## What is not controlled\n\n**1. One.**\n\n**1b. One b.**\n\n**2. Two.**\n' > "$TMP/subitem.md"
assert_eq "" "$(out_of_order "$TMP/subitem.md")" "a lettered sub-item is not read as out of order"

# --- it must not claim compliance ---------------------------------------------
# The one assertion here that is about wording rather than structure. A control
# document that drifts into claiming an audit it has not had is the specific
# dishonesty worth guarding, and it is cheap to catch the direct forms.
doc="$(cat "$DOC")"
assert_not_contains "$doc" "SOC 2 compliant" "it does not claim SOC 2 compliance"
assert_not_contains "$doc" "SOC 2 certified" "it does not claim SOC 2 certification"
assert_not_contains "$doc" "fully audited" "it does not claim to be audited"
assert_contains "$doc" "has not been audited" "it states plainly that it has not been audited"

# --- the undecided control is stated as undecided ------------------------------
# CTRL-1 and item 2 cover the separation-of-duties question that discovery found
# unresolved. Claiming it would be the worst available error.
assert_contains "$doc" "Undecided, in both directions" "the unresolved control is marked undecided"
assert_contains "$doc" "not a requirement we met" "it distinguishes our practice from a requirement"

assert_done
