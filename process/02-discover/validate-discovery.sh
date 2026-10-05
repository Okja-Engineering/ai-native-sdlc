#!/usr/bin/env bash
# The Discover checks that do not depend on a topic's shape.
#
# usage: process/02-discover/validate-discovery.sh [file ...]
#        process/02-discover/validate-discovery.sh          # every topic
#
# Discover is the phase carrying the most claims — one artifact holds 55 graded
# ones — and it had no mechanical check at all. The contract deferred its gate
# until a second topic could separate shape from accident. Two now exist, on
# differently shaped questions, so the deferral is spent.
#
# WHAT THE CONTRACT ASKED FOR, AND WHAT TURNED OUT TO BE CHECKABLE
#
# The contract named four checks and called three of them mechanical. Writing
# this found that two of the three are not, and that is recorded rather than
# faked:
#
#   "every claim carries a grade"   -> NOT CHECKABLE. It needs a claim to be a
#   "every claim carries a source"     delimited thing. The two topics mark
#                                      claims as prose paragraphs, in different
#                                      markup — one uses bare [E], the other
#                                      bold **[E]** — with no boundary a script
#                                      can find. Counting "claims" would mean
#                                      inventing a convention mid-gate and then
#                                      checking the artifacts against a rule
#                                      they were not written to. What IS
#                                      checkable is that every grade marker used
#                                      is from the enum, which catches a typo or
#                                      an invented grade, and that the enum is
#                                      declared. That is less than the contract
#                                      hoped for and is stated as such.
#
#   "the [O] section exists and is   -> CHECKABLE, and built. Same shape as the
#    not silently empty"                existing outlier check in Define.
#
#   "no recommendation language"     -> DELIBERATELY NOT BUILT. A pattern match
#                                      on "recommend" fires on the sentence
#                                      "No option set, no recommendation, no
#                                      decision" — a correct disclaimer flagged
#                                      as the thing it disclaims. The real
#                                      failure is a neutral-sounding paragraph
#                                      that steers, which no pattern catches.
#                                      Mechanising the proxy would spend reader
#                                      trust on false positives. A reader's job.
#
# Section presence is matched loosely on purpose. The two topics carry the same
# required sections in different form: one as `## 5 · What we could not
# establish` with bold inline labels, the other as `## What could not be
# established` with `###` subheadings. Both satisfy the contract. A gate keyed
# to exact headings would have encoded the newer artifact's markup as a rule.
#
# exit 0  every file checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOPICS="${DISCOVER_TOPICS_DIR:-$SCRIPT_DIR/topics}"

# A document that DISPLAYS a declaration must not thereby SATISFY it. The rule used
# to be stated here, about fenced blocks, and applied to one predicate. It is now one
# reading, shared by every gate — see bin/lib-rendering.sh for the rule, the two
# projections and the cost of sharing it.
#
# Refusing to run without it, the same way this file's sibling refuses to run without
# the findings harvester: a gate that silently lost its reading would read every
# displayed declaration as real, which is the defect, not a degraded mode.
RENDERING="${RENDERING_LIB:-$SCRIPT_DIR/../../bin/lib-rendering.sh}"
if [ ! -f "$RENDERING" ]; then
  printf 'validate-discovery: no rendering library at %s — without it a declaration shown to a reader would satisfy the check it illustrates, so this gate will not run\n' "$RENDERING" >&2
  exit 2
fi
. "$RENDERING"

refusals=0

refuse() { printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2; refusals=$((refusals + 1)); }

# VIEW is the artifact as a reader sees it, line by line — fences, indented blocks
# and HTML comment bodies blanked, code spans kept because a code span is this
# repository's house style for a real grade marker. Set once per file in check_topic
# and read by every predicate below, so a predicate written later is safe without
# knowing this rule exists.
VIEW=""
# SPANVIEW additionally blanks inline code spans, and is what a DECLARATION is read
# from: a whole HTML comment fits inside one and still matches a declaration regex.
SPANVIEW=""

