#!/usr/bin/env bash
# The Define checks that do not depend on an artifact's shape.
#
# usage: process/03-define/validate-define.sh [file ...]
#        process/03-define/validate-define.sh          # every cycle and problem
#
# Define produces two artifacts and this read only one of them. A problem was in
# no gate at all, so the Discover-to-Define edge had nothing behind it: the only
# thing that noticed `producing-themes` not naming the topic its whole cost
# argument came from was `bin/cycle.sh` printing "referenced by no problem" in a
# status report nothing fails on. What a problem's check establishes is below,
# at check_problem.
#
# For a CYCLE, define-contract.md names five checks and defers them until a
# second cycle shows which parts are shape and which are this cycle's accidents.
# Four of them do not depend on shape at all and are built here:
#
#   1. every item in the source artifact is accounted for, compared as a SET of
#      declared ids rather than as a total. This caught a real defect by hand
#      before it was mechanised — the first draft of cycle 2026-09-29 themed 54
#      of 64 and reported three wrong counts — and an external audit later broke
#      the arithmetic version two ways. See the accounting block below.
#   2. the count `from:` declares is the number of findings the source records.
#      The set comparison establishes that the ids accounted for are the ids the
#      source carries; it says nothing about what the source was SUPPOSED to
#      carry. A finding could be deleted from the source, dropped from the
#      accounting block and decremented out of one theme count, and both gates
#      passed — while `from: ..., 64 findings` stood above a 63-row table and
#      nothing read it. A number a human types and no gate reads is not an
#      anchor. See the declared count below.
#   3. the outlier section exists, and says so explicitly when empty — an
#      empty list and an omitted list look identical otherwise.
#   4. `method` is declared — a reader must know whether themes came from a
#      person, a model or a classifier before trusting the grouping.
#
# Deferred, because they do depend on shape: "every theme carries a name, a
# count and a why" (theme formatting may differ by cycle) and "no decision
# language" (needs a second cycle to know the vocabulary).
#
# For a PROBLEM, one check, which is the Discover-to-Define edge:
#
#   4. `rests on` is declared, resolves, and resolves to a Discover topic — or
#      says `none` with the reason no discovery was needed.
#
# A problem's `from:` is declared by the contract and is still unread here. Said
# rather than left implicit, and disclosed under CTRL-10, because a required field
# nothing reads is the defect this repository has now found twice.
#
# exit 0  every file checked is within the contract
# exit 1  at least one refusal
# exit 2  the gate could not run
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CYCLES="${DEFINE_CYCLES_DIR:-$SCRIPT_DIR/cycles}"
PROBLEMS="${DEFINE_PROBLEMS_DIR:-$SCRIPT_DIR/problems}"

# The one place a finding's id is harvested from a findings file. This gate used
# to carry its own expression for it, which read the whole file rather than the
# `## Findings` section — so a table anywhere else in the source counted as
# findings. Stage 1 owns the shape of a findings file, so stage 1 owns the
# harvester.
IDS="${FINDINGS_IDS:-$SCRIPT_DIR/../01-scan/findings-ids.sh}"
if [ ! -f "$IDS" ]; then
  printf 'validate-define: no findings id harvester at %s — the accounting is compared against the ids the source records, so this gate will not run without it\n' "$IDS" >&2
  exit 2
fi

refusals=0

refuse() { printf '%s:%s: refuse[%s]: %s\n' "$1" "$2" "$3" "$4" >&2; refusals=$((refusals + 1)); }
# field <file> <key> -> the first value outside a fenced block, trimmed
#
# A FENCED BLOCK is skipped. This was `sed -n "s/^$2:...//p" | head -1`, so a
# document showing what a field looks like donated the example as the field's
# value: a fenced `rests on: none — ...` ahead of the real field satisfied the
# check and the real link was never read. Found by attacking the problem check
# after writing it, and the same class this repository has already paid for once —
# an example row in a fenced block in `DECIDERS.md` would have authorized everyone
# it named, which is why the deciders list skips fences.
#
# `index` rather than a regex, because a key can contain a space (`rests on`) and
# a key is not a pattern.
field() {
  awk -v key="$2" '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    index($0, key ":") == 1 {
      v = substr($0, length(key) + 2)
      sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v)
      print v; exit
    }
  ' "$1" 2>/dev/null
}

