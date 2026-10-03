#!/usr/bin/env bash
# A fixture gate for tests/test_controls.sh. Not run by anything.
#
# It names fixture-refusal in this comment and never calls refuse with it. That is
# the exact shape that defeated the old check: tests/test_controls.sh asked
# `grep -q -- "$code" "$gate"`, so adding one comment line to any gate turned a
# fabricated refusal code from red to green.
#
# Its pair is emits-at-a-site.sh, which differs only in having a real call.
set -u
refuse() { printf '%s: refuse[%s]: %s\n' "$1" "$2" "$3" >&2; }
exit 0