# field <file> <key> — the first value in a rendering context, trimmed. It renders
# the file it is given rather than reading VIEW, so a call site reading a different
# file cannot silently get this artifact's answer; the Define twin had exactly that
# bug for one commit and its own suite caught it.
field()  { rendered_lines_file "$1" 2>/dev/null | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed 's/[[:space:]]*$//'; }

# has <file> <extended-regex> -> 0 if present in the rendering context,
# case-insensitive. The argument is kept for the call sites; the text comes from
# VIEW, because a section heading shown inside a fence is not a section.
has() { printf '%s\n' "$VIEW" | grep -qiE "$2"; }

# declares_empty <section body> -> 0 if the section declares itself empty
#
# A section with nothing in it has to SAY it is empty, in band, with a reason:
#
#   <!-- declared-empty: every question in scope was answered -->
#
# Checked for the same two things as the `not-a-claim` and `dead-pointer`
# declarations in bin/validate-standards.sh: the declaration is present, and it
# carries a reason. NOT whether the reason is true — an author can declare a
# section empty that should not be, and CONTROLS.md says so under what is not
# controlled rather than pretending otherwise.
#
# WHY THIS REPLACED A WORD SEARCH. The check read the section's body for three
# short words — the same shape as the two-number coverage proxy above and the
# four-phrase dead-pointer match, which is three times this repository has
# shipped a search standing in for a reading. An external review deleted all
# seven items from the open section of topics/agent-pr-approval.md, left "The
# discovery was exhaustive and nothing of consequence remains outstanding", and
# this gate reported the artifact within the contract: the artifact deleted every
# disclosure it owed, asserted the opposite, and passed on one incidental word.
#
# A DISPLAYED DECLARATION IS NOT A DECLARATION. A document showing what the form
# looks like must not thereby satisfy it.
#
# THIS USED TO SAY "A FENCED BLOCK IS NOT A DECLARATION", and that was the whole of
# it — the skip was two lines of awk toggling on ``` and ~~~. Issue #116 reproduced
# the rest of the class against this very predicate: delete the seven [O] items from
# topics/agent-pr-approval.md, write one line mentioning
# `<!-- declared-empty: reason -->` IN BACKTICKS, and this gate reported the artifact
# within the contract with all eighteen suites green. An inline code span, an HTML
# comment and a four-space indented block are all non-rendering and none of them was
# known to any predicate anywhere.
#
# So the caller hands this the SPAN projection of the section, and the question this
# predicate asks is only the one it is named for. The rule itself, the five display
# forms and the reason the two projections differ are in bin/lib-rendering.sh.
#
# THIS PREDICATE IS NO LONGER DUPLICATED. It was written identically here and in
# process/03-define/validate-define.sh, held together by tests/test_item_rule.sh,
# because a shared helper would be a load-bearing script outside the filename pattern
# bin/validate-controls.sh enumerates. The reading they both needed is now shared and
# that reasoning is answered where the library lives; what is left here is one regex,
# and tests/test_rendering.sh drives both sections through all five display forms.
declares_empty() { # <section body, span projection>
  printf '%s\n' "$1" | grep -q '<!--[ 	]*declared-empty:[^>]*[A-Za-z][^>]*-->'
}

# tokens <text> -> the words of a text, one per line.
#
# Backticks are dropped first, so a name written as a code span and the same
# name written in prose produce the same token. The two shipped topics differ on
# exactly that — one marks names with backticks and the other does not.
tokens() {
  printf '%s\n' "$1" | tr -d '`' \
    | grep -oE 'https?://[^][ )(]+|[A-Za-z0-9][A-Za-z0-9_/%+.-]*' \
    | sed 's/[.,;:]*$//' | grep -v '^$'
}

