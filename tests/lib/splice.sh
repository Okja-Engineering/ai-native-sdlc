# Replace a line in a fixture with a block of several lines.
#
# WHY THIS IS A LIB AND NOT A LINE OF AWK IN EACH SUITE
#
# It was `awk -v repl="$body" '/pattern/ { print repl; next } { print }'`, in
# tests/test_item_rule.sh and then again in tests/test_rendering.sh. awk cannot carry a
# newline through `-v`: it prints `awk: newline in string` to stderr, the substitution
# does not happen, and the fixture is left IDENTICAL to the one the suite started with.
#
# That is the mutation-matched-nothing failure tests/lib/mutate.sh exists for, in a
# second place. It cost twelve cells in tests/test_rendering.sh and eight in
# tests/test_item_rule.sh, all of them passing while measuring an unmodified fixture —
# and the suites reported agreement between two gates that had not been asked anything.
#
# So: a marker line goes in with awk, the shell splices the block over it, and a
# substitution that matched nothing is a failure named as one rather than a quiet pass.

# splice <file> <awk pattern> <text>
#   Replaces the first line matching the pattern, and drops any later lines that also
#   match it, with the text — which may be any number of lines.
#   Returns non-zero when the pattern matched nothing.
#
# The pattern goes through `awk -v`, so write a character class rather than a backslash
# escape: `[*][*]` and not `\*\*`. Passed through -v the backslashes are consumed and
# `**` is not the expression anybody meant. This repository has paid for that one twice
# already, in validate-discovery.sh and here.
splice() {
  local f="$1" l
  [ -f "$f" ] || return 1
  awk -v pat="$2" '$0 ~ pat { if (!done) { print "@@SPLICE@@"; done = 1 }; next } { print }' \
    "$f" > "$f.splice" && mv "$f.splice" "$f"
  if ! grep -q '@@SPLICE@@' "$f"; then
    printf 'splice: the pattern matched nothing in %s, so the fixture is unmodified\n' "$f" >&2
    return 1
  fi
  while IFS= read -r l; do
    if [ "$l" = '@@SPLICE@@' ]; then printf '%s\n' "$3"; else printf '%s\n' "$l"; fi
  done < "$f" > "$f.splice" && mv "$f.splice" "$f"
}
