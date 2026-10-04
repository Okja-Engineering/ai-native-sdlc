#!/usr/bin/env bash
# A comparison cycle: the home for the cross-cutting test decision F commissioned.
#
# The decision says the comparison "is part of this decision, not a separate
# task", and the question appeared three times as prose with nowhere for an answer
# to land. The leverage this suite pins is that the comparison needs no new gate:
# a Define cycle record over the SAME findings file, with a different `method:`,
# is already checked by validate-define.sh — so the model's grouping is forced
# through the same accounting a hand pass goes through, and it cannot drop a
# finding without being refused.
#
# Built fixtures, not the live artifacts. This suite is about SHAPE, and
# tests/lib/define-fixture.sh writes a findings file and a cycle that know their
# own answer. The live cycle is a record of a moment and should not be asked to
# demonstrate shape.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"
. "$TEST_DIR/lib/define-fixture.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/03-define/validate-define.sh"
CONTRACT="$ROOT/process/03-define/define-contract.md"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- the leverage: a second grouping of the same findings passes the gate -------
d="$TMP/second"
hand="$(define_fixture "$d" "3 2" 1)"
model="$(dirname "$hand")/2026-12-01.by-model.md"
sed 's/^method: .*/method: by model — one prompt, no human edit/' "$hand" > "$model"
assert_contains "$(cat "$model")" "method: by model" "the fixture is a second grouping, produced differently"

out="$(/bin/bash "$GATE" "$hand" 2>&1)"; rc=$?
assert_status 0 "$rc" "the hand record is within the contract"
out="$(/bin/bash "$GATE" "$model" 2>&1)"; rc=$?
assert_status 0 "$rc" "and a second record over the same findings file is too"

# The accounting check is what makes this worth doing rather than a prose note. A
# model that quietly drops a finding is refused, with the id named.
dropped="$(dirname "$hand")/2026-12-01.by-model-dropping.md"
sed 's/^F01 //' "$model" > "$dropped"
assert_not_contains "$(sed -n '/accounting:ids -->/,/\/accounting:ids -->/p' "$dropped")" "F01" \
  "the fixture really did drop a finding from the accounting"
out="$(/bin/bash "$GATE" "$dropped" 2>&1)"; rc=$?
assert_status 1 "$rc" "a comparison record that drops a finding is refused"
assert_contains "$out" "refuse[unaccounted]" "and the refusal names dropping, not formatting"
assert_contains "$out" "F01" "and says which finding"

# --- the contract declares where the result lands ------------------------------
# The two fields a comparison record carries beyond a cycle's four, read out of
# the contract rather than written here twice.
heading='## Required fields — a comparison cycle'
rows="$(sed -n "/^$heading\$/,/^## /p" "$CONTRACT" | sed -n 's/^| `\([a-z_ ]*\)` *|.*/\1/p' | tr '\n' ' ')"
assert_contains "$rows" "compares" "a comparison record declares what it is compared against"
assert_contains "$rows" "criterion" "and the criterion its result is read against"
assert_contains "$rows" "method" "and a cycle's method, which is the whole point of the comparison"

# The criterion is the owner's to set and the contract says so, with both readings
# named. Pinned on the readings rather than on an answer, because an answer here
# would be this suite inventing the decision.
section="$(sed -n '/^## A comparison cycle/,/^## /p' "$CONTRACT")"
assert_contains "$section" "unset" "the contract states the criterion is unset"
assert_contains "$section" "reproduces the seven themes closely" "and names the first reading the decision identified"
assert_contains "$section" "differently-shaped grouping" "and names the second"

# --- the scaffold produces it --------------------------------------------------
fresh() {
  local t="$TMP/$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$ROOT/bin" "$t/"
  printf '%s' "$t"
}
run() { ( cd "$1" && shift && /bin/bash bin/next.sh "$@" 2>&1 ); }

