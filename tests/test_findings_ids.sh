#!/usr/bin/env bash
# process/01-scan/findings-ids.sh is the denominator. Everything that needs to
# know how many findings a cycle recorded reads it, so a hole here is a hole in
# "nothing is dropped".
#
# The fixtures are WRITTEN HERE, not copied from the live artifacts, and the
# expected answer is known by construction. The reason is a defect this suite is
# a reaction to: tests/test_validate_define.sh mutates a copy of the shipped
# cycle file by matching literals out of it, so tampering with the artifact
# breaks the test's own mutation instead of detecting the tamper, and the failure
# then names the wrong check. A fixture built in the test cannot do that.
#
# One assertion reads the live artifacts, deliberately, and it is a cross-check
# between two of them rather than a pinned literal: the ids harvested from the
# findings file are exactly the ids the Define cycle's accounting block declares.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
HARVEST="$ROOT/process/01-scan/findings-ids.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$HARVEST" "the harvester exists"

# ids <file> [extra env assignment...] — the harvest, space separated on one line.
ids() { /bin/bash "$HARVEST" "$@" 2>/dev/null | tr '\n' ' ' | sed 's/ *$//'; }

# A findings file written here. $1 is the Findings-section body appended after
# the header and separator rows; $2 is extra content for `## Looked at`.
write_findings() { # <path> <rows> [looked-at extra]
  {
    printf '# Scan cycle — fixture\n\nsince: first run\nnothing found: no\n\n'
    printf '## Looked at\n\n- web: a fixture.\n- X: a fixture.\n- YouTube: a fixture.\n'
    [ -n "${3:-}" ] && printf '%s\n' "$3"
    printf '\n## Findings\n\n'
    printf '| id | what | source | dated | kind | might affect (guess) | consequence guess |\n'
    printf '|---|---|---|---|---|---|---|\n'
    printf '%s\n' "$2"
  } > "$1"
}

row() { # <id> <what>
  printf '| %s | %s | https://example.com/x | 2026-09-30 | practice-change | build (guess) | low |' "$1" "$2"
}

# --- the plain case, expected by construction ---------------------------------
write_findings "$TMP/plain.md" "$(row F01 'A thing happened')
$(row F02 'Another thing happened')
$(row F03 'A third thing happened')"
assert_eq "F01 F02 F03" "$(ids "$TMP/plain.md")" "three rows harvest as three ids"

# The header row and the separator row are rows of the table and must not be ids.
assert_eq "3" "$(/bin/bash "$HARVEST" "$TMP/plain.md" | grep -c .)" \
  "the header and separator rows are not findings"

# --- a table that is not the findings table is not findings --------------------
# findings-contract.md permits content in `## Looked at`, and an external audit's
# decoy table there made a two-finding file report five. The decoy's rows are
# shaped EXACTLY like findings rows, so only the section boundary separates them.
write_findings "$TMP/decoy-before.md" "$(row F01 'A thing happened')
$(row F02 'Another thing happened')" "
| id | what |
|---|---|
| F91 | a decoy |
| F92 | another decoy |"
assert_eq "F01 F02" "$(ids "$TMP/decoy-before.md")" \
  "a table above the findings table is not harvested"

# And below it. The harvester leaves the section at the next `## ` heading; a
# version that read to end of file would take these.
write_findings "$TMP/decoy-after.md" "$(row F01 'A thing happened')
$(row F02 'Another thing happened')"
printf '\n## Looked at\n\n| id | what |\n|---|---|\n| F93 | a decoy |\n' >> "$TMP/decoy-after.md"
assert_eq "F01 F02" "$(ids "$TMP/decoy-after.md")" \
  "a table below the findings table is not harvested"

# --- a mention is not a row ---------------------------------------------------
# Three shapes of mention, each a way an unanchored or unscoped extractor counts
# a finding that is not there. This is the same defect as a deleted row passing
# the gate: the accounting then reconciles against mentions instead of rows.
write_findings "$TMP/mention-cell.md" "$(row F01 'A thing happened')
$(row F02 'A follow-up to F01, which is a mention and not a row')"
assert_eq "F01 F02" "$(ids "$TMP/mention-cell.md")" \
  "an id inside another cell is a mention, not a row"

write_findings "$TMP/mention-whole-cell.md" "$(row F01 'A thing happened')
| F02 | A thing | https://example.com/x | 2026-09-30 | practice-change | F91 | low |"
assert_eq "F01 F02" "$(ids "$TMP/mention-whole-cell.md")" \
  "an id that fills a cell other than the id cell is still not a row"

