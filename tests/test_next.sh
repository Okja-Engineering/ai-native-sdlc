#!/usr/bin/env bash
# bin/next.sh scaffolds the next artifact from the contract that declares it.
#
# The load-bearing property is that fields come FROM the contract: add one
# there and the scaffold produces it with no script edit. Without a test for
# that, the script quietly becomes a second copy of each contract's shape,
# which is the duplicate-declaration failure this repository keeps catching.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A tree copy per case. next.sh resolves everything relative to its own root,
# so a copy is the only way to mutate without touching the real tree.
fresh() {
  local t="$TMP/$1"
  rm -rf "$t"; mkdir -p "$t"
  cp -R "$ROOT/process" "$ROOT/bin" "$t/"
  printf '%s' "$t"
}

run() { ( cd "$1" && shift && /bin/bash bin/next.sh "$@" 2>&1 ); }

# --- nothing missing ----------------------------------------------------------
t="$(fresh done)"
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "a complete cycle exits 0"
assert_contains "$out" "Nothing missing" "it says nothing is missing"

# --- a pending decision is called out -----------------------------------------
# These two first asserted against the shipped record while its `chosen:` was
# `pending`, and went red the moment a real decision was made — a test pinned to
# transient data rather than to behaviour. The pending state is now constructed
# here, so the assertion survives the artifact being decided, undecided, or
# superseded.
t="$(fresh pending)"
perl -0pi -e 's/^chosen: .*$/chosen: pending/m' "$t/process/05-deliver/decisions/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"
assert_contains "$out" "AWAITING A HUMAN" "it names a decision still waiting"
assert_contains "$out" "not mine to write" "it says the decision is not its to make"

t="$(fresh decided)"
perl -0pi -e 's/^chosen: .*$/chosen: F/m' "$t/process/05-deliver/decisions/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"
assert_not_contains "$out" "AWAITING A HUMAN" "a decided record is not reported as waiting"

# --- scaffolds define ---------------------------------------------------------
t="$(fresh define)"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
out="$(run "$t" 2026-09-29)"; rc=$?
assert_status 0 "$rc" "scaffolding define exits 0"
assert_contains "$out" "wrote process/03-define/cycles/2026-09-29.md" "it says what it wrote"

made="$t/process/03-define/cycles/2026-09-29.md"
assert_file_exists "$made" "the define skeleton exists"
assert_contains "$(cat "$made")" "method:" "it carries the method field the contract requires"
assert_contains "$(cat "$made")" "## Themes" "it carries the required sections"
assert_contains "$(cat "$made")" "-->" "the hint comment is closed"

# --- the property that matters ------------------------------------------------
t="$(fresh contract)"
perl -0pi -e 's/\| `method` \|/| `reviewed_by` | who checked the grouping |\n| `method` |/' \
  "$t/process/03-define/define-contract.md"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
assert_contains "$(cat "$t/process/03-define/cycles/2026-09-29.md")" "reviewed_by:" \
  "a field added to the contract appears in the scaffold, with no script edit"

# --- a problem is scaffolded from a PROBLEM's declaration ---------------------
# The problem skeleton was emitted from the cycle's field list, because the
# contract declared one table for two different artifacts. So a scaffolded
# problem carried `method:` — how a grouping was produced, which says nothing
# about a problem — and never carried `rests on:`, the field that links it to the
# Discover topic it was stated from. The Discover-to-Define edge was in no
# contract and no scaffold.
t="$(fresh problem)"
rm -f "$t/process/03-define/problems/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "scaffolding a problem exits 0"

made="$t/process/03-define/problems/producing-themes.md"
assert_file_exists "$made" "the problem skeleton exists"
assert_contains "$(cat "$made")" "rests on:" "it carries the rests on: field a problem's contract declares"
assert_not_contains "$(cat "$made")" "method:" "and not the cycle's method:, which says nothing about a problem"

# The same property as above, for the problem's own table: the contract is the
# single declaration of a problem's shape. Two words on purpose — `rests on` has
# a space in it, and a field list read by word splitting would break on that.
t="$(fresh problem-contract)"
perl -0pi -e 's/\| `rests on` \|/| `checked by` | who read the topic |\n| `rests on` |/' \
  "$t/process/03-define/define-contract.md"
rm -f "$t/process/03-define/problems/producing-themes.md"
run "$t" 2026-09-29 producing-themes >/dev/null
assert_contains "$(cat "$t/process/03-define/problems/producing-themes.md")" "checked by:" \
  "a field added to the problem's table appears in the problem scaffold, with no script edit"

