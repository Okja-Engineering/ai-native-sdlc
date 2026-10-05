#!/usr/bin/env bash
# The one Deliver gate judged worth having on n=1.
#
# usage: process/05-deliver/validate-decision.sh [file ...]
#        process/05-deliver/validate-decision.sh          # every decision record
#
# deliver-contract.md defers most of Deliver's shape to a second decision, and
# names exactly one check that does not depend on shape:
#
#   a record whose `chosen:` is anything but `pending` must carry a
#   `decided_by:` naming a person.
#
# It guards the only thing in this repository that cannot be reconstructed
# afterwards — whether a human actually chose. A machine filling both fields is
# the loop quietly closing itself, which is the failure the whole process
# exists to prevent.
#
# Two companion checks are included because they are equally shape-independent:
# a chosen option must exist in the option set it claims to choose from, and a
# decided record must be dated.
#
# exit 0  every record checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DECISIONS="${DECISIONS_DIR:-$SCRIPT_DIR/decisions}"

refusals=0

refuse() { # file line code message
  printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2
  refusals=$((refusals + 1))
}

field() { # file key -> value, first match, trimmed
  sed -n "s/^$2:[[:space:]]*//p" "$1" 2>/dev/null | head -1 | sed 's/[[:space:]]*$//'
}

line_of() { grep -n "^$2:" "$1" 2>/dev/null | head -1 | cut -d: -f1; }

# A name is a person — and the only way to check that mechanically is to
# enumerate the people. DECIDERS.md is that list.
#
# This replaced a DENYLIST: an anchored exact match against twenty words like
# `team`, `reviewer`, `claude`, `bot`. An external audit walked through it:
#
#   decided_by: the Platform Engineering Team  ->  within the contract
#   decided_by: Claude Opus 5                  ->  within the contract
#
# Any multi-word role and any model with a version number passed. Widening the
# list would not have fixed it — the set of things that are not a person is
# unbounded, so a denylist fails OPEN and every miss is silent.
#
# The tests that were supposed to catch this asserted the three literal strings
# the regex was written for. They proved the list contained three words; they
# never pinned the invariant. That is the finding this change exists for, and it
# is why the new tests use inputs chosen to sit outside the implementation.
#
# The denylist is kept only to give a clearer message for the obvious cases. It
# is advisory: the allowlist is what decides.
DECIDERS="${DECIDERS_FILE:-$ROOT/DECIDERS.md}"
OBVIOUSLY_NOT_A_PERSON='(^|[^a-z])(team|group|everyone|owner|reviewer|maintainer|claude|gpt|codex|copilot|agent|bot|assistant|automation|llm|model)([^a-z]|$)'

