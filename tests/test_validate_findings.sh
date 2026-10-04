#!/usr/bin/env bash
# The stage 1 gate has to refuse, and each refusal has to say which rule it is.
# A non-zero exit is not enough: an operator reading only "invalid" cannot tell
# a missing source from a bad date, and a gate nobody can read gets bypassed.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/01-scan/validate-findings.sh"
CONTRACT="$ROOT/process/01-scan/findings-contract.md"
FIXTURES="$TEST_DIR/fixtures/scan"
WITH_FINDINGS="$FIXTURES/2026-10-01.md"
NOTHING_FOUND="$FIXTURES/2026-11-01.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

case_no=0

# prepare <source fixture> <destination filename> [sed expression]
# Each case is one mutation of a fixture that passes, so the thing under test is
# the only thing wrong with the file.
prepare() {
  case_no=$((case_no + 1))
  dir="$TMP/case$case_no"
  mkdir -p "$dir"
  if [ "$#" -ge 3 ]; then
    sed "$3" "$1" > "$dir/$2"
  else
    cp "$1" "$dir/$2"
  fi
  printf '%s\n' "$dir/$2"
}

gate() {
  OUT="$(bash "$GATE" "$@" 2>&1)"
  STATUS=$?
}

assert_file_exists "$GATE" "the gate exists"
assert_file_exists "$CONTRACT" "the contract the gate reads exists"

# --- files that are within the contract ---------------------------------------

gate "$WITH_FINDINGS"
assert_status 0 "$STATUS" "a cycle file with findings passes"

gate "$NOTHING_FOUND"
assert_status 0 "$STATUS" "a cycle file reporting nothing found passes"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^since: 2026-09-01/since: first run/')"
assert_status 0 "$STATUS" "since: first run is accepted, for the cycle with no earlier file"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's|https://example.invalid/notes/one|doi:10.0000/fixture-one|')"
assert_status 0 "$STATUS" "a DOI is accepted as a source"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's|https://example.invalid/notes/one|arXiv:2609.00001|')"
assert_status 0 "$STATUS" "an arXiv identifier is accepted as a source"

# The worked example is the documentation of the shape, so it has to survive the
# gate that documents it.
gate "$ROOT/process/01-scan/findings/2026-09-01.md"
assert_status 0 "$STATUS" "the worked example passes the gate"

# An empty findings directory is a first run, not a failure.
mkdir -p "$TMP/empty-findings"
OUT="$(FINDINGS_DIR="$TMP/empty-findings" bash "$GATE" 2>&1)"
STATUS=$?
assert_status 0 "$STATUS" "an empty findings directory exits 0"
assert_contains "$OUT" "first run" "an empty findings directory reports a first run"

# --- no source, no finding ----------------------------------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's|https://example.invalid/notes/one||')"
assert_status 1 "$STATUS" "a finding with an empty source is refused"
assert_contains "$OUT" "no source, no finding" "an empty source says no source, no finding"
assert_contains "$OUT" "refuse[no-source]" "an empty source is refused under no-source"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's|https://example.invalid/notes/one|a thread I remember seeing|')"
assert_status 1 "$STATUS" "a finding with an unfollowable source is refused"
assert_contains "$OUT" "not a resolvable-looking locator" "an unfollowable source says it is not resolvable-looking"

# --- kind and consequence guess enums -----------------------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/release-or-capability/big-news/')"
assert_status 1 "$STATUS" "a kind outside the declared list is refused"
assert_contains "$OUT" 'kind is "big-news"' "a bad kind names the value it rejected"
assert_contains "$OUT" "refuse[kind]" "a bad kind is refused under kind"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/ medium / catastrophic /')"
assert_status 1 "$STATUS" "a consequence guess outside the declared list is refused"
assert_contains "$OUT" 'consequence guess is "catastrophic"' "a bad consequence guess names the value it rejected"
assert_contains "$OUT" "refuse[consequence]" "a bad consequence guess is refused under consequence"

# --- dated --------------------------------------------------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/ 2026-09-14 / /')"
assert_status 1 "$STATUS" "a finding with no dated cell is refused"
assert_contains "$OUT" "no dated cell" "a missing dated says the cell is missing"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/2026-09-14/last tuesday/')"
assert_status 1 "$STATUS" "a dated that is not a date is refused"
assert_contains "$OUT" 'dated is "last tuesday"' "a non-date dated names the value it rejected"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/2026-09-14/2026-02-30/')"
assert_status 1 "$STATUS" "a date-shaped value that is not a calendar date is refused"
assert_contains "$OUT" "refuse[dated]" "2026-02-30 is refused under dated"

