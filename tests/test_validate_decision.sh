#!/usr/bin/env bash
# The Deliver gate: a decision is made by a human, and the record names which one.
#
# Every refusal is asserted by its distinctive message, not by exit status alone.
# A non-zero exit cannot tell "nobody decided" from "that option does not exist",
# and a gate an operator cannot read gets bypassed.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/process/05-deliver/validate-decision.sh"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# The suite supplies its own decider list. Pointing at the real DECIDERS.md
# would make these cases fail whenever a person is added or removed, which is a
# test coupled to data rather than to behaviour — the defect that broke this
# suite once already when a decision was first made.
cat > "$TMP/DECIDERS.md" <<'DEC'
# Authorized deciders

| Name | Since |
|---|---|
| Matt Van Dusen | 2026-01-01 |
| Ada Lovelace | 2026-01-01 |
DEC
export DECIDERS_FILE="$TMP/DECIDERS.md"

# A record beside a real option set, so the options link resolves and the thing
# under test is the only thing wrong with the file.
# The problem file has to exist too. `problem:` was a required field nothing
# read until 2026-10-03, so the fixture declared a path that was never resolved.
mkdir -p "$TMP/process/04-develop/options" "$TMP/process/05-deliver/decisions" \
         "$TMP/process/03-define/problems"
printf '# Problem — thing\n' > "$TMP/process/03-define/problems/thing.md"
cat > "$TMP/process/04-develop/options/thing.md" <<'OPTS'
# Develop — thing
## A · First way
## B · Second way
OPTS

# A document for the record to amend, with a back-link, so the reciprocal check
# has something real to resolve against.
cat > "$TMP/STANDARD.md" <<'STD'
# A standard

Some claim.

decided: [thing](process/05-deliver/decisions/thing.md)
STD

# record <chosen> <decided_by> <dated> [amends]
# amends defaults to a resolving, reciprocated link. Pass a 4th argument to
# override it, or the literal string OMIT to leave the field out entirely.
record() {
  local amends="${4-[s](../../../STANDARD.md#a-standard)}"
  {
    printf '%s\n\n' '# Decision — thing'
    printf '%s\n' 'problem: [p](../../03-define/problems/thing.md)'
    printf '%s\n' 'options: [o](../../04-develop/options/thing.md)'
    printf 'chosen: %s\n' "$1"
    printf 'decided_by: %s\n' "$2"
    printf 'dated: %s\n' "$3"
    [ "$amends" = OMIT ] || printf 'amends: %s\n' "$amends"
  } > "$TMP/process/05-deliver/decisions/thing.md"
  printf '%s' "$TMP/process/05-deliver/decisions/thing.md"
}

# --- pending is a valid state -------------------------------------------------
out="$(bash "$GATE" "$(record pending '' '')" 2>&1)"; rc=$?
assert_status 0 "$rc" "a pending record with nobody named exits 0"
assert_contains "$out" "within the contract" "pending is reported as within the contract"

# --- a run that read nothing does not report conformance -----------------------
# Over an empty decisions directory this said "0 file(s) within the contract" and
# exited 0: no record was read, and the gate reported every one of them within the
# contract. CI runs this gate with no arguments. An empty phase stays exit 0, as the
# scan gate already settled; the claim is what changes.
mkdir -p "$TMP/no-decisions"
out="$(DECISIONS_DIR="$TMP/no-decisions" bash "$GATE" 2>&1)"; rc=$?
assert_status 0 "$rc" "an empty decisions directory is not a refusal"
assert_contains "$out" "nothing was checked" "but the gate says it read nothing"
assert_not_contains "$out" "within the contract" \
  "and does not report files within the contract when it read none"

# --- the gate the contract named ---------------------------------------------
out="$(bash "$GATE" "$(record A '' 2026-10-01)" 2>&1)"; rc=$?
assert_status 1 "$rc" "chosen without a decider exits 1"
assert_contains "$out" "refuse[undecided-by]" "the refusal is undecided-by"
assert_contains "$out" "a decision is made by a human" "the message says why"

