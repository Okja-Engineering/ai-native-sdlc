#!/usr/bin/env bash
# Five display forms against fifteen declaration forms. The whole cross-product.
#
# WHY THIS SUITE EXISTS
#
# A document that DISPLAYS a declaration must not thereby SATISFY it. This
# repository had repaired that five times, each time at the one site where it was
# found, and each repair covered fenced blocks only. Issue #116 is the sixth and
# seventh: a declaration shown in an INLINE CODE SPAN emptied a mandatory
# disclosure section with every suite green, and the standards gate's span
# exemption was honoured inside a fence, which switched off CTRL-8 by deleting one
# line.
#
# Five separate repairs produced five separate holes because each one sampled. So
# this suite does not sample. It enumerates:
#
#   FIFTEEN declaration forms   every in-band HTML comment carrying a name and a
#                               colon, enumerated from the tree at the end of this
#                               file. The form is not written out here, because the
#                               enumeration reads tracked text and this file is
#                               tracked — writing the shape as prose added a
#                               sixteenth form called `name`, which is the
#                               stage-before-you-verify trap in a new place.
#   FIVE display forms          backtick fence, tilde fence, inline code span,
#                               HTML comment, four-space indented block
#
# and drives each cell through the thing that READS that form, not through
# bin/lib-rendering.sh. A library-level table would prove the library and say
# nothing about whether a gate consults it, which is how four of the five earlier
# repairs looked complete.
#
# EVERY ANSWER MUST BE "not honoured". A cell that is not applicable says why here
# rather than being left out — a missing cell is how five of these survived.
#
# EACH FORM ALSO HAS A CONTROL CASE. The same declaration, displayed as nothing at
# all, must be honoured. Without it a probe that is simply broken reads as fifteen
# clean cells, which is the vacuous-assertion failure this repository has shipped
# twice.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"
. "$TEST_DIR/lib/topic-fixture.sh"
. "$TEST_DIR/lib/define-fixture.sh"
. "$TEST_DIR/lib/splice.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
. "$ROOT/bin/lib-rendering.sh"
. "$TEST_DIR/lib/retired-claim.sh"
. "$TEST_DIR/lib/enforcement-claim.sh"

DISCOVER="$ROOT/process/02-discover/validate-discovery.sh"
DEFINE="$ROOT/process/03-define/validate-define.sh"
DECISION="$ROOT/process/05-deliver/validate-decision.sh"
FINDINGS="$ROOT/process/01-scan/validate-findings.sh"
CONTROLS="$ROOT/bin/validate-controls.sh"
STANDARDS="$ROOT/bin/validate-standards.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
n=0

# --- the five display forms ---------------------------------------------------
#
# Each takes the declaration's own text — one line or several — and returns what a
# document would contain if it were showing that text to a reader rather than using
# it. All five render as something a reader can read and none of them renders as a
# declaration.
#
# `span` wraps each line, because that is the only way an inline code span can
# display a multi-line construct, and `indented` indents each line for the same
# reason.
DISPLAY_FORMS='backtick-fence tilde-fence inline-code-span html-comment indented-block'

display() { # <form> <declaration text>
  case "$1" in
    none)              printf '%s\n' "$2" ;;
    backtick-fence)    printf '```\n%s\n```\n' "$2" ;;
    tilde-fence)       printf '~~~\n%s\n~~~\n' "$2" ;;
    inline-code-span)  printf '%s\n' "$2" | sed 's/^.*$/`&`/' ;;
    html-comment)      printf '<!-- what the form looks like, for a reader:\n%s\nand that is all it is. -->\n' "$2" ;;
    indented-block)    printf '\n'; printf '%s\n' "$2" | sed 's/^/    /'; printf '\n' ;;
  esac
}

# sweep <probe> <declaration text> <label>
#
# The control first, then every display form. The control is asserted inside the
# sweep rather than beside it so a form cannot be added without one.
sweep() { # <probe> <declaration text> <label>
  local d
  assert_eq honoured "$("$1" "$(display none "$2")")" \
    "$3 — displayed as nothing, the declaration is honoured (the probe can see one)"
  for d in $DISPLAY_FORMS; do
    assert_eq 'not honoured' "$("$1" "$(display "$d" "$2")")" "$3 — $d"
  done
}

