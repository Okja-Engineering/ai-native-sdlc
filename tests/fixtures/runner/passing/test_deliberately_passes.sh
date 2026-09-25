#!/usr/bin/env bash
# Fixture: a suite that passes, so `run-all.sh` can be proven to pass when
# every suite passes. Not a real suite.
set -u
. "$(cd "$(dirname "$0")" && pwd)/../../../lib/assert.sh"

assert_eq "one" "one" "a passing assertion reports ok"

assert_done
