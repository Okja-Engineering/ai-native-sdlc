# A sentence saying a gate refuses something has to name a refusal the gate emits.
#
# WHY THIS IS A LIB AND NOT A FUNCTION IN ONE SUITE
#
# It was a function in tests/test_controls.sh. Two suites now need the same
# decision: that one, which runs it over `SOURCES.md` and over four constructed
# registers, and tests/test_rendering.sh, which has to ask the display question of
# `not-an-enforcement-claim` the same way it asks it of the other fourteen forms.
# A second copy would be the duplicated declaration this repository keeps finding,
# and the display question is exactly where two copies would diverge.
#
# THE TWO RULES, UNCHANGED
#
#   1. a sentence saying the gate refuses something names which refusal
#   2. the refusal it names is one the gate actually emits, written as the gate
#      writes it — `refuse "$DOC" "code"` — so a code appearing in a comment does
#      not resolve
#
# A line that mentions a refusal without claiming one declares that in band with a
# reason: `<!-- not-an-enforcement-claim: reason -->`.
#
# WHAT IS NEW: THE DISPLAY QUESTION
#
# The exemption was read out of the raw line, so a document showing a reader what
# the marker looks like inside an inline code span exempted its own claim. The claim
# and the refusal code are read from the LINE view and the declaration from the SPAN
# view, through bin/lib-rendering.sh — the code and the gate name are written in
# backticks here and are real content, so only the declaration moves.

# A declaration is honoured only when it carries a reason. One pattern, used by the
# sweep and by the count in tests/test_controls.sh, so the two cannot disagree about
# what counts as declared.
ENFORCEMENT_DECLARED='not-an-enforcement-claim:[[:space:]]*[A-Za-z0-9`]'

# unbacked_enforcement_claims <document> <gate> -> offending line numbers
#
# Prints the numbers and nothing else: a function whose output is captured runs in a
# subshell, so it cannot report a count by setting a variable.
unbacked_enforcement_claims() {
  local doc="$1" gate="$2" base lines spans ln rn text dtext backed c
  base="$(basename "$gate")"
  lines="$(rendered_lines_file "$doc")" || { printf 'unreadable '; return; }
  spans="$(rendered_spans_file "$doc")" || { printf 'unreadable '; return; }
  while IFS= read -r ln; do
    [ -n "$ln" ] || continue
    rn="${ln%%:*}"; text="${ln#*:}"
    # Only a sentence naming the gate is a claim about what the gate does.
    case "$text" in
      *"$base"*) ;;
      *) continue ;;
    esac
    dtext="$(printf '%s\n' "$spans" | sed -n "${rn}p")"
    if printf '%s' "$dtext" | grep -q -- '<!-- not-an-enforcement-claim:'; then
      printf '%s' "$dtext" | grep -qE "$ENFORCEMENT_DECLARED" \
        || printf '%s(declared,no-reason) ' "$rn"
      continue
    fi
    # Does it name a refusal the gate emits? The QUOTED form is what resolves — a
    # bare match would be satisfied by the code appearing in one of the gate's
    # comments.
    backed=no
    for c in $(printf '%s' "$text" | grep -oE '`[a-z][a-z-]*[a-z]`' | tr -d '`'); do
      grep -q -- "\"$c\"" "$gate" && { backed=yes; break; }
    done
    [ "$backed" = yes ] || printf '%s ' "$rn"
  done <<EOF
$(printf '%s\n' "$lines" | grep -nE '[Rr]efus(e|es|ed|ing)[^a-z]')
EOF
}