# deciders_scan -> a tab-separated description of DECIDERS.md, one fact per line:
#
#   MARK <line> <note>   a table the file DESIGNATES as the authorizing list
#   SKIP <line> <label>  a table declaring a Name column that is NOT designated
#   AUTH <name>          a Name cell in a data row of the designated table
#
# WHICH TABLE IS THE LIST, AND WHY THAT IS A DECLARATION
#
# The allowlist used to be the `Name` column of EVERY table in the file, data rows
# only. That was keyed on the column's heading text, so a second table declaring a
# Name column authorized everybody in it:
#
#   ## People who have asked to be added
#   | Name | Since |
#   |---|---|
#   | Hacker McBot | 2026-01-01 |   ->  decided_by: Hacker McBot was accepted
#
# Three documents said that could not happen — DECIDERS.md's own rule, CONTROLS.md's
# evidence note, and the comment above this function, which named a second table as
# the defect it had fixed. All three were wrong, for a cycle, because no test
# exercised a second table.
#
# So the file now says which table is the list, in band, immediately above it:
#
#   <!-- deciders-table: reason -->
#
# Checked for the same two things as `declared-empty`, `not-a-claim` and
# `dead-pointer`: the declaration is present and it carries a reason. The
# alternatives were both weaker. Keying on the column heading is what just failed.
# Keying on a heading above the table failed before that. Keying on position — "the
# first table" — cannot say which table the author meant, so inserting one above the
# list silently moves the allowlist.
#
# Three things fail CLOSED, because an allowlist whose designation can be left out
# or made ambiguous is a control an author switches off by omission:
#
#   * no designated table              -> nobody is authorized
#   * more than one designated table   -> nobody is authorized
#   * a designated table with no Name  -> nobody is authorized
#
# A FENCED BLOCK is not content, because an example row in one would otherwise
# authorize everyone it named. Neither is an HTML COMMENT BLOCK: a commented-out
# copy of the list renders as nothing, and without this the designation would bind
# to the invisible table and leave the real one undesignated. The marker itself is a
# complete comment on one line, so it is read before the block rule.
#
# Blank lines between the declaration and the table do not break the pair, because
# that is how the two read in Markdown. Anything else between them does.
deciders_scan() {
  awk -F'|' -v TAB="$(printf '\t')" '
    function clean(s) {
      gsub(/[*_`]/, "", s); sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s
    }
    function endtable() { head = 0; sep = 0; col = 0; donate = 0 }

    incomment { if ($0 ~ /-->/) incomment = 0; next }

    # A fence BREAKS the designation, unlike a blank line and unlike a comment
    # block. Found by attacking this check after it was written: put the real list
    # inside a fenced example and a second table below it, and the designation
    # skipped the fence and landed on the second table. A fence is content the
    # author wrote between the two, so it separates them.
    /^```/ { fence = !fence; endtable(); marked = 0; next }
    fence  { next }

    # The designation. A reason is required, so `<!-- deciders-table: -->` declares
    # nothing — the same shape the other in-band declarations in this repository use.
    /<!--[ \t]*deciders-table:[^>]*[A-Za-z][^>]*-->/ {
      endtable(); marked = 1; next
    }

    # An HTML comment block is not content, so it does not break the designation
    # either — it is invisible, not interposed.
    /<!--/ && !/-->/ { incomment = 1; endtable(); next }

    /^#+[ \t]/ {
      label = $0; sub(/^#+[ \t]+/, "", label); endtable(); marked = 0; next
    }

    /^[|]/ {
      if (!head) {                 # the first row of a table is its heading row
        head = 1; sep = 0; col = 0; donate = 0
        for (i = 2; i < NF; i++) if (tolower(clean($i)) == "name") col = i
        if (marked) {
          printf "MARK%s%d%s%s\n", TAB, NR, TAB, \
            (col ? "with a Name column" : "declaring no Name column")
          donate = col ? 1 : 0
        } else if (col) {
          printf "SKIP%s%d%s%s\n", TAB, NR, TAB, \
            (label == "" ? "no heading above it" : label)
        }
        marked = 0
        next
      }
      if (!sep) {                  # the second has to be the separator
        if ($0 ~ /^[|][-: |]+[|][ \t]*$/) sep = 1; else { head = 0; col = 0; donate = 0 }
        next
      }
      if (donate && col) { v = clean($col); if (v != "") printf "AUTH%s%s\n", TAB, v }
      next
    }

    # A non-table line ends the table. A BLANK one does not end the designation,
    # because a declaration and the table it designates are separate Markdown
    # blocks; anything else between them does.
    {
      endtable()
      if ($0 !~ /^[ \t]*$/) marked = 0
    }
  ' "$DECIDERS" 2>/dev/null
}

# deciders_listed -> one authorized name per line
#
# Exactly one designated table, or nobody. Two tables each claiming to be the list
# cannot both be it, and an allowlist has no safe way to guess which — so it reads
# as no list at all, the same as a file that designates none and the same as a
# missing file.
deciders_listed() {
  local tab scan
  tab="$(printf '\t')"
  scan="$(deciders_scan)"
  [ "$(printf '%s\n' "$scan" | awk -F"$tab" '$1 == "MARK"' | grep -c .)" -eq 1 ] || return 0
  printf '%s\n' "$scan" | awk -F"$tab" '$1 == "AUTH" { print $2 }'
}

# authorized <name> -> 0 if the name is a listed decider
authorized() {
  [ -f "$DECIDERS" ] || return 1
  deciders_listed | grep -qxF -- "$1"
}

# deciders_note -> what the gate ignored in DECIDERS.md, as a suffix for a refusal
#
# A refusal that says only "not listed" sends an author who added a second table and
# a name to it looking in the right file for the wrong thing. The expensive case is
# the silent one: a name sitting in a table that looks like the list and is not.
deciders_note() {
  local scan marks tab
  tab="$(printf '\t')"
  [ -f "$DECIDERS" ] || { printf '%s' ". There is no decider list at $DECIDERS"; return 0; }
  scan="$(deciders_scan)"
  marks="$(printf '%s\n' "$scan" | awk -F"$tab" '$1 == "MARK"' | grep -c .)"

  if [ "$marks" -eq 0 ]; then
    printf '%s' ". $(basename "$DECIDERS") designates no authorizing table, so it authorizes nobody: the list is the table carrying <!-- deciders-table: reason --> immediately above it"
    return 0
  fi
  if [ "$marks" -gt 1 ]; then
    printf '%s' ". $(basename "$DECIDERS") designates $marks tables as the authorizing list, which is ambiguous, so none of them authorizes anybody"
    return 0
  fi

  printf '%s\n' "$scan" | awk -F"$tab" -v f="$(basename "$DECIDERS")" '
    $1 == "SKIP" { n++; where = where (n > 1 ? ", " : "") "line " $2 " (" $3 ")" }
    END { if (n) printf ". %s declares a Name column in %d table(s) it does not designate as the list — %s — and an undesignated table donates nobody", f, n, where }'
}

# option_ids <option set> -> one declared option id per line
#
# An option set declares its options as `## <id> · <name>`, so the ids are read out
# of it and `chosen:` is compared against them AS A LITERAL.
#
# It used to be `grep -qE "^## $chosen · "` — the field interpolated into an
# expression. `chosen: .` and `chosen: [A-Z]` each matched every option, so CTRL-2
# said a chosen option existed before it was chosen and one metacharacter defeated
# it. Same shape as the `decided_by` denylist: the check was a pattern where the rule
# is membership of an enumerated set, and `authorized()` above already compares names
# with `grep -qxF` for exactly this reason.
#
# LC_ALL=C so `index` and `substr` agree about bytes. The separator is a multibyte
# `·`, and in a UTF-8 locale BSD awk counts characters in substr and bytes in index,
# which would cut the id short.
#
# The heading is recognised with a STRING COMPARISON rather than an anchored regex,
# the way validate-define.sh scopes its outlier section — an anchored regex has an
# anchor a sweep can drop, and a comparison does not.
#
# NO TEST DISTINGUISHES THAT GUARD, and it is worth saying which claim it does and
# does not support. Removing it entirely leaves every suite green, because a prose
# line mentioning a heading cannot yield a WELL-FORMED id: the offsets no longer line
# up and what comes out is `# A` or `## A`, which collides with nothing a record would
# declare. So the guard makes the harvest well defined; it is not what makes the gate
# correct. The invariant — a mention of an option is not a declaration of one — is
# pinned by the mid-line case in tests/test_validate_decision.sh, which passes for
# that reason rather than because of this line. A fixture built to make this line
# observable would have to collide a byte offset with a `chosen:` value, which pins
# the arithmetic and not the rule.
option_ids() { # <path>
  LC_ALL=C awk '
    substr($0, 1, 3) != "## " { next }
    { i = index($0, " · "); if (i > 3) print substr($0, 4, i - 4) }
  ' "$1" 2>/dev/null
}

check_record() {
  local f="$1" chosen decided dated opts ln
  chosen="$(field "$f" chosen)"
  decided="$(field "$f" decided_by)"
  dated="$(field "$f" dated)"
  opts="$(field "$f" options)"

  if ! grep -q '^chosen:' "$f"; then
    refuse "$f" "-" "no-chosen-field" "a decision record declares chosen:, even when it is pending"
    return
  fi

  # pending is a valid, expected state: the work is done and the gate is not passed.
  if [ -z "$chosen" ] || [ "$chosen" = "pending" ] || [ "$chosen" = "none" ]; then
    if [ -n "$decided" ]; then
      ln="$(line_of "$f" decided_by)"
      refuse "$f" "${ln:--}" "pending-but-decided" \
        "chosen is '$chosen' but decided_by names \"$decided\": a record cannot be both awaiting a human and decided"
    fi
    return
  fi

  # --- the gate the contract named ---------------------------------------
  ln="$(line_of "$f" decided_by)"
  if [ -z "$decided" ]; then
    refuse "$f" "${ln:--}" "undecided-by" \
      "chosen is '$chosen' but decided_by is empty: a decision is made by a human and the record names which one"
  elif ! authorized "$decided"; then
    # Two messages for one refusal code, because the fix differs. A role or a
    # model name is wrong and needs replacing; a real person's name just is not
    # on the list yet, and adding them is a reviewable change to DECIDERS.md.
    #
    # Both carry the same suffix: what the gate read the list from, and what in that
    # file it ignored. "Not listed" alone is true and unhelpful when the name IS in
    # the file, in a table that is not the list.
    local note; note="$(deciders_note)"
    if printf '%s' "$decided" | tr 'A-Z' 'a-z' | grep -Eq "$OBVIOUSLY_NOT_A_PERSON"; then
      refuse "$f" "${ln:--}" "not-a-person" \
        "decided_by is \"$decided\", which is a role or a machine, not a named person. A decision is made by someone listed in DECIDERS.md$note"
    else
      refuse "$f" "${ln:--}" "not-a-person" \
        "decided_by is \"$decided\", who is not listed in DECIDERS.md: if that is a real person authorized to decide, add them there — the list is the control, and adding to it is meant to be an explicit change$note"
    fi
  fi

  ln="$(line_of "$f" dated)"
  [ -n "$dated" ] || refuse "$f" "${ln:--}" "undated-decision" \
    "chosen is '$chosen' but dated is empty: when a person decided is part of the record"

  # --- the stated problem must be linked ---------------------------------
  # deliver-contract.md requires `problem:` and nothing read it. Deleting the
  # line from a decision record left the gate reporting the file within the
  # contract — the decision-to-problem edge of the chain had no check at all,
  # and CONTROLS.md did not disclose that. Found by the external audit in #22.
  local prob prob_path prob_resolved
  prob="$(field "$f" problem)"
  if [ -z "$prob" ]; then
    refuse "$f" "-" "no-problem-link" \
      "no problem: field — a decision records the problem it decided, or it is an answer with no question"
  else
    prob_path="$(printf '%s' "$prob" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
    if [ -z "$prob_path" ]; then
      refuse "$f" "-" "problem-not-linked" \
        "problem: names something but does not link it, so the problem cannot be read from the decision"
    else
      prob_resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$prob_path")" 2>/dev/null && pwd)/$(basename "$prob_path")"
      [ -f "$prob_resolved" ] || refuse "$f" "-" "problem-unresolved" \
        "the declared problem does not resolve: $prob_path"
    fi
  fi

  # --- the chosen option must exist --------------------------------------
  #
  # These used to `return` on their own refusals, which made check_amends
  # unreachable for any record with no resolvable options link — a record could
  # be missing both and only hear about one. The amends check is independent of
  # the options check, so it runs either way now.
  local opts_ok=1 opts_path=""
  case "$opts" in
    *"]("*) opts_path="$(printf '%s' "$opts" | sed -n 's/.*](\([^)]*\)).*/\1/p')" ;;
    "") : ;;
    *) opts_path="$opts" ;;
  esac
  if [ -z "$opts_path" ]; then
    refuse "$f" "-" "no-options-link" "chosen is '$chosen' but no options set is declared to have chosen from"
    opts_ok=0
  fi
  if [ "$opts_ok" -eq 1 ]; then
    local resolved ids; resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$opts_path")" 2>/dev/null && pwd)/$(basename "$opts_path")"
    if [ ! -f "$resolved" ]; then
      refuse "$f" "-" "options-unresolved" "the declared option set does not resolve: $opts_path"
    else
      ids="$(option_ids "$resolved")"
      if ! printf '%s\n' "$ids" | grep -qxF -- "$chosen"; then
        refuse "$f" "-" "chosen-not-an-option" \
          "chosen is '$chosen', which is not an option in $(basename "$resolved"). That set declares: ${ids:+$(printf '%s' "$ids" | tr '\n' ',' | sed -e 's/,$//' -e 's/,/, /g')}${ids:-nothing — no '## <id> · <name>' heading in it}. If the right answer was not developed, go back to Develop"
      fi
    fi
  fi

  check_amends "$f"
}

