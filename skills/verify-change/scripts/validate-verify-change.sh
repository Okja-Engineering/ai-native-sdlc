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

receipt_files=()
while IFS= read -r -d '' file; do
  receipt_files+=("$file")
done < <(find "$output_root" -type f -name '05-evidence-receipt.md' -print0)

if [[ "${#receipt_files[@]}" -eq 0 ]]; then
  fail "$output_root" receipt "no 05-evidence-receipt.md found"
fi

for receipt_file in "${receipt_files[@]}"; do
  slice_dir="$(dirname "$receipt_file")"

  if [[ "$(head -n 1 "$receipt_file")" != "---" ]]; then
    fail "$receipt_file" frontmatter "missing frontmatter"
    continue
  fi

  for key in slice_id base_revision verified_revision acceptance_coverage checks findings missing_evidence residual_risks review_status reviewer reviewed_at decision; do
    if ! has_field "$receipt_file" "$key"; then
      fail "$receipt_file" "$key" "missing required field"
    fi
  done

  decision_file="$slice_dir/06-merge-decision.md"
  if [[ ! -f "$decision_file" ]]; then
    fail "$decision_file" file "missing 06-merge-decision.md"
  else
    if [[ "$(head -n 1 "$decision_file")" != "---" ]]; then
      fail "$decision_file" frontmatter "missing frontmatter"
    fi
    for key in reviewer reviewed_at verified_revision decision rationale accepted_residual_risks; do
      if ! has_field "$decision_file" "$key"; then
        fail "$decision_file" "$key" "missing required field"
      fi
    done
    decision="$(field "$decision_file" decision 2>/dev/null || true)"
    case "$decision" in
      merge-ready|revise|split|reject) ;;
      "") fail "$decision_file" decision "required" ;;
      *) fail "$decision_file" decision "invalid value: $decision" ;;
    esac

    receipt_revision="$(field "$receipt_file" verified_revision 2>/dev/null || true)"
    decision_revision="$(field "$decision_file" verified_revision 2>/dev/null || true)"
    if [[ -n "$receipt_revision" && -n "$decision_revision" && "$receipt_revision" != "$decision_revision" ]]; then
      fail "$decision_file" verified_revision "must match receipt verified_revision ($receipt_revision)"
    fi

    receipt_status="$(field "$receipt_file" review_status 2>/dev/null || true)"
    if [[ "$receipt_status" != "reviewed" ]]; then
      fail "$receipt_file" review_status "must be reviewed before merge decision"
    fi
  fi

done

if [[ "$failures" -gt 0 ]]; then
  exit 2
fi