write_findings "$TMP/mention-prose.md" "$(row F01 'A thing happened')

F91 was looked at separately and is not a row."
assert_eq "F01" "$(ids "$TMP/mention-prose.md")" \
  "an id in prose inside the findings section is not a row"

write_findings "$TMP/mention-partial.md" "$(row F01 'A thing happened')
| see F02 | A thing | https://example.com/x | 2026-09-30 | practice-change | build (guess) | low |"
assert_eq "F01" "$(ids "$TMP/mention-partial.md")" \
  "an id cell carrying more than the id is not a row"

# --- the audit's original exploit ---------------------------------------------
# The counter was `grep -cE '^| [A-Z]'`, so lowercasing a finding's first word
# removed the row from the denominator. The id, not the prose, is what counts.
write_findings "$TMP/lower-what.md" "$(row F01 'A thing happened')
$(row F02 'another thing happened')"
assert_eq "F01 F02" "$(ids "$TMP/lower-what.md")" \
  "lowercasing a finding's first letter does not remove it from the denominator"

# A lowercased ID is a different thing: it is not an id, so it is not harvested —
# and the stage 1 gate is what refuses the row. Both halves are asserted, because
# "not harvested" alone would be a silent drop.
write_findings "$TMP/lower-id.md" "$(row F01 'A thing happened')
| f02 | A thing | https://example.com/x | 2026-09-30 | practice-change | build (guess) | low |"
assert_eq "F01" "$(ids "$TMP/lower-id.md")" "a lowercased id is not harvested"
out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" "$TMP/lower-id.md" 2>&1)"
assert_contains "$out" "refuse[id]" "and the stage 1 gate refuses the row that carries it"

# --- the column position comes from the contract ------------------------------
# The property that keeps this from being a second declaration of the table's
# shape. Reordering the contract's columns list reorders what the harvester
# reads, with no edit here and none in the harvester.
mkdir -p "$TMP/reordered"
awk '
  $0 == "<!-- contract:columns -->" { print; print "- `what`"; print "- `id`"; skip = 2; next }
  skip > 0 { skip--; next }
  { print }
' "$ROOT/process/01-scan/findings-contract.md" > "$TMP/reordered/findings-contract.md"
assert_contains "$(sed -n '/contract:columns -->/,/\/contract:columns -->/p' "$TMP/reordered/findings-contract.md" | tr '\n' ' ')" \
  '- `what` - `id`' "the fixture contract declares what before id"

write_findings "$TMP/swapped.md" "| A thing happened | F01 | https://example.com/x | 2026-09-30 | practice-change | build (guess) | low |
| Another thing happened | F02 | https://example.com/x | 2026-09-30 | practice-change | build (guess) | low |"
got="$(FINDINGS_CONTRACT="$TMP/reordered/findings-contract.md" /bin/bash "$HARVEST" "$TMP/swapped.md" | tr '\n' ' ' | sed 's/ *$//')"
assert_eq "F01 F02" "$got" "the id is read from the position the contract declares"

# The same file against the shipped contract must harvest nothing, or the
# assertion above would pass for a harvester that scanned every cell.
assert_eq "" "$(ids "$TMP/swapped.md")" \
  "and the same file read with the shipped column order harvests nothing"

# --- it cannot run without a column order, and says so -----------------------
# A harvester that printed nothing here would make every caller's denominator
# zero, and a zero denominator reconciles with an empty accounting block.
awk '$0 == "<!-- contract:columns -->" { print; print "- `what`"; skip = 1; next }
     skip > 0 && /^- / { next }
     { skip = 0; print }' \
  "$ROOT/process/01-scan/findings-contract.md" > "$TMP/no-id-column.md"
out="$(FINDINGS_CONTRACT="$TMP/no-id-column.md" /bin/bash "$HARVEST" "$TMP/plain.md" 2>&1)"; rc=$?
assert_status 2 "$rc" "a contract declaring no id column exits 2 rather than printing no ids"
assert_contains "$out" "refusing to run" "and it says it refused to run"

out="$(FINDINGS_CONTRACT="$TMP/absent.md" /bin/bash "$HARVEST" "$TMP/plain.md" 2>&1)"; rc=$?
assert_status 2 "$rc" "a missing contract exits 2"
assert_contains "$out" "the column order cannot be read" "and it says why"

out="$(/bin/bash "$HARVEST" "$TMP/not-there.md" 2>&1)"; rc=$?
assert_status 2 "$rc" "a missing findings file exits 2"

out="$(/bin/bash "$HARVEST" 2>&1)"; rc=$?
assert_status 2 "$rc" "no argument exits 2"

