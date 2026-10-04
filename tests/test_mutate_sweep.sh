#!/usr/bin/env bash
# The instrument that finds checks which cannot fail has to hold itself to the
# same rule.
#
#   $ tests/mutate-sweep.sh --operator D --target .githooks/commit-msg
#   mutate-sweep: 0 mutations enumerated, 0 caught, 0 NOT caught, 0 inconclusive
#   $ echo $?
#   0
#
# Operator D replaces a `refuse` call. The hooks refuse by exit status and have no
# `refuse` calls, so that scope has nothing in it — and a sweep over nothing
# reported success. `tests/lib/assert.sh` already refuses a suite with no
# assertions and `tests/run-all.sh` already refuses a run with no suites; this is
# the same rule applied to the thing that measures the others.
#
# It matters beyond the obvious case because of what it composes with. The
# emission-site count is guarded by a floor rather than a denominator, so the
# lister can lose a fifth of its sites while the sweep reports `0 NOT caught` and
# exits 0, with nothing saying the denominator moved.
#
# WHAT THIS SUITE DOES NOT DO
#
# It does not run a real sweep. A sweep runs the whole suite against a pristine
# copy before it mutates anything, which is two minutes before the first mutation,
# so the mutation path is exercised by hand and recorded in the pull request. What
# is cheap, and what the defect actually was, is the enumeration and the exit
# status over it — `--list` copies nothing and an empty scope refuses before the
# copy is checked.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
cd "$ROOT" || exit 2

SWEEP="$ROOT/tests/mutate-sweep.sh"
assert_file_exists "$SWEEP" "the sweep is where this suite expects it"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# run <args...> -> exit status, with stdout and stderr kept in $TMP/out
run() {
  /bin/bash "$SWEEP" "$@" > "$TMP/out" 2>&1
  printf '%s' "$?"
}

# --- an empty scope refuses ---------------------------------------------------
# The reported case. Not pinned to this target and operator alone: the second pair
# below is a different file under a different operator, because a fix written to
# the shape of one report is the defect this repository keeps shipping.
for scope in "D .githooks/commit-msg" "X .githooks/pre-push" "E .githooks/pre-push"; do
  op="${scope%% *}"; target="${scope#* }"

  # The scope has to actually be empty, or the assertion below proves nothing.
  # Read from the instrument's own enumeration rather than asserted here, so a
  # scope that stops being empty shows up as this line failing rather than as a
  # refusal test that quietly tests nothing.
  listed="$(/bin/bash "$SWEEP" --list --operator "$op" --target "$target" 2>/dev/null \
            | grep -cE "^$op " || true)"
  assert_eq "0" "${listed:-}" "operator $op over $target enumerates nothing"

  status="$(run --operator "$op" --target "$target")"
  [ "$status" != 0 ] && refused=yes || refused=no
  assert_eq "yes" "$refused" "a sweep over an empty scope refuses (operator $op, $target)"

  # The message has to name what was empty, or a reader cannot tell an empty
  # scope from a sweep that found everything clean.
  assert_contains "$(cat "$TMP/out")" "$op" "the refusal names the operator that found nothing"
  assert_contains "$(cat "$TMP/out")" "$target" "the refusal names the target that was empty"

  # `--list` is the same measurement with nothing run, so it refuses too. This is
  # the path a reader uses to argue with the denominator before trusting a sweep,
  # and an empty one read as a pass there is the same hole one step earlier.
  status="$(run --list --operator "$op" --target "$target")"
  [ "$status" != 0 ] && refused=yes || refused=no
  assert_eq "yes" "$refused" "--list over an empty scope refuses (operator $op, $target)"
done

# --- a scope that enumerates something still passes ---------------------------
# Or the refusal above would be refusing the instrument rather than the empty
# scope, and `--list` would be useless.
status="$(run --list --operator A --target .githooks/commit-msg)"
assert_eq "0" "$status" "--list over a scope with sites exits 0"
assert_contains "$(cat "$TMP/out")" "# denominator:" "--list prints the denominator"

# --- the denominator the header reports is the list it printed ----------------
# No number is pinned. The count in the header and the number of enumerated lines
# below it are the same measurement written twice, and a sweep whose header
# disagreed with its own list would be the same class of defect as one reporting a
# result over nothing.
status="$(run --list)"
assert_eq "0" "$status" "--list over the whole surface exits 0"
header="$(grep -oE '^# denominator: [0-9]+' "$TMP/out" | grep -oE '[0-9]+')"
sites="$(grep -cE '^[DATXEP] [A-Za-z0-9_./-]+:[0-9]+$' "$TMP/out" || true)"
assert_eq "$header" "$sites" "the denominator in the header is the number of sites listed"

# And the whole surface is not empty, or everything above passes over nothing.
[ "${header:-0}" -ge 1 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "the whole surface enumerates something (found ${header:-0})"

# --- an unknown argument still refuses ----------------------------------------
# The argument parser is what decides the scope, so a typo must not silently
# become a different scope. `bin/validate-authorship.sh` was turned off once by a
# mistyped ref that read as "no commits to check".
status="$(run --no-such-option)"
[ "$status" != 0 ] && refused=yes || refused=no
assert_eq "yes" "$refused" "an unknown argument refuses"

# --- a target that does not exist refuses -------------------------------------
# The other way to end up with an empty scope is to name a file that is not there.
# That already refuses, and it is asserted so the two paths to "nothing was
# measured" are both held.
status="$(run --target tests/no-such-gate.sh)"
[ "$status" != 0 ] && refused=yes || refused=no
assert_eq "yes" "$refused" "a target that does not exist refuses"

assert_done