# A decision that changes how we work has to land somewhere. This repository's
# stated output is a change to our standards, and for five phases nothing
# carried a decision to the document — the link lived in the head of whoever
# had just made the call.
#
# `amends:` is that link, checked in BOTH directions. A one-way pointer is the
# same duplicated-declaration failure this repository keeps finding: the
# standard would say one thing, the decision another, and nothing would notice.
#
# `amends: none` is valid and expected. A decision to measure rather than act
# changes nothing about how we work, and saying so is what makes the absence
# visible instead of indistinguishable from an omission.

# claim_lines <document> <anchor> -> the lines of the claim that anchor names
#
# A heading's anchor is its text, lowercased, with everything but letters, digits,
# spaces, hyphens and underscores removed, and spaces turned into hyphens. That is
# computed here from the headings the document actually has, rather than guessed
# at, so an anchor is matched against a real claim or against nothing.
#
# A claim runs to the next heading at the same depth or shallower, so it INCLUDES
# its subsections. A back-link under a deeper heading inside the claim has not
# left it, and refusing that would push an author into flattening a document to
# satisfy a gate.
#
# A FENCED BLOCK is not part of the claim. Found by attacking this check once it
# was written: a document showing what a back-link looks like, inside a fenced
# example, reciprocated the real thing. This repository has already been burnt by
# that class — an example row in a fenced block in `DECIDERS.md` would have
# authorized everyone it named — so the deciders list skips fences for the same
# reason. A heading inside a fence is not a heading either.
#
# exit 3  no heading in the document slugs to that anchor
claim_lines() { # document anchor
  LC_ALL=C awk -v want="$2" '
    function slug(s) {
      s = tolower(s); gsub(/[^a-z0-9 _-]/, "", s); gsub(/ /, "-", s); return s
    }
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /^#+[ \t]/ {
      match($0, /^#+/); lvl = RLENGTH
      h = substr($0, lvl + 1); sub(/^[ \t]+/, "", h); sub(/[ \t]+$/, "", h)
      if (found) { if (inside && lvl <= depth) inside = 0 }
      else if (slug(h) == want) { found = 1; inside = 1; depth = lvl }
      next
    }
    inside { print }
    END { exit (found ? 0 : 3) }
  ' "$1"
}

