#!/usr/bin/env bash
set -euo pipefail

target_repo="${1:-}"
workflow_spec="${2:-}"

failures=0
fail() {
  printf '%s:%s\n' "$1" "$2"
  failures=$((failures + 1))
}

if [[ -z "$target_repo" ]]; then
  fail target_repo "not supplied"
fi
if [[ ! -d "${target_repo:-}" ]]; then
  fail target_repo "not a directory"
fi
if [[ -z "$workflow_spec" ]]; then
  fail workflow_spec "not supplied"
fi
if [[ ! -f "${workflow_spec:-}" ]]; then
  fail workflow_spec "not a file"
fi

if [[ -f "$workflow_spec" && "$(head -n 1 "$workflow_spec")" != "---" ]]; then
  fail workflow_spec "missing frontmatter"
fi

if [[ "$failures" -gt 0 ]]; then
  exit 2
fi