# And the two declarations stay apart. One contract now declares fields for two
# artifacts, so a scaffold has to read the table its own artifact declares
# whatever order the contract lists them in. The tables are swapped here for that
# reason: with the problem's table first, a heading matched as a prefix hands the
# cycle the problem's fields, and asserting this against the shipped order would
# pass either way.
t="$(fresh split)"
perl -0777 -pi -e 's/(## Required fields\n.*?)(## Required fields — a problem\n.*?)(## Required sections\n)/$2$1$3/s' \
  "$t/process/03-define/define-contract.md"
assert_eq "## Required fields — a problem" \
  "$(grep -m1 '^## Required fields' "$t/process/03-define/define-contract.md")" \
  "the fixture really did put the problem's table first"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
rm -f "$t/process/03-define/problems/producing-themes.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
assert_contains "$(cat "$made")" "method:" "a cycle skeleton still carries the cycle's fields"
assert_not_contains "$(cat "$made")" "rests on:" "and does not inherit the problem's"
run "$t" 2026-09-29 producing-themes >/dev/null
made="$t/process/03-define/problems/producing-themes.md"
assert_contains "$(cat "$made")" "rests on:" "a problem skeleton still carries the problem's fields"
assert_not_contains "$(cat "$made")" "method:" "and does not inherit the cycle's"

# --- it does not touch a complete cycle ---------------------------------------
# `write_once`'s refusal is defensive: the phase chain only calls it when the
# file is absent, so no invocation reaches it. Asserting on that refusal passed
# with the guard deleted — vacuous. What is reachable, and what actually matters
# to someone running this over work in progress, is that a complete cycle comes
# back byte-identical.
t="$(fresh untouched)"
before="$(cd "$t" && find process -type f -exec cksum {} + | sort)"
run "$t" 2026-09-29 producing-themes >/dev/null
after="$(cd "$t" && find process -type f -exec cksum {} + | sort)"
assert_eq "$before" "$after" "a complete cycle is left byte-identical"

# --- the scaffold produces every structural input the gate reads ---------------
# A scaffolded cycle carried no `<!-- accounting:ids -->` block, because
# define-contract.md declared that block as a worked example rather than as a
# field or a section, and the scaffold reads fields and sections. So the gate
# refused its own skeleton with `no-accounting` — the one input it depends on
# most.
#
# The invariant is NOT that a skeleton passes the gate. It cannot, and should not:
# `method` is a person's declaration of how the themes were produced, the themes
# are the work itself, and an empty outlier list has to say it is empty, which is
# also a claim. Scaffolding those would be inventing them, which is the same
# reason this script refuses to scaffold a problem without a human's pick.
#
# What is testable, and what actually matters, is the split: every refusal left on
# a fresh skeleton names content a person must write, and none of them names
# structure the scaffold should have produced.
t="$(fresh scaffold_gate)"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
out="$(/bin/bash "$ROOT/process/03-define/validate-define.sh" "$made" 2>&1)"

codes="$(printf '%s\n' "$out" | sed -n 's/.*refuse\[\([a-z-]*\)\].*/\1/p' | sort | tr '\n' ' ')"
assert_eq "counts-disagree no-method silent-empty-outliers " "$codes" \
  "the only refusals left on a fresh skeleton are the ones naming unwritten content"

# Spelled out as well as compared as a set, because the set assertion above would
# also pass if the gate stopped emitting a structural refusal altogether.
assert_not_contains "$out" "refuse[no-accounting]" "the skeleton carries an accounting block"
assert_contains "$(cat "$made")" "<!-- accounting:ids -->" "and the block's markers come from the contract"
assert_not_contains "$(cat "$made")" "scaffold:source-ids" "the placeholder was substituted, not copied"

# The ids in the block are the ids the source records, read through the same
# harvester the gate reads. Compared, not written literally.
block="$(sed -n '/accounting:ids -->/,/\/accounting:ids -->/p' "$made" \
  | grep -oE 'F[0-9]+' | sort | tr '\n' ' ')"
want="$(/bin/bash "$ROOT/process/01-scan/findings-ids.sh" "$t/process/01-scan/findings/2026-09-29.md" \
  | sort | tr '\n' ' ')"
assert_eq "$want" "$block" "the block accounts for exactly the ids the source records"
[ -n "$want" ] && any=yes || any=no
assert_eq "yes" "$any" "and that comparison ran against a non-empty set"

