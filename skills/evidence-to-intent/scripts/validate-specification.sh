#!/usr/bin/env bash
set -euo pipefail

specification="${1:-}"
shift || true
output_root=""
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output-root)
      output_root="${2:-}"
      shift 2
      ;;
    *)
      printf 'usage: validate-specification.sh SPEC --output-root OUTPUT_ROOT\n' >&2
      exit 2
      ;;
  esac
done

if [[ -z "$specification" || ! -f "$specification" ]]; then
  printf '%s:file:not found\n' "${specification:-NOT FOUND}"
  exit 2
fi
if [[ -L "$specification" ]]; then
  printf '%s:path:symlink specifications are not supported\n' "$specification"
  exit 2
fi
if [[ -z "$output_root" || ! -d "$output_root" ]]; then
  printf '%s:output_root:not a directory\n' "${output_root:-NOT FOUND}"
  exit 2
fi

field() {
  local key="$1"
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
  ' "$specification"
}

has_field() {
  local key="$1"
  awk -v key="$key" '
    NR == 1 && $0 == "---" { frontmatter=1; next }
    frontmatter && $0 == "---" { exit }
    frontmatter && index($0, key ":") == 1 { found=1; exit }
    END { exit !found }
  ' "$specification"
}

has_section_content() {
  local heading="$1"
  awk -v heading="## $heading" '
    $0 == heading { found=1; next }
    found && /^## / { exit }
    found && $0 !~ /^[[:space:]]*$/ { content=1 }
    END { exit !(found && content) }
  ' "$specification"
}

failures=0
fail() {
  printf '%s:%s:%s\n' "$specification" "$1" "$2"
  failures=$((failures + 1))
}

if [[ "$(head -n 1 "$specification")" != "---" ]]; then
  fail frontmatter "missing frontmatter"
fi
for key in run_id status implementation_authorized review_status reviewer reviewed_at decision rationale source_revision; do
  has_field "$key" || fail "$key" "missing required field"
done
for key in run_id status implementation_authorized review_status source_revision; do
  [[ -n "$(field "$key")" ]] || fail "$key" "empty required field"
done

[[ "$(field status)" == "provisional" ]] || fail status "must be provisional"
[[ "$(field implementation_authorized)" == "false" ]] || fail implementation_authorized "must be false"

output_root="$(cd "$output_root" && pwd -P)"
specification="$(cd "$(dirname "$specification")" && pwd -P)/$(basename "$specification")"
run_id="$(field run_id)"
if [[ -n "$run_id" ]]; then
  expected="$output_root/$run_id/intent-specification.md"
  [[ "$specification" == "$expected" ]] || fail path "must equal OUTPUT_ROOT/$run_id/intent-specification.md"
fi

review_status="$(field review_status)"
case "$review_status" in
  pending|reviewed) ;;
  *) fail review_status "invalid value: $review_status" ;;
esac

decision="$(field decision)"
case "$decision" in
  ""|accept|revise|reject) ;;
  *) fail decision "invalid value: $decision" ;;
esac
if [[ "$review_status" == "pending" && -n "$decision" ]]; then
  fail decision "pending review cannot contain a decision"
fi
if [[ "$review_status" == "reviewed" ]]; then
  for key in reviewer reviewed_at decision rationale; do
    [[ -n "$(field "$key")" ]] || fail "$key" "required when reviewed"
  done
fi

for heading in \
  'Purpose and explicit boundary' \
  'Owner facts and unresolved questions' \
  'Evidence inventory by E/D/R/A class' \
  'Contradictions, exclusions, and applicability' \
  'Independently derived responsibility map' \
  'Proposed intent and acceptance evidence' \
  'Deterministic/orchestration/AI/human split' \
  'External handoffs and non-responsibilities' \
  'Candidate-name comparison' \
  'Assumptions and NOT FOUND items' \
  'Owner decision block'; do
  has_section_content "$heading" || fail section "missing or empty: $heading"
done

if [[ "$failures" -gt 0 ]]; then
  exit 2
fi