# declares_empty <section body> -> 0 if the section declares itself empty
#
# A section with nothing in it has to SAY it is empty, in band, with a reason:
#
#   <!-- declared-empty: every finding this cycle fitted a theme -->
#
# Checked for the same two things as the `not-a-claim` and `dead-pointer`
# declarations in bin/validate-standards.sh, and for the same reason `rests on:
# none` needs its reason below: the declaration is present, and it carries a
# reason. NOT whether the reason is true.
#
# WHY THIS REPLACED A WORD SEARCH. The check read this section's body for three
# short words. The shipped cycle's own explanation of why outliers matter uses one
# of them twice, so for that artifact the refusal could never fire: delete all
# three outliers and the section still satisfied its own emptiness check. The same
# shape in the Discover gate let a topic delete all seven of its "could not be
# established" items, assert the opposite, and pass. A word in a sentence is not a
# declaration, and this is the third time this repository has shipped a search
# standing in for a reading — after the two-number coverage proxy and the
# four-phrase dead-pointer match.
#
# A FENCED BLOCK IS NOT A DECLARATION, for the same reason `field` below skips
# fences: a document showing what the form looks like must not thereby satisfy it.
# A fenced `rests on: none` donated itself as the real field's value once, and an
# example row in a fenced block in DECIDERS.md would have authorized everyone it
# named. Found by attacking this check after writing it.
#
# This predicate is also written, identically, in
# process/02-discover/validate-discovery.sh, which owns the other section that may
# be empty. The gates share no library and adding one would put a load-bearing
# script outside the filename pattern bin/validate-controls.sh enumerates —
# the gap that document records. So the form is declared once in the two contracts
# and in CONTROLS.md, and what holds the two copies together is that both suites
# pin the same behaviour rather than the expression.
declares_empty() {
  printf '%s\n' "$1" | awk '
    /^[ \t]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    /<!--[ \t]*declared-empty:[^>]*[A-Za-z][^>]*-->/ { found = 1 }
    END { exit found ? 0 : 1 }'
}

# outlier_body <file> — the Outliers section's BODY, heading excluded.
#
# This was `sed -n '/^## Outliers/,/^---/p'`, which includes the heading, so any
# of `none`, `empty` or `nothing` in the TITLE satisfied the "it must say it is
# empty" check. define-contract.md's own name for the section is "Outliers —
# surfaced because they fit nothing", so a cycle using the contract's wording and
# listing no outliers at all passed the one refusal that makes the section
# load-bearing. The range also ran to end of file when a cycle carried no `---`
# after the section, taking every section below it with it.
outlier_body() {
  awk '
    !inside && substr($0, 1, 11) == "## Outliers" { inside = 1; next }
    inside && (substr($0, 1, 3) == "## " || $0 ~ /^---[[:space:]]*$/) { exit }
    inside { print }
  ' "$1"
}