# referents <text> -> the tokens that NAME something a reader could go and check
#
# Three classes, and the reason each one is in:
#
#   a URL                 an address that can be opened.
#
#   an interior capital   an acronym, a product or a repository: MMLU, WANLI,
#                         JevBench, TypeSafe, GitHub. Interior and not leading,
#                         because a leading capital is only the start of a
#                         sentence. This is the whole of why "Nothing" is not a
#                         referent and "WANLI" is.
#
#   letters with digits   an id, a version, a commit, a quantity carrying its
#                         unit: 27B, v1.5.1, 23cf1f3, S-NBER-2026-01.
#
# A bare number is deliberately NOT a referent. 875 and 2026-10-03 name nothing
# on their own — the thing measured is what a reader would go and look at — and
# a date in particular is available to any sentence, including one denying that
# anything was checked.
referents() {
  tokens "$1" | grep -E '^https?://|^.[A-Za-z0-9_/%+.-]*[A-Z]|^[A-Za-z0-9_/%+.-]*[A-Za-z][A-Za-z0-9_/%+.-]*[0-9]|^[A-Za-z0-9_/%+.-]*[0-9][A-Za-z0-9_/%+.-]*[A-Za-z]'
}

check_topic() {
  local f="$1" grades bad bad_links seen cov R_LABEL N_LABEL V_LABEL opensec opensec_spans

  # The artifact as a reader sees it, read once. Every check below reads this rather
  # than the file, so a heading, a field, an item, a grade or a link that exists only
  # inside a fenced example is not there as far as this gate is concerned — in both
  # directions: it cannot satisfy a requirement and it cannot draw a refusal.
  VIEW="$(rendered_lines_file "$f")" || {
    printf 'validate-discovery: could not read %s as rendered text\n' "$f" >&2
    exit 2
  }
  SPANVIEW="$(rendered_spans_file "$f")" || {
    printf 'validate-discovery: could not read %s as rendered text\n' "$f" >&2
    exit 2
  }

  # --- the fields the contract declares -----------------------------------
  [ -n "$(field "$f" dated)" ] || refuse "$f" "-" "undated" \
    "no dated: field — a discovery artifact is a statement about a moment, and an undated one cannot be aged"
  [ -n "$(field "$f" status)" ] || refuse "$f" "-" "no-status" \
    "no status: field — a reader cannot tell discovery complete from discovery abandoned"

  # --- the question, in the asker's own words ------------------------------
  # Quoted rather than paraphrased, so a blockquote has to be present.
  if ! has "$f" "the question, in the (asker|owner)'s"; then
    refuse "$f" "-" "no-question" \
      "the question is not stated in the asker's own words: a tidied restatement answers a different question, and the first topic's skepticism and the second's falsified premise both survived only because the wording did"
  elif ! printf '%s\n' "$VIEW" | grep -qE '^>'; then
    refuse "$f" "-" "question-not-quoted" \
      "the question section carries no quotation: the contract requires the asker's words, not a summary of them"
  fi

  # --- coverage, in three parts -------------------------------------------
  #
  # These checks used to grep the WHOLE FILE for each phrase, and an external
  # audit walked a hollow artifact straight through them:
  #
  #   "Everything was reached. Nothing was not reached. Nothing was verified by
  #    hand — we took the agent's word for all of it."
  #
  # `no-reached` was satisfied by the substring inside "not reached".
  # `no-verified-by-hand` was satisfied by a sentence DENYING hand verification.
  # The three-part coverage this repository calls "what separates an agent
  # reported this from someone checked it" was a presence-of-phrase test.
  #
  # So each part is now located INSIDE the coverage section and has to NAME
  # things, which part_names_things below measures directly.
  #
  # The heading match is also loosened. `^#+ *coverage` required the word
  # immediately after the hashes, so `## Coverage` passed while `## 2 · Coverage`
  # was refused — heading-shape coupling in a gate whose header says it avoids
  # exactly that, and the only reason the hollow artifact was refused at all.
  if ! printf '%s\n' "$VIEW" | grep -qiE '^#+[^a-z]*coverage|^\*\*coverage'; then
    refuse "$f" "-" "no-coverage" "no coverage section"
  else
    cov="$(awk '
      /^#+[^a-zA-Z]*[Cc]overage|^\*\*[Cc]overage/ { inside = 1; next }
      /^## / { if (inside) exit }
      inside { print }' <<EOF
$VIEW
EOF
)"

    # part_body <label-regex> — the lines belonging to one coverage part.
    #
    # A part's body runs from its label to the next part label, which the two
    # topics write differently: `### Verified by hand` in one, a bold inline
    # `**Verified by hand before recording:**` in the other. Both are matched.
    #
    # The label is matched against a lowercased copy of each line while the
    # ORIGINAL line is what gets printed, because the referent test below needs
    # the capitalisation. awk's IGNORECASE is a GNU extension: BSD awk ignores
    # it silently, so on macOS a lowercase pattern never matched `### Verified
    # by hand` and every part came back empty, refusing both real topics. Third
    # GNU-ism of this kind here, after `\?` in sed and `\b` in git grep.
    part_body() {
      printf '%s\n' "$cov" | awk -v re="$1" '
        BEGIN { on = 0 }
        {
          l = tolower($0)
          is_label = (l ~ /^#+ /) || (l ~ /^[*][*][a-z]/)
          if (on && is_label && l !~ re) exit
          if (l ~ re) { on = 1 }
          if (on) print
        }'
    }

    # part_names_things <label-regex> -> 0 if the part names something the rest
    # of the artifact also carries.
    #
    # This replaced two numbers — a minimum separator count and a minimum
    # character count — whose comment asserted that "a fabricated part tops out
    # around 43 characters and 2 separators". It does not. The artifact from #32
    # passed by adding two commas to a sentence denying that anything was
    # checked, and the same sentence without the commas was refused. The gate
    # was measuring the shape of a sentence instead of reading it.
    #
    # What a coverage part has to do is name things, and that is directly
    # measurable: a name appears somewhere else in the artifact, because the
    # things a discovery artifact checked are the things it is about. A denial
    # names nothing however it is punctuated, and a part naming one real thing
    # in four words is a coverage part even though both old numbers refused it.
    #
    # The bar is ONE resolving referent, not a count. A count would be another
    # proxy, and the proxy is what was wrong.
    part_names_things() {
      local b rest refs
      b="$(part_body "$1")"
      [ -n "$b" ] || return 1
      refs="$(referents "$b" | sort -u)"
      [ -n "$refs" ] || return 1
      # The artifact with this part's own lines removed, so a word cannot
      # corroborate itself. Same scope discipline as the checks above: look at
      # the part, then at everything that is not the part.
      rest="$(printf '%s\n' "$VIEW" | grep -vxFf <(printf '%s\n' "$b"))"
      tokens "$rest" | grep -qxF -- "$refs"
    }

    # Patterns are anchored to a LABEL — `### reached` or `**reached:**` — not to
    # the word anywhere. Unanchored, `reached` also matched `not reached`, so the
    # reached part's scope ran on through its neighbour and read its items. An
    # artifact with an empty reached part and a full not-reached part would have
    # passed.
    # `[*][*]` rather than `\*\*`: passed through awk's -v the backslashes are
    # consumed, leaving `**`, which is an invalid ERE — awk printed "illegal
    # primary" and every count came back empty. A character class survives both
    # awk and grep unchanged.
    R_LABEL='^(#+ |[*][*])reached'
    N_LABEL='^(#+ |[*][*])not reached'
    V_LABEL='^(#+ |[*][*])verified by hand'

    printf '%s\n' "$cov" | grep -qiE "$R_LABEL" || refuse "$f" "-" "no-reached" \
      "coverage has no 'reached' part"
    printf '%s\n' "$cov" | grep -qiE "$N_LABEL" || refuse "$f" "-" "no-not-reached" \
      "coverage does not say what was NOT reached: an artifact claiming only successes is claiming completeness it has not earned"

    if ! printf '%s\n' "$cov" | grep -qiE "$V_LABEL"; then
      refuse "$f" "-" "no-verified-by-hand" \
        "coverage has no 'verified by hand' part: without it there is nothing separating an agent reported this from someone checked it, and a discovery artifact becomes a pile of agent output"
    elif ! part_names_things "$V_LABEL"; then
      refuse "$f" "-" "empty-verified-by-hand" \
        "the 'verified by hand' part names nothing this artifact carries anywhere else: a sentence asserting a state, however it is punctuated, is not a coverage part. Name what was checked — the file, the id, the measurement, the page"
    fi

    # The refusal names the PART, not the pattern. It used to print the label
    # regex, which told an operator which line of the gate fired and not which
    # part of their artifact was hollow.
    if printf '%s\n' "$cov" | grep -qiE "$R_LABEL" && ! part_names_things "$R_LABEL"; then
      refuse "$f" "-" "empty-coverage-part" \
        "the 'reached' coverage part names nothing this artifact carries anywhere else: a coverage part names what was reached, it does not assert that everything was"
    fi
    if printf '%s\n' "$cov" | grep -qiE "$N_LABEL" && ! part_names_things "$N_LABEL"; then
      refuse "$f" "-" "empty-coverage-part" \
        "the 'not reached' coverage part names nothing this artifact carries anywhere else: a coverage part names what was not reached, it does not assert that nothing was missed"
    fi
  fi

  # --- the open section ----------------------------------------------------
  # Anchored to a heading, not a mention. A first version matched the phrase
  # anywhere, so an artifact whose status line said "see What could not be
  # established" passed the presence check after its actual heading had been
  # renamed — and then refused as a silently empty section. Wrong refusal for
  # the wrong reason. The presence check and the range below now use the same
  # anchored pattern.
  if ! printf '%s\n' "$VIEW" | grep -qiE '^#+.*could not .*establish'; then
    refuse "$f" "-" "no-open-section" \
      "no 'what could not be established' section: this is the section a reader checks to find out whether the question was actually answered, and omitting it claims completeness"
  else
    # Same reasoning as Define's empty-outlier check: an omitted list and an
    # empty one look identical, so an empty one must say so — and SAYING SO IS A
    # DECLARATION, not a sentence that happens to carry the right word. See
    # declares_empty above.
    #
    # No `\?` in this address. It is a GNU extension to BRE: BSD sed does not
    # support it, so the range matched nothing on macOS and the check refused
    # every artifact, while passing on the Linux CI leg. Same class of bug as
    # `\b` in git grep, found the same way — by running it on both.
    #
    # THE SECTION ENDS AT THE NEXT HEADING OR THE NEXT `---`, which is how
    # Define already scopes its outlier section. Stopping only at the next `## `
    # left the section's own trailing separator inside the body, and `---` begins
    # with a list marker, so an open section emptied of every one of its items
    # still counted one and the emptiness check never ran at all. That path
    # needed no word: it was the third way in, found while repairing the first
    # two. An earlier version of this range ran to end of file, which counted
    # list items in later sections.
    opensec="$(awk '/^#+.*could not .*establish/ { inside = 1; next }
                    inside && (substr($0, 1, 3) == "## " || $0 ~ /^---[[:space:]]*$/) { exit }
                    inside { print }' <<EOF
$VIEW
EOF
)"
    # The same range over the SPAN projection, which is what a DECLARATION is read
    # from. One range expression, two projections, so the body the item count walks
    # and the body the declaration is looked for in cannot be different sections.
    opensec_spans="$(awk '/^#+.*could not .*establish/ { inside = 1; next }
                    inside && (substr($0, 1, 3) == "## " || $0 ~ /^---[[:space:]]*$/) { exit }
                    inside { print }' <<EOF
