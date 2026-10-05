#!/usr/bin/env bash
# One answer to "would a reader of the rendered document see this?"
#
# usage: . bin/lib-rendering.sh    then rendered_spans_file <path>
#                                       rendered_lines_file <path>
#        bin/lib-rendering.sh [--lines] [file ...]   as a filter, to look by hand
#
# THE RULE, IN ONE SENTENCE
#
# A document that DISPLAYS a declaration's syntax must not thereby SATISFY it.
#
# This repository already states that rule — at
# process/02-discover/validate-discovery.sh, about fenced blocks only — and had
# paid for the class five times before this file existed:
#
#   a fenced `rests on: none` donated itself as the real field's value
#   an example row in a fenced block in DECIDERS.md would have authorized everyone
#   a fenced `declared-empty` emptied a mandatory disclosure section
#   a fenced `graded-claims-cite-inline` exempted a document's own uncited claims
#   a fenced illustration of an open item counted toward the item total
#
# Each was repaired where it was found. The tree carries FIFTEEN in-band
# declaration forms, read by seven gates, one load-bearing helper and two test
# suites, and fence-awareness ran from all of them to none. Two gates had none, and
# that is where both criticals on issue #116 live: the whole of the scan contract's
# six machine-read lists was readable out of a fenced example, and the standards
# gate's span exemption was honoured inside one.
#
# AND A FENCE IS NOT THE ONLY WAY TO DISPLAY SOMETHING. An inline code span, an
# HTML comment and a four-space indented block are all non-rendering, and no
# predicate anywhere knew that. The first of those is critical 1: a declaration
# shown in backticks emptied a mandatory section while every suite stayed green.
#
# WHAT IS NON-CONTENT
#
#   a fenced code block      ``` or ~~~, three or more, indented up to three
#   an indented code block   four spaces or a tab, outside a list
#   an HTML comment's body   everything between <!-- and the --> that closes it
#   an inline code span      a backtick run and its matching run
#
# The first three are properties of a LINE. The fourth is a property of a SPAN
# inside a line, and that difference is load-bearing, so there are two projections
# of one state machine rather than one view used twice.
#
# WHICH PROJECTION A READER WANTS DEPENDS ON THE SHAPE OF WHAT IT READS
#
# rendered_spans — for a COMMENT-SHAPED construct, which is all fifteen
# declarations. A whole HTML comment fits inside an inline code span and still
# matches a declaration regex exactly, so the span has to go. That is critical 1.
#
# rendered_lines — for a LINE-SHAPED construct: a `key: value` field, a list item
# in a contract block, a table row, a heading, a graded line. Code spans are KEPT,
# because in this repository a code span is house style for real content inside a
# real line: the four graded claims in AGENTS.md write their grade as `[E]`, and
# every item in the scan contract's `columns` block is written as `- `id``.
# Blanking spans there would have hidden four real claims and emptied six machine-
# read lists — measured, not assumed, and that measurement is why this file has two
# functions instead of one.
#
# Wrapping a line-shaped construct in a code span is not a display form for it, for
# free: `- an item [O]` in backticks starts with a backtick, so it is no longer a
# line beginning with a list marker. The cell is closed by the shape of the rule
# rather than by this file, which is why it is recorded rather than defended.
#
# WHAT STAYS RAW, AND THE MEASUREMENT THAT SAYS SO
#
# A non-rendering occurrence never CREATES PERMISSION and never SATISFIES A
# REQUIREMENT. It may still INCUR one.
#
# So bin/validate-standards.sh reads its EXEMPTIONS through rendered_spans and its
# GRADED CLAIMS, CITATIONS and EVIDENCE POINTERS out of the raw file. That is not a
# convenience: a grade marker and a commit are both written in backticks here, so
# sixteen lines carrying a real `[E]` or `[S]` disappear from the span projection,
# AGENTS.md's four among them. Reading claims through it would be a loosening of a
# check that works, made as a side effect of closing something else.
#
# The consequence is stated rather than hidden: a graded claim written inside a
# fence is still read, and a `not-a-claim` written inside the same fence does not
# exempt it. A document wanting to show a reader an example graded claim cites it or
# declares it outside the fence.
#
# WHICH DIRECTION THIS IS SAFE IN
#
# Removing too much costs a declaration, which costs a refusal — loud, and in the
# operator's own document. Removing too little is the silent hole this file exists
# to close. Every caller fails closed in the first direction: an empty contract list
# exits 2, a missing field refuses, an unexempted claim refuses, an uncounted item
# refuses, an undesignated table authorizes nobody.
#
# WHY THIS IS A SHARED LIBRARY AND NOT A NINTH COPY
#
# The two `declares_empty` copies were held together by tests/test_item_rule.sh
# driving one line through both gates, and the reasoning recorded at both copies was
# that a shared helper would be a load-bearing script outside the filename pattern
# bin/validate-controls.sh enumerates. That reasoning was right for TWO copies and
# does not scale to twelve clients: four of the six sites on #116 exist because the
# rule was copied rather than shared, and the two gates that never received a copy
# hold both criticals.
#
# One copy also buys something duplication cannot. This is a READING, not a
# predicate: a gate obtains its artifact's text through here once and every
# predicate below reads that, so a NEW predicate written by someone who has never
# heard of this rule is still safe, because the displayed form is not in the text it
# is handed. CONTROLS.md item 15 records that nothing stops a third section being
# written with a fourth word search. This is that mechanism.
#
# THE COST, STATED. This is the third load-bearing script outside the enforcement
# surface `Sideways` builds, after `bin/list-refusals.sh` and
# `process/01-scan/findings-ids.sh`, both of which CONTROLS.md already discloses at
# the same place. It emits no refusal code, so all four directions of
# bin/validate-controls.sh are blind to it by construction — the same blindness the
# fourth direction was built to fix for declared fields. It does NOT widen the
# surface, so the decision #95 holds is untouched. And it is a single point of
# failure: one wrong edit moves seven gates at once. Three things bound that, and
# none of them is a promise:
#
#   every caller exits 2 when it cannot read this file, the pattern
#   validate-define.sh already uses for the findings harvester
#
#   both _file functions return non-zero when the view does not have the same number
#   of lines as the file, so a truncation cannot be read as a clean document
#
#   tests/test_rendering.sh is the denominator: five display forms against fifteen
#   declaration forms, every cell enumerated and none omitted
#
# LINE AND COLUMN NUMBERS ARE PRESERVED. Non-content is replaced by spaces rather
# than deleted, so a refusal that reports `file:line` still names the line the
# operator will find it on, and a caller may read a projection and the raw file in
# the same pass by line number.
#
# Portability: bash 3.2, BSD and GNU userland. No -P, no in-place sed, no awk
# IGNORECASE, no interval expressions — BSD awk does not support `{3,}`, so a fence
# run is counted by hand rather than matched.

