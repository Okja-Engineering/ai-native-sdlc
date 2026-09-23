#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

# describe-workflow fixture + behavior tests (proposal §11, S7).
# Static fixtures exercise the observation validator and interview gate;
# dynamic cases exercise snapshot init, overlap/run-id refusal, inspected-repo
# immutability, staleness, and rerun comparison.

SCRIPTS="skills/describe-workflow/scripts"
FX="tests/fixtures/describe-workflow"

failures=0
check() { # name, ok(0)/bad(1), detail
  if [[ "$2" -eq 0 ]]; then printf '  ok — %s\n' "$1"; else
    printf '  MISMATCH — %s: %s\n' "$1" "$3"; failures=$((failures + 1))
  fi
}

# --- static observation fixtures ------------------------------------------
echo "== observation validator fixtures"
obs_case() { # name, dir, expected(pass|fail)
  printf 'case: %s (expected %s)\n' "$1" "$3"
  local actual=pass
  "$SCRIPTS/validate-observation.sh" "$2" >/dev/null 2>&1 || actual=fail
  if [[ "$actual" == "$3" ]]; then printf '  ok\n'; else
    printf '  MISMATCH: expected %s, got %s\n' "$3" "$actual"
    "$SCRIPTS/validate-observation.sh" "$2" || true
    failures=$((failures + 1))
  fi
}
obs_case "valid"                  "$FX/valid"                    pass
obs_case "missing-locator"        "$FX/missing-locator"          fail
obs_case "executed-no-record"     "$FX/executed-no-record"       fail
obs_case "conflict-missing-locator" "$FX/conflict-missing-locator" fail
obs_case "gap-with-source"        "$FX/gap-with-source"          fail
obs_case "bad-schema-version"     "$FX/bad-schema-version"       fail
obs_case "duplicate-claim-id"     "$FX/duplicate-claim-id"       fail
obs_case "bad-claim-status"       "$FX/bad-claim-status"         fail
obs_case "duplicate-field"        "$FX/duplicate-field"          fail
obs_case "malformed-line"         "$FX/malformed-line"           fail
obs_case "executed-rev-only"      "$FX/executed-rev-only"        fail

# --- interview input gate --------------------------------------------------
echo "== interview record fixtures"
iv_case() { # name, file, expected
  printf 'case: %s (expected %s)\n' "$1" "$3"
  local actual=pass
  "$SCRIPTS/check-interview-record.sh" "$2" >/dev/null 2>&1 || actual=fail
  if [[ "$actual" == "$3" ]]; then printf '  ok\n'; else
    printf '  MISMATCH: expected %s, got %s\n' "$3" "$actual"
    "$SCRIPTS/check-interview-record.sh" "$2" || true
    failures=$((failures + 1))
  fi
}
iv_case "good-interview" "$FX/good-interview.md" pass
iv_case "bad-interview"  "$FX/bad-interview.md"  fail

# --- dynamic snapshot behavior --------------------------------------------
echo "== snapshot behavior"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
repo="$work/repo"; out="$work/observations"
mkdir -p "$repo/.github/workflows" "$out"
printf '# rules\n' > "$repo/AGENTS.md"
printf 'name: ci\n' > "$repo/.github/workflows/ci.yml"

repo_manifest() { find "$repo" -type f | sort | xargs shasum -a 256 | shasum -a 256 | awk '{print $1}'; }

before="$(repo_manifest)"
"$SCRIPTS/new-snapshot.sh" "$repo" "$out" run-01 --scope 'AGENTS.md,.github' > "$work/init.log" 2>&1
check "snapshot created" "$?" "$(cat "$work/init.log")"
after="$(repo_manifest)"
[[ "$before" == "$after" ]] \
  && check "inspected repo byte-identical after run" 0 "" \
  || check "inspected repo byte-identical after run" 1 "repo changed during inspection"

printf 'case: output root inside inspected repo (expected refuse)\n'
mkdir -p "$repo/docs"
"$SCRIPTS/new-snapshot.sh" "$repo" "$repo/docs" run-x >"$work/o1.log" 2>&1 && rc=0 || rc=$?
[[ "$rc" -ne 0 ]] && grep -q 'REFUSE' "$work/o1.log" \
  && check "overlap refused" 0 "" || check "overlap refused" 1 "rc=$rc $(cat "$work/o1.log")"

printf 'case: output root overlapping via symlink (expected refuse)\n'
mkdir -p "$repo/obs-home"; ln -s "$repo/obs-home" "$work/outlink"
"$SCRIPTS/new-snapshot.sh" "$repo" "$work/outlink" run-x >"$work/o2.log" 2>&1 && rc=0 || rc=$?
[[ "$rc" -ne 0 ]] && grep -q 'REFUSE' "$work/o2.log" \
  && check "symlink overlap refused" 0 "" || check "symlink overlap refused" 1 "rc=$rc $(cat "$work/o2.log")"

printf 'case: existing run id (expected refuse)\n'
"$SCRIPTS/new-snapshot.sh" "$repo" "$out" run-01 >"$work/o3.log" 2>&1 && rc=0 || rc=$?
[[ "$rc" -ne 0 ]] && grep -q 'REFUSE' "$work/o3.log" \
  && check "existing run id refused" 0 "" || check "existing run id refused" 1 "rc=$rc $(cat "$work/o3.log")"

printf 'case: end-to-end valid snapshot (expected pass)\n'
cat >> "$out/run-01/OBSERVATION.md" <<'EOF'

