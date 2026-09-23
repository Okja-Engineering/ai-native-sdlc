#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
. tests/lib/contract-blocks.sh
. skills/sdlc-scaffold/scripts/lib-loading.sh

# Progressive-disclosure rules as executable checks (proposal §5).
# Context entries are required entry points, not a read allow-list; these
# tests enforce resolution, budgets, no whole-directory loads, entry/never
# conflicts, and routing-link presence. The check functions come from the
# sdlc-scaffold loading library so the exporter's staged validation runs the
# same rules (proposal §12.6).
#
# Check functions EMIT "  FAIL file:kind:msg" lines on stdout; they never
# touch the global counter. Callers decide whether findings are real
# failures (counted) or expected fixture failures (isolated and discarded).
# This keeps a broken example from being masked by a negative fixture.

failures=0
emit_fail() { printf '  FAIL %s:%s:%s\n' "$1" "$2" "$3"; }
fail() { emit_fail "$@"; failures=$((failures + 1)); }
ok()   { printf '  ok — %s\n' "$1"; }

modular="examples/leaked-db-errors/modular"
compact="examples/leaked-db-errors/compact/SDLC.md"
broken="tests/fixtures/loading-rules/broken-refs"
dirload="tests/fixtures/loading-rules/dir-load"
ctxbad="tests/fixtures/loading-rules/context-entry-missing"
ctxconflict="tests/fixtures/loading-rules/entry-never-conflict"

# scan_examples FN — run check FN over every real file; findings count.
scan_examples() {
  local fn="$1" f line n=0
  while IFS= read -r f; do
    while IFS= read -r line; do printf '%s\n' "$line"; n=$((n + 1)); done \
      < <("$fn" "$f")
  done < <(find "$modular" -name '*.md' | sort)
  while IFS= read -r line; do printf '%s\n' "$line"; n=$((n + 1)); done \
    < <("$fn" "$compact")
  failures=$((failures + n))
}

# expect_fail DIR LABEL FN — run check FN over fixture DIR; findings are
# expected: reported, counted locally, never added to the real-failure count.
expect_fail() { # dir, label, check-fn
  local dir="$1" label="$2" fn="$3" f line n=0
  if [[ ! -d "$dir" ]]; then fail "$dir" fixture "missing"; return; fi
  while IFS= read -r f; do
    while IFS= read -r line; do printf '%s\n' "$line"; n=$((n + 1)); done \
      < <("$fn" "$f")
  done < <(find "$dir" -name '*.md' | sort)
  if [[ "$n" -gt 0 ]]; then
    ok "$label detected ($n)"
  else
    fail "$dir" fixture "$label: fixture did not trigger a failure"
  fi
}

echo "== line budgets"
check_budget() { # file, limit
  local n; n="$(wc -l < "$1" | tr -d ' ')"
  [[ "$n" -le "$2" ]] && ok "$1 ($n <= $2)" || fail "$1" budget "$n lines exceeds $2"
}
check_budget "$modular/ROUTER.md" 150
check_budget "$modular/CONTEXT.md" 150
check_budget "$compact" 260
while IFS= read -r f; do check_budget "$f" 80; done \
  < <(find "$modular/stages" -name CONTEXT.md | sort)

echo "== referenced paths resolve and are files (not whole-directory loads)"
scan_examples check_refs
ok "reference scan complete"

echo "== context_entry paths resolve; no entry/never conflicts"
scan_examples check_context_fields
ok "context field scan complete"

echo "== context_never paths are not referenced in prose"
scan_examples check_never
ok "context_never scan complete"

echo "== negative fixtures (expected fail; isolated from real-failure count)"
expect_fail "$broken"      "broken refs"          check_refs
expect_fail "$dirload"     "directory loads"      check_refs
expect_fail "$ctxbad"      "missing context_entry" check_context_fields
expect_fail "$ctxconflict" "entry/never conflict" check_context_fields

echo "== regression: a real failure is not erased by negative fixtures"
# Reproduces the counter-reset bug: inject one real failure, run a negative
# fixture, then require the count to be exactly one higher than before.
reg="$(mktemp -d)"
printf 'Stage references `missing-review-reference.md`.\n' > "$reg/PROBE.md"
pre=$failures
probe_out="$(check_refs "$reg/PROBE.md")"
printf '%s\n' "$probe_out"
[[ -n "$probe_out" ]] && failures=$((failures + 1))
expect_fail "$broken" "broken refs (regression re-scan)" check_refs
if [[ "$failures" -eq $((pre + 1)) ]]; then
  ok "accumulated failure count preserved through fixture isolation"
  failures=$pre  # the probe failure was synthetic; retire it
else
  fail "$reg/PROBE.md" counter \
    "fixture isolation disturbed the failure count (expected $((pre + 1)), got $failures)"
fi
rm -rf "$reg"

echo "== routing links (presence only — not a behavioral navigation test)"
grep -q 'examples/leaked-db-errors/README.md' AGENTS.md \
  && ok "AGENTS.md names the route to the worked example" \
  || fail AGENTS.md nav "no route to worked example"
grep -q 'compact/SDLC.md' examples/leaked-db-errors/README.md \
  && grep -q 'modular/ROUTER.md' examples/leaked-db-errors/README.md \
  && ok "example README names both forms" \
  || fail examples/leaked-db-errors/README.md nav "does not name both forms"
grep -q 'CONTEXT.md' "$modular/ROUTER.md" \
  && ok "modular router names the CONTEXT.md handoff" \
  || fail "$modular/ROUTER.md" nav "no CONTEXT.md handoff"

if [[ "$failures" -gt 0 ]]; then
  echo "FAIL: $failures loading-rule check(s) failed" >&2
  exit 1
fi
echo "PASS: loading rules"