check_amends() { # file
  local f="$1" amends link target anchor resolved first rest self claim backs
  local back back_target back_resolved matched linked unresolved other
  amends="$(field "$f" amends)"

  if [ -z "$amends" ]; then
    refuse "$f" "-" "no-amends" \
      "a decided record declares amends: — the document it changes, or 'none' with the reason nothing changed. The stated output of this repository is a change to our standards, and an unlinked decision never reaches one"
    return
  fi

  # `none` has to be the WHOLE first word, followed by a reason. The previous
  # version matched the prefix `none*`, so `amends: nonetheless, we decided not
  # to say where this lands` was accepted as a declaration that nothing changed.
  # Found by the external audit in #22.
  first="$(printf '%s' "$amends" | awk '{print tolower($1)}' | tr -d '.,;:')"
  if [ "$first" = none ]; then
    rest="$(printf '%s' "$amends" | sed -e 's/^[Nn]one//' -e 's/^[[:punct:][:space:]]*//')"
    if [ "${#rest}" -lt 10 ]; then
      refuse "$f" "-" "bare-none-amends" \
        "amends: none needs the reason nothing changed, otherwise it cannot be told apart from an oversight"
    fi
    return
  fi

  # The link is parsed once, into the document and the claim within it. It used to
  # be read with `[^)#]*`, which DISCARDED the anchor before anything compared it.
  link="$(printf '%s' "$amends" | sed -n 's/.*](\([^)]*\)).*/\1/p')"
  target="${link%%#*}"
  case "$link" in *#*) anchor="${link#*#}" ;; *) anchor="" ;; esac
  if [ -z "$target" ]; then
    refuse "$f" "-" "amends-not-linked" \
      "amends: names something but does not link it, so nothing can verify the change landed"
    return
  fi

  resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$target")" 2>/dev/null && pwd)/$(basename "$target")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "amends-unresolved" "the amended document does not resolve: $target"
    return
  fi

  # A decision amends a CLAIM, not a file. The anchor is what says which one, and
  # without it the section-level half of this check could be switched off by
  # leaving it out — the denylist shape AGENTS.md rules against, a control an
  # author disables by omission. A document amended as a whole is still named
  # through the heading that carries the claim.
  if [ -z "$anchor" ]; then
    refuse "$f" "-" "amends-no-claim" \
      "amends: links $target and names no claim within it: a decision changes a claim, so the link carries the #anchor of the heading that holds it, and reciprocity is checked inside that claim"
    return
  fi

  claim="$(claim_lines "$resolved" "$anchor")"
  if [ "$?" -eq 3 ]; then
    refuse "$f" "-" "amends-claim-unresolved" \
      "$(basename "$resolved") carries no heading whose anchor is #$anchor: amends: names a claim this document does not have, so there is nothing for the two halves to agree about"
    return
  fi

  # The other direction. Without this the pair is one assertion, not two halves
  # that agree.
  #
  # This was `grep -q "$(basename "$f")"` — a bare filename match anywhere in the
  # file. An external audit replaced the `decided:` link with the sentence "A
  # note: the file agent-pr-approval.md exists somewhere in this repository" and
  # the gate reported the pair reciprocated. A mention is not a link.
  #
  # What is required now is a `decided:` line carrying a markdown link whose
  # target resolves back to THIS record. Same two-way discipline the `from:`
  # check in Define already uses.
  # EVERY `decided:` line, not the first.
  #
  # This was `... | head -1`. A document is amended more than once — STANDARDS.md
  # is the document decisions amend, and it already carried one amendment — so the
  # second correctly-formed amendment was refused, with a message accusing a
  # correct pair of disagreeing, and no further decision could land on that
  # document. One amendment per document was never the rule; it was an artefact of
  # reading one line.
  #
  # The pair is (decision, claim). What has to hold is that SOME back-link names
  # this record; a back-link naming a different one is only a disagreement when no
  # other back-link names this one.
  # And every one of them INSIDE THE CLAIM. The anchor was stripped before the
  # comparison, so a back-link anywhere in the file reciprocated: deleting a
  # claim's `decided:` line and re-inserting the identical line in a different
  # claim, while `amends:` still named the first, passed. The gate established that
  # two documents pointed at each other, not that they pointed at the same claim.
  self="$(cd "$(dirname "$f")" && pwd)/$(basename "$f")"
  backs="$(printf '%s\n' "$claim" | sed -n 's/^decided:[[:space:]]*//p')"
  if [ -z "$backs" ]; then
    if grep -q '^decided:' "$resolved"; then
      refuse "$f" "-" "amends-not-reciprocated" \
        "$(basename "$resolved") carries a 'decided:' line, but not inside the claim amends: names (#$anchor): a back-link in another claim pairs this record with a claim it did not amend"
    else
      refuse "$f" "-" "amends-not-reciprocated" \
        "$(basename "$resolved") carries no 'decided:' line: an amended claim links back to the record that changed it, or the grade on that claim is unsupported"
    fi
    return
  fi

  # Each back-link is classified, and the refusal reported is the closest one to
  # being right: a link that resolves elsewhere is a disagreement, a link that
  # resolves to nothing is a dangling pointer, and no link at all is a mention.
  matched=no; linked=no; unresolved=""; other=""
  while IFS= read -r back; do
    [ -n "$back" ] || continue
    back_target="$(printf '%s' "$back" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
    [ -n "$back_target" ] || continue
    linked=yes
    back_resolved="$(cd "$(dirname "$resolved")" && cd "$(dirname "$back_target")" 2>/dev/null && pwd)/$(basename "$back_target")"
    if [ ! -f "$back_resolved" ]; then
      unresolved="${unresolved:+$unresolved, }$back_target"
    elif [ "$self" = "$back_resolved" ]; then
      matched=yes
      break
    else
      other="${other:+$other, }$(basename "$back_resolved")"
    fi
  done <<EOF