# --- nothing found, and the empty cycle ---------------------------------------

gate "$(prepare "$NOTHING_FOUND" 2026-11-01.md 's/^nothing found: yes/nothing found: no/')"
assert_status 1 "$STATUS" "a cycle with no findings and no nothing-found declaration is refused"
assert_contains "$OUT" "neither a finding nor an explicit" "an empty cycle says it carries neither"
assert_contains "$OUT" "refuse[empty-cycle]" "an empty cycle is refused under empty-cycle"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md '/^nothing found:/d')"
assert_status 1 "$STATUS" "a missing nothing-found field is refused"
assert_contains "$OUT" 'no "nothing found" field' "a missing nothing-found field says it is missing"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^nothing found: no/nothing found: maybe/')"
assert_status 1 "$STATUS" "a nothing-found value outside yes/no is refused"
assert_contains "$OUT" 'nothing found is "maybe"' "a bad nothing-found value names what it rejected"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^nothing found: no/nothing found: yes/')"
assert_status 1 "$STATUS" "nothing found: yes alongside findings is refused"
assert_contains "$OUT" "carries 3 findings" "the contradiction says how many findings it saw"

# --- looked at ----------------------------------------------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md '/^## Looked at$/d')"
assert_status 1 "$STATUS" "a cycle with no Looked at section is refused"
assert_contains "$OUT" "the ground actually covered" "a missing Looked at says why it is needed"
assert_contains "$OUT" "refuse[looked-at]" "a missing Looked at is refused under looked-at"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md '/^- YouTube:/d')"
assert_status 1 "$STATUS" "a Looked at section missing one declared source is refused"
assert_contains "$OUT" "no line for the YouTube source" "a missing source line names the source"

# --- since --------------------------------------------------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md '/^since:/d')"
assert_status 1 "$STATUS" "a missing since is refused"
assert_contains "$OUT" 'no "since" field' "a missing since says it is missing"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^since: 2026-09-01/since: august/')"
assert_status 1 "$STATUS" "a since that is neither a date nor first run is refused"
assert_contains "$OUT" 'since is "august"' "a bad since names the value it rejected"

# --- filename -----------------------------------------------------------------

gate "$(prepare "$WITH_FINDINGS" october.md)"
assert_status 1 "$STATUS" "a findings filename that is not a cycle date is refused"
assert_contains "$OUT" "is not a cycle date" "a bad filename says it is not a cycle date"
assert_contains "$OUT" "refuse[filename]" "a bad filename is refused under filename"

gate "$(prepare "$WITH_FINDINGS" 2026-02-30.md)"
assert_status 1 "$STATUS" "a date-shaped filename that is not a date is refused"
assert_contains "$OUT" "shaped like a date but is not one" "a bad date filename says so"

# --- required cells, and fields that appear twice -----------------------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/| A platform shipped a review gate that a person configures per repository. |/|  |/')"
assert_status 1 "$STATUS" "a finding with an empty what cell is refused"
assert_contains "$OUT" "the what cell is empty" "an empty what cell says which cell is empty"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/| verify (guess) | medium |/|  | medium |/')"
assert_status 1 "$STATUS" "a finding with an empty might-affect cell is refused"
assert_contains "$OUT" "the might affect cell is empty" "an empty might-affect cell says which cell is empty"

mkdir -p "$TMP/duplicate-field"
awk '{ print } /^since: 2026-09-01$/ { print "since: 2026-08-01" }' \
  "$WITH_FINDINGS" > "$TMP/duplicate-field/2026-10-01.md"
gate "$TMP/duplicate-field/2026-10-01.md"
assert_status 1 "$STATUS" "a field that appears twice is refused"
assert_contains "$OUT" 'the "since" field appears 2 times' "a duplicated field says how many times it appeared"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^example: yes/example: perhaps/')"
assert_status 1 "$STATUS" "an example field outside yes/no is refused"
assert_contains "$OUT" 'the "example" field is "perhaps"' "a bad example value names what it rejected"

