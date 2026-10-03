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

# --- every gate named in the document exists ----------------------------------
# Scripts are cited as `process/<phase>/validate-<thing>.sh` in backticks.
# Gates live beside their phase, except the STANDARDS.md gate, which has no phase
# to live beside: applying a decision is a field plus a link — `amends:` on the
# decision, `decided:` back from the amended claim — rather than a sixth phase, so
# nothing called `process/06-update/` exists for that gate to sit in. The reasoning
# is in process/05-deliver/deliver-contract.md, section "`amends`, and why Update
# is not a sixth phase"; decided in issue #18, which a clone cannot read.
#
# The first version of this pattern matched only process/ and reported CTRL-8's
# refusals as emitted by nothing.
gates="$(grep -oE '(process/[0-9a-z-]+|bin)/validate-[a-z-]+\.sh' "$DOC" | sort -u)"
assert_contains "$gates" "validate-decision.sh" "the document cites the deliver gate"
assert_contains "$gates" "validate-define.sh" "the document cites the define gate"
assert_contains "$gates" "validate-findings.sh" "the document cites the scan gate"

missing_gates=""
for g in $gates; do
  [ -f "$ROOT/$g" ] || missing_gates="$missing_gates $g"
done
assert_eq "" "$missing_gates" "every gate the document names exists"

# --- every refusal code cited appears in some gate ----------------------------
# Codes appear in the refusal tables as `code` in backticks. Collect anything
# shaped like a refusal code, then require each to be present in a gate script.
# This is the check that stops a control claiming enforcement it does not have.
codes="$(grep -oE '^\| `[a-z][a-z-]{3,}`' "$DOC" | tr -d '|` ' | sort -u)"
n=0; orphans=""
for c in $codes; do
  n=$((n + 1))
  found=no
  for g in $gates; do
    grep -q -- "$c" "$ROOT/$g" && { found=yes; break; }
  done
  [ "$found" = yes ] || orphans="$orphans $c"
done

assert_eq "" "$orphans" "every refusal code cited is emitted by a gate"
[ "$n" -ge 15 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the document cites at least 15 refusal codes (found $n)"

# --- codes mentioned in prose, not only in tables -----------------------------
# CTRL-6 lists its refusals inline rather than as a table. Spot-check that those
# resolve too, since a prose list is exactly where an invented code would hide.
for c in nothing-found empty-cycle filename; do
  assert_contains "$(cat "$ROOT/process/01-scan/validate-findings.sh")" "$c" \
    "scan gate emits '$c' as the document claims"
done

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

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

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
