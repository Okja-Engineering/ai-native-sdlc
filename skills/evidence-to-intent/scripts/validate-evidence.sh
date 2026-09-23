#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

input_root="${1:-}"
if [[ -z "$input_root" || ! -d "$input_root" ]]; then
  printf '%s:input_root:not a directory\n' "${input_root:-NOT FOUND}"
  exit 2
fi
input_root="$(cd "$input_root" && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
ids="$tmp/ids"
: > "$ids"
failures=0
records=0

field() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { frontmatter=1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && index($0, key ":") == 1 {
      sub("^[^:]*:[[:space:]]*", "")
      sub(/[[:space:]]+$/, "")
      gsub(/^['\''\"]|['\''\"]$/, "")
      sub(/^[[:space:]]+/, "")
      sub(/[[:space:]]+$/, "")
      print
      exit
    }
  ' "$file"
}

has_field() {
  local file="$1" key="$2"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { frontmatter=1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && index($0, key ":") == 1 { found=1; exit }
    END { exit !found }
  ' "$file"
}

fail() {
  printf '%s:%s:%s\n' "$1" "$2" "$3"
  failures=$((failures + 1))
}

files=()
while IFS= read -r -d '' file; do
  files+=("$file")
done < <(find "$input_root" -type f -name '*.md' -print0)
for ((i=1; i<${#files[@]}; i++)); do
  current="${files[$i]}"
  j=$((i - 1))
  while [[ "$j" -ge 0 && "${files[$j]}" > "$current" ]]; do
    files[$((j + 1))]="${files[$j]}"
    j=$((j - 1))
  done
  files[$((j + 1))]="$current"
done

for file in "${files[@]}"; do
  case "$file" in
    */research/claims/*|*/research/patterns/*|*/research/controls/*|*/research/measures/*)
      if [[ "$(head -n 1 "$file")" != "---" ]]; then
        fail "$file" frontmatter "malformed frontmatter"
        continue
      fi
      ;;
  esac

  id="$(field "$file" id)"
  [[ -n "$id" ]] || continue
  records=$((records + 1))

  for key in id title kind status review_status source_locator; do
    value="$(field "$file" "$key")"
    if ! has_field "$file" "$key"; then
      fail "$file" "$key" "missing required field"
    elif [[ -z "$value" ]]; then
      fail "$file" "$key" "empty required field"
    fi
  done

  if [[ ! "$id" =~ ^(R-[A-Z0-9]+(-[A-Z0-9]+)*|[EDAQ][0-9]+)$ ]]; then
    fail "$file" id "invalid evidence id: $id"
  fi
  if grep -Fqx "$id" "$ids"; then
    fail "$file" id "duplicate evidence id: $id"
  else
    printf '%s\n' "$id" >> "$ids"
  fi

  kind="$(field "$file" kind)"
  case "$kind" in
    empirical-claim|implementation-claim|design-pattern|control-pattern|measurement-pattern|owner-answer|owner-correction|inspected-document|assumption|open-question) ;;
    "") ;;
    *) fail "$file" kind "invalid kind: $kind" ;;
  esac

  status="$(field "$file" status)"
  case "$status" in
    evaluated|current|open|superseded|rejected) ;;
    "") ;;
    *) fail "$file" status "invalid status: $status" ;;
  esac

  review_status="$(field "$file" review_status)"
  case "$review_status" in
    pending-owner-review|reviewed|superseded|rejected) ;;
    "") ;;
    *) fail "$file" review_status "invalid review_status: $review_status" ;;
  esac

  locator="$(field "$file" source_locator)"
  if [[ -z "$locator" || "$locator" == *://* || "$locator" == \#* ]]; then
    continue
  fi
  if [[ "$locator" = /* ]]; then
    target="$locator"
  else
    target="$(dirname "$file")/$locator"
  fi
  if [[ -L "$target" ]]; then
    fail "$file" source_locator "symlink source locators are not supported: $locator"
    continue
  fi
  if [[ ! -e "$target" ]]; then
    fail "$file" source_locator "unresolved local path: $locator"
    continue
  fi
  target="$(cd "$(dirname "$target")" && pwd -P)/$(basename "$target")"
  case "$target" in
    "$input_root"|"$input_root"/*) ;;
    *) fail "$file" source_locator "outside input root: $locator" ;;
  esac
done

if [[ "$records" -eq 0 ]]; then
  fail "$input_root" evidence "no E/D/R/A/Q evidence records found"
fi

if [[ "$failures" -gt 0 ]]; then
  exit 2
fi
