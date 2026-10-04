#!/usr/bin/env bash
# List every refusal emission site in a gate script.
#
# usage: bin/list-refusals.sh <script> [<script>...]
#
# Prints one line per site:
#
#   <path>:<line>:<code>
#
# An **emission site** is a line that calls the gate's `refuse` function with a
# refusal code. That is a narrower thing than "the code appears in the file", and
# the difference is the whole reason this script exists: `tests/test_controls.sh`
# used to ask whether a cited code appeared anywhere in any gate, which a comment
# satisfies, and `CONTROLS.md` told an assessor that the association between a
# control and its gate was checked. One added comment line turned that check from
# red to green.
#
# Two things read this, and they have to agree on the denominator:
#
#   bin/validate-controls.sh   binds a cited code to the gate its control names
#   a mutation sweep           mutates every site by line number
#
# When those two disagree, a guard can be invisible to the document check and
# invisible to the sweep at the same time, which is how the `id` refusal in
# process/01-scan/validate-findings.sh reached production with no test at all.
#
# WHAT COUNTS AS A SITE
#
# A line is a site when `refuse` appears on it as a command — at the start of the
# line, or after `||`, `&&`, `;`, `(`, `)` or `{` — and is followed by arguments.
# These are excluded, each because a real line in this repository looks like it:
#
#   * a comment line, and a `refuse` call after a `#` on the line
#   * the `refuse()` definition itself, and the `printf` inside it
#   * `refuses`, `refused`, `refusal` — prose, not a call
#   * a line continuing the previous one. Four of the five gates write the code on
#     the `refuse` line and the message on the next, and a message containing the
#     word "refuse" followed by a space reads as a second call otherwise. That is
#     not hypothetical: it happened in bin/validate-controls.sh while this was
#     being written, and produced a phantom refusal code called `and`.
#
# READING THE CODE OUT OF THE CALL
#
# The five gates that use a `refuse` function do not agree on its signature:
#
#   refuse <file> <line> <code> <message>    process/01-scan, 02-discover,
#                                            03-define, 05-deliver
#   refuse <file> <code> <message>           bin/validate-standards.sh
#   refuse <code> <message>                  bin/validate-authorship.sh
#
# So the position of the code is not fixed. What is true in all three shapes is
# that the code is the first argument that is not a variable expansion, is not the
# bare `-` placeholder, and is shaped like a code: lower case, digits and hyphens,
# no spaces. The message always follows the code and always contains spaces, so
# "first" is unambiguous.
#
# A site whose code cannot be read prints `?` rather than being skipped. A
# silently dropped site is the failure this script exists to prevent, so an
# unreadable one is loud: bin/validate-controls.sh refuses on it.
#
# exit 0  at least one script was read
# exit 2  a named script does not exist
set -u

[ "$#" -ge 1 ] || { printf 'usage: bin/list-refusals.sh <script> [<script>...]\n' >&2; exit 2; }

for f in "$@"; do
  [ -f "$f" ] || { printf 'list-refusals: no such script: %s\n' "$f" >&2; exit 2; }
done

awk '
  # The code is the first argument that could be one. Arguments are tokenised
  # with quotes honoured, so a message containing spaces stays one token and
  # cannot be mistaken for a code.
  function code_of(s,   i, n, c, tok, q, na, t) {
    na = 0; tok = ""; q = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
      c = substr(s, i, 1)
      if (q != "") {
        if (c == "\\") { i++; continue }        # \" inside a message
        if (c == q) { q = "" } else { tok = tok c }
        continue
      }
      if (c == "\"" || c == "'"'"'") { q = c; continue }
      if (c == "\\") continue                   # line continuation
      if (c == " " || c == "\t") {
        if (tok != "") { na++; args[na] = tok; tok = "" }
        continue
      }
      if (c == ";") break
      tok = tok c
    }
    if (tok != "") { na++; args[na] = tok }
    # One test, not three. Explicit skips for "$file" and for the bare `-`
    # placeholder were written first and then deleted: neither could ever fire,
    # because a variable expansion carries a `$` and a dash has no leading letter,
    # so the shape test already rejects both. A guard that cannot fire reads as if
    # it were doing something.
    for (i = 1; i <= na; i++) {
      t = args[i]
      if (t ~ /^[a-z][a-z0-9]*(-[a-z0-9]+)*$/) return t
    }
    return "?"
  }

  FNR == 1 { cont = 0 }

  {
    comment = ($0 ~ /^[ \t]*#/)
    wascont = cont
    cont = (!comment && $0 ~ /\\[ \t]*$/)       # this line is continued
    if (comment || wascont) next                # a comment, or a continuation
  }

  {
    # A leading space so the boundary class below needs no "^" alternative:
    # BSD awk does not accept "^" inside a group the way GNU awk does.
    s = " " $0
    if (!match(s, /[ \t;&|{)(]refuse[ \t]/)) next
    pre = substr(s, 1, RSTART - 1)
    if (pre ~ /#/) next                         # the call is inside a comment
    rest = substr(s, RSTART + RLENGTH)
    printf "%s:%d:%s\n", FILENAME, FNR, code_of(rest)
  }
' "$@"