# The sections come out in the order the contract lists them, so a cycle file is
# comparable with the next one.
assert_eq "Themes Outliers Accounting Where" \
  "$(grep '^## ' "$made" | sed -e 's/^## //' -e 's/ .*//' | tr '\n' ' ' | sed 's/ *$//')" \
  "the sections are in the order the contract declares"

# --- a skeleton is declared by the contract, not by this script ----------------
# The same property the field case below asserts, for a section that carries a
# literal shape. A contract that declares one gets it scaffolded; one that does
# not gets *To be written.*
t="$(fresh skeleton)"
perl -0pi -e 's/^### Where this stops$/### Reviewed\n\n```markdown\n<!-- review:signoff -->\n<!-- \/review:signoff -->\n```\n\n### Where this stops/m' \
  "$t/process/03-define/define-contract.md"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
assert_contains "$(cat "$made")" "<!-- review:signoff -->" \
  "a section skeleton added to the contract appears in the scaffold, with no script edit"
assert_contains "$(cat "$made")" "*To be written.*" \
  "and a section declaring no skeleton still gets the placeholder"

# --- a problem is a human's pick ---------------------------------------------
t="$(fresh pick)"
rm -f "$t"/process/03-define/problems/*.md
out="$(run "$t" 2026-09-29)"; rc=$?
assert_status 0 "$rc" "no problem yet exits 0"
assert_contains "$out" "The next step is yours" "it hands the pick back to a person"
assert_contains "$out" "would be inventing the pick" "it says why it will not scaffold one"

# --- and it is a pick per cycle ----------------------------------------------
# next.sh:95 counted `problems/*.md` across every cycle, so from the second cycle
# onward the count was never zero and the hand-back above could never be reached.
# A second cycle was instead offered the FIRST cycle's problems to continue, which
# is a different cycle's work. bin/cycle.sh already filters problems by the cycle
# their own `from:` names; this reads the same linkage.
t="$(fresh second_cycle)"
sed 's/^since: first run$/since: 2026-09-29/' \
  "$t/process/01-scan/findings/2026-09-29.md" > "$t/process/01-scan/findings/2026-11-01.md"
sed 's|findings/2026-09-29|findings/2026-11-01|g' \
  "$t/process/03-define/cycles/2026-09-29.md" > "$t/process/03-define/cycles/2026-11-01.md"
out="$(run "$t" 2026-11-01)"; rc=$?
assert_status 0 "$rc" "a second cycle with no problem of its own exits 0"
assert_contains "$out" "The next step is yours" "and the pick is handed back for THAT cycle"
assert_not_contains "$out" "producing-themes" "the first cycle's problems are not offered to continue"

# The first cycle still sees its own, so the filter did not simply stop finding
# anything.
out="$(run "$t" 2026-09-29)"
assert_contains "$out" "producing-themes" "the cycle that owns a problem still lists it"
assert_contains "$out" "Several problems exist" "and is asked which one"

# And once the second cycle has a problem of its own, the list it is offered is
# its own and not the other cycle's. Counting and listing are two places the same
# filter has to be applied, and the count alone passing proved nothing about the
# list.
sed 's|cycles/2026-09-29|cycles/2026-11-01|g' \
  "$t/process/03-define/problems/producing-themes.md" > "$t/process/03-define/problems/cadence.md"
out="$(run "$t" 2026-11-01)"
assert_contains "$out" "cadence" "the second cycle is offered its own problem"
assert_not_contains "$out" "producing-themes" "and not the first cycle's"
assert_not_contains "$out" "agent-pr-approval" "nor the first cycle's other one"

# --- the count it writes is the count the source records ----------------------
# next.sh:83 was `rows=$(grep -cE '^| [A-Z]' "$findings")` — the exact expression
# define-contract.md names as the one an external audit defeated, still writing
# the `from: ..., N findings` line of every new cycle. Two things are wrong with
# it: the case of a finding's first letter decides whether it counts, and it reads
# the whole file, so any markdown table counts. findings-contract.md permits
# content in `## Looked at`, and the fixture below is a contract-valid file with
# two findings and one decoy table there. It reported five.
#
# The count is not written literally here. It is compared against the harvester,
# which is the thing that decides what a finding is, and against the raw row count
# it must NOT be — so a regression to counting rows fails rather than passing on a
# fixture that happens to agree.
t="$(fresh decoy)"
rm -f "$t"/process/01-scan/findings/*.md "$t"/process/03-define/cycles/*.md
DECOY="$t/process/01-scan/findings/2026-10-04.md"
{
  printf '# Scan cycle — 2026-10-04\n\nsince: 2026-09-29\nnothing found: no\n\n'
  printf '## Looked at\n\n'
  printf -- '- web: release notes and preprints, 2026-09-29 to 2026-10-04.\n'
  printf -- '- X: the syndication endpoint only, 2026-09-29 to 2026-10-04.\n'
  printf -- '- YouTube: channel feeds, 2026-09-29 to 2026-10-04.\n\n'
  printf 'The ground each agent could not reach, as a table:\n\n'
  printf '| id | what |\n|---|---|\n| F91 | a decoy row |\n| F92 | another decoy row |\n\n'
  printf '## Findings\n\n'
  printf '| id | what | source | dated | kind | might affect (guess) | consequence guess |\n'
  printf '|---|---|---|---|---|---|---|\n'
  printf '| F01 | A thing happened | https://example.com/a | 2026-09-30 | practice-change | build (guess) | low |\n'
  printf '| F02 | another thing happened | https://example.com/b | 2026-10-01 | practice-change | build (guess) | low |\n'
} > "$DECOY"

out="$(/bin/bash "$ROOT/process/01-scan/validate-findings.sh" "$DECOY" 2>&1)"; rc=$?
assert_status 0 "$rc" "the decoy fixture is within the stage 1 contract, so nothing there refuses it"

run "$t" 2026-10-04 >/dev/null
made="$t/process/03-define/cycles/2026-10-04.md"
wrote="$(sed -n 's/^from:.*,[[:space:]]*\([0-9][0-9]*\)[[:space:]]*findings.*/\1/p' "$made" | head -1)"
want="$(/bin/bash "$ROOT/process/01-scan/findings-ids.sh" "$DECOY" | grep -c .)"
raw="$(grep -cE '^\| ' "$DECOY")"
assert_eq "$want" "$wrote" "the count it writes is the number of findings the source records"
[ "$wrote" = "$raw" ] && same=yes || same=no
assert_eq "no" "$same" "and it is not the number of table rows in the file (which is $raw)"

