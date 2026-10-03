#!/usr/bin/env bash
# STANDARDS.md must cite something a reader of this repository can open.
#
# The audit in #22 found 31 graded claims and zero citations, with the only
# route to evidence being a branch that does not exist. This suite is what stops
# that recurring.
#
# NOTE ON METHOD, carried from #29. That finding was that a gate's tests asserted
# the three literal strings its regex was written for, which proved the allowlist
# contained three words and not that the invariant held. So these cases are
# written against the invariant — "a graded claim resolves to something openable"
# — and include inputs chosen to be outside what the implementation obviously
# handles, not just the ones it was built for.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/bin/validate-standards.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A copy per case. The gate checks refs against the repository it is in, so the
# copy keeps .git — otherwise the dangling-ref check has nothing to resolve
# against and would pass everything.
fresh() {
  local t="$TMP/$1"; rm -rf "$t"; mkdir -p "$t"
  cp "$ROOT/STANDARDS.md" "$ROOT/SOURCES.md" "$ROOT/README.md" "$t/"
  mkdir -p "$t/bin" && cp "$GATE" "$t/bin/"
  ( cd "$t" && git init -q . && git commit -q --allow-empty -m init ) 2>/dev/null
  printf '%s' "$t"
}
gate() { ( cd "$1" && bash bin/validate-standards.sh 2>&1 ); }

# --- the shipped documents pass -----------------------------------------------
t="$(fresh base)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "the shipped STANDARDS.md and register are within the contract"
assert_contains "$out" "cited and resolving" "it says they resolve"

# --- an uncited graded claim --------------------------------------------------
t="$(fresh uncited)"
printf '\n**[E]** Teams that adopt this ship better software.\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "an uncited graded claim exits 1"
assert_contains "$out" "refuse[uncited-claim]" "the refusal is uncited-claim"
assert_contains "$out" "an assertion wearing a label" "the message says what an uncited grade is"

# The invariant, not the literal: a [S] claim must also be caught, and so must a
# combined grade. The implementation handles these by separate patterns, which is
# exactly the kind of thing that works for the cases its author listed.
t="$(fresh uncited_s)"
printf '\n**[S]** NIST requires this.\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "an uncited [S] claim is refused too"

t="$(fresh uncited_combo)"
printf '\nSomething is true. **[E]/[S]** because of reasons.\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "an uncited combined grade is refused"

# Markup does not exempt a line. The gate used to skip anything beginning `|` or
# `> ` and to match only four marker forms, so a bare `[E]`, a table row and a
# blockquote all passed uncited — and a bare marker is this repository's own
# house style for a graded claim, which both discovery topics and AGENTS.md use.
#
# The forms below are deliberately NOT the four from the finding. They are
# chosen to sit outside whatever an implementation would obviously handle: a
# nested blockquote, a list item, a heading, a grade in a table's second cell, an
# indented line, bold-italic, and the backticked bare marker the rest of the
# repository writes. The invariant is that markdown around a grade marker does
# not decide whether the sentence is a claim. A rewrite that strips markup some
# other way still passes this.
i=0
while IFS= read -r form; do
  i=$((i + 1))
  t="$(fresh "markup$i")"
  printf '\n%s\n' "$form" >> "$t/STANDARDS.md"
  out="$(gate "$t")"; rc=$?
  assert_status 1 "$rc" "an uncited claim written as: $form"
  assert_contains "$out" "refuse[uncited-claim]" "and the refusal is uncited-claim, not a pass"
done <<'FORMS'
Agents never hallucinate in production. `[E]`
>> **[E]** Agents never hallucinate in production.
- Agents never hallucinate in production. [E]
### [S] Agents never hallucinate in production
    Agents never hallucinate in production. [E]
***[E]*** Agents never hallucinate in production.
FORMS

# A table row with the grade in the second cell rather than the first.
t="$(fresh markuprow)"
printf '\n| Agents never hallucinate in production. | **[E]** |\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a table row with the grade in the second cell is not exempt"
assert_contains "$out" "refuse[uncited-claim]" "the refusal is uncited-claim"

# --- an exemption has to be declared, and has to say why ----------------------
# Some lines carry a grade marker and do not grade anything: the table that
# declares what each grade means, and a sentence about the scheme rather than
# graded by it. Those are declared in band with a reason, which is greppable and
# reviewable, where the old skip-by-first-character was silent.
t="$(fresh exempt_ok)"
printf '\nThe grade `[E]` is the strongest one. <!-- not-a-claim: names the marker, does not use it -->\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a line declared not a claim, with a reason, is accepted"
assert_contains "$out" "declared not a claim" "the summary reports how many exemptions are declared"

# A marker with no reason is not a declaration, so the line is still checked.
# Otherwise the exemption is an unconditional escape hatch again.
t="$(fresh exempt_bare)"
printf '\nThe grade `[E]` is the strongest one. <!-- not-a-claim: -->\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "an exemption with no reason does not exempt"

# The sharpest pair: the SAME table row, inside the declared block and outside
# it. The grade key is a table and must not be read as a pile of uncited claims;
# an identical row appended elsewhere is a claim. Identical markup, and the
# declaration is what differs.
t="$(fresh exempt_block)"
printf '\n<!-- not-a-claim-block: these rows declare what a grade means -->\n| **[E]** | Empirical, something |\n<!-- end-not-a-claim-block -->\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a row inside a declared not-a-claim block is accepted"