# The invariant: decided_by denotes a natural person authorized to decide.
#
# The previous version of this block asserted exactly `the team`, `Claude` and
# `reviewer` — the three literals the old denylist regex was written for. It
# proved the list contained three words and never tested the invariant, so an
# external audit passed `the Platform Engineering Team` and `Claude Opus 5`
# through a check this repository calls irreplaceable.
#
# These cases are deliberately chosen to sit OUTSIDE whatever the implementation
# obviously handles: multi-word roles, versioned model names, a vendor prefix, a
# plausible-looking human who simply is not authorized. If the implementation is
# rewritten, these must still pass.
# The list also includes the text the TABLE ITSELF is made of. The allowlist was
# harvested with `grep -oE '^\| [^|]+ \|'` — the first cell of every row in the
# file, header included — so `decided_by: Name` was an authorized decider. The
# column heading is not a person and neither is the separator row.
for bad in \
  'the team' 'Claude' 'reviewer' \
  'the Platform Engineering Team' 'Claude Opus 5' 'Anthropic Claude Opus 5.1' \
  'Engineering Leadership Group' 'the SRE on call' 'GPT-5' 'our LLM' \
  'nobody' 'TBD' 'A. N. Other' \
  'Matt' 'Ada' 'Van Dusen' 'Matt Van Dusen and the team' 'matt van dusen' \
  'Name' 'Since' 'name' '---' '-' '|'
do
  out="$(bash "$GATE" "$(record A "$bad" 2026-10-01)" 2>&1)"; rc=$?
  assert_status 1 "$rc" "refuses decided_by: $bad"
done

# And the positive half, which is what makes it an allowlist rather than a
# denylist: a listed decider is accepted, and so is a second one.
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "an authorized decider is accepted"
out="$(bash "$GATE" "$(record A 'Ada Lovelace' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a second authorized decider is accepted"

# The two messages, because the fix differs. A role needs replacing; a real
# person needs adding to the list.
out="$(bash "$GATE" "$(record A 'the Platform Engineering Team' 2026-10-01)" 2>&1)"
assert_contains "$out" "a role or a machine" "a role gets the role message"
out="$(bash "$GATE" "$(record A 'Grace Hopper' 2026-10-01)" 2>&1)"
assert_contains "$out" "not listed in DECIDERS.md" "an unlisted person is told to be added"

# No decider list at all must fail closed, not open.
out="$(DECIDERS_FILE=/nonexistent/DECIDERS.md bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a missing decider list refuses rather than passing everything"

# --- only the list authorizes, not everything else in the file ----------------
# The extraction was not anchored to the list, so anything shaped like a table
# row donated its first cell. A decider file grows prose, examples and other
# tables over time, and none of those authorize anybody.
cat > "$TMP/DECIDERS-busy.md" <<'DEC'
# Authorized deciders

| Name | Since |
|---|---|
| Ada Lovelace | 2026-01-01 |

Grace Hopper reviewed the first draft of this file.

## Who has asked to be added

| Candidate | Asked |
|---|---|
| Alan Turing | 2026-02-02 |

## What the list looks like

```
| Name | Since |
|---|---|
| Edsger Dijkstra | 2026-03-03 |
```
DEC
for outsider in 'Alan Turing' 'Edsger Dijkstra' 'Grace Hopper' 'Candidate'; do
  out="$(DECIDERS_FILE="$TMP/DECIDERS-busy.md" bash "$GATE" "$(record A "$outsider" 2026-10-01)" 2>&1)"; rc=$?
  assert_status 1 "$rc" "a name elsewhere in the decider file does not authorize: $outsider"
done
out="$(DECIDERS_FILE="$TMP/DECIDERS-busy.md" bash "$GATE" "$(record A 'Ada Lovelace' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "and the one on the list still is authorized"

# A decider file that lists nobody authorizes nobody. Same choice as a missing
# file: the allowlist exists so that the absence of a name refuses.
cat > "$TMP/DECIDERS-empty.md" <<'DEC'
# Authorized deciders

Nobody is currently authorized to decide.
DEC
out="$(DECIDERS_FILE="$TMP/DECIDERS-empty.md" bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decider file listing nobody authorizes nobody"

# --- companion checks, equally shape-independent ------------------------------
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' '')" 2>&1)"
assert_contains "$out" "refuse[undated-decision]" "a decided record must be dated"

out="$(bash "$GATE" "$(record Z 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[chosen-not-an-option]" "an option that does not exist is refused"
assert_contains "$out" "go back to Develop" "the message says where to go instead"

out="$(bash "$GATE" "$(record pending 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[pending-but-decided]" "a record cannot be both pending and decided"

# --- amends: the decision has to land somewhere -------------------------------
# For five phases the repository's stated output — a change to our standards —
# was never produced, because nothing carried a decision to the document. These
# check the link exists and resolves in BOTH directions; a one-way pointer would
# let the standard and the decision disagree silently.

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 OMIT)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decided record with no amends exits 1"
assert_contains "$out" "refuse[no-amends]" "the refusal is no-amends"
assert_contains "$out" "never reaches one" "the message says why an unlinked decision is the problem"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 none)" 2>&1)"
assert_contains "$out" "refuse[bare-none-amends]" "a bare 'none' cannot be told from an oversight"

# `none` must be the WHOLE first word. The previous version matched the prefix
# `none*`, so a word merely STARTING with those letters was read as a
# declaration that nothing changed. The audit used "nonetheless".
for sneaky in \
  'nonetheless, we decided not to say where this lands' \
  'nonexistent, so nothing to point at' \
  'nones of this applies'
do
  out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 "$sneaky")" 2>&1)"; rc=$?
  assert_status 1 "$rc" "refuses amends starting with none but not meaning it: ${sneaky%%,*}"
done

# And the legitimate forms still pass, including a trailing punctuation variant.
for ok in \
  'none — chose to measure first, nothing about how we work changed' \
  'none. The decision defers, so no document changes yet.'
do
  out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 "$ok")" 2>&1)"; rc=$?
  assert_status 0 "$rc" "accepts a real 'none' with a reason: ${ok%%,*}"