t="$(fresh scaffold)"
out="$(run "$t" 2026-09-29.by-model)"; rc=$?
assert_status 0 "$rc" "scaffolding a comparison record exits 0"
made="$t/process/03-define/cycles/2026-09-29.by-model.md"
assert_file_exists "$made" "the comparison skeleton exists"
assert_contains "$(cat "$made")" "compares:" "it carries the record it is compared against"
assert_contains "$(cat "$made")" "criterion:" "and the criterion field, for the owner to fill"

# It reads the SAME findings file as the hand record. That is the whole design: two
# groupings of one source, which is what makes them comparable at all.
src="$(sed -n 's/^from:.*(\([^)]*\)).*/\1/p' "$made" | head -1)"
hand_src="$(sed -n 's/^from:.*(\([^)]*\)).*/\1/p' "$t/process/03-define/cycles/2026-09-29.md" | head -1)"
assert_eq "$hand_src" "$src" "and its from: names the same findings file as the hand record"
[ -n "$src" ] && any=yes || any=no
assert_eq "yes" "$any" "and that comparison ran against a value, not two empty strings"

# The accounting block is scaffolded with the source's ids, read through the same
# harvester the gate reads. This is the leverage, so it is asserted here and not
# assumed from the cycle case.
block="$(sed -n '/accounting:ids -->/,/\/accounting:ids -->/p' "$made" | grep -oE 'F[0-9]+' | sort | tr '\n' ' ')"
want="$(/bin/bash "$ROOT/process/01-scan/findings-ids.sh" "$t/process/01-scan/findings/2026-09-29.md" | sort | tr '\n' ' ')"
assert_eq "$want" "$block" "the comparison skeleton accounts for exactly the ids the source records"

# Scaffold then gate. The invariant is not that a skeleton passes — `method`, the
# themes and an empty outlier list are all claims a person makes — but that every
# refusal left names unwritten content and none names structure.
codes="$(/bin/bash "$GATE" "$made" 2>&1 | sed -n 's/.*refuse\[\([a-z-]*\)\].*/\1/p' | sort | tr '\n' ' ')"
assert_eq "counts-disagree no-method silent-empty-outliers " "$codes" \
  "the only refusals on a fresh comparison skeleton are the ones naming unwritten content"

# It refuses to overwrite, like every other skeleton.
out="$(run "$t" 2026-09-29.by-model)"; rc=$?
assert_status 0 "$rc" "running it again exits 0"
assert_contains "$out" "Nothing missing" "and says the comparison record is already there"

# A comparison record is not a cycle with its own problems. The problem chain
# hangs off the hand pass, and offering to continue from a comparison would be
# offering to state a problem from the model's grouping.
assert_not_contains "$out" "The next step is yours" "it does not offer to start a problem from a comparison"

# And a comparison over a scan that does not exist still fails for the right
# reason: the source is the part before the dot.
t="$(fresh noscan)"
out="$(run "$t" 2099-01-01.by-model)"; rc=$?
assert_status 2 "$rc" "a comparison over a scan that does not exist exits 2"
assert_contains "$out" "a cycle starts with a scan" "and says what is missing"

# --- the gap this does NOT close ----------------------------------------------
# bin/cycle.sh looks up `cycles/$c.md` by exact name, keyed on the findings file,
# so a record named for the comparison rather than for a date is invisible to the
# report. Asserted rather than left in a comment, for the reason
# tests/test_validate_claims.sh asserts that a speed claim it cannot catch does
# pass: a limitation nobody can see is indistinguishable from coverage.
#
# WHEN THE GAP IS CLOSED, INVERT THIS ASSERTION. It pins a known hole, not a
# behaviour worth keeping.
t="$(fresh invisible)"
run "$t" 2026-09-29.by-model >/dev/null
out="$( cd "$t" && /bin/bash bin/cycle.sh 2>&1 )"
assert_not_contains "$out" "by-model" \
  "KNOWN GAP: the report does not see a comparison record, because it keys cycles by the findings file name"
assert_contains "$out" "2026-09-29" "while the hand pass over the same scan is reported"

assert_done