check_cycle() {
  local f="$1" src src_path resolved outliers outlier_text declared src_ids src_n declared_n
  local uniq_declared missing extra dupes themes_sum accounted_n

  # --- method is declared -------------------------------------------------
  if [ -z "$(field "$f" method)" ]; then
    refuse "$f" "-" "no-method" \
      "method is not declared: a reader must know whether themes came from a person, a model or a classifier before trusting the grouping"
  fi

  # --- the outlier section exists ----------------------------------------
  # Read once. The count was computed from the same expression three times over,
  # which is three places for the section boundary to be got wrong differently.
  outlier_text="$(outlier_body "$f")"
  outliers=$(printf '%s\n' "$outlier_text" | grep -cE '^- \*\*')
  if ! grep -q '^## Outliers' "$f"; then
    refuse "$f" "-" "no-outlier-section" \
      "no Outliers section: an empty outlier list and an omitted one look identical, so an empty one must say so"
  elif [ "$outliers" -eq 0 ] && ! declares_empty "$outlier_text"; then
    refuse "$f" "-" "silent-empty-outliers" \
      "the Outliers section lists nothing and does not declare itself empty — the declared form is <!-- declared-empty: reason --> in the section, not in its heading and not as a sentence. Until 2026-10-04 this was a search of the section's prose for a short word, and the shipped cycle's own explanation of why outliers matter carries one of those words twice, so for that artifact this refusal could never fire"
  fi

  # --- every source item accounted for ------------------------------------
  src="$(field "$f" from)"
  src_path="$(printf '%s' "$src" | sed -n 's/.*](\([^)]*\)).*/\1/p')"
  if [ -z "$src_path" ]; then
    refuse "$f" "-" "no-source" "from: does not link a source artifact, so nothing can be accounted for"
    return
  fi
  resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$src_path")" 2>/dev/null && pwd)/$(basename "$src_path")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "source-unresolved" "the declared source does not resolve: $src_path"
    return
  fi

  # --- the source is a real scan ------------------------------------------
  # `example: yes` means "not a real scan". Two words inserted into the only real
  # findings file made bin/cycle.sh collapse to a skipped line and both gates
  # report the files within the contract, while this cycle's `from:` went on
  # resolving to it — so the record of a month's work rested on a file declaring
  # itself a worked example, and nothing said so. findings-contract.md disclosed
  # the inverse case, an example that forgets its marker, and this direction
  # nowhere.
  #
  # The marker is not what is refused. An example read by nothing is a legitimate
  # file and findings/2026-09-01.md is one. The contradiction between the marker
  # and a cycle that depends on the file is what is refused, and it is refused
  # here because this is where the dependency is written down.
  if [ "$(field "$resolved" example)" = "yes" ]; then
    refuse "$f" "-" "source-is-example" \
      "the declared source is marked \`example: yes\`, so it is not a real scan: $src_path — a cycle cannot rest on a worked example, and the anchor the next scan reads skips it"
  fi

  src_ids="$(bash "$IDS" "$resolved")"
  if [ "$?" -ne 0 ]; then
    refuse "$f" "-" "source-unreadable" \
      "the ids of the declared source could not be read: $src_path"
    return
  fi
  src_n="$(printf '%s\n' "$src_ids" | grep -c .)"
  src_ids="$(printf '%s\n' "$src_ids" | sort)"

  # --- the declared count is the denominator ------------------------------
  #
  # `from:` states the source artifact and its item count. The count is what the
  # rest of the record is written against — the artifact's own prose says "every
  # one of the 64 rows" — and until this check existed nothing read it. Deleting
  # a finding from the source, dropping its id from the accounting block and
  # decrementing one theme count left both gates reporting the file within the
  # contract, with the declared count standing over a table one row shorter.
  #
  # Checked against the source's rows rather than against the accounting block,
  # because the set comparison below already ties the block to the source. The
  # two together give the three-way agreement, and each disagreement keeps its
  # own refusal instead of being folded into one message that names three
  # numbers and no cause.
  declared_n="$(printf '%s' "$src" \
    | sed -n 's/.*,[[:space:]]*\([0-9][0-9]*\)[[:space:]]*findings.*/\1/p')"
  if [ -z "$declared_n" ]; then
    refuse "$f" "-" "no-declared-count" \
      "from: links a source but declares no item count: the count is the denominator every theme count is written against, and one nothing states cannot be checked"
  elif [ "$declared_n" -ne "$src_n" ]; then
    refuse "$f" "-" "declared-count" \
      "from: declares $declared_n findings, and the source records $src_n — a theme is a summary, not a filter, and the declared count is what says how much there was to summarise"
  fi

  # --- the accounting, as a SET comparison --------------------------------
  #
  # This used to add two totals and compare them. An external audit showed that
  # a total cannot establish what this control claims: lowercasing a finding's
  # first letter removed the row from the denominator — the counter was
  # `grep -cE '^\| [A-Z]'` — and both gates passed a genuinely dropped finding.
  #
  # A total also cannot tell a dropped item from a miscounted one. Comparing the
  # declared id set against the source's gives each its own refusal.
  declared="$(sed -n '/accounting:ids -->/,/\/accounting:ids -->/p' "$f" \
    | grep -oE 'F[0-9]+' | sort)"

  if [ -z "$declared" ]; then
    refuse "$f" "-" "no-accounting" \
      "no accounting:ids block: a theme is a summary, not a filter, and nothing may be dropped — which a total cannot establish, so the ids accounted for are declared explicitly"
    return
  fi

  dupes="$(printf '%s\n' "$declared" | uniq -d | tr '\n' ' ')"
  [ -z "$dupes" ] || refuse "$f" "-" "duplicate-accounting" \
    "id(s) accounted for more than once: $dupes"

  uniq_declared="$(printf '%s\n' "$declared" | uniq)"
  missing="$(printf '%s\n' "$src_ids" | comm -23 - <(printf '%s\n' "$uniq_declared") | tr '\n' ' ')"
  extra="$(printf '%s\n' "$src_ids" | comm -13 - <(printf '%s\n' "$uniq_declared") | tr '\n' ' ')"

  [ -z "$missing" ] || refuse "$f" "-" "unaccounted" \
    "finding(s) in the source and not accounted for: $missing — a theme is a summary, not a filter, and nothing may be dropped"
  [ -z "$extra" ] || refuse "$f" "-" "invented-accounting" \
    "id(s) accounted for that are not in the source: $extra"

  # Theme counts must still sum to what was accounted for. This does NOT detect
  # an item moved between themes; that needs per-theme ids, which this cycle
  # predates and the contract requires from the next one.
  themes_sum=$(grep -oE '^\*\*[0-9]+ findings' "$f" | grep -oE '[0-9]+' | awk '{s+=$1} END {print s+0}')
  accounted_n=$(printf '%s\n' "$uniq_declared" | grep -c .)
  if [ "$((themes_sum + outliers))" -ne "$accounted_n" ]; then
    refuse "$f" "-" "counts-disagree" \
      "theme counts ($themes_sum) plus outliers ($outliers) is $((themes_sum + outliers)), but $accounted_n ids are accounted for"
  fi
}