```contract
id: claim-01
kind: claim
statement: the router maps tasks to files
plane: routing
basis: declared
source: AGENTS.md:1-2
status: observed
```
EOF
"$SCRIPTS/validate-observation.sh" "$out/run-01" "$repo" >/dev/null 2>&1 \
  && check "fresh snapshot validates clean" 0 "" \
  || { check "fresh snapshot validates clean" 1 ""; "$SCRIPTS/validate-observation.sh" "$out/run-01" "$repo" || true; }

printf 'case: dirty-tree staleness — same HEAD, uncommitted change (expected fail)\n'
git -C "$repo" init -q 2>/dev/null || true
git -C "$repo" -c user.email=t@t -c user.name=t add -A 2>/dev/null
git -C "$repo" -c user.email=t@t -c user.name=t commit -qm init 2>/dev/null
# re-snapshot at the committed state so the only delta is the dirty edit
"$SCRIPTS/new-snapshot.sh" "$repo" "$out" run-02 --scope 'AGENTS.md,.github' >/dev/null 2>&1
printf '# rules changed without commit\n' > "$repo/AGENTS.md"
"$SCRIPTS/validate-observation.sh" "$out/run-02" "$repo" >"$work/stale.log" 2>&1 && rc=0 || rc=$?
[[ "$rc" -ne 0 ]] && grep -qi 'stale' "$work/stale.log" \
  && check "dirty tree reported stale (HEAD unchanged)" 0 "" \
  || check "dirty tree reported stale (HEAD unchanged)" 1 "rc=$rc $(cat "$work/stale.log")"

printf 'case: symlink retarget makes observation stale (expected fail)\n'
linkrepo="$work/linkrepo"; out2="$work/obs2"
mkdir -p "$linkrepo" "$out2"
printf 'rules A\n' > "$linkrepo/rules-a.md"
printf 'rules B\n' > "$linkrepo/rules-b.md"
ln -s 'rules-a.md' "$linkrepo/AGENTS.md"
"$SCRIPTS/new-snapshot.sh" "$linkrepo" "$out2" run-01 --scope '.' >/dev/null 2>&1
grep -q '^LINK  AGENTS.md  ->  rules-a.md' "$out2/run-01/SNAPSHOT-MANIFEST" \
  && check "symlink recorded with target" 0 "" \
  || check "symlink recorded with target" 1 "$(cat "$out2/run-01/SNAPSHOT-MANIFEST")"
rm "$linkrepo/AGENTS.md"; ln -s 'rules-b.md' "$linkrepo/AGENTS.md"
"$SCRIPTS/validate-observation.sh" "$out2/run-01" "$linkrepo" >"$work/link.log" 2>&1 && rc=0 || rc=$?
[[ "$rc" -ne 0 ]] && grep -qi 'stale' "$work/link.log" \
  && check "retargeted symlink reported stale" 0 "" \
  || check "retargeted symlink reported stale" 1 "rc=$rc $(cat "$work/link.log")"

printf 'case: external symlink recorded, never traversed (expected pass)\n'
ln -s '/etc/hosts' "$linkrepo/EXTERNAL.md"
"$SCRIPTS/new-snapshot.sh" "$linkrepo" "$out2" run-02 --scope '.' >/dev/null 2>&1
grep -q '^LINK  EXTERNAL.md  ->  /etc/hosts  \[external\]' "$out2/run-02/SNAPSHOT-MANIFEST" \
  && check "external link marked, not read" 0 "" \
  || check "external link marked, not read" 1 "$(cat "$out2/run-02/SNAPSHOT-MANIFEST")"

printf 'case: broken links — missing parent / missing final name (expected complete snapshot)\n'
ln -s 'missing-dir/file.md' "$linkrepo/BROKEN-PARENT.md"
ln -s 'rules-a.md/no-such.md' "$linkrepo/BROKEN-NAME.md"
ln -s 'missing-name.md' "$linkrepo/BROKEN-FILE.md"
"$SCRIPTS/new-snapshot.sh" "$linkrepo" "$out2" run-03 --scope '.' >"$work/broken.log" 2>&1 && rc=0 || rc=$?
ok=0
[[ "$rc" -eq 0 && -f "$out2/run-03/SNAPSHOT-MANIFEST" ]] || ok=1
for pat in 'BROKEN-PARENT.md  ->  missing-dir/file.md  \[broken\]' \
           'BROKEN-NAME.md  ->  rules-a.md/no-such.md  \[broken\]' \
           'BROKEN-FILE.md  ->  missing-name.md  \[broken\]'; do
  grep -q "$pat" "$out2/run-03/SNAPSHOT-MANIFEST" || ok=1
done
check "broken links recorded; snapshot completes" "$ok" "rc=$rc $(cat "$work/broken.log"; cat "$out2/run-03/SNAPSHOT-MANIFEST" 2>/dev/null)"

printf 'case: rerun — new snapshot + comparison, prior untouched (expected pass)\n'
prior_hash="$(shasum -a 256 "$out/run-01/OBSERVATION.md" | awk '{print $1}')"
"$SCRIPTS/new-snapshot.sh" "$repo" "$out" run-03 --scope 'AGENTS.md,.github' \
  --compare-with "$out/run-01" >/dev/null 2>&1
ok=0
[[ -s "$out/run-03/COMPARISON.md" ]] || ok=1
[[ "$(shasum -a 256 "$out/run-01/OBSERVATION.md" | awk '{print $1}')" == "$prior_hash" ]] || ok=1
check "comparison written; prior snapshot untouched" "$ok" ""

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures describe-workflow check(s) failed" >&2
  exit 1
fi
echo "PASS: describe-workflow"