# _RENDERING_AWK is the whole of it, in one variable, so the two projections cannot
# drift from each other: they are the same program run with SPANS set or unset.
_RENDERING_AWK='
function blank(s,   n) {
  n = length(s)
  if (n <= 0) return ""
  while (length(SP) < n) SP = SP SP "                "
  return substr(SP, 1, n)
}

# fence_info(line) -> "<char>:<run length>" when the line could open or close a
# fenced block, "" otherwise. Up to three leading spaces; four is an indented code
# block and is handled there.
function fence_info(line,   i, ch, n) {
  i = 1
  while (substr(line, i, 1) == " ") {
    i++
    if (i > 4) return ""
  }
  ch = substr(line, i, 1)
  if (ch != "`" && ch != "~") return ""
  n = 0
  while (substr(line, i, 1) == ch) { n++; i++ }
  if (n < 3) return ""
  return ch ":" n
}

# A CLOSING fence carries nothing but its own run. That is what CommonMark says and
# it is also the conservative reading: closing a block early would make the lines
# below it content again, which is the direction that opens a hole.
function closes_fence(line, ch, want,   info, rest, i, n) {
  info = fence_info(line)
  if (info == "") return 0
  if (substr(info, 1, 1) != ch) return 0
  n = substr(info, 3) + 0
  if (n < want) return 0
  i = index(line, ch)
  rest = substr(line, i + n)
  if (rest ~ /^[ \t]*$/) return 1
  return 0
}

# A backtick run of length n is closed by a run of EXACTLY n. An unmatched run is
# literal text, which is what Markdown does with it.
function close_run(s, from, n,   L, i, j, k) {
  L = length(s)
  i = from
  while (i <= L) {
    if (substr(s, i, 1) == "`") {
      k = 0; j = i
      while (j <= L && substr(s, j, 1) == "`") { k++; j++ }
      if (k == n) return i
      i = j
    } else i++
  }
  return 0
}

# HTML comments do not nest. Inside one kept comment every `<!--` after the first is
# literal text a reader never sees, so it must not be able to introduce a
# declaration. In
#
#   <!-- a note saying an empty section writes
#        <!-- declared-empty: reason -->
#        in its body. -->
#
# the comment a browser ends at the FIRST `-->`, so the illustration is invisible
# and a per-line regex reads the middle line as a real declaration.
function one_opener(s,   head, tail, p) {
  head = substr(s, 1, 4)
  tail = substr(s, 5)
  while ((p = index(tail, "<!--")) > 0)
    tail = substr(tail, 1, p - 1) "    " substr(tail, p + 4)
  return head tail
}

# A four-space indent is a code block, EXCEPT under a list, where it is the list
# item continuing and a reader does see it. Refusing a declaration written in a
# nested list would be the false refusal this change exists to remove.
function list_marker(line,   i, ch) {
  i = 1
  while (substr(line, i, 1) == " ") {
    i++
    if (i > 4) return 0
  }
  ch = substr(line, i, 1)
  if ((ch == "-" || ch == "*" || ch == "+") && substr(line, i + 1, 1) ~ /[ \t]/) return 1
  if (ch ~ /[0-9]/) {
    while (substr(line, i, 1) ~ /[0-9]/) i++
    if (substr(line, i, 1) ~ /[.)]/ && substr(line, i + 1, 1) ~ /[ \t]/) return 1
  }
  return 0
}

