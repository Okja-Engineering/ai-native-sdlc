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

# --- commit-msg: the four subject rules that had no test ----------------------
# The section above covers the conventional-subject check and the merge exemption.
# Four more rules live in the same hook and nothing exercised them: the 72-character
# limit, the trailing period, the imperative form, and the tool-attribution pattern.
# The `Co-Authored-By` half of the attribution ban was covered above; the other
# half — `generated with`, the robot emoji, the two addresses — was not, and it is
# the half a tool actually writes.
#
# Driven by handing the hook a message file, which is its whole contract. The merge
# case above needs real git state and is driven through `git commit`; these do not,
# and a direct call keeps a dozen cases cheap.
hook_msg() { # <message> -> output in $out, status in $rc
  printf '%s\n' "$1" > "$TMP/msg"
  out="$(cd "$R" && /bin/bash "$HOOKS/commit-msg" "$TMP/msg" 2>&1)"
  rc=$?
}

# The hook skips every subject rule while a merge is in progress, so a lingering
# MERGE_HEAD would make all of the assertions below pass without running anything.
# The merge case above ends with `git merge --abort`; this is the assertion that the
# abort worked, and it is here because the failure mode is silent.
assert_eq "" "$(cd "$R" && ls .git/MERGE_HEAD 2>/dev/null)" \
  "the fixture repository is not mid-merge, or every subject rule below is skipped"

# The limit is "> 72", so 72 has to pass and 73 has to fail. A test of one side only
# passes against `-ge 72` as well, which is a different rule.
s72="fix: $(printf 'a%.0s' $(seq 67))"
s73="fix: $(printf 'a%.0s' $(seq 68))"
assert_eq "72" "${#s72}" "the accepted fixture is exactly 72 characters"
assert_eq "73" "${#s73}" "the refused fixture is exactly 73 characters"

hook_msg "$s72"
assert_status 0 "$rc" "a 72-character subject is accepted"
hook_msg "$s73"
assert_status 1 "$rc" "a 73-character subject is refused"
assert_contains "$out" "limit is 72" "and the refusal names the limit"

hook_msg 'fix: repair the thing.'
assert_status 1 "$rc" "a subject ending with a period is refused"
assert_contains "$out" "ends with a period" "and the refusal says so"

# The imperative check is an enumeration, so the suite walks all of it rather than
# the one form it was written for. AGENTS.md: include inputs the implementation was
# not written for, and if a reasonable rewrite would still pass, the suite is
# pinning behaviour.
for v in adding adds added fixes fixed updates updated removes removed changes changed; do
  hook_msg "fix: $v the thing"
  assert_status 1 "$rc" "a subject opening with '$v' is refused"
done
for v in add fix update remove change repair carry; do
  hook_msg "fix: $v the thing"
  assert_status 0 "$rc" "a subject opening with '$v' is accepted"
done

# --- commit-msg: the attribution ban, both halves -----------------------------
# Only the Co-Authored-By form had a test. The others are what a tool writes by
# default, which is the reason the ban exists.
hook_msg "$(printf 'fix: repair the thing\n\nCo-Authored-By: Somebody <nobody@example.invalid>\n')"
assert_status 1 "$rc" "a Co-Authored-By trailer is refused"
assert_contains "$out" "Co-Authored-By trailer is not allowed" "and the refusal names the trailer"

hook_msg "$(printf 'fix: repair the thing\n\nGenerated with a tool\n')"
assert_status 1 "$rc" "a generated-with line is refused"
assert_contains "$out" "tool or model attribution" "and the refusal names the rule"

hook_msg "$(printf 'fix: repair the thing\n\n%s a tool\n' "$(printf '\360\237\244\226')")"
assert_status 1 "$rc" "the robot emoji is refused"

hook_msg "$(printf 'fix: repair the thing\n\nnoreply@anthropic.com\n')"
assert_status 1 "$rc" "a model vendor address is refused"

hook_msg "$(printf 'fix: repair the thing\n\nclaude.com/claude-code\n')"
assert_status 1 "$rc" "a tool URL is refused"

# And an ordinary body is not caught by any of them, or the ban would refuse prose.
hook_msg "$(printf 'fix: repair the thing\n\nThe cause was a substring search. Found by hand.\n')"
assert_status 0 "$rc" "an ordinary body is accepted"

# --- pre-push: the secret scan and the never-publish guard --------------------
# Neither had a test. Both live in pre-push and neither has a server-side
# counterpart, so a hook that stopped refusing would be the only thing between a
# mistake and a public repository — CTRL-9 says exactly that.
#
# A second fixture repository, so the sequence above keeps its own state. The
# never-publish list has to be INSIDE the repository being pushed: pre-push reads
# `$(git rev-parse --show-toplevel)/.githooks/never-publish`, not the list belonging
# to whatever core.hooksPath points at. Without one in the fixture the guard reads
# as absent and passes everything, which is the reason this is written with the list
# present rather than relying on the real one.
R2="$TMP/local2"
git init -q --bare "$TMP/remote2"
mkdir -p "$R2"
(
  cd "$R2" || exit 2
  git init -q .
  git config core.hooksPath "$HOOKS"
  git config user.name 'A Person'
  git config user.email 'person@example.invalid'
  git remote add origin "$TMP/remote2"
  mkdir -p .githooks
  printf '%s\n' '# a fixture list' '.scuba/*' > .githooks/never-publish
  printf 'one\n' > a.txt
  git add -A && git commit -q -m 'feat: add a and a never-publish list'
  git branch -M main
  git push -q origin main
) >/dev/null 2>&1
push2() { ( cd "$R2" && git push "$@" 2>&1 ); }

