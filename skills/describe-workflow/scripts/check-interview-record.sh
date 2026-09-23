#!/usr/bin/env bash
set -euo pipefail

# check-interview-record.sh FILE
#
# Validates the optional Workflow Package Builder interview record against
# the minimal input contract: one ```contract block per evidence row with
# id, statement, source-ref, and review-status. Unsupported formats produce
# an explicit diagnostic and a non-zero exit — they are never silently
# interpreted as verified owner facts.

file="${1:-}"
if [[ -z "$file" || ! -f "$file" ]]; then
  printf '%s:interview:not a readable file — unsupported interview input\n' "${file:-NOT FOUND}"
  exit 2
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
awk -v dir="$tmp" '
  /^```contract[[:space:]]*$/ { inb=1; n++; out=sprintf("%s/blk-%d.contract", dir, n); next }
  inb && /^```[[:space:]]*$/ { inb=0; close(out); next }
  inb { print > out }
' "$file"

blocks=()
while IFS= read -r b; do blocks+=("$b"); done < <(find "$tmp" -name '*.contract' | sort)
if [[ "${#blocks[@]}" -eq 0 ]]; then
  printf '%s:interview:no contract blocks — unsupported interview input\n' "$file"
  exit 2
fi

bval() {
  awk -v key="$2" '
    index($0, key ":") == 1 { sub("^[^:]*:[[:space:]]*", ""); sub(/[[:space:]]+$/, ""); print; exit }
  ' "$1"
}

failures=0
rows=0
for b in "${blocks[@]}"; do
  [[ "$(bval "$b" kind)" == "interview-evidence" ]] || continue
  rows=$((rows + 1))
  for k in id statement source-ref review-status; do
    if [[ -z "$(bval "$b" "$k")" ]]; then
      printf '%s:interview.%s:missing required field\n' "$file" "$k"
      failures=$((failures + 1))
    fi
  done
done

if [[ "$rows" -eq 0 ]]; then
  printf '%s:interview:no kind:interview-evidence rows — unsupported interview input\n' "$file"
  exit 2
fi
[[ "$failures" -eq 0 ]] || exit 1
printf '%s: ok (%s evidence row(s))\n' "$file" "$rows"
