#!/usr/bin/env bash
# The runner must fail when a suite fails. A green runner that hides a red
# suite is worse than no runner.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

RUN_ALL="$TEST_DIR/run-all.sh"
FIXTURES="$TEST_DIR/fixtures/runner"

# --- a failing suite fails the runner ----------------------------------------
out="$(bash "$RUN_ALL" "$FIXTURES/failing" 2>&1)"
status=$?
assert_status 1 "$status" "runner exits 1 when a suite fails"
assert_contains "$out" "FAIL" "runner marks the failing suite FAIL"
assert_contains "$out" "1 of 1 suites failed" "runner names how many suites failed"

# --- a passing suite passes the runner ---------------------------------------
out="$(bash "$RUN_ALL" "$FIXTURES/passing" 2>&1)"
status=$?
assert_status 0 "$status" "runner exits 0 when every suite passes"
assert_contains "$out" "PASS" "runner marks the passing suite PASS"
assert_contains "$out" "1 suites passed" "runner reports how many suites passed"

# --- an empty directory is a failure, not a pass -----------------------------
empty="$(mktemp -d)"
out="$(bash "$RUN_ALL" "$empty" 2>&1)"
status=$?
rm -rf "$empty"
assert_status 1 "$status" "runner exits 1 when it finds no suites"
assert_contains "$out" "no test suites found" "runner says it found no suites"

# --- a missing directory is a failure ----------------------------------------
out="$(bash "$RUN_ALL" "$TEST_DIR/fixtures/no-such-dir" 2>&1)"
status=$?
assert_status 1 "$status" "runner exits 1 when the directory does not exist"
assert_contains "$out" "not a directory" "runner says the directory does not exist"

# --- a suite with no assertions is a failure, not a pass ---------------------
tmp="$(mktemp -d)"
printf '#!/usr/bin/env bash\nset -u\n. "%s/lib/assert.sh"\nassert_done\n' \
  "$TEST_DIR" > "$tmp/test_no_assertions.sh"
out="$(bash "$RUN_ALL" "$tmp" 2>&1)"
status=$?
rm -rf "$tmp"
assert_status 1 "$status" "runner exits 1 when a suite ran no assertions"
assert_contains "$out" "no assertions ran" "suite says no assertions ran"

assert_done