# A problem is the OTHER artifact Define produces, and nothing read one.
#
# What this establishes: a problem declares the Discover topic it was stated from,
# that link resolves, and it resolves to something in the Discover topics
# directory rather than to any file that happens to exist. An omitted `rests on:`
# and a problem deliberately stated without discovery look identical otherwise,
# which is the reasoning behind `amends: none` in Deliver and behind an empty
# outlier list having to say it is empty.
#
# What it does not establish is in CONTROLS.md under CTRL-10. In particular the
# topic has to be a topic and does not have to be the RIGHT topic, and a problem's
# `from:` is still unread.
check_problem() {
  local f="$1" rests first rest path resolved topics_dir

  rests="$(field "$f" 'rests on')"
  if [ -z "$rests" ]; then
    refuse "$f" "-" "no-rests-on" \
      "no 'rests on:' field: a problem names the Discover topic it was stated from, or 'none' with the reason no discovery was needed. An omitted field and a declared skip look identical, and only one of them a reader can check"
    return
  fi

  # `none` has to be the WHOLE first word, followed by a reason. The Deliver gate
  # had the prefix version of this defect: `amends: nonetheless, we decided not to
  # say where this lands` was read as a declaration that nothing changed.
  first="$(printf '%s' "$rests" | awk '{print tolower($1)}' | tr -d '.,;:')"
  if [ "$first" = none ]; then
    rest="$(printf '%s' "$rests" | sed -e 's/^[Nn]one//' -e 's/^[[:punct:][:space:]]*//')"
    if [ "${#rest}" -lt 10 ]; then
      refuse "$f" "-" "bare-none-rests-on" \
        "'rests on: none' needs the reason no discovery was needed, otherwise it cannot be told apart from the field being forgotten"
    fi
    return
  fi

  path="$(printf '%s' "$rests" | sed -n 's/.*](\([^)#]*\)[^)]*).*/\1/p')"
  if [ -z "$path" ]; then
    refuse "$f" "-" "rests-on-not-linked" \
      "'rests on:' names something but does not link it, so the discovery the problem rests on cannot be read from the problem"
    return
  fi

  resolved="$(cd "$(dirname "$f")" && cd "$(dirname "$path")" 2>/dev/null && pwd)/$(basename "$path")"
  if [ ! -f "$resolved" ]; then
    refuse "$f" "-" "rests-on-unresolved" "the declared discovery does not resolve: $path"
    return
  fi

  # Resolving is not enough. A link to any file that happens to exist would
  # satisfy "the topic exists" and establish nothing about the Discover edge, so
  # the allowed location is enumerated rather than inferred: the Discover topics
  # directory beside this problem's own phase.
  topics_dir="$(cd "$(dirname "$f")/../../02-discover/topics" 2>/dev/null && pwd)"
  if [ -z "$topics_dir" ]; then
    refuse "$f" "-" "rests-on-not-a-topic" \
      "there is no Discover topics directory beside this problem, so nothing can establish that 'rests on:' names a topic"
  elif [ "$(dirname "$resolved")" != "$topics_dir" ]; then
    refuse "$f" "-" "rests-on-not-a-topic" \
      "'rests on:' resolves to $path, which is not in process/02-discover/topics: a problem rests on a discovery, and a link to another artifact says nothing about the Discover step"
  fi
}