done

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 'none — chose to measure first, nothing about how we work changed')" 2>&1)"; rc=$?
assert_status 0 "$rc" "'none' with a reason is accepted"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 'STANDARD.md section 1')" 2>&1)"
assert_contains "$out" "refuse[amends-not-linked]" "naming a document without linking it is refused"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01 '[s](../../../NOPE.md)')" 2>&1)"
assert_contains "$out" "refuse[amends-unresolved]" "an amended document that does not exist is refused"

# The reciprocal half. Remove the back-link and the pair stops agreeing.
cp "$TMP/STANDARD.md" "$TMP/STANDARD.bak"
grep -v '^decided:' "$TMP/STANDARD.bak" > "$TMP/STANDARD.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "an amended document with no decided: line is refused"
assert_contains "$out" "the grade on that claim is unsupported" "the message says what the missing back-link costs"
cp "$TMP/STANDARD.bak" "$TMP/STANDARD.md"

# A MENTION is not a link. This was `grep -q "$(basename "$f")"` — a bare
# filename match anywhere in the file — and an external audit replaced the
# decided: link with a sentence naming the file in prose. The gate reported the
# pair reciprocated.
# Two shapes, because the audit's exploit sits between them. Dropping the
# `decided:` prefix entirely hits the no-line branch; keeping the prefix and
# naming the file in prose hits the not-a-link branch. Both were accepted by the
# old filename match.
printf '# A standard\n\nSome claim.\n\nA note: the file thing.md exists somewhere in this repository.\n' > "$TMP/STANDARD.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "a filename in prose with no decided: line does not reciprocate"

printf '# A standard\n\nSome claim.\n\ndecided: see thing.md, somewhere in this repository\n' > "$TMP/STANDARD.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "a decided: line naming a file without linking it does not reciprocate"
assert_contains "$out" "not a link" "the message says a mention is not a link"

