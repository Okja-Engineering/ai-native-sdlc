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

# --- accounting, as a set -----------------------------------------------------
# This was arithmetic comparing two totals. An external audit broke it two ways:
# lowercasing a finding's first letter removed it from the denominator, and two
# theme counts could move in opposite directions with the total reconciling.
# These cases cover the four distinct things that can be wrong with a set, which
# is what a total cannot distinguish.

# A finding deleted from the source — the case the arithmetic version passed.
t="$(fresh_tree drop_row)"
perl -0pi -e 's/^\| F03 \|.*\n//m' "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a finding deleted from the source exits 1"
assert_contains "$out" "refuse[invented-accounting]" "an id accounted for but no longer in the source"
assert_contains "$out" "F03" "the refusal names which id"

# The same deletion, with the id mentioned in prose elsewhere in the source. The
# id set must come from table ROWS, not from anywhere the string appears — a
# loosened extractor passes this, which the mutation sweep found and nothing
# else caught.
t="$(fresh_tree drop_row_alibi)"
perl -0pi -e 's/^\| F03 \|.*\n//m' "$t/process/01-scan/findings/2026-09-29.md"
printf '\nNote: F03 was reviewed separately.\n' >> "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a deleted row is still caught when its id appears in prose"
assert_contains "$out" "refuse[invented-accounting]" "ids come from table rows, not from any mention"

t="$(fresh_tree drop_id)"
perl -0pi -e 's/\bF03 //' "$t/$CYCLE_REL"
out="$(gate "$t")"
assert_contains "$out" "refuse[unaccounted]" "a finding left out of the accounting is refused"
assert_contains "$out" "nothing may be dropped" "the message states the rule it enforces"

t="$(fresh_tree invent)"
perl -0pi -e 's/\bF64\b/F64 F99/' "$t/$CYCLE_REL"
assert_contains "$(gate "$t")" "refuse[invented-accounting]" "an invented id is refused"

t="$(fresh_tree dupe)"
perl -0pi -e 's/\bF10 /F10 F10 /' "$t/$CYCLE_REL"
assert_contains "$(gate "$t")" "refuse[duplicate-accounting]" "an id accounted for twice is refused"

# No block at all must refuse, not fall back to arithmetic.
t="$(fresh_tree no_block)"
perl -0pi -e 's/<!-- accounting:ids -->.*?<!-- \/accounting:ids -->//s' "$t/$CYCLE_REL"
assert_contains "$(gate "$t")" "refuse[no-accounting]" "a cycle with no accounting block is refused"

t="$(fresh_tree counts)"
perl -0pi -e 's/\*\*7 findings · mostly `high`/**3 findings · mostly `high`/' "$t/$CYCLE_REL"
assert_contains "$(gate "$t")" "refuse[counts-disagree]" "theme counts that do not sum to the accounting are refused"

t="$(fresh_tree outlier_drop)"
perl -0pi -e 's/^- \*\*Models beat the human record.*?\n//ms' "$t/$CYCLE_REL"
assert_contains "$(gate "$t")" "refuse[counts-disagree]" "losing an outlier is caught too"

# The documented limit, asserted so nobody mistakes it for coverage: moving a
# count between themes leaves the set unchanged and is NOT detected. Per-theme
# ids would close it, and cycle 2026-09-29 predates them.
t="$(fresh_tree launder)"
perl -0pi -e 's/\*\*12 findings/**11 findings/; s/\*\*16 findings/**17 findings/' "$t/$CYCLE_REL"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "moving a count between themes is NOT detected — the documented limit"

# Lowercasing a finding's prose must no longer change the accounting. The old
# counter was `grep -cE '^| [A-Z]'`, which dropped the row from the denominator.
t="$(fresh_tree lowercase)"
perl -0pi -e 's/^\| F03 \| A study of/| F03 | a study of/m' "$t/process/01-scan/findings/2026-09-29.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "lowercasing a finding's first letter no longer removes it"

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


# --- an outlier section that lists outliers is accepted ------------------------
# Found by tests/mutate-sweep.sh, by loosening `-eq 0` to `-ge 0` on the outlier
# count. The silent-empty check has two halves — nothing listed, and nothing saying
# it is empty — and only the refusal was covered. Nothing established that a section
# LISTING outliers is accepted, so with the count loosened a populated section is
# refused and no suite noticed.
#
# The shipped cycle cannot distinguish the two halves, because its outlier prose
# happens to contain the word "nothing" and that satisfies the second half on its
# own. This fixture takes those words out, so the count is the only thing left to
# decide it.
t="$(fresh_tree outliers_listed)"
awk '
  /^## Outliers/ { inside = 1 }
  inside && /^---/ { inside = 0 }
  inside {
    gsub(/[Nn]othing/, "little"); gsub(/[Nn]one/, "neither"); gsub(/[Ee]mpty/, "bare")
  }
  { print }
' "$t/$CYCLE_REL" > "$t/edited" && mv "$t/edited" "$t/$CYCLE_REL"
assert_eq "0" "$(sed -n '/^## Outliers/,/^---/p' "$t/$CYCLE_REL" | grep -ciE 'none|empty|nothing')" \
  "the fixture's outlier section says none of none, empty or nothing"
nout="$(sed -n '/^## Outliers/,/^---/p' "$t/$CYCLE_REL" | grep -cE '^- \*\*')"
[ "$nout" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "and it still lists outliers (found $nout)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "an outlier section that lists outliers is accepted"
assert_not_contains "$out" "refuse[silent-empty-outliers]" "and is not called silently empty"

# --- the gate with no arguments reads the cycles directory ---------------------
# Found by loosening `-gt 0` to `-ge 0` on the argument count. The gate then took the
# "files were named" branch with nothing named, looped over nothing, and reported
# "0 file(s) within the contract" and exit 0. CI runs this gate with no arguments, so
# that is a gate reporting a clean tree having evaluated nothing — the shape this
# repository keeps finding.
out="$(cd "$ROOT" && bash process/03-define/validate-define.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "the gate with no arguments passes over the real cycle files"
assert_not_contains "$out" "0 file(s) within the contract" \
  "and does not report having checked nothing"
ncyc="$(ls "$ROOT"/process/03-define/cycles/*.md 2>/dev/null | grep -c .)"
assert_contains "$out" "$ncyc file(s) within the contract" \
  "it checked every cycle file in the directory (found $ncyc)"

assert_done
