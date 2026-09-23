#!/usr/bin/env bash
set -euo pipefail

# new-snapshot.sh INSPECTED_ROOT OUTPUT_ROOT RUN_ID [--scope p1,p2,...] [--compare-with OBS_DIR]
#
# Creates a new observation snapshot directory for describe-workflow.
# - OUTPUT_ROOT must already exist and resolve OUTSIDE INSPECTED_ROOT
#   (symlink-resolved). Overlap is refused before anything is written.
# - RUN_ID must not already exist — snapshots are never overwritten.
# - Records inspected revision, tree state, inspection scope, and a
#   content-based snapshot_id covering uncommitted/untracked files.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib-snapshot.sh"

usage() {
  echo "usage: new-snapshot.sh INSPECTED_ROOT OUTPUT_ROOT RUN_ID [--scope paths] [--compare-with DIR]" >&2
  exit 2
}

[[ $# -ge 3 ]] || usage
repo="$1"; outroot="$2"; runid="$3"; shift 3
scope="."; compare=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) scope="${2:?--scope needs a value}"; shift 2 ;;
    --compare-with) compare="${2:?--compare-with needs a value}"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -d "$repo" ]] || { echo "ERROR: inspected root '$repo' is not a directory" >&2; exit 2; }
[[ -d "$outroot" ]] || { echo "ERROR: output root '$outroot' is not a directory — create it explicitly" >&2; exit 2; }
case "$runid" in */*|''|*..*) echo "ERROR: invalid run id '$runid'" >&2; exit 2 ;; esac

canon_repo="$(cd "$repo" && pwd -P)"
canon_out="$(cd "$outroot" && pwd -P)"

case "$canon_out" in
  "$canon_repo"|"$canon_repo"/*)
    echo "REFUSE: output root resolves inside inspected repository ($canon_out)" >&2
    exit 3 ;;
esac

dest="$canon_out/$runid"
if [[ -e "$dest" ]]; then
  echo "REFUSE: run id '$runid' already exists at $dest — snapshots are never overwritten" >&2
  exit 3
fi

# Revision and tree state.
if git -C "$canon_repo" rev-parse HEAD >/dev/null 2>&1; then
  revision="$(git -C "$canon_repo" rev-parse HEAD)"
  if [[ -n "$(git -C "$canon_repo" status --porcelain 2>/dev/null)" ]]; then
    tree_state=dirty
  else
    tree_state=clean
  fi
else
  revision="none"
  tree_state=no-git
fi

mkdir -p "$dest"
snapshot_manifest "$canon_repo" "$scope" | sort > "$dest/SNAPSHOT-MANIFEST"
snap_id="sha256:$(hash_stdin < "$dest/SNAPSHOT-MANIFEST")"

scope_display="$(printf '%s' "$scope" | tr ',' '|')"

cat > "$dest/OBSERVATION.md" <<EOF
# Workflow observation — $runid

Draft claims below as \`\`\`contract blocks per
\`workflow-observation/0.1.0\`. Every claim needs a source locator and a basis
class (declared / configured / executed); gaps carry no source.

\`\`\`contract
id: obs-$runid
kind: observation
schema_version: workflow-observation/0.1.0
inspected_repo: $canon_repo
inspected_revision: $revision
tree_state: $tree_state
snapshot_id: $snap_id
inspection_scope: $scope
observed_at: $(date +%Y-%m-%d)
observer: describe-workflow
\`\`\`
EOF

cat > "$dest/GAP-REPORT.md" <<'EOF'
# Gap report

Missing owner facts for follow-up. Add one gap block per fact using the
`kind: gap` contract format (missing, needed_from, optional searched) — see
references/observation-contract.md. A gap never carries a source locator.
EOF

if [[ -n "$compare" ]]; then
  "$SCRIPT_DIR/compare-observations.sh" "$compare" "$dest" > "$dest/COMPARISON.md"
fi

printf 'CREATE %s\n' "$dest"
