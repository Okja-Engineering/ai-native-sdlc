#!/usr/bin/env bash
# bin/next.sh scaffolds the next artifact from the contract that declares it.
#
# The load-bearing property is that fields come FROM the contract: add one
# there and the scaffold produces it with no script edit. Without a test for
# that, the script quietly becomes a second copy of each contract's shape,
# which is the duplicate-declaration failure this repository keeps catching.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case. next.sh resolves everything relative to its own root,
# so a copy is the only way to mutate without touching the real tree.
fresh() {
  local t="$TMP/$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$ROOT/bin" "$t/"
  printf '%s' "$t"
}

run() { ( cd "$1" && shift && /bin/bash bin/next.sh "$@" 2>&1 ); }

# --- nothing missing ----------------------------------------------------------
t="$(fresh done)"
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "a complete cycle exits 0"
assert_contains "$out" "Nothing missing" "it says nothing is missing"

# --- a pending decision is called out -----------------------------------------
# These two first asserted against the shipped record while its `chosen:` was
# `pending`, and went red the moment a real decision was made — a test pinned to
# transient data rather than to behaviour. The pending state is now constructed
# here, so the assertion survives the artifact being decided, undecided, or
# superseded.
t="$(fresh pending)"
perl -0pi -e 's/^chosen: .*$/chosen: pending/m' "$t/process/05-deliver/decisions/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"
assert_contains "$out" "AWAITING A HUMAN" "it names a decision still waiting"
assert_contains "$out" "not mine to write" "it says the decision is not its to make"

t="$(fresh decided)"
perl -0pi -e 's/^chosen: .*$/chosen: F/m' "$t/process/05-deliver/decisions/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"
assert_not_contains "$out" "AWAITING A HUMAN" "a decided record is not reported as waiting"

# --- scaffolds define ---------------------------------------------------------
t="$(fresh define)"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
out="$(run "$t" 2026-09-29)"; rc=$?
assert_status 0 "$rc" "scaffolding define exits 0"
assert_contains "$out" "wrote process/03-define/cycles/2026-09-29.md" "it says what it wrote"

made="$t/process/03-define/cycles/2026-09-29.md"
assert_file_exists "$made" "the define skeleton exists"
assert_contains "$(cat "$made")" "method:" "it carries the method field the contract requires"
assert_contains "$(cat "$made")" "## Themes" "it carries the required sections"
assert_contains "$(cat "$made")" "-->" "the hint comment is closed"

# --- the property that matters ------------------------------------------------
t="$(fresh contract)"
perl -0pi -e 's/\| `method` \|/| `reviewed_by` | who checked the grouping |\n| `method` |/' \
  "$t/process/03-define/define-contract.md"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
assert_contains "$(cat "$t/process/03-define/cycles/2026-09-29.md")" "reviewed_by:" \
  "a field added to the contract appears in the scaffold, with no script edit"

# --- a problem is scaffolded from a PROBLEM's declaration ---------------------
# The problem skeleton was emitted from the cycle's field list, because the
# contract declared one table for two different artifacts. So a scaffolded
# problem carried `method:` — how a grouping was produced, which says nothing
# about a problem — and never carried `rests on:`, the field that links it to the
# Discover topic it was stated from. The Discover-to-Define edge was in no
# contract and no scaffold.
t="$(fresh problem)"
rm -f "$t/process/03-define/problems/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "scaffolding a problem exits 0"

made="$t/process/03-define/problems/producing-themes.md"
assert_file_exists "$made" "the problem skeleton exists"
assert_contains "$(cat "$made")" "rests on:" "it carries the rests on: field a problem's contract declares"
assert_not_contains "$(cat "$made")" "method:" "and not the cycle's method:, which says nothing about a problem"

# The same property as above, for the problem's own table: the contract is the
# single declaration of a problem's shape. Two words on purpose — `rests on` has
# a space in it, and a field list read by word splitting would break on that.
t="$(fresh problem-contract)"
perl -0pi -e 's/\| `rests on` \|/| `checked by` | who read the topic |\n| `rests on` |/' \
  "$t/process/03-define/define-contract.md"
rm -f "$t/process/03-define/problems/producing-themes.md"
run "$t" 2026-09-29 producing-themes >/dev/null
assert_contains "$(cat "$t/process/03-define/problems/producing-themes.md")" "checked by:" \
  "a field added to the problem's table appears in the problem scaffold, with no script edit"

# And the two declarations stay apart. One contract now declares fields for two
# artifacts, so a scaffold has to read the table its own artifact declares
# whatever order the contract lists them in. The tables are swapped here for that
# reason: with the problem's table first, a heading matched as a prefix hands the
# cycle the problem's fields, and asserting this against the shipped order would
# pass either way.
t="$(fresh split)"
perl -0777 -pi -e 's/(## Required fields\n.*?)(## Required fields — a problem\n.*?)(## Required sections\n)/$2$1$3/s' \
  "$t/process/03-define/define-contract.md"
assert_eq "## Required fields — a problem" \
  "$(grep -m1 '^## Required fields' "$t/process/03-define/define-contract.md")" \
  "the fixture really did put the problem's table first"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
rm -f "$t/process/03-define/problems/producing-themes.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
assert_contains "$(cat "$made")" "method:" "a cycle skeleton still carries the cycle's fields"
assert_not_contains "$(cat "$made")" "rests on:" "and does not inherit the problem's"
run "$t" 2026-09-29 producing-themes >/dev/null
made="$t/process/03-define/problems/producing-themes.md"
assert_contains "$(cat "$made")" "rests on:" "a problem skeleton still carries the problem's fields"
assert_not_contains "$(cat "$made")" "method:" "and does not inherit the cycle's"

# --- it does not touch a complete cycle ---------------------------------------
# `write_once`'s refusal is defensive: the phase chain only calls it when the
# file is absent, so no invocation reaches it. Asserting on that refusal passed
# with the guard deleted — vacuous. What is reachable, and what actually matters
# to someone running this over work in progress, is that a complete cycle comes
# back byte-identical.
t="$(fresh untouched)"
before="$(cd "$t" && find process -type f -exec cksum {} + | sort)"
run "$t" 2026-09-29 producing-themes >/dev/null
after="$(cd "$t" && find process -type f -exec cksum {} + | sort)"
assert_eq "$before" "$after" "a complete cycle is left byte-identical"

# --- a problem is a human's pick ---------------------------------------------
t="$(fresh pick)"
rm -f "$t"/process/03-define/problems/*.md
out="$(run "$t" 2026-09-29)"; rc=$?
assert_status 0 "$rc" "no problem yet exits 0"
assert_contains "$out" "The next step is yours" "it hands the pick back to a person"
assert_contains "$out" "would be inventing the pick" "it says why it will not scaffold one"

# --- a cycle starts with a scan ----------------------------------------------
t="$(fresh noscan)"
out="$(run "$t" 2099-01-01)"; rc=$?
assert_status 2 "$rc" "an unknown cycle exits 2"
assert_contains "$out" "a cycle starts with a scan" "it says what is missing"

assert_done