# The scaffold and the gate have to agree about the count, or the first thing a
# person does with a new cycle is argue with a refusal the scaffold caused.
out="$(/bin/bash "$ROOT/process/03-define/validate-define.sh" "$made" 2>&1)"
assert_not_contains "$out" "refuse[declared-count]" \
  "the gate does not refuse the count the scaffold wrote"
assert_not_contains "$out" "refuse[no-declared-count]" \
  "and the scaffold did write one"

# --- a cycle starts with a scan ----------------------------------------------
t="$(fresh noscan)"
out="$(run "$t" 2099-01-01)"; rc=$?
assert_status 2 "$rc" "an unknown cycle exits 2"
assert_contains "$out" "a cycle starts with a scan" "it says what is missing"

# --- a skeleton may contain a markdown heading -------------------------------
# skeleton() ended a section at the next `## ` or `### ` line WITHOUT asking
# whether that line was inside a fence, and sections() read `### ` out of the
# Required sections range the same way. So a contract could not declare a
# skeleton that contains a heading — the scaffold truncated it at the heading,
# and sections() read the heading as the name of another required section.
#
# That is the shape every per-theme structure needs, because a theme IS a
# heading. Asserted on a constructed contract rather than on the shipped theme
# skeleton, so this survives that skeleton being rewritten.
t="$(fresh fenced_heading)"
perl -0pi -e 's/^### Where this stops$/### Reviewed\n\n```markdown\n### N \xc2\xb7 a heading inside a fence\n**N findings**\n\n<!-- review:signoff -->\n<!-- \/review:signoff -->\n```\n\n### Where this stops/m' \
  "$t/process/03-define/define-contract.md"
assert_contains "$(cat "$t/process/03-define/define-contract.md")" "a heading inside a fence" \
  "the fixture really did add a skeleton containing a heading"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
assert_contains "$(grep '^### ' "$made")" "a heading inside a fence" \
  "a declared skeleton is emitted whole, heading included, at the level it was written"
assert_contains "$(cat "$made")" "<!-- review:signoff -->" \
  "and the part below that heading is not truncated away"
assert_not_contains "$(grep '^## ' "$made")" "a heading inside a fence" \
  "a heading inside a fence is not read as a required section of its own"

