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

# --- a suite that disappeared is a failure, not a smaller pass ---------------
# Discovery is a glob. Deleting tests/test_validate_findings.sh made the runner
# report "12 suites passed" where it had said 13, and tests/test_run_all.sh passed
# 12 assertions over it. The runner asserted that it could fail and not that it was
# still looking at everything.
#
# Driven against a throwaway git repository, because the expectation comes from git
# and only a real work tree has one. Two suites, both tracked, one then removed.
REPO="$(mktemp -d)"
(
  cd "$REPO" || exit 2
  git init -q .
  git config user.name 'A Person'
  git config user.email 'person@example.invalid'
  for n in one two; do
    printf '#!/usr/bin/env bash\nset -u\n. "%s/lib/assert.sh"\nassert_eq a a "%s"\nassert_done\n' \
      "$TEST_DIR" "$n" > "test_$n.sh"
  done
  git add -A && git commit -q -m 'test: add two suites'
) >/dev/null 2>&1

out="$(bash "$RUN_ALL" "$REPO" 2>&1)"
status=$?
assert_status 0 "$status" "two tracked suites, both present, pass"
assert_contains "$out" "2 suites passed" "and the runner reports both"

rm -f "$REPO/test_two.sh"
out="$(bash "$RUN_ALL" "$REPO" 2>&1)"
status=$?
assert_status 1 "$status" "a suite git tracks and the runner did not run is a failure"
assert_contains "$out" "test_two.sh" "and the refusal names the suite that disappeared"
assert_not_contains "$out" "1 suites passed" "it does not report a smaller pass instead"

# A NEW suite that git does not track yet still runs, and does not trip the check.
# Otherwise adding a suite would fail the runner until it was committed, and the
# check would be fought rather than kept.
printf '#!/usr/bin/env bash\nset -u\n. "%s/lib/assert.sh"\nassert_eq a a three\nassert_done\n' \
  "$TEST_DIR" > "$REPO/test_three.sh"
printf '#!/usr/bin/env bash\nset -u\n. "%s/lib/assert.sh"\nassert_eq a a two\nassert_done\n' \
  "$TEST_DIR" > "$REPO/test_two.sh"
out="$(bash "$RUN_ALL" "$REPO" 2>&1)"
status=$?
assert_status 0 "$status" "an untracked new suite runs and does not trip the check"
assert_contains "$out" "3 suites passed" "and is counted"
rm -rf "$REPO"

# Outside a work tree the runner says it could not cross-check, rather than
# reporting a pass that silently skipped the check.
nogit="$(mktemp -d)"
printf '#!/usr/bin/env bash\nset -u\n. "%s/lib/assert.sh"\nassert_eq a a x\nassert_done\n' \
  "$TEST_DIR" > "$nogit/test_x.sh"
out="$(cd "$nogit" && bash "$RUN_ALL" "$nogit" 2>&1)"
rm -rf "$nogit"
assert_contains "$out" "not cross-checked" "outside a work tree it says the list was not checked"

# --- the real suite directory is cross-checked -------------------------------
# The assertions above are about constructed directories. This one is about the
# repository: every suite git tracks in tests/ has to be present, now.
tracked_here="$(git -C "$TEST_DIR" ls-files -- 'test_*.sh' | grep -vc '/' || true)"
[ "${tracked_here:-0}" -ge 10 ] && ok=yes || ok=no
assert_eq "yes" "$ok" "git tracks the suites in tests/ (found ${tracked_here:-0})"
gone=""
for t in $(git -C "$TEST_DIR" ls-files -- 'test_*.sh'); do
  case "$t" in */*) continue ;; esac
  [ -f "$TEST_DIR/$t" ] || gone="$gone $t"
done
assert_eq "" "$gone" "no suite this repository tracks is missing from the tree"

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
