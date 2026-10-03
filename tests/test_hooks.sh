#!/usr/bin/env bash
# The hooks must hold the same commit-message rule as the server side.
#
# CTRL-9 is about a convention applying only to whoever remembered to enable it,
# so the hooks have a server-side counterpart where they can. The failure this
# suite exists for is the reverse one: the enforcement points DISAGREEING. One
# rule — the conventional subject — is enforced in three places, and until
# 2026-10-03 the merge exemption existed in exactly one of them:
#
#   .githooks/commit-msg   every commit, merges included        refused merges
#   .githooks/pre-push     every commit in the pushed range     refused merges
#   the commit-messages job  `rev-list --no-merges`             exempt
#
# AGENTS.md states the exemption and gives the reason: a merge subject is
# generated, by git locally or by the forge on a pull request, so holding it to
# the convention refuses something nobody wrote. Both hooks were stricter than
# CI, which is the opposite of what CTRL-9 is for — a push refused locally has no
# server-side run to compare against, and the only way through was --no-verify,
# which also turns off the secret scan.
#
# Neither showed up in ordinary use. `commit-msg` needs a local `git merge`;
# `pre-push` needs a force-push of a rebased branch, where the remote tip is no
# longer an ancestor so `$rsha..$lsha` covers the merges on main as well.
#
# Driven end to end against a throwaway repository and a bare remote, because the
# range arithmetic is the part that was wrong and only a real push computes it.
# Nothing here touches this repository's own refs.
set -u
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$TEST_DIR/lib/assert.sh"

ROOT="$(cd "$TEST_DIR/.." && pwd)"
HOOKS="$ROOT/.githooks"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

assert_file_exists "$HOOKS/pre-push" "the pre-push hook exists"
assert_file_exists "$HOOKS/commit-msg" "the commit-msg hook exists"

git init -q --bare "$TMP/remote"
R="$TMP/local"
mkdir -p "$R"
(
  cd "$R" || exit 2
  git init -q .
  git config core.hooksPath "$HOOKS"
  git config user.name 'A Person'
  git config user.email 'person@example.invalid'
  git remote add origin "$TMP/remote"
  printf 'one\n' > a.txt && git add -A && git commit -q -m 'feat: add a'
  git branch -M main
  git push -q origin main
) >/dev/null 2>&1

push_out() { ( cd "$R" && git push "$@" 2>&1 ); }

# --- a conventional commit is accepted ---------------------------------------
# The baseline. Without it, every refusal below could be the hook refusing
# everything, and the suite would not know.
(
  cd "$R" || exit 2
  printf 'two\n' > b.txt && git add -A && git commit -q -m 'feat: add b'
) >/dev/null 2>&1
out="$(push_out origin main)"; rc=$?
assert_status 0 "$rc" "a conventional commit is pushed"
assert_not_contains "$out" "push refused" "nothing was refused"

# --- commit-msg still refuses a non-merge subject ------------------------------
# The guard the merge exemption must not have widened. Without this, setting
# `merging=yes` unconditionally passes the whole suite — which it did, found by
# mutating the flag rather than by deleting the check.
(
  cd "$R" || exit 2
  printf 'two-and-a-half\n' > b2.txt && git add -A
  git commit -m 'added a file, not conventional'
) >"$TMP/commit1.log" 2>&1
rc=$?
assert_status 1 "$rc" "commit-msg refuses a non-conventional subject on an ordinary commit"
assert_contains "$(cat "$TMP/commit1.log")" "subject is not a conventional commit" \
  "the refusal names the rule"
( cd "$R" && git reset -q HEAD -- . && rm -f b2.txt ) >/dev/null 2>&1

