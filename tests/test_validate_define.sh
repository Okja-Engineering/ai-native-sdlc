#!/usr/bin/env bash
# The Define checks that do not depend on a cycle's shape.
#
# The accounting check is the one that matters most: it caught a real defect by
# hand before it was ever mechanised. The first draft of cycle 2026-09-29 themed
# 54 of 64 findings and reported three wrong counts, and the ten strays included
# a pattern nobody had named. This suite exists so the next one is caught in CI.
#
# Each case mutates a copy of the shipped cycle file in a full tree copy, so the
# relative source link still resolves and the mutation is the only thing wrong.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
CYCLE_REL="process/03-define/cycles/2026-09-29.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case: the gate resolves `from:` relative to the cycle file, so
# copying the file alone would refuse on an unresolved source before reaching
# the check under test.
fresh_tree() {
  local t="$TMP/t$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$t/process"
  printf '%s' "$t"
}

gate() { bash "$ROOT/process/03-define/validate-define.sh" "$1/$CYCLE_REL" 2>&1; }

# --- the shipped cycle passes -------------------------------------------------
t="$(fresh_tree base)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "the shipped cycle file is within the contract"
assert_contains "$out" "within the contract" "it says so"

# --- accounting ---------------------------------------------------------------
t="$(fresh_tree count)"
perl -0pi -e 's/\*\*7 findings · mostly `high`/**3 findings · mostly `high`/' "$t/$CYCLE_REL"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a theme count that does not add up exits 1"
assert_contains "$out" "refuse[unaccounted]" "the refusal is unaccounted"
assert_contains "$out" "nothing may be dropped" "the message states the rule it enforces"

t="$(fresh_tree outlier_drop)"
perl -0pi -e 's/^- \*\*Models beat the human record.*?\n//ms' "$t/$CYCLE_REL"
out="$(gate "$t")"
assert_contains "$out" "refuse[unaccounted]" "losing an outlier is caught too"

# --- method -------------------------------------------------------------------
t="$(fresh_tree method)"
perl -0pi -e 's/^method: .*\n//m' "$t/$CYCLE_REL"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-method]" "an undeclared method is refused"
assert_contains "$out" "before trusting the grouping" "the message says why it matters"

# --- outlier section ----------------------------------------------------------
t="$(fresh_tree outliers)"
perl -0pi -e 's/^## Outliers.*?(?=^## Where)//ms' "$t/$CYCLE_REL"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-outlier-section]" "a missing Outliers section is refused"
assert_contains "$out" "look identical" "the message says why an empty one must say so"

# --- source -------------------------------------------------------------------
t="$(fresh_tree source)"
perl -0pi -e 's/^from: .*\n/from: nothing in particular\n/m' "$t/$CYCLE_REL"
out="$(gate "$t")"
assert_contains "$out" "refuse[no-source]" "a cycle with no linked source is refused"

t="$(fresh_tree gone)"
rm -f "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[source-unresolved]" "a source that does not resolve is refused"

assert_done
