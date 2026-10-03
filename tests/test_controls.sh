#!/usr/bin/env bash
# CONTROLS.md must describe gates that exist and refusals they actually emit.
#
# A control document is the one artifact here with a strong incentive to drift
# optimistic: it is read by people assessing the process, and nothing about
# writing prose forces it to stay true.
#
# WHAT CHANGED, AND WHY THIS SUITE LOOKS DIFFERENT
#
# This suite used to do the checking itself, with two string searches, and both
# were vacuous:
#
#   * It collected every gate path named anywhere in the document into one set and
#     asked whether a cited code appeared in ANY of them. Pointing CTRL-1 at the
#     scan gate, which emits none of its four codes, passed 18 of 18.
#   * The membership test was `grep -q -- "$code" "$gate"` — a plain substring over
#     the whole file. Adding one comment line to any gate made a fabricated
#     refusal code pass.
#
# The checking now lives in bin/validate-controls.sh, for the same reason
# bin/validate-claims.sh stopped being a line in ci.yml: a check embedded in its
# own test cannot be run against a document built to break it. This suite drives
# that gate against the shipped document and against documents constructed to
# fail, so a green result here means the gate refused what it should and accepted
# what it should.
#
# Most of the failing documents are DERIVED from the live CONTROLS.md at run time
# rather than checked in. A checked-in copy goes stale the moment someone edits a
# control, and then the drift test is testing an old document.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
DOC="$ROOT/CONTROLS.md"
GATE="$ROOT/bin/validate-controls.sh"
FIX="$TEST_DIR/fixtures/controls"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$DOC" "the controls document exists"
assert_file_exists "$GATE" "the gate that checks it exists"

# run <document> — the gate's output, with its exit status on the last line.
run() { out="$(/bin/bash "$GATE" "$1" 2>&1)"; st=$?; printf '%s\n' "$out"; return "$st"; }

# --- the shipped document is within the contract ------------------------------
out="$(run "$DOC")"; st=$?
assert_status 0 "$st" "the shipped document passes the gate"