# --- a non-conventional subject is still refused at push ----------------------
# The guard the --no-merges change must not have loosened. Written with
# --no-verify on the commit so the commit-msg hook does not catch it first: the
# point is that pre-push catches what reached the branch anyway.
(
  cd "$R" || exit 2
  printf 'three\n' > c.txt && git add -A
  git commit -q --no-verify -m 'added a third file'
) >/dev/null 2>&1
out="$(push_out origin main)"; rc=$?
assert_status 1 "$rc" "a non-conventional subject is refused"
assert_contains "$out" "not a conventional commit" "the refusal names the rule"
assert_contains "$out" "added a third file" "and names the subject"

# Take it back out, so the branch is clean for the merge case.
( cd "$R" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1

# --- a merge commit is exempt, on a force-push of a rebased branch -------------
# The shape that found the defect, reproduced exactly. The order matters:
#
#   1. branch off main and push, so the remote tip predates the merge
#   2. merge something into main with a forge-style subject
#   3. rebase the branch onto main, so the merge becomes one of its ancestors
#   4. force-push
#
# Only then is the merge inside `$rsha..$lsha`. The first version of this fixture
# pushed the branch AFTER the merge and amended it, which left the merge reachable
# from the remote tip and therefore outside the range — the merge assertion passed
# against the unfixed hook, which is the vacuous assertion this repository keeps
# shipping. Caught by reverting the fix and watching this case stay green.
(
  cd "$R" || exit 2
  git checkout -q -b work main
  printf 'five\n' > e.txt && git add -A && git commit -q -m 'feat: add e'
  git push -q origin work
  git checkout -q -b side main
  printf 'four\n' > d.txt && git add -A && git commit -q -m 'feat: add d'
  git checkout -q main
  git merge -q --no-ff side -m 'Merge pull request #1 from somewhere/side'
  git checkout -q work
  git rebase -q main
) >/dev/null 2>&1

# The merge above went through the commit-msg hook, so it is also the fixture for
# that half. If the hook had refused it, main would still be where it was and the
# rebase would be a no-op — which is how the first version of this suite passed
# vacuously against both unfixed hooks.
merged_subject="$(cd "$R" && git log -1 --format=%s main)"
assert_eq "Merge pull request #1 from somewhere/side" "$merged_subject" \
  "commit-msg accepts a generated merge subject"

out="$(push_out --force origin work)"; rc=$?
assert_status 0 "$rc" "a force-push whose range contains a merge commit is accepted"
assert_not_contains "$out" "not a conventional commit" "no commit in the range is called a defect"

# The merge really is in the range, or the assertion above proves nothing about
# merges. The disclosure lists the range, so the merge appears there — and that is
# the point: it is disclosed as being pushed and not held to the convention.
assert_contains "$out" "Merge pull request #1" "the merge is inside the pushed range"

# --- the merge exemption does not cover the attribution ban -------------------
# The one part of the rule that applies to a merge as much as to anything else. A
# merge message can be edited, so the exemption is for the generated subject and
# not for whatever someone adds to the body.
(
  cd "$R" || exit 2
  git checkout -q -b side2 main
  printf 'six\n' > f.txt && git add -A && git commit -q -m 'feat: add f'
  git checkout -q main
  git merge -q --no-ff side2 \
    -m 'Merge pull request #2 from somewhere/side2' \
    -m 'Co-Authored-By: Somebody <nobody@example.invalid>'
) >"$TMP/merge2.log" 2>&1
rc=$?
assert_status 1 "$rc" "a merge carrying an attribution trailer is refused"
assert_contains "$(cat "$TMP/merge2.log")" "Co-Authored-By trailer is not allowed" \
  "the refusal names the trailer and not the subject"
( cd "$R" && git merge --abort ) >/dev/null 2>&1

# --- pre-push and the job exempt merges by the same expression -----------------
# Both use `--no-merges`. Checked because the two drifted apart once already, and
# a reader comparing them should find the same mechanism rather than two.
assert_contains "$(cat "$HOOKS/pre-push")" "rev-list --no-merges" \
  "the hook excludes merges from the message check"
assert_contains "$(cat "$ROOT/.github/workflows/ci.yml")" "rev-list --no-merges" \
  "the job excludes merges from the message check"

assert_done
