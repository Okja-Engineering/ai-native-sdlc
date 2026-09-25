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

if [ "$failed" -ne 0 ]; then
  printf 'run-all: %d of %d suites failed:%s\n' "$failed" "$ran" "$failed_names" >&2
  exit 1
fi

printf 'run-all: %d suites passed\n' "$ran"
exit 0