# A decided: line that links a DIFFERENT record. The two halves then name
# different decisions, which is exactly the disagreement this check exists for
# and which a filename match could never see.
printf '# A standard\n\nSome claim.\n\ndecided: [other](process/05-deliver/decisions/other.md)\n' > "$TMP/STANDARD.md"
: > "$TMP/process/05-deliver/decisions/other.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "a back-link to a different record is refused"
assert_contains "$out" "name different records" "the message says the two halves disagree"
rm -f "$TMP/process/05-deliver/decisions/other.md"

# A decided: line linking something that does not exist.
printf '# A standard\n\nSome claim.\n\ndecided: [gone](process/05-deliver/decisions/gone.md)\n' > "$TMP/STANDARD.md"
out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"
assert_contains "$out" "refuse[amends-not-reciprocated]" "a back-link that does not resolve is refused"
cp "$TMP/STANDARD.bak" "$TMP/STANDARD.md"

out="$(bash "$GATE" "$(record A 'Matt Van Dusen' 2026-10-01)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a reciprocated link is accepted once restored"

# --- one document, amended more than once ------------------------------------
# STANDARDS.md is THE document decisions amend, and it already carried one
# amendment. The back-link was read with `head -1`, so the SECOND correctly
# formed amendment was refused — with a message accusing a correct pair of
# disagreeing — and no further decision could ever land on that document.
#
# The invariant is that reciprocity holds between a decision and the claim its
# `amends:` names. Nothing below says how the gate finds the back-link, so a
# rewrite using a different mechanism has to pass these too.
MANY="$TMP/MANY.md"

# amendment <n> [anchor] -> a record amending claim <n> of MANY.md, path on stdout
#
# The anchor defaults to the claim the record is about. Pass another one to point
# the record at a different claim, or NONE for a link carrying no anchor at all.
amendment() {
  local anchor="${2-claim-$1}" link
  case "$anchor" in
    NONE) link="../../../MANY.md" ;;
    *)    link="../../../MANY.md#$anchor" ;;
  esac
  cat > "$TMP/process/05-deliver/decisions/d$1.md" <<EOF
# Decision — d$1

