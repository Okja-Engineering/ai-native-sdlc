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

# --- a citation that resolves to nothing -------------------------------------
t="$(fresh unknown)"
perl -0pi -e 's/`S-NBER-2026-01`/`S-INVENTED-9999-01`/' "$t/STANDARDS.md"
out="$(gate "$t")"
assert_contains "$out" "refuse[unknown-source]" "a citation absent from the register is refused"
assert_contains "$out" "reads as evidence" "the message says why a dangling citation is worse than none"

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
# gate refuses its own document for existing.
t="$(fresh key)"
assert_not_contains "$(gate "$t")" "line 9" "the grade key table is not treated as a claim"

assert_done