# sweep_per_line — for a declaration that RIDES ON the line it exempts.
#
# `corrected-claim` and `corrected-overclaim` exempt the one line they sit on, so a
# block-level display form — a fence, a comment, an indented block — takes the claim
# out of sight along with the declaration. There is then no claim to exempt, and
# "not reported" is the right answer for a reason that is not the exemption. Those
# four cells say that rather than pretending to measure something else, and the
# assertions after each sweep carry the half they cannot see: the same sentence
# displayed with NO declaration is also not reported.
#
# The inline code span is the one display form that can hide the declaration and
# leave the claim visible, so it is the real cell for these two forms.
sweep_per_line() { # <probe> <declaration text> <label>
  local d
  assert_eq honoured "$("$1" "$(display none "$2")")" \
    "$3 — displayed as nothing, the declaration is honoured (the probe can see one)"
  assert_eq 'not honoured' "$("$1" "$(display inline-code-span "$2")")" \
    "$3 — inline-code-span, the claim stays visible and the declaration stops exempting it"
  for d in backtick-fence tilde-fence html-comment indented-block; do
    assert_eq honoured "$("$1" "$(display "$d" "$2")")" \
      "$3 — $d takes the claim out of sight with the declaration, so nothing is claimed"
  done
}

# not_read <form> <reason> — a cell that does not exist, with the reason, plus the
# measurement that says it does not exist. A form nothing reads cannot be satisfied
# by displaying it, and the assertion is that nothing reads it.
not_read() { # <marker> <reason>
  local hits
  hits="$(cd "$ROOT" && grep -l -- "$1" bin/validate-*.sh process/*/validate-*.sh 2>/dev/null | tr '\n' ' ')"
  assert_eq "" "${hits% }" "$2"
}

# ==============================================================================
# 1 · declared-empty — three readers, one form
# ==============================================================================
DECL_EMPTY='<!-- declared-empty: a reason that is written down -->'

