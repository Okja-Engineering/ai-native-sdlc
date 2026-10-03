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
  local f="$1" grades bad seen

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
  # The third is the one a findings-style coverage line does not have, and the
  # one that separates "an agent reported this" from "someone checked it".
  has "$f" '^#+ *coverage|^\*\*coverage' || refuse "$f" "-" "no-coverage" \
    "no coverage section"
  has "$f" 'reached' || refuse "$f" "-" "no-reached" \
    "coverage does not say what was reached"
  has "$f" 'not reached' || refuse "$f" "-" "no-not-reached" \
    "coverage does not say what was NOT reached: an artifact claiming only successes is claiming completeness it has not earned"
  has "$f" 'verified by hand' || refuse "$f" "-" "no-verified-by-hand" \
    "coverage has no 'verified by hand' part: without it there is nothing separating an agent reported this from someone checked it, and a discovery artifact becomes a pile of agent output"

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
    seen=$(sed -n '/^#.*could not .*establish/,$p' "$f" | grep -cE '^[-*0-9]|\[O\]')
    if [ "$seen" -eq 0 ] && ! sed -n '/^#.*could not .*establish/,$p' "$f" | grep -qiE 'none|nothing|everything was'; then
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

  has "$f" '\[V\].*vendor|vendor.*\[V\]|never outcome evidence' || refuse "$f" "-" "no-grade-key" \
    "the grade scheme is not declared in the document: a reader meeting [V] for the first time has no way to know it is never outcome evidence"

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
