#!/usr/bin/env bash
set -euo pipefail

# check-loading-rules.sh TREE [--client ROOT] — run the portable
# progressive-disclosure checks (prose references resolve, context_entry
# paths resolve, no entry/never conflicts, no prose references to excluded
# paths) over every .md file under TREE. Prints FAIL lines; exits non-zero
# if any. With --client, path-valued references also resolve against the
# client repository root (proposal §12.4 client-repository class).

here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib-contract.sh"
. "$here/lib-loading.sh"

tree=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --client) CLIENT_ROOT="${2:-}"; shift 2 ;;
    -*) printf 'check-loading-rules: unknown flag %s\n' "$1" >&2; exit 2 ;;
    *) tree="$1"; shift ;;
  esac
done

if [[ -z "$tree" || ! -d "$tree" ]]; then
  printf 'check-loading-rules: tree directory not supplied or does not exist\n' >&2
  exit 2
fi
export CLIENT_ROOT="${CLIENT_ROOT:-}"

fails=0
while IFS= read -r f; do
  for check in check_refs check_context_fields check_never; do
    while IFS= read -r line; do
      printf '%s\n' "$line"; fails=$((fails + 1))
    done < <("$check" "$f")
  done
done < <(find "$tree" -name '*.md' -type f | sort)

[[ "$fails" -eq 0 ]]
