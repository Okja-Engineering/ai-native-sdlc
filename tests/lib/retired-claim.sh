# A sentence that stopped being true, and the in-band declaration that retires it.
#
# WHY THIS IS A LIB AND NOT A FUNCTION IN TWO SUITES
#
# tests/test_doc_claims.sh and tests/test_cycle.sh both hold the same rule: a line
# carrying a phrase this repository has retired is reported, unless the line
# declares the retirement in band, naming the phrase and carrying a reason. One had
# it as `declared corrected-overclaim <pattern> <line>`; the other had it as a
# `case` chain over `<!-- corrected-claim:`, with a different idea of what a
# declaration is — the second accepted any declaration that carried a reason without
# checking it named the phrase.
#
# Two copies of the same three rules is two things to get wrong, which is the
# duplicated-declaration failure this repository keeps finding. tests/test_controls.sh
# holds a third variant for `not-an-enforcement-claim` and keeps it, because that one
# also has to resolve a refusal code against a gate; what it takes from here is the
# reading.
#
# THE THREE RULES, UNCHANGED
#
#   the declaration names the phrase it retires   a correction has to quote what it
#                                                 corrects
#   it carries a reason                           `<!-- corrected-claim: -->` retires
#                                                 nothing
#   it is on the line it retires                  a declaration elsewhere in the
#                                                 document exempts nothing
#
# WHAT IS NEW: THE DISPLAY QUESTION, IN BOTH DIRECTIONS
#
# Before this, `tests/test_cycle.sh` refused a document that quoted a retired
# sentence inside a fenced block. That is the one place that HAS to be able to show
# a reader the sentence, and it could not. The reverse hole was open at the same
# time: a declaration written inside an inline code span exempted a real claim,
# because the check read the raw line.
#
# Both come from one question and it is asked once, through bin/lib-rendering.sh:
#
#   the CLAIM counts when its line is one a reader sees        rendered_lines
#   the DECLARATION counts when it is not merely displayed     rendered_spans
#
# The two projections differ exactly where they have to. A retired sentence is
# line-shaped, so a fence, an indented block or a comment hides it and a code span
# does not — `the last thing printed` inside backticks is still a sentence a reader
# reads. A declaration is comment-shaped, so a code span hides it too.

# retired_claim_declared <keyword> <phrase pattern> <claim text> [<declaration text>]
#   -> 0 when the line declares the claim it carries
#
# Takes the line rather than a file so the fixtures in both suites can drive the
# decision itself rather than a second copy of it.
#
# TWO TEXTS, AND WHY. The phrase is read from the line view and the declaration from
# the span view, because the two projections disagree on exactly one thing and it
# matters here: a retired phrase written inside backticks is still a sentence a
# reader reads, so it is still a claim, while a declaration written inside backticks
# is an illustration and retires nothing. Read both out of one text and one of those
# two is wrong. The second argument defaults to the first so a fixture that carries
# no non-content passes one line.
retired_claim_declared() {
  local kw="$1" pat="$2" text="$3" phrase decl rest
  local dtext="${4-$3}"
  phrase="$(printf '%s' "$text" | grep -oiE "$pat" | head -1 | tr 'A-Z' 'a-z')"
  [ -n "$phrase" ] || return 0                       # no such claim on the line
  decl="$(printf '%s' "$dtext" \
    | sed -n "s/.*<!--[[:space:]]*${kw}:\([^>]*\)-->.*/\1/p" \
    | tr 'A-Z' 'a-z')"
  case "$decl" in
    *"$phrase"*) ;;
    *) return 1 ;;                                   # names a different phrase, or none
  esac
  rest="${decl/$phrase/}"                            # what is left is the reason
  case "$rest" in
    *[a-z0-9]*) return 0 ;;
    *) return 1 ;;
  esac
}

# retired_claim_offenders <keyword> <phrase pattern> <file...>
#   -> " file:line" for every line that makes the retired claim and does not retire it
#
# The claim is looked for in the LINE view and the declaration in the SPAN view, by
# line number, which the two projections preserve. `grep -i` on the line view rather
# than on the file, because a fenced quotation is not a claim and reading the file
# would make it one.
retired_claim_offenders() {
  local kw="$1" pat="$2" f lines spans hit lno text dtext out=""
  shift 2
  for f in "$@"; do
    [ -f "$f" ] || continue
    lines="$(rendered_lines_file "$f")" || { out="$out $f:unreadable"; continue; }
    spans="$(rendered_spans_file "$f")" || { out="$out $f:unreadable"; continue; }
    while IFS= read -r hit; do
      [ -n "$hit" ] || continue
      lno="${hit%%:*}"
      text="$(printf '%s\n' "$lines" | sed -n "${lno}p")"
      dtext="$(printf '%s\n' "$spans" | sed -n "${lno}p")"
      retired_claim_declared "$kw" "$pat" "$text" "$dtext" || out="$out $f:$lno"
    done <<EOF
$(printf '%s\n' "$lines" | grep -niE "$pat")
EOF
  done
  printf '%s' "$out"
}