# --- the boundary: stage 1 may not judge what a finding means -----------------

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/| A platform shipped a review gate that a person configures per repository./| We should move our own review gate, and this is why./')"
assert_status 1 "$STATUS" "a finding carrying a judgment is refused"
assert_contains "$OUT" "refuse[assessment]" "a judgment in a finding is refused under assessment"
assert_contains "$OUT" "no authority to judge what it means" "the refusal says stage 1 has no authority to judge"
assert_contains "$OUT" "behind a human gate" "the refusal names the gate that was skipped"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/| consequence guess |/| consequence guess | impact |/')"
assert_status 1 "$STATUS" "a findings table with an added judgment column is refused"
assert_contains "$OUT" "refuse[assessment]" "an added judgment column trips the boundary rule, not only the shape rule"
assert_contains "$OUT" "refuse[columns]" "an added column is also refused under columns"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^## Findings$/## What this means/')"
assert_status 1 "$STATUS" "a section outside the declared set is refused"
assert_contains "$OUT" "is not a declared section" "an undeclared section says so"
assert_contains "$OUT" "refuse[sections]" "an undeclared section is refused under sections"

gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/| dated |/| when |/')"
assert_status 1 "$STATUS" "a renamed column is refused"
# Asserted on the names, not the index. The index version broke when `id` was
# added as the first column — a test coupled to the column order it happened to
# be written against rather than to the behaviour it was checking.
assert_contains "$OUT" 'is "when"; the contract declares "dated"' \
  "a renamed column names both what it found and what was declared"

# --- the gate refuses to run on a contract it cannot read ---------------------

OUT="$(FINDINGS_CONTRACT="$TMP/no-such-contract.md" bash "$GATE" "$WITH_FINDINGS" 2>&1)"
STATUS=$?
assert_status 2 "$STATUS" "a missing contract stops the gate rather than passing the file"
assert_contains "$OUT" "nothing to enforce" "a missing contract says the gate has nothing to enforce"

printf '# not the contract, and carries none of its declarations\n' > "$TMP/hollow-contract.md"
OUT="$(FINDINGS_CONTRACT="$TMP/hollow-contract.md" bash "$GATE" "$WITH_FINDINGS" 2>&1)"
STATUS=$?
assert_status 2 "$STATUS" "a contract with no declared lists stops the gate"
assert_contains "$OUT" "would pass everything" "a hollow contract says the gate would otherwise pass everything"

# --- the contract is the only place the shape is declared ---------------------
# Not a grep for duplication: change the contract, and the gate's verdict has to
# change with it. If the gate carried its own copy of a list, this would not.

widened="$TMP/widened-contract.md"
awk '{ print } /^- `sentiment-shift`$/ { print "- `big-news`" }' "$CONTRACT" > "$widened"
if grep -Fq -- '- `big-news`' "$widened"; then
  assert_pass "the widened contract really declares the extra kind"
else
  assert_fail "the widened contract really declares the extra kind" "the fixture edit did not land, so the case below would prove nothing"
fi
with_new_kind="$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/release-or-capability/big-news/')"

gate "$with_new_kind"
assert_status 1 "$STATUS" "a kind the contract does not declare is refused"

OUT="$(FINDINGS_CONTRACT="$widened" bash "$GATE" "$with_new_kind" 2>&1)"
STATUS=$?
assert_status 0 "$STATUS" "the same file passes once the contract declares that kind"

for value in release-or-capability practice-change milestone-or-event counter-evidence sentiment-shift; do
  if grep -Fq -- "$value" "$GATE"; then
    assert_fail "the gate carries no copy of the kind \"$value\"" "found it in $GATE"
  else
    assert_pass "the gate carries no copy of the kind \"$value\""
  fi
done


# --- a field the contract declares once, declared twice -----------------------
# Found by tests/mutate-sweep.sh. The duplicate-field refusal fires for three
# fields and only one of them was covered: deleting the `nothing found` or the
# `example` duplicate check left every suite green. A findings file declaring a
# field twice has two answers to the same question, and the next cycle's comparison
# reads whichever one the gate happened to pick.
#
# The field list is read out of the GATE rather than written here, so a fourth
# declared field is covered by existing rather than by someone remembering to add a
# case. That is the difference between pinning the invariant and pinning the two
# literals the sweep happened to find.
declared_fields="$(grep -oE "field_count ('[a-z ]+'|[a-z]+)" "$GATE" \
                   | sed 's/field_count //' | tr -d "'" | sort -u)"