BEGIN { SP = " " }

FNR == 1 { fence = 0; fchar = ""; incomment = 0; listopen = 0 }

{
  line = $0
  out = ""
  midline = 0

  if (incomment) {
    p = index(line, "-->")
    if (p == 0) { print blank(line); next }
    out = blank(substr(line, 1, p + 2))
    line = substr(line, p + 3)
    incomment = 0
    midline = 1
  }

  if (!midline) {
    if (fence) {
      if (closes_fence(line, fchar, fence)) { fence = 0; fchar = "" }
      print blank(line)
      next
    }
    info = fence_info(line)
    if (info != "") {
      fchar = substr(info, 1, 1)
      fence = substr(info, 3) + 0
      print blank(line)
      next
    }
    if (line ~ /^\t/ || line ~ /^    /) {
      if (!listopen) { print blank(line); next }
    } else if (line ~ /^[ \t]*$/) {
      # a blank line neither opens nor closes a list
    } else if (list_marker(line)) {
      listopen = 1
    } else {
      listopen = 0
    }
  }

  while (length(line) > 0) {
    b = SPANS ? index(line, "`") : 0
    c = index(line, "<!--")
    if (b == 0 && c == 0) { out = out line; break }
    if (c == 0 || (b > 0 && b < c)) {
      out = out substr(line, 1, b - 1)
      rest = substr(line, b)
      n = 0
      while (substr(rest, n + 1, 1) == "`") n++
      cl = close_run(rest, n + 1, n)
      if (cl == 0) {
        out = out substr(rest, 1, n)
        line = substr(rest, n + 1)
      } else {
        out = out blank(substr(rest, 1, cl + n - 1))
        line = substr(rest, cl + n)
      }
    } else {
      out = out substr(line, 1, c - 1)
      rest = substr(line, c)
      e = index(rest, "-->")
      if (e == 0) {
        out = out blank(rest)
        incomment = 1
        line = ""
      } else {
        out = out one_opener(substr(rest, 1, e + 2))
        line = substr(rest, e + 3)
      }
    }
  }
  print out
}
'

# rendered_spans — for a comment-shaped construct. Reads stdin.
rendered_spans() { awk -v SPANS=1 "$_RENDERING_AWK"; }

# rendered_lines — for a line-shaped construct. Reads stdin.
rendered_lines() { awk -v SPANS=0 "$_RENDERING_AWK"; }

# _rendered_file <spans> <path> — a projection over a file, with the line count
# checked. A truncated view would make every declaration below the cut disappear,
# which is a refusal rather than a hole, but a refusal naming the wrong problem. So it
# is detected and named here instead.
#
# THE SENTINEL IS LOAD-BEARING AND IT IS HERE BECAUSE THE FIRST VERSION WAS WRONG.
# Command substitution strips trailing newlines, and a projection ends in blanked
# lines whenever a document ends inside a fence or with blank lines — so counting the
# captured text reported CONTROLS.md as 547 lines of 557 and this guard fired on a
# correct view. Worse than a false alarm: the caller then read an EMPTY view and every
# exemption in that document silently disappeared. A non-blank line appended after the
# render is what command substitution keeps, so the count is of the render and not of
# the shell.
#
# The caller still gets a view with its own trailing blanks stripped, which is
# harmless: every caller indexes from line 1 and a blanked trailing line carries no
# declaration.
_rendered_file() {
  local raw view out
  [ -f "$2" ] || return 1
  raw="$(awk 'END { print NR + 0 }' "$2")"
  [ "$raw" = 0 ] && return 0
  view="$(awk -v SPANS="$1" "$_RENDERING_AWK" "$2"; printf '.\n')"
  if [ "$(( $(printf '%s\n' "$view" | awk 'END { print NR + 0 }') - 1 ))" != "$raw" ]; then
    printf 'lib-rendering: the view of %s is not %s lines, which is what the file holds\n' \
      "$2" "$raw" >&2
    return 2
  fi
  out="${view%$'\n'.}"
  printf '%s\n' "$out"
}

rendered_spans_file() { _rendered_file 1 "$1"; }
rendered_lines_file() { _rendered_file 0 "$1"; }

# Run directly, this is a filter. Nothing depends on that; it is here so a
# surprising refusal can be explained by looking at what the gate actually read,
# which is how three cells in tests/test_rendering.sh were found.
case "${0##*/}" in
  lib-rendering.sh)
    _spans=1
    if [ "${1:-}" = --lines ]; then _spans=0; shift; fi
    if [ "$#" -gt 0 ]; then awk -v SPANS="$_spans" "$_RENDERING_AWK" "$@"
    else awk -v SPANS="$_spans" "$_RENDERING_AWK"; fi
    ;;
esac
