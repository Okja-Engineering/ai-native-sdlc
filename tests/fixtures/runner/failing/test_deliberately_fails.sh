#!/usr/bin/env bash
# Fixture: a suite that fails on purpose, so `run-all.sh` can be proven to fail
# when a suite fails. Not a real suite — it lives under fixtures/ so the
# top-level `test_*.sh` glob does not pick it up.
set -u
. "$(cd "$(dirname "$0")" && pwd)/../../../lib/assert.sh"

assert_eq "one" "one" "a passing assertion still reports ok"
assert_eq "one" "two" "this assertion fails on purpose"

assert_done