$SPANVIEW
EOF
)"
    # AN OPEN ITEM IS A LIST ITEM CARRYING ITS `[O]` GRADE. A list item is a line
    # beginning, FLUSH LEFT, with a list marker — `-`, `*`, `+`, `1.` or `1)` —
    # followed by a space. Nothing about emphasis: a bullet is what makes the line a
    # list item, and "an item is a list item" is the whole of the rule.
    #
    # The rule is stated once, in discovery-contract.md under "What could not be
    # established", and define-contract.md cites that statement for its Outliers
    # section rather than restating it. This expression and the one in
    # validate-define.sh are that rule in two places. They are not shared as a
    # library for the reason #104 records — a shared helper would be a load-bearing
    # script outside the enumeration in CONTROLS.md, which is #95's decision — so
    # what stops them drifting is tests/test_item_rule.sh, which drives one
    # candidate line through both gates and asserts the verdicts are equal.
    #
    # THREE VERSIONS OF THIS WERE WRONG, each more narrowly than the last.
    #
    #   1. `^[-*0-9]` OR an `[O]` anywhere in the body, as an alternation, so one
    #      line of prose carrying a grade marker was an item.
    #   2. Leading whitespace tolerated, so an indented line counted — and four
    #      spaces is a code block in Markdown, so a reader saw no item where the
    #      gate counted one.
    #   3. A bullet, a number OR ANY LINE BEGINNING `**`, with the `[O]` anywhere
    #      after it. That accepted a bold-led SENTENCE as an item, including
    #      `**Nothing remains open.** … the grade [O] is not used in this
    #      artifact.` — a line that denies the grade satisfying a check for an item
    #      carrying it. Reproduced on the shipped topic with all seven items
    #      deleted: gate exit 0, suite green.
    #
    # WHY THE BOLD-LABEL FORM IS GONE RATHER THAN REPAIRED. The distinction the
    # contract was reaching for — a label used as a label, versus a sentence that
    # mentions the grade — can be drawn here, by requiring the `[O]` inside the
    # label's own bold span. It cannot be drawn in the Define twin at all, because
    # an outlier carries no grade and there is nothing there to anchor it to. A form
    # only one of the two gates can police is how the two came to disagree, so the
    # form both can police is the one that survives.
    #
    # WHY NOT NARROWER. `^- \*\*` was the obvious answer: it is what the Define gate
    # already counted, what all three shipped artifacts write, and it loosens
    # nothing. It was rejected because no sentence can say WHY bold — it would be
    # this repository's own named failure of encoding today's markup as a rule, and
    # a coverage fixture in tests/test_validate_discovery.sh had already written a
    # plain bullet as an item without anyone thinking twice. A bullet has a reason
    # behind it; two asterisks do not.
    seen=$(printf '%s\n' "$opensec" \
      | grep -cE '^([-*+]|[0-9]+[.)])[[:space:]].*\[O\]')
    if [ "$seen" -eq 0 ] && ! declares_empty "$opensec_spans"; then
      refuse "$f" "-" "silent-empty-open" \
        "the open section lists no [O] item and does not declare itself empty. An item is a LIST ITEM carrying its own grade: a line starting flush left with \`-\`, \`*\`, \`+\`, \`1.\` or \`1)\` and a space, with its [O] on that line. A bold label is not a list marker, and a line of prose carrying an [O] somewhere in it is not an item — this is the same rule validate-define.sh counts in Outliers, stated in discovery-contract.md. An artifact with nothing open is making a strong claim, and it makes it as a declaration in the section — <!-- declared-empty: reason --> — not as a sentence. Two earlier versions of this check were weaker: a search of the section's prose for a short word, and then a count that accepted any bold-led line carrying an [O] anywhere, so a sentence denying the grade satisfied a check for an item carrying it"
    fi
  fi

  # --- where this stops ----------------------------------------------------
  has "$f" 'where this stops' || refuse "$f" "-" "no-where-this-stops" \
    "no 'where this stops' section: what a later phase will need and this one could not supply gets recorded, or it is rediscovered"

  # --- grades --------------------------------------------------------------
  # Not "every claim has a grade" — see the header. This checks that the grades
  # used are the declared ones, which catches a typo and an invented grade.
  grades=$(printf '%s\n' "$VIEW" | grep -oE '\[[A-Z]{1,2}\]' | sort -u | tr -d '[]' | tr '\n' ' ')
  bad=""
  for g in $grades; do
    case "$g" in E|S|V|P|O) ;; *) bad="$bad $g" ;; esac
  done
  [ -z "$bad" ] || refuse "$f" "-" "grade-not-in-enum" \
    "grade(s) not in the STANDARDS.md scheme:$bad — the enum is E, S, V, P, O"

  if [ -z "$grades" ]; then
    refuse "$f" "-" "no-grades" \
      "no graded claims at all: a discovery artifact whose claims carry no grade is indistinguishable from an opinion piece"
  fi

  # A DECLARATION, not a sentence that happens to pair "vendor" with a [V].
  #
  # This matched `\[V\].*vendor|vendor.*\[V\]|never outcome evidence` as an OR,
  # so any prose line doing that satisfied it — and the newer topic has several.
  # Removing the actual grade key left the check passing, which a test written
  # for it immediately found. It also meant the newer topic never had a grade
  # key at all and the gate never said so.
  #
  # A real key names most of the scheme on one line. Three of five is the bar.
  if ! awk '
      { n = 0
        if ($0 ~ /\[E\]/) n++
        if ($0 ~ /\[S\]/) n++
        if ($0 ~ /\[V\]/) n++
        if ($0 ~ /\[P\]/) n++
        if ($0 ~ /\[O\]/) n++
        if (n >= 3) found = 1 }
      END { exit found ? 0 : 1 }' <<EOF