nfields="$(printf '%s\n' "$declared_fields" | grep -c .)"
[ "$nfields" -ge 3 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the declared field list was read from the gate (found $nfields)"

# duplicate_field <field name> -> a prepared file declaring that field twice
duplicate_field() {
  case_no=$((case_no + 1))
  dir="$TMP/case$case_no"
  mkdir -p "$dir"
  awk -v f="$1:" '{ print; if (index($0, f) == 1) print }' "$WITH_FINDINGS" > "$dir/2026-10-01.md"
  printf '%s\n' "$dir/2026-10-01.md"
}

printf '%s\n' "$declared_fields" | while IFS= read -r f; do
  [ -n "$f" ] || continue
  printf '%s\n' "$f"
done > "$TMP/fields"
while IFS= read -r f; do
  [ -n "$f" ] || continue
  dup="$(duplicate_field "$f")"
  # The duplication has to have happened, or the assertions below pass against an
  # unmodified fixture. This is the check that the awk matched the field at all.
  n="$(grep -c "^$f:" "$dup")"
  assert_eq "2" "$n" "the fixture declares \"$f\" twice"
  gate "$dup"
  assert_status 1 "$STATUS" "a file declaring \"$f\" twice is refused"
  assert_contains "$OUT" "refuse[field]" "a duplicated \"$f\" is refused under field"
  assert_contains "$OUT" "appears 2 times" "and the refusal says how many times (\"$f\")"
done < "$TMP/fields"

# --- the Looked at section present and empty ----------------------------------
# Found by tests/mutate-sweep.sh. The missing-section refusal was covered and the
# present-but-empty one was not, so deleting it left every suite green. The two are
# not the same case: a heading with nothing under it is what a half-finished cycle
# looks like, and it is the one a reader is most likely to skim past.
#
# Written with awk and not with a sed address. The first version used
# `/^- \(web\|X\|YouTube\):/d`, where `\|` is a GNU extension BSD sed does not
# honour: it deleted nothing, the fixture was unchanged, and the gate correctly
# reported it within the contract. The assertion below about the fixture is what
# caught that, which is why it is there.
empty_section() { # <heading> -> a prepared file with that section's body removed
  case_no=$((case_no + 1))
  dir="$TMP/case$case_no"
  mkdir -p "$dir"
  awk -v h="## $1" '
    $0 == h { print; inside = 1; next }
    /^## / { inside = 0 }
    inside && $0 !~ /^[ \t]*$/ { next }
    { print }' "$WITH_FINDINGS" > "$dir/2026-10-01.md"
  printf '%s\n' "$dir/2026-10-01.md"
}
emptied="$(empty_section 'Looked at')"
assert_eq "0" "$(sed -n '/^## Looked at$/,/^## /p' "$emptied" | grep -c '^- ')" \
  "the fixture leaves the Looked at heading with nothing under it"
gate "$emptied"
assert_status 1 "$STATUS" "a Looked at section with a heading and nothing under it is refused"
assert_contains "$OUT" "refuse[looked-at]" "and it is refused under looked-at"
assert_contains "$OUT" "section is empty" "and the refusal says the section is empty"

# --- a findings row with the wrong number of cells -----------------------------
# Found by tests/mutate-sweep.sh. The header's column count and the header's column
# names were both covered; a ROW with the wrong cell count was not. It is the first
# thing the row check does and everything after it reads cells by position, so a row
# that gets past it with too few cells makes every later refusal name the wrong cell.
#
# Both directions, because a check written as `-lt` passes a row with too many.
short="$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^| F01 | A platform shipped[^|]*|/| F01 |/')"
gate "$short"
assert_status 1 "$STATUS" "a findings row with too few cells is refused"
assert_contains "$OUT" "refuse[columns]" "and it is refused under columns"
assert_contains "$OUT" "cells; the contract declares" "and the refusal compares the counts"

long="$(prepare "$WITH_FINDINGS" 2026-10-01.md 's/^| F01 |/| F01 | spare |/')"
gate "$long"
assert_status 1 "$STATUS" "a findings row with too many cells is refused"
assert_contains "$OUT" "refuse[columns]" "a row with too many cells is refused under columns"

# --- the optional field is optional -------------------------------------------
# Found by tests/mutate-sweep.sh, by loosening `-ge 1` to `-ge 0`. Every fixture
# here declares `example`, so nothing established that a file without it is accepted
# — and with the comparison loosened the gate refuses one, reporting an empty value
# for a field the contract does not require. The absent case is the one no fixture
# happened to cover.
gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md '/^example: /d')"
assert_status 0 "$STATUS" "a cycle file that declares no example field is accepted"
assert_not_contains "$OUT" "refuse[field]" "and the absent field is not reported as an empty one"