# --- a file with no findings section is zero, not an error -------------------
# `nothing found: yes` is a valid cycle, and zero is its honest denominator.
printf '# Scan cycle — fixture\n\nsince: first run\nnothing found: yes\n\n## Looked at\n\n- web: nothing.\n' \
  > "$TMP/empty.md"
out="$(ids "$TMP/empty.md")"; rc=$?
assert_status 0 "$rc" "a cycle with no findings section exits 0"
assert_eq "" "$out" "and harvests no ids"

# --- the live artifacts agree with each other --------------------------------
# Not a pinned count. The findings file and the Define cycle that reads it are
# written by different hands at different times; this asserts they still say the
# same thing about which findings exist.
live_ids="$(ids "$ROOT/process/01-scan/findings/2026-09-29.md")"
accounted="$(sed -n '/accounting:ids -->/,/\/accounting:ids -->/p' \
  "$ROOT/process/03-define/cycles/2026-09-29.md" \
  | grep -oE 'F[0-9]+' | sort | tr '\n' ' ' | sed 's/ *$//')"
assert_eq "$accounted" "$(printf '%s' "$live_ids" | tr ' ' '\n' | sort | tr '\n' ' ' | sed 's/ *$//')" \
  "the ids the shipped findings file records are the ids the shipped cycle accounts for"
[ -n "$accounted" ] && any=yes || any=no
assert_eq "yes" "$any" "and that comparison ran against a non-empty set"

# --- a displayed declaration declares nothing, and this harvester decides which cell
#
# This script reads the contract's `columns` block to learn which cell an id comes out
# of, and it had no fence awareness at all. Three loosenings of it — reading the
# contract raw, unioning a second block, reading the findings table raw — were caught
# by NOTHING, which is how these cases came to exist.
#
# The stakes here are higher than in the gate it feeds: the answer is a column
# POSITION, so a displayed block that reorders the columns moves every id silently.
CONTRACT="$ROOT/process/01-scan/findings-contract.md"

# One real row, and a second `columns` block displayed four ways, each declaring a
# different order. The harvest must be unchanged by all four.
write_findings "$TMP/disp.md" "$(row F01 'a thing')"
expected="$(ids "$TMP/disp.md")"
assert_eq "F01" "$expected" "the baseline harvest reads the id from the declared cell"

for form in backtick-fence tilde-fence html-comment indented-block; do
  c="$TMP/contract-$form.md"
  cp "$CONTRACT" "$c"
  { printf '\nFor a reader, the block looks like this:\n\n'
    case "$form" in
      backtick-fence) printf '```\n<!-- contract:columns -->\n- `what`\n- `id`\n<!-- /contract:columns -->\n```\n' ;;
      tilde-fence)    printf '~~~\n<!-- contract:columns -->\n- `what`\n- `id`\n<!-- /contract:columns -->\n~~~\n' ;;
      html-comment)   printf '<!-- the block, for a reader:\n<!-- contract:columns -->\n- `what`\n- `id`\n<!-- /contract:columns -->\nand no more. -->\n' ;;
      indented-block) printf '\n    <!-- contract:columns -->\n    - `what`\n    - `id`\n    <!-- /contract:columns -->\n\n' ;;
    esac
  } >> "$c"
  assert_eq "F01" "$(FINDINGS_CONTRACT="$c" ids "$TMP/disp.md")" \
    "a columns block displayed in a $form does not move which cell an id comes from"
done

# A SECOND REAL BLOCK IS A REFUSAL TO RUN, not a merge. Two declarations of one column
# order cannot both be the rule, and the union of them is nobody's declaration.
c="$TMP/contract-two.md"; cp "$CONTRACT" "$c"
printf '\n<!-- contract:columns -->\n- `what`\n- `id`\n<!-- /contract:columns -->\n' >> "$c"
out="$(FINDINGS_CONTRACT="$c" /bin/bash "$HARVEST" "$TMP/disp.md" 2>&1)"; rc=$?
assert_status 2 "$rc" "a second columns block makes the harvester refuse to run"
assert_contains "$out" "more than one block" "and the message says which problem it is"

# The findings TABLE is read in a rendering context too, or a fenced example row
# donates ids that are not in the record.
write_findings "$TMP/fencedrow.md" "$(row F01 'a thing')"
printf '\n```\n| F99 | an example row | https://example.com | 2026-01-01 | practice-change | build (guess) | low |\n```\n' \
  >> "$TMP/fencedrow.md"
assert_eq "F01" "$(ids "$TMP/fencedrow.md")" "a fenced example row donates no id"

assert_done
