#!/usr/bin/env bash
# Run every suite in a directory and fail if any of them fails.
#
# usage: tests/run-all.sh [directory]
#
# Suites are files matching `test_*.sh` directly in the directory (default:
# this one). Fixtures live in subdirectories so they are not picked up here.
#
# Exit 0 only when every suite exited 0 and at least one suite ran.
set -u

dir="${1:-$(dirname "$0")}"

if [ ! -d "$dir" ]; then
  printf 'run-all: not a directory: %s\n' "$dir" >&2
  exit 1
fi

ran=0
failed=0
failed_names=""

for suite in "$dir"/test_*.sh; do
  [ -f "$suite" ] || continue
  ran=$((ran + 1))
  printf '\n=== %s\n' "$suite"
  if bash "$suite"; then
    printf 'PASS %s\n' "$suite"
  else
    printf 'FAIL %s\n' "$suite"
    failed=$((failed + 1))
    failed_names="$failed_names $suite"
  fi
done

printf '\n'

if [ "$ran" -eq 0 ]; then
  printf 'run-all: no test suites found in %s\n' "$dir" >&2
  exit 1
fi

# --- every suite the repository holds has to have run -------------------------
# Discovery is a glob, and a glob reports whatever is in front of it. Delete a
# suite file and this said "12 suites passed" where it had said 13, with nothing
# to signal that coverage had shrunk — the same shape as a gate reporting a clean
# tree having evaluated nothing. CTRL-9 lists suite integrity as a control and
# asserts that this runner can fail; it did not assert that the runner was still
# looking at everything.
#
# The expectation comes from git rather than from a list kept beside the suites. A
# tracked manifest would be the duplicated state this repository keeps being burnt
# by, and a gate-to-suite naming convention does not hold: test_hooks.sh covers two
# hooks and test_controls.sh covers a differently named gate.
#
# WHAT THIS DOES NOT CATCH, stated because the gap is narrow and real: a deletion
# that is committed. git then does not track the file either, and nothing in the
# tree says it should. What it catches is a suite that disappeared from the working
# tree or from a checkout — which is the case that reaches CI.
missing=""
if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for tracked in $(git -C "$dir" ls-files -- 'test_*.sh' 2>/dev/null); do
    # A suite path with a directory in it is a fixture, and fixtures are not run
    # from here on purpose.
    case "$tracked" in */*) continue ;; esac
    [ -f "$dir/$tracked" ] || missing="$missing $tracked"
  done
else
  # Said rather than skipped. test_run_all.sh drives this runner over mktemp
  # directories that are in no work tree, so "could not check" is a real state and
  # a silent one would be a hole.
  printf 'run-all: %s is not in a git work tree, so the suite list was not cross-checked\n' "$dir"
fi

if [ -n "$missing" ]; then
  printf 'run-all: git tracks %d suite(s) in %s that did not run:%s\n' \
    "$(printf '%s\n' $missing | grep -c .)" "$dir" "$missing" >&2
  printf 'run-all: %d suites ran. A suite that disappears must not read as a smaller pass.\n' \
    "$ran" >&2
  exit 1
fi

if [ "$failed" -ne 0 ]; then
  printf 'run-all: %d of %d suites failed:%s\n' "$failed" "$ran" "$failed_names" >&2
  exit 1
fi

printf 'run-all: %d suites passed\n' "$ran"
exit 0
