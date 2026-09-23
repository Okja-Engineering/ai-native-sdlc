#!/usr/bin/env bash
set -euo pipefail

output_root="${1:-}"

if [[ -z "$output_root" || ! -d "$output_root" ]]; then
  printf '%s:output_root:not a directory\n' "${output_root:-NOT FOUND}"
  exit 2
fi

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

failures=0
fail() {
  printf '%s:%s:%s\n' "$1" "$2" "$3"
  failures=$((failures + 1))
}

intent_files=()
while IFS= read -r -d '' file; do
  intent_files+=("$file")
done < <(find "$output_root" -type f -name '01-intent.md' -print0)

if [[ "${#intent_files[@]}" -eq 0 ]]; then
  fail "$output_root" intent "no 01-intent.md found"
fi

for intent_file in "${intent_files[@]}"; do
  slice_dir="$(dirname "$intent_file")"
  slice_id="$(basename "$slice_dir")"

  if [[ "$(head -n 1 "$intent_file")" != "---" ]]; then
    fail "$intent_file" frontmatter "missing frontmatter"
    continue
  fi

  for key in slice_id source request_owner outcome affected_user_or_operator constraints non_goals review_status reviewer reviewed_at decision; do
    if ! has_field "$intent_file" "$key"; then
      fail "$intent_file" "$key" "missing required field"
    fi
  done

  slice_file="$slice_dir/02-slice.md"
  if [[ ! -f "$slice_file" ]]; then
    fail "$slice_file" file "missing 02-slice.md"
  else
    if [[ "$(head -n 1 "$slice_file")" != "---" ]]; then
      fail "$slice_file" frontmatter "missing frontmatter"
    fi
    for key in slice_id independent_value boundaries dependencies acceptance_evidence merge_condition rollback_containment review_status reviewer reviewed_at decision rationale; do
      if ! has_field "$slice_file" "$key"; then
        fail "$slice_file" "$key" "missing required field"
      fi
    done
  fi

  plan_file="$slice_dir/03-evidence-plan.md"
  if [[ ! -f "$plan_file" ]]; then
    fail "$plan_file" file "missing 03-evidence-plan.md"
  else
    if [[ "$(head -n 1 "$plan_file")" != "---" ]]; then
      fail "$plan_file" frontmatter "missing frontmatter"
    fi
    for key in slice_id acceptance_checks commands expected_signals evidence_locations failure_behavior protected_checks review_status reviewer reviewed_at decision; do
      if ! has_field "$plan_file" "$key"; then
        fail "$plan_file" "$key" "missing required field"
      fi
    done
  fi

  decision="$(field "$intent_file" decision || true)"
  if [[ "$decision" != "accept" ]]; then
    fail "$intent_file" decision "must be accept to proceed"
  fi
  slice_decision="$(field "$slice_file" decision 2>/dev/null || true)"
  if [[ -n "$slice_decision" && "$slice_decision" != "select" && "$slice_decision" != "accept" ]]; then
    fail "$slice_file" decision "must be select or accept to proceed"
  fi
  plan_decision="$(field "$plan_file" decision 2>/dev/null || true)"
  if [[ -n "$plan_decision" && "$plan_decision" != "accept" ]]; then
    fail "$plan_file" decision "must be accept to proceed"
  fi
done

if [[ "$failures" -gt 0 ]]; then
  exit 2
fi
