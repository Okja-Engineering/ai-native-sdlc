#!/usr/bin/env bash
# The commit that records a decision must be authored by a decider.
#
# This gate REFUSES on the current repository, and that is the point: the
# identities are not separated, so authorship cannot be verified from git. The
# suite therefore asserts two different things —
#
#   1. that the gate refuses the real history, with the right refusals
#   2. that it ACCEPTS a history where the identities are separated
#
# Without the second, the gate could be refusing for any reason at all and the
# suite would not know. That is the vacuous-assertion failure this repository has
# shipped three times today.
#
# Mutations and fixtures run in a throwaway repository under the test's own temp
# directory, never a copy of the tree.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
GATE="$ROOT/bin/validate-authorship.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- the real repository refuses ----------------------------------------------
# Asserted loosely ON PURPOSE. These run against whatever history the checkout
# has, and CI clones shallow: locally `git log --all` sees two author names on
# the shared address and emits `identity-shared`, while in CI it sees one and
# does not. The first version asserted that specific refusal and failed on both
# CI legs — a test coupled to checkout depth rather than to behaviour.
#
# So this asserts only that the real history refuses and names a cause. The
# precise refusals are pinned by the fixtures below, which build their own
# history and do not depend on the environment.
out="$(bash "$GATE" 2>&1)"; rc=$?
assert_status 1 "$rc" "the real history refuses"
assert_contains "$out" "refuse[" "it names a cause"
assert_contains "$out" "not yet enforced" "it points at where the gap is recorded"

# --- a clean fixture must be ACCEPTED ----------------------------------------
# Built from scratch so the identities are genuinely separate. If the gate
# refused this too, every refusal above would be meaningless.
R="$TMP/clean"
mkdir -p "$R/process/05-deliver/decisions" "$R/bin"
cp "$GATE" "$R/bin/"
cat > "$R/DECIDERS.md" <<'DEC'
# Authorized deciders

| Name | Since | git identity |
|---|---|---|
| Ada Lovelace | 2026-01-01 | `Ada Lovelace <ada@example.invalid>` |
DEC
( cd "$R" && git init -q . \
  && git -c user.name='An Agent' -c user.email='agent@example.invalid' \
       commit -q --allow-empty -m 'chore: set up' ) 2>/dev/null

# The agent drafts the record as pending. That must not be gated.
printf 'chosen: pending\n' > "$R/process/05-deliver/decisions/thing.md"
( cd "$R" && git add -A && git -c user.name='An Agent' -c user.email='agent@example.invalid' \
    commit -q -m 'docs: draft the decision' ) 2>/dev/null
out="$(cd "$R" && bash bin/validate-authorship.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "an agent drafting a pending record is not gated"
assert_contains "$out" "0 decision-setting commit" "a pending draft is not a decision-setting commit"

# The decider sets it. Authored under the declared identity.
printf 'chosen: D\n' > "$R/process/05-deliver/decisions/thing.md"
( cd "$R" && git add -A && git -c user.name='Ada Lovelace' -c user.email='ada@example.invalid' \
    commit -q -m 'feat: decide' ) 2>/dev/null
out="$(cd "$R" && bash bin/validate-authorship.sh 2>&1)"; rc=$?
assert_status 0 "$rc" "a decision committed by the declared decider is accepted"
assert_contains "$out" "1 decision-setting commit" "it counted the decision commit"

# --- and the agent setting it is refused -------------------------------------
# The case the whole control exists for.
printf 'chosen: E\n' > "$R/process/05-deliver/decisions/other.md"
( cd "$R" && git add -A && git -c user.name='An Agent' -c user.email='agent@example.invalid' \
    commit -q -m 'feat: decide for them' ) 2>/dev/null
out="$(cd "$R" && bash bin/validate-authorship.sh 2>&1)"; rc=$?
assert_status 1 "$rc" "an agent setting a decision is refused"
assert_contains "$out" "refuse[author-not-a-decider]" "the refusal names the cause"
assert_contains "$out" "An Agent" "the refusal names who authored it"

# --- a shared address is refused even when the name matches ------------------
# A declared identity is not enough if the address carries more than one name.
R2="$TMP/shared"
mkdir -p "$R2/process/05-deliver/decisions" "$R2/bin"
cp "$GATE" "$R2/bin/"
cat > "$R2/DECIDERS.md" <<'DEC'
# Authorized deciders

| Name | Since | git identity |
|---|---|---|
| Ada Lovelace | 2026-01-01 | `Ada Lovelace <shared@example.invalid>` |
DEC
( cd "$R2" && git init -q . \
  && git -c user.name='An Agent' -c user.email='shared@example.invalid' \
       commit -q --allow-empty -m 'chore: an agent uses the same address' ) 2>/dev/null
printf 'chosen: D\n' > "$R2/process/05-deliver/decisions/thing.md"
( cd "$R2" && git add -A && git -c user.name='Ada Lovelace' -c user.email='shared@example.invalid' \
    commit -q -m 'feat: decide' ) 2>/dev/null
out="$(cd "$R2" && bash bin/validate-authorship.sh 2>&1)"; rc=$?
assert_status 1 "$rc" "a declared identity on a shared address is still refused"
assert_contains "$out" "refuse[identity-shared]" "the refusal is identity-shared"
assert_not_contains "$out" "refuse[author-not-a-decider]" "and not the other one — the name did match"

# --- no declared identity at all ---------------------------------------------
perl -0pi -e 's/\| `Ada Lovelace <shared\@example\.invalid>` \|/| |/' "$R2/DECIDERS.md"
out="$(cd "$R2" && bash bin/validate-authorship.sh 2>&1)"
assert_contains "$out" "refuse[no-identities]" "a decider list with no git identity is refused"

# --- it is deliberately not in CI --------------------------------------------
# A gate that cannot pass would block every branch. If someone wires it in
# before the identities are separated, this fails and says why.
assert_not_contains "$(cat "$ROOT/.github/workflows/ci.yml")" "validate-authorship" \
  "the gate is not wired into CI while it cannot pass"

assert_done