# The Discover gate: the "what could not be established" section.
p_discover_open() { # <section body>
  local f out
  n=$((n + 1)); f="$(topic_fixture "$TMP/t$n.md" "$1")"
  out="$(bash "$DISCOVER" "$f" 2>&1)"
  case "$out" in
    *'refuse[silent-empty-open]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

# The Define gate: the Outliers section.
p_define_outliers() { # <section body>
  local dir cyc out
  n=$((n + 1)); dir="$TMP/o$n"; cyc="$(define_fixture "$dir" "3 2" 1)"
  splice "$cyc" '^- [*][*]An outlier' "$1" || { printf 'probe failed'; return; }
  out="$(bash "$DEFINE" "$cyc" 2>&1)"
  case "$out" in
    *'refuse[silent-empty-outliers]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

# The Define gate: a declared-empty id set inside the accounting block, which is
# the only passing state for a cycle over a quiet scan.
p_define_accounting() { # <block body>
  local dir cyc out
  n=$((n + 1)); dir="$TMP/a$n"; cyc="$(define_fixture "$dir" "" 0)"
  splice "$cyc" '^<!-- declared-empty: the source is a quiet cycle' "$1" \
    || { printf 'probe failed'; return; }
  out="$(bash "$DEFINE" "$cyc" 2>&1)"
  case "$out" in
    *'refuse[no-accounting]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

sweep p_discover_open    "$DECL_EMPTY" 'declared-empty, the Discover open section'
sweep p_define_outliers  "$DECL_EMPTY" 'declared-empty, the Define Outliers section'
sweep p_define_accounting "$DECL_EMPTY" 'declared-empty, the Define accounting block'

# ==============================================================================
# 2 · accounting — the block delimiters the Define gate reads an id set out of
# ==============================================================================
ACCT_BLOCK='<!-- accounting:ids -->
F01 F02 F03 F04 F05 F06
<!-- /accounting:ids -->'

# The real block is removed and the candidate put in its place, so a displayed
# block has to carry the whole weight.
p_define_acct_block() { # <block text>
  local dir cyc out
  n=$((n + 1)); dir="$TMP/b$n"; cyc="$(define_fixture "$dir" "3 2" 1)"
  # The real block goes out entirely, so the candidate carries the whole weight.
  awk '
    /^<!-- accounting:ids -->/ { inside = 1; print "@@BLOCK@@"; next }
    inside && /^<!-- \/accounting:ids -->/ { inside = 0; next }
    inside { next }
    { print }' "$cyc" > "$cyc.new" && mv "$cyc.new" "$cyc"
  splice "$cyc" '^@@BLOCK@@$' "$1" || { printf 'probe failed'; return; }
  out="$(bash "$DEFINE" "$cyc" 2>&1)"
  case "$out" in
    *'refuse[no-accounting]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

sweep p_define_acct_block "$ACCT_BLOCK" 'accounting:ids, the Define accounting block'

# ==============================================================================
# 3 · deciders-table — the designation that decides who may decide
# ==============================================================================
DECIDERS_DECL='<!-- deciders-table: the authorizing list, designated for this fixture -->'

p_deciders() { # <designation text>
  local d out
  n=$((n + 1)); d="$TMP/deciders$n.md"
  { printf '# Deciders\n\n'
    printf '%s\n' "$1"
    printf '\n| Name | Since |\n|---|---|\n| Matthew Van Dusen | 2026-01-01 |\n'
  } > "$d"
  out="$( DECIDERS_FILE="$d" bash "$DECISION" 2>&1 )"
  case "$out" in
    *'refuse[not-a-person]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

sweep p_deciders "$DECIDERS_DECL" 'deciders-table, the designated authorizing list'

# ==============================================================================
# 4 · contract — the six machine-read lists the scan gate takes its rules from
# ==============================================================================
# A SECOND block is what the exploit uses: the real one stays, a displayed one
# names a third section, and the gate unioned them. `## What this means` is the
# heading findings-contract.md says the gate refuses.
SECTIONS_BLOCK='<!-- contract:sections -->
- Looked at
- Findings
- What this means
<!-- /contract:sections -->'

p_contract_sections() { # <block text>
  local c f out dir
  n=$((n + 1)); dir="$TMP/fc$n"; mkdir -p "$dir"
  c="$dir/findings-contract.md"
  { cat "$ROOT/process/01-scan/findings-contract.md"
    printf '\nFor a reader, this is what the declaration looks like:\n\n'
    printf '%s\n' "$1"
  } > "$c"
  f="$dir/2026-12-01.md"
  { printf '# Scan cycle — 2026-12-01\n\nsince: 2026-11-01\nnothing found: yes\n\n'
    printf '## Looked at\n\n'
    printf -- '- web: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- X: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- YouTube: a built fixture, 2026-11-01 to 2026-12-01.\n\n'
    printf '## What this means\n\nStage 2 arriving in a stage 1 file.\n'
  } > "$f"
  out="$( FINDINGS_CONTRACT="$c" bash "$FINDINGS" "$f" 2>&1 )"
  case "$out" in
    *'refuse[sections]'*) printf 'not honoured' ;;
    *'refuse[contract-unreadable]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

# The control case for this form is the other way round from the rest: displayed as
# nothing, a SECOND sections block is a second declaration of the same rule, and the
# gate refuses rather than unioning. So the control is asserted directly instead of
# through sweep, and the five display cells follow.
assert_eq 'not honoured' "$(p_contract_sections "$(display none "$SECTIONS_BLOCK")")" \
  'contract:sections — a second block in a rendering context refuses rather than unions'
for d in $DISPLAY_FORMS; do
  assert_eq 'not honoured' "$(p_contract_sections "$(display "$d" "$SECTIONS_BLOCK")")" \
    "contract:sections — $d"
done

# A DISPLAYED BLOCK AS THE ONLY BLOCK, which the five cells above cannot distinguish.
#
# Each of those keeps the real block and adds a displayed one, so the one-block refusal
# and the display rule both produce "not honoured" and either alone would pass the cell.
# The loosening sweep found that: making the contract read raw was caught by nothing,
# because the raw read then saw two blocks and refused for the other reason.
#
# With the real block REPLACED by a fenced one, the two answers differ — read raw the
# third section is allowed, read as rendered text there is no block at all and the gate
# exits 2 rather than passing everything.
p_contract_only_displayed() { # <block text>
  local c f out dir
  n=$((n + 1)); dir="$TMP/fo$n"; mkdir -p "$dir"
  c="$dir/findings-contract.md"
  awk '
    /^<!-- contract:sections -->/ { inside = 1; print "@@SECTIONS@@"; next }
    inside && /^<!-- \/contract:sections -->/ { inside = 0; next }
    inside { next }
    { print }' "$ROOT/process/01-scan/findings-contract.md" > "$c"
  splice "$c" '^@@SECTIONS@@$' "$1" || { printf 'probe failed'; return; }
  f="$dir/2026-12-01.md"
  { printf '# Scan cycle — 2026-12-01\n\nsince: 2026-11-01\nnothing found: yes\n\n'
    printf '## Looked at\n\n'
    printf -- '- web: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- X: a built fixture, 2026-11-01 to 2026-12-01.\n'
    printf -- '- YouTube: a built fixture, 2026-11-01 to 2026-12-01.\n\n'
    printf '## What this means\n\nStage 2 arriving in a stage 1 file.\n'
  } > "$f"
  out="$( FINDINGS_CONTRACT="$c" bash "$FINDINGS" "$f" 2>&1 )"
  case "$out" in
    *'refuse[sections]'*|*'refuse[contract-unreadable]'*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

assert_eq honoured "$(p_contract_only_displayed "$(display none "$SECTIONS_BLOCK")")" \
  'contract:sections — as the only block, undisplayed, it is the declaration (the probe can see one)'
for d in $DISPLAY_FORMS; do
  assert_eq 'not honoured' "$(p_contract_only_displayed "$(display "$d" "$SECTIONS_BLOCK")")" \
    "contract:sections as the only block — $d"
done

# And the one real block is still read, or every cell above passes for the wrong
# reason.
assert_eq 0 "$(cd "$ROOT" && bash "$FINDINGS" >/dev/null 2>&1; printf '%s' $?)" \
  'the shipped findings files are still within the contract'

# ==============================================================================
# 5 · the standards gate's four forms
# ==============================================================================
# A copied tree, because the gate enumerates its own surface from the filesystem
# and resolves evidence pointers against the repository it runs in. Built once; each
# cell rewrites one document in it.
STD_TREE="$TMP/stdtree"
mkdir -p "$STD_TREE"
( cd "$ROOT" && tar cf - --exclude .git . ) | ( cd "$STD_TREE" && tar xf - )
( cd "$STD_TREE" && git init -q . \
  && printf '%s/objects\n' "$(git -C "$ROOT" rev-parse --absolute-git-dir)" \
       > .git/objects/info/alternates \
  && git commit -q --allow-empty -m init ) 2>/dev/null

std_probe() { # <probe document body> <refusal code meaning "not honoured">
  local out
  printf '%s\n' "$1" > "$STD_TREE/probe.md"
  out="$( cd "$STD_TREE" && bash bin/validate-standards.sh 2>&1 )"
  rm -f "$STD_TREE/probe.md"
  case "$out" in
    *"refuse[$2]"*) printf 'not honoured' ;;
    *) printf 'honoured' ;;
  esac
}

# not-a-claim — exempts the one line it sits on, so the claim travels with it.
NOT_A_CLAIM='A sentence that names a grade without using one. [E] <!-- not-a-claim: it names the marker, it does not use it -->'
p_not_a_claim() { std_probe "# Probe

$1" uncited-claim; }
sweep p_not_a_claim "$NOT_A_CLAIM" 'not-a-claim, the per-line exemption'

# not-a-claim-block — the span form. It is RETIRED, so even displayed as nothing it
# exempts nothing, and the control case says that rather than being omitted.
NACB='<!-- not-a-claim-block: the lines below declare what a grade means -->'
p_not_a_claim_block() {
  std_probe "# Probe

$1

An uncited graded claim. [E]

<!-- end-not-a-claim-block -->" uncited-claim
}
assert_eq 'not honoured' "$(p_not_a_claim_block "$(display none "$NACB")")" \
  'not-a-claim-block — the span form is retired, so it exempts nothing even undisplayed'
for d in $DISPLAY_FORMS; do
  assert_eq 'not honoured' "$(p_not_a_claim_block "$(display "$d" "$NACB")")" \
    "not-a-claim-block — $d"
done

# graded-claims-cite-inline — a whole-document declaration.
GCCI='<!-- graded-claims-cite-inline: the claim below names its source in the prose, a built fixture -->'
p_gcci() { std_probe "# Probe

An uncited graded claim whose source is named right here in the prose. [E]

$1" uncited-claim; }
sweep p_gcci "$GCCI" 'graded-claims-cite-inline, the whole-document declaration'

# dead-pointer — names one pointer and exempts that one. The declaration sits on the
# line carrying the pointer, so the pointer travels with it under a block-level display
# form; the pointer extraction reads the RAW file, so it is still found there and the
# cell is real for all five.
#
# THE PROBE NEEDS A LIVE COMMIT TOKEN. The pointer surface is derived from the tree —
# a document is in it when it cites an object name — so without one this document was
# never read and all five cells passed for the wrong reason. Caught by the control case
# only after the probe was fixed, which is the argument for having a control case.
LIVE_COMMIT="$(git -C "$ROOT" rev-parse --short=7 HEAD)"
DEAD="This document points at \`experiment/never-existed\` and records that it is dead. <!-- dead-pointer: experiment/never-existed — it was never a ref on origin -->"
p_dead_pointer() { std_probe "# Probe

The evidence is at \`$LIVE_COMMIT\`, which is what puts this document in the pointer surface.

$1" dangling-ref; }
sweep p_dead_pointer "$DEAD" 'dead-pointer, the retired evidence pointer'

# ==============================================================================
# 6 · declared-not-enforced — the contracts' set, read by the controls gate
# ==============================================================================
# Polarity is the other way round for this one: the declaration does not grant
# permission, it CREATES an obligation on CONTROLS.md. So "honoured" means the gate
# read the displayed text as a real declaration and demanded a disclosure row — and
# that is the false refusal on #116: a contract illustrating the form broke the
# build.
DNE='<!-- declared-not-enforced: a probe field — nothing reads it, this is a fixture -->'

p_declared_not_enforced() { # <declaration text>
  local cr out
  n=$((n + 1)); cr="$TMP/cr$n"
  mkdir -p "$cr/process/09-probe"
  { printf '# A probe contract\n\n'
    printf '%s\n' "$1"
  } > "$cr/process/09-probe/probe-contract.md"
  out="$( CONTRACT_ROOT="$cr" bash "$CONTROLS" 2>&1 )"
  case "$out" in
    *'a probe field'*) printf 'honoured' ;;
    *) printf 'not honoured' ;;
  esac
}

sweep p_declared_not_enforced "$DNE" 'declared-not-enforced, the contracts set'

# ==============================================================================
# 7 · the two retired-claim forms, read by tests/lib/retired-claim.sh
# ==============================================================================
# These are the OTHER direction of the same defect: a document that quotes a
# retired sentence inside a fence was refused, so the one place that has to be able
# to display a retired sentence could not display it.
OVERCLAIM='all of it in git|everything is in git|entirely in git'
LASTBLOCK='the last thing printed|the last thing it prints'

# honoured here means the exemption was read, so the line was not reported.
retired_probe() { # <keyword> <pattern> <text to write>
  local f
  n=$((n + 1)); f="$TMP/retired$n.md"
  printf '%s\n' "$3" > "$f"
  if [ -n "$(retired_claim_offenders "$1" "$2" "$f")" ]; then
    printf 'not honoured'
  else
    printf 'honoured'
  fi
}

CORRECTED_OVERCLAIM='AGENTS.md said *"All of it in git."* <!-- corrected-overclaim: all of it in git — this line is the correction -->'
p_corrected_overclaim() { retired_probe corrected-overclaim "$OVERCLAIM" "$1"; }
sweep_per_line p_corrected_overclaim "$CORRECTED_OVERCLAIM" 'corrected-overclaim, the retired overclaim'

CORRECTED_CLAIM='This said the `topics` block is the last thing printed. <!-- corrected-claim: the last thing printed — it was true until the dates block landed -->'
p_corrected_claim() { retired_probe corrected-claim "$LASTBLOCK" "$1"; }
sweep_per_line p_corrected_claim "$CORRECTED_CLAIM" 'corrected-claim, the retired sentence'

# THE FALSE REFUSAL, from #116. tests/test_cycle.sh refused a document that quoted
# the retired sentence inside a fenced block — so the one place that has to be able
# to show a reader the sentence could not show it. A quotation is not a claim.
for d in backtick-fence tilde-fence html-comment indented-block; do
  assert_eq honoured \
    "$(retired_probe corrected-claim "$LASTBLOCK" "$(display "$d" 'README.md said: the `topics` block is the last thing printed.')")" \
    "a retired sentence displayed, with no declaration, is not a claim — $d"
done

# An inline code span is the one display form that does NOT hide a sentence: a
# reader sees it, as code, and reads it. So it is still a claim and still has to be
# retired in band. Written as a case rather than left out, because assuming the five
# forms behave alike is how four of this week's holes were made.
assert_eq 'not honoured' \
  "$(retired_probe corrected-claim "$LASTBLOCK" 'README.md said: `the last thing printed` is the topics block.')" \
  'a retired sentence inside an inline code span is still read, because a reader reads it'

assert_eq 'not honoured' \
  "$(retired_probe corrected-claim "$LASTBLOCK" 'The `topics` block is the last thing printed.')" \
  'and the same sentence in prose, undeclared, still is'

# ==============================================================================
# 8 · not-an-enforcement-claim, read by tests/lib/enforcement-claim.sh
# ==============================================================================
# Driven through the same predicate tests/test_controls.sh runs over SOURCES.md, not
# through the library, so the cell says something about the check and not only about
# the reading.
#
# This one rides on the line it exempts, like the two retired-claim forms: a
# block-level display form takes the enforcement claim out of sight with the
# declaration, so there is no claim to exempt.
NAEC='`bin/validate-standards.sh` refuses it. <!-- not-an-enforcement-claim: this sentence is about the rule, not about a refusal -->'

p_naec() { # <text>
  local f
  n=$((n + 1)); f="$TMP/naec$n.md"
  printf '%s\n' "$1" > "$f"
  case "$(unbacked_enforcement_claims "$f" "$STANDARDS")" in
    '') printf 'honoured' ;;
    *) printf 'not honoured' ;;
  esac
}

sweep_per_line p_naec "$NAEC" 'not-an-enforcement-claim, the enforcement-claim exemption'

# ==============================================================================
# 9 · the three forms nothing reads — N/A, with the reason and the measurement
# ==============================================================================
# A form no gate reads cannot be satisfied by displaying it, so its five cells do
# not exist. The reason is recorded here rather than the cells being left out,
# because a missing cell is how five of these survived.
#
#   scaffold:source-ids   bin/next.sh substitutes it while copying a fenced
#                         skeleton out of a contract. It permits nothing and
#                         satisfies nothing, and it is read from INSIDE a fence on
#                         purpose, which is the opposite of the question here.
#   review:signoff        the same: a marker inside a fenced skeleton.
#   theme:ids             read by nothing at all. define-contract.md declares it
#                         not enforced and CONTROLS.md discloses that.
not_read 'scaffold:'   'no gate reads scaffold:source-ids, so displaying it satisfies nothing'
not_read 'review:'     'no gate reads review:signoff, so displaying it satisfies nothing'
not_read 'theme:ids'   'no gate reads theme:ids, so displaying it satisfies nothing'

# And the two that ARE read from inside a fence still work, or the N/A above is
# hiding a regression in the scaffolder.
assert_contains "$(cat "$ROOT/process/03-define/define-contract.md")" '<!-- scaffold:source-ids -->' \
  'the Define contract still carries the scaffold marker next.sh substitutes'

# ==============================================================================
# 10 · the reading itself, where the loosening sweep found nothing watching
# ==============================================================================
# Five sites in bin/lib-rendering.sh survived a loosening with every suite green, so
# they are pinned here. Each is a line of that file whose repair nothing proved.

# A NESTED `<!--` INSIDE A KEPT COMMENT. HTML comments do not nest, so in
# `<!-- see <!-- declared-empty: x --> -->` the comment a browser ends at the FIRST
# `-->` and everything after it is text. A per-line regex reads the inner part as a
# real declaration unless the second opener is neutralised.
assert_eq 'not honoured' \
  "$(p_discover_open '<!-- an aside about the form, which mentions <!-- declared-empty: a reason --> and stops there -->')" \
  'a declaration nested inside another comment declares nothing'

# A CLOSING FENCE CARRIES NOTHING BUT ITS OWN RUN. Loosening that closes the block at
# the first line that merely starts with the fence character, so the lines below it
# become content again — which is the direction that opens a hole.
assert_eq 'not honoured' \
  "$(p_discover_open "$(printf '```\n```markdown is not a closing fence\n%s\n```\n' "$DECL_EMPTY")")" \
  'a fence is not closed by a line that carries an info string'

# BOTH PROJECTIONS PRESERVE THE LINE COUNT, over a file carrying a multibyte
# character, which is what broke the macOS CI leg: macOS awk under a UTF-8 locale cuts
# inside a multibyte character and aborts, and a 105-line view came back as 5 lines.
MB="$TMP/multibyte.md"
printf '# A record\n\nrests on: none — a reason with an em dash in it\n\nand a line after it.\n' > "$MB"
assert_eq 5 "$(rendered_lines_file "$MB" | awk 'END { print NR }')" \
  'the line projection of a file carrying a multibyte character keeps every line'
assert_eq 5 "$(rendered_spans_file "$MB" | awk 'END { print NR }')" \
  'and so does the span projection'
assert_contains "$(rendered_lines_file "$MB")" 'rests on: none' \
  'and the field on the line with the em dash is still readable'

# AND THE LINE-COUNT GUARD ITSELF REFUSES. It is the thing that turned that abort into
# a refusal instead of a document with every declaration below line 6 missing, so it
# needs a case of its own. Driven by replacing the program the two readers share,
# which is a variable, and putting it back.
_KEEP_AWK="$_RENDERING_AWK"
_RENDERING_AWK='NR <= 2 { print }'
rendered_lines_file "$MB" >/dev/null 2>&1
assert_eq 2 "$?" 'a view with the wrong number of lines is refused rather than returned'
assert_contains "$(rendered_lines_file "$MB" 2>&1 >/dev/null)" 'is not 5 lines' \
  'and the message names how many lines the file holds'
_RENDERING_AWK="$_KEEP_AWK"
assert_eq 5 "$(rendered_lines_file "$MB" | awk 'END { print NR }')" \
  'and the real program is back, so the cases above measured the real one'

# ==============================================================================
# 11 · the denominator, printed
# ==============================================================================
# Fifteen declaration forms, enumerated from the tree rather than from this file, so
# a sixteenth is a failure here rather than a cell nobody wrote.
FORMS_IN_TREE="$(cd "$ROOT" && git grep -hoE '<!-- ?[a-z][a-z-]+:' -- '*.md' '*.sh' \
  | sed -e 's/<!-- *//' -e 's/:$//' | sort -u | grep -v '^end-' | tr '\n' ' ')"
assert_eq \
  'accounting contract corrected-claim corrected-overclaim dead-pointer deciders-table declared-empty declared-not-enforced graded-claims-cite-inline not-a-claim not-a-claim-block not-an-enforcement-claim review scaffold theme ' \
  "$FORMS_IN_TREE" \
  'the tree carries exactly the fifteen declaration forms this suite enumerates'

assert_done
