#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

for path in LICENSE CHANGELOG.md RELEASE_NOTES.md .out-of-scope.md; do
  test -f "$path"
done

check_manifest() {
  local path="$1" expected_skills="$2"
  test "$(jq -r '.name' "$path")" = "evidence-led-delivery"
  test "$(jq -r '.version' "$path")" = "0.1.0"
  test "$(jq -r '.skills' "$path")" = "$expected_skills"
  test "$(jq -r '.license' "$path")" = "MIT"
}
check_manifest .devin-plugin/plugin.json skills
check_manifest .claude-plugin/plugin.json ./skills/
check_manifest .codex-plugin/plugin.json ./skills/
check_manifest .cursor-plugin/plugin.json ./skills/

for skill_dir in skills/*; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"
  test -f "$skill_file"
  grep -q "^name: $skill_name$" "$skill_file"
  for field in description license compatibility metadata; do
    grep -q "^$field:" "$skill_file"
  done
  grep -q '^  version: "0\.1\.0"$' "$skill_file"
  for heading in 'When to use' Inputs Process 'Deterministic actions' Orchestration 'AI judgment' Outputs 'Human check' Example Constraints; do
    grep -q "^## $heading" "$skill_file"
  done
  refs=()
  while IFS= read -r -d '' ref; do
    refs+=("$ref")
  done < <(find "$skill_dir/references" -type f -print0 2>/dev/null || true)
  if [[ "${#refs[@]}" -eq 0 ]]; then
    echo "FAIL: $skill_name has no references/" >&2
    exit 1
  fi

  scripts=()
  while IFS= read -r -d '' script; do
    scripts+=("$script")
  done < <(find "$skill_dir/scripts" -type f -print0 2>/dev/null || true)
  if [[ "${#scripts[@]}" -eq 0 ]]; then
    echo "FAIL: $skill_name has no scripts/" >&2
    exit 1
  fi
  for script in "${scripts[@]}"; do
    test -x "$script" || {
      echo "FAIL: $script is not executable" >&2
      exit 1
    }
    bash -n "$script"
  done
done

test -f skills/evidence-to-intent/references/evidence-contract.md
test -f skills/evidence-to-intent/references/specification-contract.md
test ! -d skills/reviewable-delivery

if find . -type f -name '*.py' -print -quit | grep -q .; then
  echo 'FAIL: Python scripts are prohibited' >&2
  exit 1
fi

echo "PASS: structure"