problem: [p](../../03-define/problems/thing.md)
options: [o](../../04-develop/options/thing.md)
chosen: A
decided_by: Ada Lovelace
dated: 2026-10-01
amends: [\`MANY.md\` claim $1]($link)
EOF
  printf '%s' "$TMP/process/05-deliver/decisions/d$1.md"
}

# many_doc <n>... -> MANY.md carrying claim <n> and its back-link, in the order given
many_doc() {
  printf '# Many claims\n' > "$MANY"
  for n in "$@"; do
    printf '\n## Claim %s\n\nSomething.\n\ndecided: [d%s](process/05-deliver/decisions/d%s.md)\n' \
      "$n" "$n" "$n" >> "$MANY"
  done
}

many_doc 1 2
out="$(bash "$GATE" "$(amendment 1)" "$(amendment 2)" 2>&1)"; rc=$?
assert_status 0 "$rc" "two decisions amending one document both pass"
assert_not_contains "$out" "amends-not-reciprocated" "neither correct pair is accused of disagreeing"

# Order must not decide it. This is the half `head -1` got right by accident.
many_doc 2 1
out="$(bash "$GATE" "$(amendment 1)" "$(amendment 2)" 2>&1)"; rc=$?
assert_status 0 "$rc" "and both pass with the back-links in the other order"

many_doc 1 2 3
out="$(bash "$GATE" "$(amendment 1)" "$(amendment 2)" "$(amendment 3)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a third amendment on the same document passes as well"

# Reading every back-link must not become "any back-link will do". Claim 3 is
# present and carries a link to a different record, so the record under test is
# named by nothing.
many_doc 1 2
printf '\n## Claim 3\n\nSomething.\n\ndecided: [d1](process/05-deliver/decisions/d1.md)\n' >> "$MANY"
out="$(bash "$GATE" "$(amendment 3)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a record that no back-link names is still refused"
assert_contains "$out" "refuse[amends-not-reciprocated]" "the refusal is amends-not-reciprocated"

# --- reciprocity holds on the claim, not merely on the file -------------------
# `amends:` names a claim through its #anchor, and the anchor was stripped before
# the comparison. So deleting a claim's back-link and re-inserting the identical
# `decided:` line in a different claim — while `amends:` still named the first —
# passed. The gate established that two documents pointed at each other, not that
# they pointed at the same claim.
#
# The invariant: the back-link has to sit inside the claim `amends:` names.
cat > "$MANY" <<'DOC'
# Many claims

## Claim 1

Something.

## Claim 2

Something else.

decided: [d1](process/05-deliver/decisions/d1.md)
DOC
out="$(bash "$GATE" "$(amendment 1)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a back-link in a different claim than amends: names is refused"
assert_contains "$out" "refuse[amends-not-reciprocated]" "the refusal is amends-not-reciprocated"
assert_contains "$out" "not inside the claim" "the message says the back-link is in the wrong claim"

# The same file, the same pair, the back-link moved into the claim that was
# amended. Nothing else differs, so this is the one fact under test.
cat > "$MANY" <<'DOC'
# Many claims

## Claim 1

Something.

decided: [d1](process/05-deliver/decisions/d1.md)

## Claim 2

Something else.
DOC
out="$(bash "$GATE" "$(amendment 1)" 2>&1)"; rc=$?
assert_status 0 "$rc" "and the same pair passes once the back-link sits in that claim"

# A claim includes its subsections. A back-link under a deeper heading inside the
# claim has not left it, and refusing that would push authors into flattening a
# document to satisfy a gate.
cat > "$MANY" <<'DOC'
# Many claims

## Claim 1

Something.

### Why this changed

decided: [d1](process/05-deliver/decisions/d1.md)

## Claim 2

Something else.
DOC
out="$(bash "$GATE" "$(amendment 1)" 2>&1)"; rc=$?
assert_status 0 "$rc" "a back-link under a subsection of the named claim reciprocates"

# An anchor the document carries no heading for. `amends:` then names a claim
# that does not exist, which is a refusal and not an empty section to search.
many_doc 1 2
out="$(bash "$GATE" "$(amendment 1 claim-9)" 2>&1)"; rc=$?
assert_status 1 "$rc" "an anchor no heading in the document carries is refused"
assert_contains "$out" "refuse[amends-claim-unresolved]" "the refusal is amends-claim-unresolved"

# An anchor present in neither half: the record names it and the document has no
# such heading, so there is nothing for the pair to agree about.
out="$(bash "$GATE" "$(amendment 1 'a-claim-nobody-wrote')" 2>&1)"; rc=$?
assert_status 1 "$rc" "an anchor in neither document is refused"
assert_contains "$out" "refuse[amends-claim-unresolved]" "and it is the same refusal"

# No anchor at all. Without one the record names a document rather than a claim,
# and the section-level check could be switched off by leaving the anchor out —
# which is the denylist shape: a control an author disables by omission.
out="$(bash "$GATE" "$(amendment 1 NONE)" 2>&1)"; rc=$?
assert_status 1 "$rc" "amends: naming a document and no claim within it is refused"
assert_contains "$out" "refuse[amends-no-claim]" "the refusal is amends-no-claim"

# The anchor is matched against the headings the document actually has, so a
# heading whose text differs only in punctuation and case still resolves. These
# are the forms a forge generates and an author pastes.
cat > "$MANY" <<'DOC'
# Many claims

## 7. Learning has to improve the generating system

Something.

decided: [d1](process/05-deliver/decisions/d1.md)
DOC
out="$(bash "$GATE" "$(amendment 1 '7-learning-has-to-improve-the-generating-system')" 2>&1)"; rc=$?
assert_status 0 "$rc" "a numbered heading with punctuation resolves to its forge anchor"

# A back-link shown as an EXAMPLE does not reciprocate. Found by attacking this
# check after it was written. The same class has already cost this repository
# once: an example row in a fenced block in DECIDERS.md would have authorized
# everyone it named, which is why the deciders list skips fences.
cat > "$MANY" <<'DOC'
# Many claims

## Claim 1

This is what a back-link looks like:

```
decided: [d1](process/05-deliver/decisions/d1.md)
```
DOC
out="$(bash "$GATE" "$(amendment 1)" 2>&1)"; rc=$?
assert_status 1 "$rc" "a back-link inside a fenced example does not reciprocate"
assert_contains "$out" "refuse[amends-not-reciprocated]" "the refusal is amends-not-reciprocated"

# A heading inside a fence is not a heading, so an anchor cannot resolve to one.
cat > "$MANY" <<'DOC'
# Many claims

Example of a claim:

```
## Claim 1

decided: [d1](process/05-deliver/decisions/d1.md)
```
DOC
out="$(bash "$GATE" "$(amendment 1)" 2>&1)"; rc=$?
assert_status 1 "$rc" "an anchor cannot resolve to a heading inside a fenced example"
assert_contains "$out" "refuse[amends-claim-unresolved]" "the refusal is amends-claim-unresolved"

# Two decisions amending the SAME claim. The claim then carries two back-links and
# each record has to find its own.
cat > "$MANY" <<'DOC'
# Many claims

## Claim 1

decided: [d1](process/05-deliver/decisions/d1.md)
decided: [d2](process/05-deliver/decisions/d2.md)
DOC
out="$(bash "$GATE" "$(amendment 1)" "$(amendment 2 claim-1)" 2>&1)"; rc=$?
assert_status 0 "$rc" "two decisions amending one claim both pass"

# --- the stated problem must be linked ---------------------------------------
# `problem:` was a required field in the contract and nothing read it. Deleting
# the line left the gate reporting the record within the contract, so the
# decision-to-problem edge of the chain had no check at all. Found by the audit.
REC="$TMP/process/05-deliver/decisions/thing.md"

record A 'Matt Van Dusen' 2026-10-01 >/dev/null
grep -v '^problem:' "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
out="$(bash "$GATE" "$REC" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decision with no problem: field exits 1"
assert_contains "$out" "refuse[no-problem-link]" "the refusal is no-problem-link"
assert_contains "$out" "an answer with no question" "the message says what a problemless decision is"

record A 'Matt Van Dusen' 2026-10-01 >/dev/null
sed 's|^problem: .*|problem: the thing we talked about|' "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
assert_contains "$(bash "$GATE" "$REC" 2>&1)" "refuse[problem-not-linked]" \
  "a problem named but not linked is refused"

record A 'Matt Van Dusen' 2026-10-01 >/dev/null
sed 's|problems/thing.md|problems/gone.md|' "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
assert_contains "$(bash "$GATE" "$REC" 2>&1)" "refuse[problem-unresolved]" \
  "a problem link that does not resolve is refused"

# --- the amends check runs even when the options link is broken --------------
# It sat after two early returns, so a record missing both an options link and
# an amends field only ever heard about one of them.
record A 'Matt Van Dusen' 2026-10-01 OMIT >/dev/null
sed 's|^options: .*|options: [o](../../04-develop/options/gone.md)|' "$REC" > "$REC.tmp" && mv "$REC.tmp" "$REC"
out="$(bash "$GATE" "$REC" 2>&1)"
assert_contains "$out" "refuse[options-unresolved]" "an unresolved options link is still refused"
assert_contains "$out" "refuse[no-amends]" "and the amends check still runs"

# --- the shipped records ------------------------------------------------------
# These use the REAL DECIDERS.md, because they are checking real records. The
# fixture list above is for the synthetic cases only.
unset DECIDERS_FILE

out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/producing-themes.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the measure-first record is within the contract"

out="$(bash "$GATE" "$ROOT/process/05-deliver/decisions/agent-pr-approval.md" 2>&1)"; rc=$?
assert_status 0 "$rc" "the record that amends STANDARDS.md is within the contract"

# The real list must actually name the person the real records name, or the two
# agree only by the gate not looking.
assert_contains "$(cat "$ROOT/DECIDERS.md")" \
  "$(sed -n 's/^decided_by:[[:space:]]*//p' "$ROOT/process/05-deliver/decisions/agent-pr-approval.md" | head -1)" \
  "the real decider list names the person the real record names"


# --- a missing option set is named once, not twice -----------------------------
# Found by tests/mutate-sweep.sh, by loosening `-eq 1` to `-ge 0` on the guard that
# skips resolution when there is nothing to resolve. The gate then tried to resolve
# an empty path and added `options-unresolved` on top of `no-options-link`: two
# refusals naming two different problems where the record has one. The existing
# assertion on `no-options-link` passes either way, which is why nothing caught it.
#
# This gate's own sibling already records what that costs a reader. The scan gate's
# header describes an index shifted by one producing "four confident refusals that
# each named the wrong problem".
{
  printf '%s\n\n' '# Decision — thing'
  printf '%s\n' 'problem: [p](../../03-define/problems/thing.md)'
  printf 'chosen: %s\n' 'A'
  printf 'decided_by: %s\n' 'Ada Lovelace'
  printf 'dated: %s\n' '2026-10-01'
  printf 'amends: %s\n' '[s](../../../STANDARD.md#a-standard)'
} > "$TMP/process/05-deliver/decisions/thing.md"
assert_eq "0" "$(grep -c '^options:' "$TMP/process/05-deliver/decisions/thing.md")" \
  "the fixture declares no option set"
out="$(bash "$GATE" "$TMP/process/05-deliver/decisions/thing.md" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decided record declaring no option set exits 1"
assert_contains "$out" "refuse[no-options-link]" "and the refusal is no-options-link"
assert_not_contains "$out" "refuse[options-unresolved]" \
  "and the gate does not also refuse an option set it was never given"

# --- the gate with no arguments reads the decisions directory ------------------
# Found by tests/mutate-sweep.sh, by loosening `-gt 0` to `-ge 0` on the argument
# count. The gate then took the "files were named" branch with nothing named, looped
# over nothing, and reported "0 file(s) within the contract" and exit 0. CI runs this
# gate with no arguments, so that is the gate this repository says guards the one
# thing that cannot be reconstructed afterwards, reporting clean having read nothing.
#
# DECIDERS_FILE is unset for this call. The rest of the suite supplies its own decider
# list on purpose, and here the point is the real records against the real list.
out="$(cd "$ROOT" && unset DECIDERS_FILE && bash process/05-deliver/validate-decision.sh 2>&1)"
rc=$?
assert_status 0 "$rc" "the gate with no arguments passes over the real decision records"
assert_not_contains "$out" "0 file(s)" "and does not report having checked nothing"
nrec="$(ls "$ROOT"/process/05-deliver/decisions/*.md 2>/dev/null | grep -c .)"
assert_contains "$out" "$nrec file(s)" "it checked every decision record (found $nrec)"


# --- a missing option set is named once, not twice -----------------------------
# Found by tests/mutate-sweep.sh, by loosening `-eq 1` to `-ge 0` on the guard that
# skips resolution when there is nothing to resolve. The gate then tried to resolve
# an empty path and added `options-unresolved` on top of `no-options-link`: two
# refusals naming two different problems where the record has one. The existing
# assertion on `no-options-link` passes either way, which is why nothing caught it.
#
# This gate's own sibling already records what that costs a reader. The scan gate's
# header describes an index shifted by one producing "four confident refusals that
# each named the wrong problem".
{
  printf '%s\n\n' '# Decision — thing'
  printf '%s\n' 'problem: [p](../../03-define/problems/thing.md)'
  printf 'chosen: %s\n' 'A'
  printf 'decided_by: %s\n' 'Ada Lovelace'
  printf 'dated: %s\n' '2026-10-01'
  printf 'amends: %s\n' '[s](../../../STANDARD.md#a-standard)'
} > "$TMP/process/05-deliver/decisions/thing.md"
assert_eq "0" "$(grep -c '^options:' "$TMP/process/05-deliver/decisions/thing.md")" \
  "the fixture declares no option set"
out="$(bash "$GATE" "$TMP/process/05-deliver/decisions/thing.md" 2>&1)"; rc=$?
assert_status 1 "$rc" "a decided record declaring no option set exits 1"
assert_contains "$out" "refuse[no-options-link]" "and the refusal is no-options-link"
assert_not_contains "$out" "refuse[options-unresolved]" \
  "and the gate does not also refuse an option set it was never given"

# --- the gate with no arguments reads the decisions directory ------------------
# Found by tests/mutate-sweep.sh, by loosening `-gt 0` to `-ge 0` on the argument
# count. The gate then took the "files were named" branch with nothing named, looped
# over nothing, and reported "0 file(s) within the contract" and exit 0. CI runs this
# gate with no arguments, so that is the gate this repository says guards the one
# thing that cannot be reconstructed afterwards, reporting clean having read nothing.
#
# DECIDERS_FILE is unset for this call. The rest of the suite supplies its own decider
# list on purpose, and here the point is the real records against the real list.
out="$(cd "$ROOT" && unset DECIDERS_FILE && bash process/05-deliver/validate-decision.sh 2>&1)"
rc=$?
assert_status 0 "$rc" "the gate with no arguments passes over the real decision records"
assert_not_contains "$out" "0 file(s)" "and does not report having checked nothing"
nrec="$(ls "$ROOT"/process/05-deliver/decisions/*.md 2>/dev/null | grep -c .)"
assert_contains "$out" "$nrec file(s)" "it checked every decision record (found $nrec)"

# --- chosen: has to be a field, and the option has to be a heading --------------
# Found by tests/mutate-sweep.sh, by dropping the `^` from `grep -q '^chosen:'` and
# from `grep -qE "^## $chosen · "`.
#
# Unanchored, a record with no `chosen:` field passes as long as some line mentions
# the word, and an option set passes as long as it mentions the chosen option
# somewhere rather than declaring it as a heading. CTRL-1 cites the first refusal and
# CTRL-2 the second, so both are controls a reader is invited to trust.
#
# Every case above either has a real `chosen:` field or has nothing resembling one,
# which is why nothing could see the difference.
{
  printf '%s\n\n' '# Decision — thing'
  printf '%s\n' 'problem: [p](../../03-define/problems/thing.md)'
  printf '%s\n' 'options: [o](../../04-develop/options/thing.md)'
  printf '%s\n' 'A note: chosen: is the field this record is missing.'
  printf 'decided_by: %s\n' 'Ada Lovelace'
  printf 'dated: %s\n' '2026-10-01'
  printf 'amends: %s\n' '[s](../../../STANDARD.md#a-standard)'
} > "$TMP/process/05-deliver/decisions/thing.md"
out="$(bash "$GATE" "$TMP/process/05-deliver/decisions/thing.md" 2>&1)"; rc=$?
assert_status 1 "$rc" "a record that mentions chosen: without declaring it is refused"
assert_contains "$out" "refuse[no-chosen-field]" "and the refusal is no-chosen-field"

# The chosen option named in prose rather than declared as a heading. Paired against
# the real option set in the same breath, so a gate refusing every option set would
# fail the first of the two rather than passing the second.
cat > "$TMP/process/04-develop/options/thing.md" <<'OPTS'
# Develop — thing
## A · First way
## B · Second way
OPTS
out="$(bash "$GATE" "$(record A 'Ada Lovelace' 2026-10-01 OMIT)" 2>&1)"
assert_not_contains "$out" "refuse[chosen-not-an-option]" \
  "an option declared as a heading resolves"

# The option's heading QUOTED mid-line rather than written as a heading. A sentence
# with no locator in it is refused either way, so the fixture has to carry the exact
# text the gate looks for, somewhere other than the start of a line.
cat > "$TMP/process/04-develop/options/thing.md" <<'OPTS'
# Develop — thing

Two ways were weighed. The first was going to be written up as ## A · First way and
never was, and the second as ## B · Second way.
OPTS
out="$(bash "$GATE" "$(record A 'Ada Lovelace' 2026-10-01 OMIT)" 2>&1)"
assert_contains "$out" "refuse[chosen-not-an-option]" \
  "an option heading quoted mid-line is not a declared option"

assert_done
