#!/usr/bin/env bash
set -euo pipefail

# compare-observations.sh OLD_OBS_DIR NEW_OBS_DIR
#
# Prints a comparison report on stdout. Read-only: neither snapshot is
# modified. Envelope identity changes are reported; claim/conflict/gap
# content is diffed on normalized contract lines.

old_dir="${1:-}"; new_dir="${2:-}"
for d in "$old_dir" "$new_dir"; do
  [[ -f "$d/OBSERVATION.md" ]] || { echo "ERROR: '$d' is not an observation snapshot" >&2; exit 2; }
done

# norm_obs FILE — id::key=item lines, one per list item (same encoding as the
# workflow-contract normalizer).
norm_obs() {
  awk '
    /^```contract[[:space:]]*$/ { inb = 1; id = ""; next }
    inb && /^```[[:space:]]*$/ { inb = 0; next }
    inb && /^[A-Za-z_]+:/ {
      key = $0; sub(/:.*/, "", key)
      val = $0; sub(/^[^:]*:[[:space:]]*/, "", val)
      n = split(val, p, "|")
      for (i = 1; i <= n; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", p[i])
      for (i = 1; i <= n; i++) for (j = i + 1; j <= n; j++)
        if (p[j] < p[i]) { t = p[i]; p[i] = p[j]; p[j] = t }
      if (key == "id") id = p[1]
      for (i = 1; i <= n; i++) printf "%s::%s=%s\n", id, key, p[i]
    }
  ' "$1"
}

env_val() { # file, key
  awk -v key="$2" '
    /^```contract[[:space:]]*$/ { inb=1; next }
    inb && /^```[[:space:]]*$/ { inb=0; next }
    inb && index($0, key ":") == 1 { sub("^[^:]*:[[:space:]]*", ""); sub(/[[:space:]]+$/, ""); print; exit }
  ' "$1"
}

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
find "$old_dir" -name '*.md' | sort | while IFS= read -r f; do norm_obs "$f"; done | sort > "$work/old.norm"
find "$new_dir" -name '*.md' | sort | while IFS= read -r f; do norm_obs "$f"; done | sort > "$work/new.norm"

printf '# Observation comparison\n\n'
printf -- '- old: %s\n- new: %s\n\n' "$old_dir" "$new_dir"
printf '## Snapshot identity\n\n'
printf -- '- inspected_revision: %s -> %s\n' \
  "$(env_val "$old_dir/OBSERVATION.md" inspected_revision)" \
  "$(env_val "$new_dir/OBSERVATION.md" inspected_revision)"
printf -- '- snapshot_id: %s -> %s\n' \
  "$(env_val "$old_dir/OBSERVATION.md" snapshot_id)" \
  "$(env_val "$new_dir/OBSERVATION.md" snapshot_id)"
printf -- '- tree_state: %s -> %s\n\n' \
  "$(env_val "$old_dir/OBSERVATION.md" tree_state)" \
  "$(env_val "$new_dir/OBSERVATION.md" tree_state)"

printf '## Differences\n\n'
if diff -u "$work/old.norm" "$work/new.norm" > "$work/diff" 2>&1; then
  printf 'No claim, conflict, or gap differences.\n'
else
  sed 's/^/    /' "$work/diff"
fi
