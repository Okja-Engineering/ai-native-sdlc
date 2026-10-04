#!/usr/bin/env bash
# A fixture gate for tests/test_controls.sh. Not run by anything.
#
# Two refusal codes where one is a prefix of the other. Its pair, prefix-code.md,
# cites the longer one in its table and mentions the shorter one in prose. The
# code-in-prose check compares a prose token against the cited codes as a WHOLE line;
# as a substring, `fixture-ref` would be read as already cited and the prose mention
# would go unchecked.
set -u
refuse() { printf '%s: refuse[%s]: %s\n' "$1" "$2" "$3" >&2; }
refuse "$0" fixture-refusal "the longer code, cited in the table"
refuse "$0" fixture-ref "the shorter code, a prefix of the other"
exit 0