# A gate that checked nothing would also exit 0. The summary carries the
# denominator for exactly that reason.
assert_contains "$out" "emission sites" "the gate reports how many emission sites it checked"
nsites="$(printf '%s\n' "$out" | sed -n 's/.*controls, \([0-9]*\) emission sites.*/\1/p')"
[ "${nsites:-0}" -ge 80 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "it checked a real denominator of sites (reported ${nsites:-none})"
nctrl="$(printf '%s\n' "$out" | sed -n 's/validate-controls: \([0-9]*\) controls.*/\1/p')"
[ "${nctrl:-0}" -ge 9 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "it found every control block (reported ${nctrl:-none})"

# --- forward: the code has to be emitted by the gate THIS control names -------
# The invariant, stated as the assertion: a refusal code that some other gate
# emits does not satisfy the control that cites it. `undecided-by` is emitted by
# the deliver gate, so the old document-wide union passed this document; the
# per-control binding must not.
awk '{ gsub(/process\/05-deliver\/validate-decision.sh/, "process/01-scan/validate-findings.sh"); print }' \
  "$DOC" > "$TMP/wrong-gate.md"
out="$(run "$TMP/wrong-gate.md")"; st=$?
assert_status 1 "$st" "a control pointed at a gate that emits none of its codes is refused"
assert_contains "$out" "refuse[cited-not-emitted]" "and the refusal says the cited code is not emitted"
assert_contains "$out" 'cites refusal `undecided-by`' "and it names the code that does not resolve"

# The code is still emitted somewhere in the repository, which is what makes this
# a test of the binding rather than of the code's existence.
assert_contains "$(/bin/bash "$ROOT/bin/list-refusals.sh" "$ROOT/process/05-deliver/validate-decision.sh")" \
  "undecided-by" "the code is still emitted by the gate the document stopped naming"

# --- forward: a mention is not an emission site -------------------------------
# The two fixture documents differ in one thing: the path on the Enforced by line.
# The two fixture gates differ in one thing: whether the code is in a comment or
# in a call. So the red and green below can only be about that difference.
out="$(run "$FIX/comment-only.md")"; st=$?
assert_status 1 "$st" "a code that appears only in a comment is refused"
assert_contains "$out" 'cites refusal `fixture-refusal`' "and the refusal names it"

assert_contains "$(cat "$FIX/mentions-in-a-comment.sh")" "fixture-refusal" \
  "the comment-only fixture does contain the code as a substring"

out="$(run "$FIX/emission-site.md")"
assert_not_contains "$out" "refuse[cited-not-emitted]" \
  "the same code at a real emission site is accepted"

# --- forward: a code in prose rather than in the table ------------------------
# The table is the only place the forward check reads codes from, so a code that
# drifts into prose would be unchecked. CTRL-5 and CTRL-6 both had codes in prose
# and all nine of them were outside the old check.
awk '{ if ($0 ~ /^\| `not-a-person`/) print "This control also emits `not-a-person`."; else print }' \
  "$DOC" > "$TMP/in-prose.md"
out="$(run "$TMP/in-prose.md")"; st=$?
assert_status 1 "$st" "a code moved out of the table into prose is refused"
assert_contains "$out" "refuse[code-in-prose]" "and the refusal says to put it back in the table"

# --- a control with no enforcement at all ------------------------------------
awk 'BEGIN { done = 0 }
     /^\*\*Enforced by\*\*/ && done == 0 { done = 1; next }
     { print }' "$DOC" > "$TMP/no-enforced-by.md"
out="$(run "$TMP/no-enforced-by.md")"; st=$?
assert_status 1 "$st" "a control naming no enforcement is refused"
assert_contains "$out" "refuse[no-enforced-by]" "and the refusal says a control names what refuses"

# --- backward: a refusal no control claims -----------------------------------
# A gate emitting a code nothing cites has no control and usually no test. That
# is how validate-decision.sh's `no-chosen-field` came to have neither.
awk '{ if ($0 ~ /^\| `undated-decision`/) next; print }' "$DOC" > "$TMP/uncited.md"
out="$(run "$TMP/uncited.md")"; st=$?
assert_status 1 "$st" "a refusal a gate emits and no control cites is refused"
assert_contains "$out" "refuse[uncited-refusal]" "and the refusal says so"
assert_contains "$out" 'emits refusal `undated-decision`' "and names the unclaimed code"

# --- sideways: a gate no control names ---------------------------------------
# The two git hooks were absent from this document until an external audit found
# them, and a check that reads only the document can never notice an omission.
awk '{ gsub(/`process\/01-scan\/validate-findings.sh`/, "`process/01-scan/validate-findings.sh `"); print }' \
  "$DOC" > "$TMP/unnamed-gate.md"
out="$(run "$TMP/unnamed-gate.md")"; st=$?
assert_status 1 "$st" "a gate no control names is refused rather than skipped"
assert_contains "$out" "refuse[uncontrolled-gate]" "and the refusal names the gate with no control"

# --- CTRL-9's enforcement is resolved, not excluded ---------------------------
# Its enforcement is two hooks, a script and three CI jobs, and it has no refusal
# table. That put it outside the old check twice: codes were harvested from table
# rows, and the gate pattern matched only validate-*.sh.
assert_contains "$(cat "$DOC")" '`.githooks/pre-push`' "the document names the pre-push hook"
awk '{ gsub(/`commit-messages`/, "`commit-msgs`"); print }' "$DOC" > "$TMP/bad-job.md"
out="$(run "$TMP/bad-job.md")"; st=$?
assert_status 1 "$st" "a CI job a control names and the workflow does not declare is refused"
assert_contains "$out" "refuse[job-unresolved]" "and the refusal says which job"

awk '{ gsub(/`.githooks\/pre-push`/, "`.githooks/pre-pish`"); print }' "$DOC" > "$TMP/bad-hook.md"
out="$(run "$TMP/bad-hook.md")"; st=$?
assert_status 1 "$st" "a hook path a control names and the repository does not have is refused"
assert_contains "$out" "refuse[enforcement-unresolved]" "and the refusal says which path"

# --- an exception has to carry a reason --------------------------------------
# The exception table is the replacement for silent exclusion, so an entry with no
# reason is the thing it was built to stop.
awk '{ if ($0 ~ /^\| `bin\/validate-authorship.sh`/) print "| `bin/validate-authorship.sh` | the gate itself |  |"; else print }' \
  "$DOC" > "$TMP/no-reason.md"
out="$(run "$TMP/no-reason.md")"; st=$?
assert_status 1 "$st" "an exception with no reason is refused"
assert_contains "$out" "refuse[exception-no-reason]" "and the refusal says a reason is required"

# --- a document the gate cannot read must not report clean -------------------
# Exit 2 is "could not run". Exit 0 on a document with no controls would make
# every assertion above pass against an empty denominator.
printf '# Not a controls document\n\nNothing here.\n' > "$TMP/empty.md"
run "$TMP/empty.md" >/dev/null 2>&1
assert_status 2 "$?" "a document declaring no controls exits 2 rather than reporting clean"

# --- the document claims only what the gate checks ---------------------------
# The smaller half of this repair and the more important one. The sentence an
# assessor relies on to shortcut the audit has to be true.
doc="$(cat "$DOC")"
assert_not_contains "$doc" "a control cannot drift from its enforcement" \
  "it no longer claims a control cannot drift from its enforcement"
assert_contains "$doc" "It checks the wiring, not the claim" \
  "it says the check establishes wiring and not the control's prose"
assert_contains "$doc" "Whether a control's prose describes what its refusal actually does" \
  "the gap the check leaves is in what is not controlled"
assert_contains "$doc" "## Refusals and gates no control covers" \
  "the deliberate exceptions are a visible section, not a silent skip"

# --- it must not claim compliance ---------------------------------------------
# The assertions here are about wording rather than structure. A control document
# that drifts into claiming an audit it has not had is the specific dishonesty
# worth guarding, and it is cheap to catch the direct forms.
assert_not_contains "$doc" "SOC 2 compliant" "it does not claim SOC 2 compliance"
assert_not_contains "$doc" "SOC 2 certified" "it does not claim SOC 2 certification"
assert_not_contains "$doc" "fully audited" "it does not claim to be audited"
assert_contains "$doc" "has not been audited" "it states plainly that it has not been audited"

# --- the honest section is present and not empty ------------------------------
# The whole document is worth less than nothing if it lists controls and omits
# what is not controlled.
assert_contains "$doc" "## What is not controlled" "the not-controlled section exists"
notctl="$(sed -n '/^## What is not controlled/,$p' "$DOC" | grep -cE '^\*\*[0-9]+\.')"
[ "$notctl" -ge 6 ] && many=yes || many=no
assert_eq "yes" "$many" "the not-controlled section lists at least 6 gaps (found $notctl)"

# --- the undecided control is stated as undecided ------------------------------
# CTRL-1 and item 2 cover the separation-of-duties question that discovery found
# unresolved. Claiming it would be the worst available error.
assert_contains "$doc" "Undecided, in both directions" "the unresolved control is marked undecided"
assert_contains "$doc" "not a requirement we met" "it distinguishes our practice from a requirement"

assert_done