# A cycle and a problem are different artifacts with different checks, told apart
# by the directory the contract already puts them in. Sniffing their contents
# would be guessing at which one a file is meant to be.
check_file() {
  case "$1" in
    */problems/*) check_problem "$1" ;;
    *)            check_cycle "$1" ;;
  esac
}

# The two artifacts are counted and reported SEPARATELY, not added together.
#
# One merged denominator would make the claim unreadable: "3 file(s) within the
# contract" over one cycle and two problems says nothing about whether either
# phase was read, and an empty cycles directory would still print a conformance
# claim because the problems made the total non-zero. That is the shape the
# empty-input sweep had just closed for cycles, pointed at problems instead.
#
# So a cycle count is a cycle count, and the problem line says what it read
# without claiming conformance for the phase it says nothing about.
main() {
  local files=0 problems=0
  if [ "$#" -gt 0 ]; then
    for f in "$@"; do
      [ -f "$f" ] || { printf 'validate-define: no such file: %s\n' "$f" >&2; exit 2; }
      files=$((files + 1)); check_file "$f"
    done
  else
    [ -d "$CYCLES" ] || { printf 'validate-define: no cycles directory: %s\n' "$CYCLES" >&2; exit 2; }
    for f in "$CYCLES"/*.md; do
      [ -f "$f" ] || continue
      files=$((files + 1)); check_cycle "$f"
    done
    # A problems directory that is absent is a refusal to run rather than a clean
    # report over nothing. The repository's own lesson: a gate that evaluates an
    # empty set and exits 0 reads exactly like a gate that passed.
    [ -d "$PROBLEMS" ] || { printf 'validate-define: no problems directory: %s\n' "$PROBLEMS" >&2; exit 2; }
    for f in "$PROBLEMS"/*.md; do
      [ -f "$f" ] || continue
      problems=$((problems + 1)); check_problem "$f"
    done
  fi

  if [ "$refusals" -gt 0 ]; then
    printf 'validate-define: %s refusal(s) across %s file(s)\n' \
      "$refusals" "$((files + problems))" >&2
    exit 1
  fi

  # The problem phase, said before the cycle claim so neither reads as the other.
  # Deliberately NOT phrased as "within the contract": a problem is checked for one
  # thing, the Discover edge, and the phrase this gate uses for a cycle means every
  # check the contract names has run.
  if [ "$#" -eq 0 ]; then
    if [ "$problems" -eq 0 ]; then
      printf 'validate-define: no problem files in %s, so no problem was checked\n' "$PROBLEMS"
    else
      printf 'validate-define: %s problem(s) checked for the Discover edge, no refusals\n' "$problems"
    fi
  fi

  # A run that read no artifact does not get to report conformance. This printed
  # "0 file(s) within the contract" over an empty cycles directory, and CI runs this
  # gate with no arguments. Still exit 0: an empty phase is a real state, as the scan
  # gate already settled. What changes is the claim.
  if [ "$files" -eq 0 ]; then
    printf 'validate-define: no cycle files in %s, so nothing was checked\n' "$CYCLES"
    return 0
  fi
  printf 'validate-define: %s file(s) within the contract\n' "$files"
}

main "$@"