# --- a cycle records what the convergence pass cost ---------------------------
# Decision F commits to two more cycles and to recording the pass duration, and
# no artifact had anywhere to put it. The field name is read OUT OF the contract
# rather than written here twice: the contract is the single declaration of a
# cycle's shape, and what this asserts is that the declaration reaches the
# scaffold.
contract="$ROOT/process/03-define/define-contract.md"
dur="$(sed -n '/^## Required fields$/,/^## /p' "$contract" \
  | sed -n 's/^| `\([a-z_ ]*\)` *|.*convergence pass took.*/\1/p' | head -1)"
assert_eq "pass took" "$dur" \
  "the cycle's own field table declares a field for how long the convergence pass took"
# An empty `$dur` would make every assertion below it pass against nothing, which
# is the vacuous-fixture failure tests/lib/mutate.sh exists for.
[ -n "$dur" ] && any=yes || any=no
assert_eq "yes" "$any" "and the field name was read from the contract, not assumed"

t="$(fresh duration)"
rm -f "$t/process/03-define/cycles/2026-09-29.md"
run "$t" 2026-09-29 >/dev/null
made="$t/process/03-define/cycles/2026-09-29.md"
assert_contains "$(cat "$made")" "$dur:" \
  "and a scaffolded cycle carries it, so the next pass has somewhere to write it"

