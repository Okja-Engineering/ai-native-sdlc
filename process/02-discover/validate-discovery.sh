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

refusals=0

refuse() { printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2; refusals=$((refusals + 1)); }
field()  { sed -n "s/^$2:[[:space:]]*//p" "$1" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//'; }

# has <file> <extended-regex> -> 0 if present, case-insensitive
has() { grep -qiE "$2" "$1"; }

check_topic() {
  local f="$1" grades bad seen cov p low R_LABEL N_LABEL V_LABEL PART_MIN_SEPS PART_MIN_CHARS opensec

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
  elif ! grep -qE '^>' "$f"; then
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
  # So each part is now located INSIDE the coverage section and has to carry
  # items, not a phrase. An item is a list marker or a separator — the two real
  # topics use numbered lists, `·` and `;`, and a denial sentence has none.
  #
  # The heading match is also loosened. `^#+ *coverage` required the word
  # immediately after the hashes, so `## Coverage` passed while `## 2 · Coverage`
  # was refused — heading-shape coupling in a gate whose header says it avoids
  # exactly that, and the only reason the hollow artifact was refused at all.
  if ! grep -qiE '^#+[^a-z]*coverage|^\*\*coverage' "$f"; then
    refuse "$f" "-" "no-coverage" "no coverage section"
  else
    cov="$(awk '
      /^#+[^a-zA-Z]*[Cc]overage|^\*\*[Cc]overage/ { inside = 1; next }
      /^## / { if (inside) exit }
      inside { print }' "$f")"

    # part_items <label-regex> — items under one coverage part.
    #
    # A part's body runs from its label to the next part label, which the two
    # topics write differently: `### Verified by hand` in one, a bold inline
    # `**Verified by hand before recording:**` in the other. Both are matched.
    #
    # An item is a list marker, a `;` or a `·`. Those are what both real topics
    # use, and crucially a denial sentence has none of them — which is what the
    # audit's hollow artifact relied on.
    # Input is lowercased before matching rather than using awk's IGNORECASE,
    # which is a GNU extension. BSD awk ignores it silently, so on macOS the
    # label `### Verified by hand` never matched a lowercase pattern and every
    # part counted zero items — refusing both real topics. Third GNU-ism of this
    # kind in the repository, after `\?` in sed and `\b` in git grep, and found
    # the same way: by running it.
    # part_body <label-regex> — the lines belonging to one coverage part.
    part_body() {
      printf '%s\n' "$cov" | tr 'A-Z' 'a-z' | awk -v re="$1" '
        BEGIN { on = 0 }
        {
          is_label = ($0 ~ /^#+ /) || ($0 ~ /^[*][*][a-z]/)
          if (on && is_label && $0 !~ re) exit
          if ($0 ~ re) { on = 1 }
          if (on) print
        }'
    }

    # A part has to NAME things, which two measures separate from a sentence
    # asserting a state. Both thresholds were set from the real artifacts rather
    # than guessed: their parts run 304–2226 characters with 5–32 separators,
    # while a fabricated part tops out around 43 characters and 2. The bar sits
    # well below the real floor and well above the fabricated ceiling.
    PART_MIN_SEPS=2
    PART_MIN_CHARS=60

    part_ok() { # label-regex -> 0 if the part names things
      local b s c
      b="$(part_body "$1")"
      s="$(printf '%s' "$b" | grep -oE '[;·,]|^[[:space:]]*([0-9]+\.|[-*])[[:space:]]' | grep -c .)"
      c="$(printf '%s' "$b" | wc -c | tr -d ' ')"
      [ "$s" -ge "$PART_MIN_SEPS" ] && [ "$c" -ge "$PART_MIN_CHARS" ]
    }

    # Patterns are anchored to a LABEL — `### reached` or `**reached:**` — not to
    # the word anywhere. Unanchored, `reached` also matched `not reached`, so the
    # reached part's scope ran on through its neighbour and counted its items. An
    # artifact with an empty reached part and a full not-reached part would have
    # passed.
    # `[*][*]` rather than `\*\*`: passed through awk's -v the backslashes are
    # consumed, leaving `**`, which is an invalid ERE — awk printed "illegal
    # primary" and every count came back empty. A character class survives both
    # awk and grep unchanged.
    R_LABEL='^(#+ |[*][*])reached'
    N_LABEL='^(#+ |[*][*])not reached'
    V_LABEL='^(#+ |[*][*])verified by hand'
    low="$(printf '%s\n' "$cov" | tr 'A-Z' 'a-z')"

    printf '%s\n' "$low" | grep -qE "$R_LABEL" || refuse "$f" "-" "no-reached" \
      "coverage has no 'reached' part"
    printf '%s\n' "$low" | grep -qE "$N_LABEL" || refuse "$f" "-" "no-not-reached" \
      "coverage does not say what was NOT reached: an artifact claiming only successes is claiming completeness it has not earned"

    if ! printf '%s\n' "$low" | grep -qE "$V_LABEL"; then
      refuse "$f" "-" "no-verified-by-hand" \
        "coverage has no 'verified by hand' part: without it there is nothing separating an agent reported this from someone checked it, and a discovery artifact becomes a pile of agent output"
    elif ! part_ok "$V_LABEL"; then
      refuse "$f" "-" "empty-verified-by-hand" \
        "the 'verified by hand' part names nothing: a sentence saying nothing was checked is not a coverage part, it is the artifact saying it is pure relay. List what was checked"
    fi

    for p in "$R_LABEL" "$N_LABEL"; do
      if printf '%s\n' "$low" | grep -qE "$p" && ! part_ok "$p"; then
        refuse "$f" "-" "empty-coverage-part" \
          "a coverage part matching /$p/ names nothing: a coverage part lists what was or was not reached, not a sentence asserting it"
      fi
    done
  fi

  # --- the open section ----------------------------------------------------
  # Anchored to a heading, not a mention. A first version matched the phrase
  # anywhere, so an artifact whose status line said "see What could not be
  # established" passed the presence check after its actual heading had been
  # renamed — and then refused as a silently empty section. Wrong refusal for
  # the wrong reason. The presence check and the range below now use the same
  # anchored pattern.
  if ! grep -qiE '^#+.*could not .*establish' "$f"; then
    refuse "$f" "-" "no-open-section" \
      "no 'what could not be established' section: this is the section a reader checks to find out whether the question was actually answered, and omitting it claims completeness"
  else
    # Same reasoning as Define's empty-outlier check: an omitted list and an
    # empty one look identical, so an empty one must say so.
    #
    # No `\?` in this address. It is a GNU extension to BRE: BSD sed does not
    # support it, so the range matched nothing on macOS and the check refused
    # every artifact, while passing on the Linux CI leg. Same class of bug as
    # `\b` in git grep, found the same way — by running it on both.
    # Scoped to the SECTION, not to the end of the file. The range ran to EOF,
    # so list items in later sections counted as open items and emptying the
    # open section entirely still passed. Same scope error the audit found in
    # the coverage checks, in a different place.
    opensec="$(awk '/^#+.*could not .*establish/ { inside = 1; next }
                    /^## / { if (inside) exit }
                    inside { print }' "$f")"
    seen=$(printf '%s\n' "$opensec" | grep -cE '^[-*0-9]|\[O\]')
    if [ "$seen" -eq 0 ] && ! printf '%s\n' "$opensec" | grep -qiE 'none|nothing|everything was'; then
      refuse "$f" "-" "silent-empty-open" \
        "the open section lists nothing and does not say so: an artifact with nothing open is making a strong claim and has to make it explicitly"
    fi
  fi

  # --- where this stops ----------------------------------------------------
  has "$f" 'where this stops' || refuse "$f" "-" "no-where-this-stops" \
    "no 'where this stops' section: what a later phase will need and this one could not supply gets recorded, or it is rediscovered"

  # --- grades --------------------------------------------------------------
  # Not "every claim has a grade" — see the header. This checks that the grades
  # used are the declared ones, which catches a typo and an invented grade.
  grades=$(grep -oE '\[[A-Z]{1,2}\]' "$f" | sort -u | tr -d '[]' | tr '\n' ' ')
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
      END { exit found ? 0 : 1 }' "$f"; then
    refuse "$f" "-" "no-grade-key" \
      "the grade scheme is not declared on any one line: a reader meeting [V] for the first time has no way to know it is never outcome evidence"
  fi

  # --- local links resolve -------------------------------------------------
  # Not "every claim has a source" — see the header. This checks the links the
  # artifact does carry actually go somewhere.
  grep -oE '\]\(([^)h][^)]*)\)' "$f" 2>/dev/null | sed 's/](\(.*\))/\1/' | sed 's/#.*//' | sort -u \
  | while IFS= read -r p; do
      [ -n "$p" ] || continue
      ( cd "$(dirname "$f")" && [ -e "$p" ] ) || printf '%s\n' "$p"
    done > /tmp/_vd_bad.$$ 2>/dev/null
  if [ -s /tmp/_vd_bad.$$ ]; then
    refuse "$f" "-" "link-unresolved" \
      "local link(s) do not resolve: $(tr '\n' ' ' < /tmp/_vd_bad.$$)"
  fi
  rm -f /tmp/_vd_bad.$$
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
  printf 'validate-discovery: %s file(s) within the contract\n' "$files"
}

main "$@"
