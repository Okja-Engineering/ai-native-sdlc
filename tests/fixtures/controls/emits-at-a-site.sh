#!/usr/bin/env bash
# A fixture gate for tests/test_controls.sh. Not run by anything.
#
# The pair to mentions-in-a-comment.sh. Same refusal code, at a real emission
# site. The two fixtures differ in nothing else, so the red and green results in
# the suite can only be about whether the code is emitted or merely mentioned.
set -u
refuse() { printf '%s: refuse[%s]: %s\n' "$1" "$2" "$3" >&2; }
refuse "$0" fixture-refusal "a fixture gate that emits the code it is cited for"
exit 0