$backs
EOF

  [ "$matched" = no ] || return

  if [ "$linked" = no ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") mentions a decision but does not link it: a filename in prose is not a link, and the pair cannot be verified from a mention"
  elif [ -n "$other" ]; then
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") links back to $other, not to $(basename "$f"): the two halves name different records, which is the disagreement this check exists to catch"
  else
    refuse "$f" "-" "amends-not-reciprocated" \
      "$(basename "$resolved") links a decision that does not resolve: $unresolved"
  fi
}

main() {
  local files=0
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do
      [ -f "$f" ] || { printf 'validate-decision: no such file: %s\n' "$f" >&2; exit 2; }
      files=$((files + 1)); check_record "$f"
    done
  else
    [ -d "$DECISIONS" ] || { printf 'validate-decision: no decisions directory: %s\n' "$DECISIONS" >&2; exit 2; }
    for f in "$DECISIONS"/*.md; do
      [ -f "$f" ] || continue
      files=$((files + 1)); check_record "$f"
    done
  fi

  if [ "$refusals" -gt 0 ]; then
    printf 'validate-decision: %s refusal(s) across %s file(s)\n' "$refusals" "$files" >&2
    exit 1
  fi
  # A run that read no record does not get to report conformance. This printed
  # "0 file(s) within the contract" over an empty decisions directory, and CI runs
  # this gate with no arguments. Still exit 0: an empty phase is a real state, as the
  # scan gate already settled. What changes is the claim.
  if [ "$files" -eq 0 ]; then
    printf 'validate-decision: no decision records in %s, so nothing was checked\n' "$DECISIONS"
    return 0
  fi
  printf 'validate-decision: %s file(s) within the contract\n' "$files"
}

main "$@"