# --- the first-run message is about a first run -------------------------------
# Also found by loosening a comparison. `-eq 0` to `-ge 0` made the gate print
# "this would be a first run" over a directory holding cycle files, which is the
# summary line a reader uses to decide whether anything was checked at all. The
# empty-directory half was covered; this is the other half of the same sentence.
OUT="$(FINDINGS_DIR="$ROOT/process/01-scan/findings" bash "$GATE" 2>&1)"
STATUS=$?
assert_status 0 "$STATUS" "the real findings directory passes"
assert_not_contains "$OUT" "would be a first run" \
  "a directory holding cycle files is not reported as a first run"

# And the count it reports is the number of files, with the wording to match. The
# plural helper is a comparison too, and nothing read its output.
assert_contains "$OUT" "2 files within the contract" \
  "the summary counts the files it checked and agrees with itself about the plural"
one="$TMP/one-cycle"
mkdir -p "$one" && cp "$WITH_FINDINGS" "$one/"
OUT="$(FINDINGS_DIR="$one" bash "$GATE" 2>&1)"
assert_contains "$OUT" "1 file within the contract" \
  "and says file, not files, for one of them"

# --- an enum value is the whole value, not a prefix of a declared one ----------
# Found by tests/mutate-sweep.sh, by loosening `in_list`'s `grep -Fxq` to `grep -Fq`.
# Every enum case above uses a value that is nothing like a declared one, so the
# loosening changed nothing any of them could see — and with it, `kind: release`
# passes against a declared `release-or-capability`.
#
# This is the shape AGENTS.md calls for under "include inputs the implementation was
# not written for": a truncation of a declared value, not a word from nowhere. It is
# also the third time this repository has shipped the same defect — `uncited-claim`
# against the bare string `S-`, and the decider allowlist against a name that was a
# cell of the table rather than a person.
for part in release practice counter sentiment; do
  gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md "s/release-or-capability/$part/")"
  assert_status 1 "$STATUS" "a kind of \"$part\" is refused, though a declared kind starts with it"
  assert_contains "$OUT" "refuse[kind]" "and \"$part\" is refused under kind"
done

for part in med hi uncl; do
  gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md "s/| medium |/| $part |/")"
  assert_status 1 "$STATUS" "a consequence guess of \"$part\" is refused"
  assert_contains "$OUT" "refuse[consequence]" "and \"$part\" is refused under consequence"
done

# And the declared values themselves still pass, or the loop above would be
# satisfied by a gate that refuses everything.
for ok_kind in release-or-capability practice-change counter-evidence; do
  gate "$(prepare "$WITH_FINDINGS" 2026-10-01.md "s/release-or-capability/$ok_kind/")"
  assert_status 0 "$STATUS" "the declared kind \"$ok_kind\" is accepted"
done

# --- a column name resolves by its exact name, and why that has no case here ----
# tests/mutate-sweep.sh loosens `col_index`'s `grep -nxF` to `grep -nF` and nothing
# catches it. That is recorded rather than tested, and the reason is specific.
#
# `col_index` is only ever called with the literal column names the gate itself
# carries, resolved against the list the contract declares. For the loosening to
# change which cell is read, the contract would have to declare two columns where one
# name is a substring of the other AND the findings file's header would have to match
# that contract exactly, because the header-names check runs first and refuses a
# mismatch. Constructing that means editing the contract, the header and every row
# together, at which point the fixture is testing the fixture.
#
# What is covered instead is the adjacent invariant, above: a renamed column is
# refused, naming both what it found and what was declared. If the column list ever
# gains a name that is a prefix of another, this reason stops holding and the case has
# to be built.
assert_contains "$(cat "$GATE")" 'grep -nxF' \
  "col_index still matches a column name as a whole line"

assert_done
