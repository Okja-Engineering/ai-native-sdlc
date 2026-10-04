#!/usr/bin/env bash
# A fixture gate for tests/test_controls.sh. Not run by anything.
#
# Two refuse calls. The first carries a readable code; the second carries a variable
# where the code should be, so bin/list-refusals.sh cannot say which refusal it is.
#
# A site like this is a hole in the denominator: neither the document check nor a
# mutation sweep by line number can see what it refuses. bin/validate-controls.sh
# treats it as a refusal rather than skipping it, and this fixture is what proves it.
set -u
refuse() { printf '%s: refuse[%s]: %s\n' "$1" "$2" "$3" >&2; }
refuse "$0" fixture-refusal "a readable call"
code="whatever-the-caller-decided"
refuse "$0" "$code" "a call whose refusal code cannot be read"
exit 0
