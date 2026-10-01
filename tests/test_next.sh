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
assert_contains "$out" "AWAITING A HUMAN" "it names the decision still waiting"
assert_contains "$out" "not mine to write" "it says the decision is not its to make"

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
