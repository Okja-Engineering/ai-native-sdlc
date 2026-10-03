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

# A copy per case. The gate checks evidence pointers against the repository it is
# in, so the copy is a repository — otherwise the check has nothing to resolve
# against and would pass everything.
#
# It has no refs of its own, so a dangling BRANCH reference still dangles. It
# borrows the real repository's objects, so a COMMIT the documents cite does
# resolve. Without the alternate every cited commit would look dead in here and
# the fixture would prove the opposite of what it is for.
# One template repository, copied per case.
#
# It holds the whole working tree, not four files: the documents cite paths in
# it, and a gate that checks a document points at something openable has to be
# able to see those paths. A four-file copy reported every linked script as
# unreachable, which was the fixture lying rather than the gate.
#
# It has no refs of its own, so a dangling BRANCH reference still dangles. It
# borrows the real repository's objects, so a COMMIT the documents cite does
# resolve. Without the alternate every cited commit would look dead in here and
# the fixture would prove the opposite of what it is for.
#
# Built once rather than per case, because the cases differ only in the documents
# and rebuilding it each time was most of this suite's runtime.
TEMPLATE="$TMP/_template"
mkdir -p "$TEMPLATE"
( cd "$ROOT" && tar cf - --exclude .git . ) | ( cd "$TEMPLATE" && tar xf - )
( cd "$TEMPLATE" && git init -q . \
  && printf '%s/objects\n' "$(git -C "$ROOT" rev-parse --absolute-git-dir)" \
       > .git/objects/info/alternates \
  && git commit -q --allow-empty -m init ) 2>/dev/null

fresh() {
  local t="$TMP/$1"; rm -rf "$t"
  cp -R "$TEMPLATE" "$t"
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
# document cannot record its own history. The exemption is DECLARED and names the
# pointer it covers.
t="$(fresh dangling_ok)"
printf '\n`experiment/0.0.0` was referenced here and does not exist on origin. <!-- dead-pointer: experiment/0.0.0 — recorded as dead, not offered as a route -->\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a declared dead pointer is accepted"

# The exemption is per POINTER, not per line. A line that records one pointer as
# dead must not exempt a second pointer beside it — `SOURCES.md` has exactly such
# a sentence, naming the dead branch and the live commit together, and the
# previous phrase match exempted both.
t="$(fresh dangling_scope)"
printf '\n`experiment/0.0.0` is dead and `archive/9.9.9` is the new home. <!-- dead-pointer: experiment/0.0.0 — recorded as dead -->\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a second pointer on a line with a declaration is still checked"
assert_contains "$out" 'archive/9.9.9' "the refusal names the pointer that was not declared"

# A declaration carrying nothing but the pointer records no reason, so it does
# not exempt. Otherwise it is a switch rather than a statement.
t="$(fresh dangling_noreason)"
printf '\nThe corpus is on `archive/0.0.0`. <!-- dead-pointer: archive/0.0.0 -->\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[dangling-ref]" "a declaration with no reason does not exempt"

# Prose that says a pointer is dead, without declaring it, no longer exempts it.
# The four phrases the gate used to match were a guess at what a sentence meant.
t="$(fresh dangling_prose)"
printf '\n`archive/0.0.0` does not exist and never did.\n' >> "$t/STANDARDS.md"
assert_contains "$(gate "$t")" "refuse[dangling-ref]" "prose saying a pointer is dead does not exempt it"

# --- a cited commit is an evidence pointer too --------------------------------
# The check matched backtick-quoted strings beginning `experiment/` or `branch/`
# — the two namespaces the one known defect happened to use. The pointer this
# repository now depends on is a COMMIT: the research corpus is in history and
# not on any branch, and `DECIDERS.md` records that the planned identity cleanup
# rewrites every SHA. Replacing the commit with a dead one left the gate
# reporting the documents clean.
#
# The cases below are written against the invariant — a pointer into git that
# the clone cannot resolve is refused — rather than against a namespace list.
for dead in \
  'The corpus is in history at `deadbee`.' \
  'The corpus is in history at `0123456789abcdef0123456789abcdef01234567`.' \
  'The corpus is preserved on `archive/0.0.0`.' \
  'The corpus is preserved on `refs/notes/corpus`.'
do
  t="$(fresh "dead$(printf '%s' "$dead" | tr -dc 'a-z' | cut -c1-14)")"
  printf '\n%s\n' "$dead" >> "$t/STANDARDS.md"
  out="$(gate "$t")"; rc=$?
  assert_status 1 "$rc" "an unresolvable pointer exits 1: ${dead##* }"
  assert_contains "$out" "refuse[dangling-ref]" "and the refusal is dangling-ref"
done

# A path inside a commit is a pointer as well: the register cites one directly,
# and a commit that resolves does not make every path inside it resolve.
t="$(fresh deadpath)"
perl -0pi -e 's/source-register\.md`/source-register-that-never-existed.md`/' "$t/SOURCES.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[dangling-ref]" "a path inside a cited commit that does not exist is refused"

# The real commit the documents cite, replaced with a dead one. This is the
# reproduction from the finding.
t="$(fresh deadreal)"
perl -0pi -e 's/`fa7538a`/`deadbee`/g' "$t/STANDARDS.md" "$t/SOURCES.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "replacing the cited commit with a dead one is refused"

# And the decider record, which cites the same commit while recording that the
# cleanup would rewrite it. It was outside the gate's scope entirely.
t="$(fresh deaddeciders)"
perl -0pi -e 's/`fa7538a`/`deadbee`/g' "$t/DECIDERS.md"
out="$(gate "$t")"; rc=$?
assert_status 1 "$rc" "a dead commit citation in the decider record is refused"

# The other half, which matters as much: a backticked token that is NOT a pointer
# must not be refused. A path, a field name, a value and a command all appear in
# these documents in backticks, and a gate that read them as refs would refuse
# the shipped documents.
t="$(fresh notpointers)"
printf '\nSee `bin/validate-standards.sh`, the field `decided_by:`, the state `pending`, and `git log`.\n' >> "$t/STANDARDS.md"
out="$(gate "$t")"; rc=$?
assert_status 0 "$rc" "a path, a field, a value and a command in backticks are not pointers"

# --- the gate must not report clean when it cannot check ----------------------
# A shallow clone does not have the history these pointers are into. Reporting
# the documents clean from one would be the failure AGENTS.md records for
# validate-claims.sh, where a pattern that would not compile was read as nothing
# found. Exit 2 is "the gate could not run".
t="$(fresh shallowsrc)"
( cd "$t" && git add -A >/dev/null 2>&1 && git commit -q -m 'docs: fixture' ) 2>/dev/null
shallow="$TMP/shallow"
rm -rf "$shallow"
if git clone -q --depth 1 "file://$t" "$shallow" 2>/dev/null; then
  mkdir -p "$shallow/bin" && cp "$GATE" "$shallow/bin/"
  out="$(gate "$shallow")"; rc=$?
  assert_status 2 "$rc" "the gate exits 2 in a shallow clone instead of reporting clean"
  assert_contains "$out" "shallow" "and says that is why it could not run"
else
  assert_fail "the gate exits 2 in a shallow clone instead of reporting clean" \
    "could not create a shallow clone to test against"
fi

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