$VIEW
EOF
  then
    refuse "$f" "-" "no-grade-key" \
      "the grade scheme is not declared on any one line: a reader meeting [V] for the first time has no way to know it is never outcome evidence"
  fi

  # --- local links resolve -------------------------------------------------
  # Not "every claim has a source" — see the header. This checks the links the
  # artifact does carry actually go somewhere.
  #
  # The unresolved links are held in a VARIABLE. They used to be collected in
  # `/tmp/_vd_bad.$$` — the only temp path in this repository not from `mktemp` —
  # and the refusal then asked `[ -s ]` about that file, which made the gate's
  # answer depend on something outside the artifact. Both directions were
  # reproduced:
  #
  #   an unwritable file already at the path   the redirect fails, the `while`
  #                                            body never runs, `[ -s ]` is false,
  #                                            and a broken link PASSED. Exit 0.
  #   a directory already at the path          `[ -s ]` is true of a directory, so
  #                                            the gate REFUSED artifacts with no
  #                                            broken link, with an empty refusal
  #                                            list, and `rm -f` could not clear
  #                                            it so every later run refused too.
  #
  # The repair is to remove the failure mode rather than to handle it: with no file
  # there is no write to fail, no path to collide on, and nothing to clean up. A
  # `mktemp` with a checked write would also have closed the fail-open, and would
  # still have been scratch state the verdict depends on.
  # `bad_links` and not `bad`: `bad` already carries the out-of-enum grades in this
  # same function, and one name for two meanings is how the next reader gets it
  # wrong.
  bad_links="$(
    printf '%s\n' "$VIEW" | grep -oE '\]\(([^)h][^)]*)\)' 2>/dev/null | sed 's/](\(.*\))/\1/' | sed 's/#.*//' | sort -u \
    | while IFS= read -r p; do
        [ -n "$p" ] || continue
        ( cd "$(dirname "$f")" && [ -e "$p" ] ) || printf '%s\n' "$p"
      done
  )"
  if [ -n "$bad_links" ]; then
    refuse "$f" "-" "link-unresolved" \
      "local link(s) do not resolve: $(printf '%s\n' "$bad_links" | tr '\n' ' ')"
  fi
}