# --- and the scaffold produces a theme's own ids ------------------------------
# define-contract.md has required this since 2026-10-03 — "From the next cycle,
# each theme lists its own ids" — and nothing produced the structure, so the
# requirement came into force against a skeleton that could not meet it. The
# marker is read out of the contract for the same reason as the field above.
marker="$(awk '
  /^### Themes$/ { on = 1; next }
  /^[ \t]*(```|~~~)/ { fence = !fence }
  on && !fence && /^### / { exit }
  on' "$contract" | sed -n 's/.*\(<!-- theme:ids -->\).*/\1/p' | head -1)"
assert_eq "<!-- theme:ids -->" "$marker" \
  "the Themes section declares a block for a theme's own ids"
[ -n "$marker" ] && any=yes || any=no
assert_eq "yes" "$any" "and the marker was read from the contract, not assumed"
assert_contains "$(cat "$made")" "$marker" \
  "and a scaffolded cycle carries it"
# --- a decision carries an expiry --------------------------------------------
# The only open decision in the repository expires on a date that lived in one
# prose sentence. Six required fields and none of them was an expiry or a review
# date, so nothing could read the condition the decision set for itself.
#
# The field name is read OUT OF the Deliver contract rather than written twice.
# What this asserts is the chain: the contract declares it, the scaffold produces
# it, and bin/next.sh needed no edit for either.
deliver="$ROOT/process/05-deliver/deliver-contract.md"
exp="$(sed -n '/^## Required fields$/,/^## /p' "$deliver" \
  | sed -n 's/^| `\([a-z_ ]*\)` *|.*when this decision expires.*/\1/p' | head -1)"
assert_eq "expires" "$exp" "a decision's field table declares when the decision expires"
[ -n "$exp" ] && any=yes || any=no
assert_eq "yes" "$any" "and the field name was read from the contract, not assumed"

t="$(fresh expiry)"
rm -f "$t/process/05-deliver/decisions/producing-themes.md"
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "scaffolding a decision exits 0"
made="$t/process/05-deliver/decisions/producing-themes.md"
assert_file_exists "$made" "the decision skeleton exists"
assert_contains "$(cat "$made")" "$exp:" \
  "and it carries the expiry field, so a decision has somewhere to set its own tripwire"

# --- an artifact belongs to a (cycle, slug), not to a slug ----------------------
# The three artifact paths were keyed on the slug alone, so with a second cycle on disk
# `bin/next.sh <new-cycle> <existing-slug>` reported "Nothing missing" because cycle
# one's problem, options and decision satisfied the chain. `bin/cycle.sh` reported
# `problems 0 stated` for the same cycle at the same moment, so the two tools
# contradicted each other and the one a person follows was the wrong one.
#
# This is the normal path. `define-contract.md` contemplates a theme recurring as the
# same theme, and the `producing-themes` decision schedules a successor for 2026-11-30 —
# which was unrepresentable for the same reason.
#
# Built, not reasoned about: neither defect is reachable at n=1.
. "$TEST_DIR/lib/define-fixture.sh"

second_cycle() { # <name> -> tree with a second cycle and its quiet scan
  local t; t="$(fresh "$1")"
  define_fixture "$t" "" 0 >/dev/null
  printf '%s' "$t"
}

t="$(second_cycle recur)"
assert_file_exists "$t/process/03-define/cycles/2026-12-01.md" "the tree now holds a second cycle"
assert_file_exists "$t/process/03-define/problems/agent-pr-approval.md" \
  "and cycle one's problem for that slug is still there"

# The two tools have to agree, which is the assertion that stops them diverging again.
# `cycle.sh` is read BEFORE `next.sh` runs, because next.sh writes: reading it after
# would be comparing the two tools across a change to the tree.
cyc_out="$( cd "$t" && /bin/bash bin/cycle.sh 2>&1 )"
section="$(printf '%s\n' "$cyc_out" | awk '/^2026-12-01$/ { i = 1; next } i && /^[0-9]{4}-/ { exit } i')"
assert_contains "$section" "problems  0 stated" \
  "bin/cycle.sh reports no problem stated for the second cycle"

out="$(run "$t" 2026-12-01 agent-pr-approval)"; rc=$?
assert_not_contains "$out" "Nothing missing" \
  "a slug whose artifacts belong to another cycle is not complete for this one"
assert_not_contains "$out" "Nothing missing" \
  "so bin/next.sh agrees with bin/cycle.sh rather than contradicting it"

# And it produces the artifact, qualified by the cycle so it cannot collide.
made="$t/process/03-define/problems/2026-12-01.agent-pr-approval.md"
assert_file_exists "$made" "the recurrence is written under a cycle-qualified name"
assert_contains "$(cat "$made")" "cycles/2026-12-01.md" "and its from: names the cycle it belongs to"
assert_contains "$(cat "$t/process/03-define/problems/agent-pr-approval.md")" "cycles/2026-09-29.md" \
  "while cycle one's problem is left exactly as it was"

# Then the chain continues within the cycle: options and decision resolve from THIS
# problem, not from a file that happens to share the slug.
out="$(run "$t" 2026-12-01 agent-pr-approval)"
assert_file_exists "$t/process/04-develop/options/2026-12-01.agent-pr-approval.md" \
  "the options set for the recurrence is written too"
assert_contains "$(cat "$t/process/04-develop/options/2026-12-01.agent-pr-approval.md")" \
  "problems/2026-12-01.agent-pr-approval.md" "and it names this cycle's problem"
out="$(run "$t" 2026-12-01 agent-pr-approval)"
assert_file_exists "$t/process/05-deliver/decisions/2026-12-01.agent-pr-approval.md" \
  "and so is the decision"
out="$(run "$t" 2026-12-01 agent-pr-approval)"; rc=$?
assert_status 0 "$rc" "once the chain is complete for this cycle it exits 0"
assert_contains "$out" "Nothing missing" "and says so"
assert_contains "$out" "2026-12-01.agent-pr-approval.md" \
  "naming the files it read, so a reader can see which cycle satisfied it"

# The first cycle is unaffected: its own chain still reads as complete.
out="$(run "$t" 2026-09-29 producing-themes)"; rc=$?
assert_status 0 "$rc" "the first cycle is still complete"
assert_contains "$out" "Nothing missing" "and still says so"

# A slug that exists for no cycle keeps the PLAIN name. The qualifier is added only
# when it is needed to say which of two things this is, so nothing in the tree is
# renamed and a first occurrence reads the way the two shipped problems do.
t="$(second_cycle newslug)"
out="$(run "$t" 2026-12-01 brand-new-theme)"
assert_file_exists "$t/process/03-define/problems/brand-new-theme.md" \
  "a slug new to the tree is written under its plain name"
assert_eq "0" "$(ls "$t"/process/03-define/problems/2026-12-01.brand-new-theme.md 2>/dev/null | grep -c .)" \
  "and not under a cycle-qualified one"

# And asking for the other cycle's slug does not resolve to it. Found by attacking the
# repaired resolution: matching the cycle alone returns whichever of that cycle's
# problems sorts first, which is a different wrong answer from the one being fixed.
t="$(second_cycle crossslug)"
out="$(run "$t" 2026-09-29 producing-themes)"
assert_contains "$out" "problems/producing-themes.md" \
  "a request for one slug resolves to that slug and not to a sibling of the same cycle"
assert_not_contains "$out" "problems/agent-pr-approval.md" \
  "which is a different wrong answer from the one this replaces"

assert_done