assert_eq "1" "$(cd "$R2" && git ls-files .githooks/never-publish | grep -c .)" \
  "the fixture repository carries its own never-publish list"

# A never-publish path already on the remote, put there with --no-verify. This is
# SETUP and not an assertion about the guard: the deletion case below needs a path
# that is already public, and the only honest way to get one past the guard is to
# bypass it on purpose. Over a range where the path is added and removed, `git diff`
# reports no change at all, so a fixture that does both inside one range tests
# nothing — which is how the first version of the deletion assertion below passed
# against a hook with the ACMR filter removed.
(
  cd "$R2" || exit 2
  mkdir -p .scuba && printf 'control plane\n' > .scuba/state.md
  git add -A && git commit -q -m 'chore: add orchestration state'
  git push -q --no-verify origin main
) >/dev/null 2>&1
assert_eq "1" "$(cd "$R2" && git ls-tree -r --name-only origin/main | grep -c '^\.scuba/state.md$')" \
  "the setup put a never-publish path on the remote, so the deletion case has one"

# The guard fires, with the list present.
(
  cd "$R2" || exit 2
  printf 'more state\n' > .scuba/other.md
  git add -A && git commit -q -m 'chore: add more orchestration state'
) >/dev/null 2>&1
out="$(push2 origin main)"; rc=$?
assert_status 1 "$rc" "a push touching a never-publish path is refused"
assert_contains "$out" "NEVER-PUBLISH" "and the refusal names the guard"
assert_contains "$out" ".scuba/other.md" "and names the file"
assert_contains "$out" "matches '.scuba/*'" "and the pattern it matched"
( cd "$R2" && git reset -q --hard HEAD~1 ) >/dev/null 2>&1

# Removing the path is not refused. The guard filters on ACMR and not on deletion on
# purpose: a push whose only involvement with a never-publish path is taking it out
# is someone fixing the mistake this exists to prevent. The path has to be on the
# remote already for the range to report a deletion at all.
(
  cd "$R2" || exit 2
  git rm -q .scuba/state.md
  git commit -q -m 'chore: remove orchestration state'
) >/dev/null 2>&1
out="$(push2 origin main)"; rc=$?
assert_status 0 "$rc" "a push that only removes a never-publish path is allowed"
assert_not_contains "$out" "NEVER-PUBLISH" "and the guard does not fire on the deletion"

# The disclosure is printed either way, because its job is to make the blast radius
# visible before the push rather than to refuse.
assert_contains "$out" "would newly publish" "the disclosure is printed on a clean push"
assert_contains "$out" "commit(s)" "and counts the commits"
assert_contains "$out" "secret scan:" "and says which secret scan ran"

# --- pre-push: every built-in secret pattern ---------------------------------
# Six classes, one assertion each, so dropping any single alternative from the
# pattern turns this red rather than five of six staying green. The scan has no
# server-side counterpart at all.
#
# The fixtures are ASSEMBLED at run time. Written literally they would match the
# pattern in this file's own added lines, and pushing this suite would be refused by
# the guard it tests.
F10='A1B2C3D4E5'
F16='A1B2C3D4E5F6G7H8'
F20='A1B2C3D4E5F6G7H8I9J0'
secret_line() {
  case "$1" in
    aws)       printf 'AKIA%s\n' "$F16" ;;
    aws-temp)  printf 'ASIA%s\n' "$F16" ;;
    github)    printf 'ghp_%s\n' "$F16" ;;
    anthropic) printf 'sk-ant-%s\n' "$F16" ;;
    pem)       printf -- '-----BEGIN %s PRIVATE KEY-----\n' 'RSA' ;;
    slack)     printf 'xoxb-%s\n' "$F10" ;;
    assigned)  printf 'api_key=%s\n' "$F20" ;;
  esac
}
leakno=0
for class in aws aws-temp github anthropic pem slack assigned; do
  leakno=$((leakno + 1))
  (
    cd "$R2" || exit 2
    secret_line "$class" > "leak$leakno.txt"
    git add -A && git commit -q -m "chore: add a $class fixture"
  ) >/dev/null 2>&1
  out="$(push2 origin main)"; rc=$?
  assert_status 1 "$rc" "a push carrying a $class credential is refused"
  assert_contains "$out" "SECRETS:" "and the refusal names the secret scan ($class)"
  # Back to whatever the remote actually has, not to HEAD~1. If one of these pushes
  # ever goes through — which is what happens when a clause has been dropped from
  # the pattern — HEAD~1 leaves the branch behind the remote, every later push is
  # rejected as a non-fast-forward, and five more assertions fail for a reason that
  # has nothing to do with them.
  ( cd "$R2" && git fetch -q origin && git reset -q --hard origin/main ) >/dev/null 2>&1
done

# And an ordinary file is not called a secret, or the scan would refuse every push.
(
  cd "$R2" || exit 2
  printf 'an ordinary line of prose about keys and passwords\n' > plain.txt
  git add -A && git commit -q -m 'docs: add a plain file'
) >/dev/null 2>&1
out="$(push2 origin main)"; rc=$?
assert_status 0 "$rc" "an ordinary file is not called a secret"

# --- what is NOT asserted here -----------------------------------------------
# The never-publish guard FAILS OPEN when the list is missing or unreadable:
# check_publish wraps everything in `[ -r "$never_publish" ]` and returns 0
# otherwise, so a push from a tree with no list is unguarded. That is a defect and
# it belongs to issue #57, which owns the two fail-open guards.
#
# The assertion that would pin it — "with no never-publish list, a push touching a
# never-publish path is still refused" — is RED against the hook as it stands, so it
# cannot be added here without also making the fix. It is left to #57 rather than
# half-done in two places. Everything above runs with the list PRESENT, and stays
# true either way.

assert_done