main() {
  local files=0 f
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do
      [ -f "$f" ] || { printf 'validate-discovery: no such file: %s\n' "$f" >&2; exit 2; }
      files=$((files + 1)); check_topic "$f"
    done
  else
    [ -d "$TOPICS" ] || { printf 'validate-discovery: no topics directory: %s\n' "$TOPICS" >&2; exit 2; }
    for f in "$TOPICS"/*.md; do
      [ -f "$f" ] || continue
      files=$((files + 1)); check_topic "$f"
    done
  fi

  if [ "$refusals" -gt 0 ]; then
    printf 'validate-discovery: %s refusal(s) across %s file(s)\n' "$refusals" "$files" >&2
    exit 1
  fi
  # A run that read no artifact does not get to report conformance. This printed
  # "0 file(s) within the contract" over an empty topics directory — every artifact
  # it never read, declared within the contract — and CI runs this gate with no
  # arguments, so emptying or moving the directory left a clean log.
  #
  # Still exit 0: a phase with no artifact is a real state, and the scan gate
  # already settled that by calling it a first run. What changes is the claim.
  if [ "$files" -eq 0 ]; then
    printf 'validate-discovery: no topic files in %s, so nothing was checked\n' "$TOPICS"
    return 0
  fi
  printf 'validate-discovery: %s file(s) within the contract\n' "$files"
}

main "$@"