t="$(fresh exempt_outside)"
printf '\n| **[E]** | Empirical, something |\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "the same row outside the block is refused"

# The block form needs a reason for the same reason the line form does. Found by
# mutating the block rule rather than the line rule: dropping the reason from one
# of them failed a test and dropping it from the other failed none.
t="$(fresh exempt_block_bare)"
printf '\n<!-- not-a-claim-block: -->\n| **[E]** | Empirical, something |\n<!-- end-not-a-claim-block -->\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "a block exemption with no reason does not open a block"

# A cited claim in any of those forms must still pass, or the gate is refusing
# markup rather than reading grades.
t="$(fresh cited_bare)"
printf '\nAgents are reviewed by people. `[E]` `S-NBER-2026-01`\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a bare-marker claim that cites a source is accepted"

# --- a citation that resolves to nothing -------------------------------------
t="$(fresh unknown)"
perl -0pi -e 's/`S-NBER-2026-01`/`S-INVENTED-9999-01`/' "$t/STANDARDS.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[unknown-source]" "a citation absent from the register is refused"
assert_contains "$out" "reads as evidence" "the message says why a dangling citation is worse than none"

# A TRUNCATED id must also be refused. Found by the #29 mutation sweep: swapping
# the exact match for a substring match caused zero test failures, so the suite
# did not pin exactness — the same defect #29 exists for, in a gate written an
# hour before. `S-NBER` is a prefix of a real id and is not an id.
t="$(fresh trunc_prefix)"
perl -0pi -e 's/`S-NBER-2026-01`/`S-NBER`/' "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[unknown-source]" "a truncated id that is still well-formed is refused"

# A MALFORMED id is not a citation at all, so the right refusal is uncited-claim.
# Both of these were initially asserted as unknown-source and were wrong — the
# gate was right and the test was not. `S-` exposed a real hole on the way: the
# uncited check tested for the substring '`S-' rather than a well-formed id, so
# `S-` satisfied "has a citation" while being extracted as none, and NEITHER
# refusal fired. Fixed in the gate; these pin it.
for malformed in 'NBER-2026-01' 'S-'; do
  t="$(fresh "mal$(printf '%s' "$malformed" | tr -dc 'A-Za-z')")"
  perl -0pi -e "s/\`S-NBER-2026-01\`/\`$malformed\`/" "$t/STANDARDS.md"
  assert_contains "$(gate "$t")" "refuse[uncited-claim]" "a malformed id '$malformed' leaves the claim uncited"
done

# --- a register entry with nothing to open -----------------------------------
t="$(fresh nolink)"
perl -0pi -e 's{\| `S-SPACE-2021-01` \| SPACE — \[queue\.acm\.org\]\(https://queue\.acm\.org/detail\.cfm\?id=3454124\)}{| `S-SPACE-2021-01` | SPACE, the well-known paper}' "$t/SOURCES.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[source-no-link]" "a register entry with no link is refused"
assert_contains "$out" "a name, not a source" "the message says what a linkless entry is"

# --- the register is missing altogether --------------------------------------
t="$(fresh noreg)"; rm -f "$t/SOURCES.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a missing register exits 1"
assert_contains "$out" "refuse[no-register]" "the refusal is no-register"

# --- a reference to a ref that does not exist --------------------------------
# The specific defect: three files pointed at `experiment/0.0.0` as the route to
# the sources, and it was never a ref.
t="$(fresh dangling)"
printf '\nThe corpus is preserved on `experiment/0.0.0`.\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[dangling-ref]" "a reference to a non-existent ref is refused"
assert_contains "$out" "no reachable evidence" "the message names the defect it is guarding"

# Naming the ref in order to say it does not exist must NOT be refused, or the
# document cannot record its own history.
t="$(fresh dangling_ok)"
printf '\n`experiment/0.0.0` was referenced here and does not exist on origin.\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "naming a dead ref to say it is dead is accepted"

# --- uncited register entries are reported, not refused ----------------------
# The first version of this gate refused them, which would have forced deleting
# real sources or attaching them to claims they do not support.
t="$(fresh orphan)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "register entries nothing cites do not fail the gate"
assert_contains "$out" "not currently cited" "they are reported in the summary instead"

# --- the grade key table is not a claim --------------------------------------
# It carries [E] and [S] markers and must not be read as uncited claims, or the
# gate refuses its own document for existing. The key sits inside a declared
# not-a-claim block, so what is checked is that the declaration is honoured. The
# previous version asserted the string "line 9", which went stale as soon as
# anything above line 9 moved and then passed for the wrong reason.
t="$(fresh key)"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "the shipped document, grade key included, is within the contract"

# And the key rows are exempt because they are DECLARED, not because they are a
# table. Strip the declarations out and the gate reads them as claims.
t="$(fresh key_undeclared)"
grep -v 'not-a-claim' "$t/STANDARDS.md" > "$t/S.tmp" && mv "$t/S.tmp" "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[uncited-claim]" "with the declarations removed, the key rows are read as claims"

assert_done
