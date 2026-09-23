#!/usr/bin/env bash
set -euo pipefail

# validate-observation.sh OBS_DIR [INSPECTED_REPO]
#
# Structural validation of a workflow-observation/0.1.0 snapshot: envelope
# completeness, per-claim source locators and basis classes, conflict
# integrity, gap rules. When the inspected repo is resolvable, also reports
# staleness (snapshot_id no longer matches, revision superseded).
# An incomplete or conflicted observation is still valid — NOT FOUND and
# unresolved are legal here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/lib-snapshot.sh"

obs_dir="${1:-}"
if [[ -z "$obs_dir" || ! -d "$obs_dir" ]]; then
  printf '%s:obs_dir:not a directory\n' "${obs_dir:-NOT FOUND}"
  exit 2
fi

obs_file="$obs_dir/OBSERVATION.md"
if [[ ! -f "$obs_file" ]]; then
  printf '%s:envelope:no OBSERVATION.md\n' "$obs_dir"
  exit 2
fi

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

# Extract every ```contract block in every .md file in the snapshot.
i=0
find "$obs_dir" -name '*.md' | sort | while IFS= read -r f; do
  i=$((i + 1))
  awk -v dir="$tmp" -v prefix="f$i" '
    /^```contract[[:space:]]*$/ { inb=1; n++; out=sprintf("%s/%s-%d.contract", dir, prefix, n); next }
    inb && /^```[[:space:]]*$/ { inb=0; close(out); next }
    inb { print > out }
  ' "$f"
done

blocks=()
while IFS= read -r b; do blocks+=("$b"); done < <(find "$tmp" -name '*.contract' | sort)
if [[ "${#blocks[@]}" -eq 0 ]]; then
  printf '%s:contract:no contract blocks found\n' "$obs_dir"
  exit 2
fi

bval() {
  awk -v key="$2" '
    index($0, key ":") == 1 { sub("^[^:]*:[[:space:]]*", ""); sub(/[[:space:]]+$/, ""); print; exit }
  ' "$1"
}
bhas() { [[ -n "$(bval "$1" "$2")" ]]; }

failures=0
fail() { printf '%s:%s:%s\n' "$1" "$2" "$3"; failures=$((failures + 1)); }

is_locator() { # item -> 0 if path:line-range or interview:id form
  [[ "$1" =~ ^[^:]+:[0-9]+(-[0-9]+)?$ || "$1" =~ ^interview:[A-Za-z0-9_.-]+$ ]]
}

# --- structural: malformed lines, duplicate keys, unique ids ---------------
all_ids=""
for b in "${blocks[@]}"; do
  bad="$(awk 'NF && $0 !~ /^[A-Za-z_][A-Za-z_0-9]*:/ { print FNR ": " $0 }' "$b")"
  [[ -n "$bad" ]] && fail "$obs_dir" "format" "malformed contract line(s): $bad"
  dup="$(awk -F: '/^[A-Za-z_][A-Za-z_0-9]*:/ { k=$1; gsub(/[[:space:]]/, "", k); print k }' "$b" | sort | uniq -d)"
  [[ -n "$dup" ]] && fail "$obs_dir" "format" "duplicate field(s) in contract block: $dup"
  bid="$(bval "$b" id)"
  if [[ -z "$bid" ]]; then
    fail "$obs_dir" id "contract block missing id"
  else
    all_ids="$all_ids $bid"
  fi
done
dup_ids="$(printf '%s\n' $all_ids | sort | uniq -d)"
if [[ -n "$dup_ids" ]]; then
  for d in $dup_ids; do fail "$obs_dir" id "duplicate block id '$d'"; done
fi

# --- envelope -------------------------------------------------------------
env_count=0 env_rev="none" env_scope="" env_snap="" env_repo=""
for b in "${blocks[@]}"; do
  [[ "$(bval "$b" kind)" == "observation" ]] || continue
  env_count=$((env_count + 1))
  for k in id kind schema_version inspected_repo inspected_revision tree_state \
           snapshot_id inspection_scope observed_at observer; do
    bhas "$b" "$k" || fail "$obs_dir" "envelope.$k" "missing required field"
  done
  sv="$(bval "$b" schema_version)"
  [[ "$sv" == "workflow-observation/0.1.0" ]] \
    || fail "$obs_dir" schema_version "unsupported '$sv' (supported: workflow-observation/0.1.0)"
  ts="$(bval "$b" tree_state)"
  case "$ts" in clean|dirty|no-git) ;; *) fail "$obs_dir" tree_state "value '$ts' not in {clean, dirty, no-git}" ;; esac
  env_rev="$(bval "$b" inspected_revision)"
  env_scope="$(bval "$b" inspection_scope)"
  env_snap="$(bval "$b" snapshot_id)"
  env_repo="$(bval "$b" inspected_repo)"
done
[[ "$env_count" -eq 1 ]] || fail "$obs_dir" envelope "expected exactly one kind:observation block, found $env_count"

# --- claims, conflicts, gaps ---------------------------------------------
for b in "${blocks[@]}"; do
  kind="$(bval "$b" kind)"; bid="$(bval "$b" id)"
  case "$kind" in
    observation) ;;
    claim)
      for k in statement plane basis source status; do
        bhas "$b" "$k" || fail "$obs_dir" "$bid.$k" "claim missing required field"
      done
      plane="$(bval "$b" plane)"
      case "$plane" in topology|workflow|routing) ;; *)
        fail "$obs_dir" "$bid.plane" "value '$plane' not in {topology, workflow, routing}" ;; esac
      basis="$(bval "$b" basis)"
      case "$basis" in declared|configured|executed) ;; *)
        fail "$obs_dir" "$bid.basis" "value '$basis' not in {declared, configured, executed}" ;; esac
      status="$(bval "$b" status)"
      [[ "$status" == "observed" ]] \
        || fail "$obs_dir" "$bid.status" "value '$status' not in {observed} — approval is not a status this artifact grants"
      # every source item must be a locator
      srcs="$(bval "$b" source)"
      OLDIFS="$IFS"; IFS='|'
      for s in $srcs; do
        IFS="$OLDIFS"; s="$(printf '%s' "$s" | sed 's/^ *//;s/ *$//')"; IFS='|'
        [[ -z "$s" ]] && continue
        is_locator "$s" || fail "$obs_dir" "$bid.source" "'$s' is not a source locator (path:lines or interview:id)"
      done
      IFS="$OLDIFS"
      if [[ "$basis" == "executed" ]]; then
        eref="$(bval "$b" execution_ref)"
        if [[ -z "$eref" ]]; then
          fail "$obs_dir" "$bid.execution_ref" "basis 'executed' requires an execution record — configuration is not execution"
        else
          # Grammar: <record>@rev:<rev> — record name and revision binding
          # are both required and nonempty. This validates the reference's
          # shape only; whether the record proves execution is human review.
          rec="${eref%%@rev:*}"; erev="${eref##*@rev:}"
          if [[ "$eref" != *@rev:* ]]; then
            fail "$obs_dir" "$bid.execution_ref" "expected <record>@rev:<rev>, got '$eref'"
          elif [[ -z "$rec" ]]; then
            fail "$obs_dir" "$bid.execution_ref" "empty record reference in '$eref'"
          elif [[ -z "$erev" ]]; then
            fail "$obs_dir" "$bid.execution_ref" "empty revision binding in '$eref'"
          elif [[ "$env_rev" != "none" && "$erev" != "$env_rev" ]]; then
            fail "$obs_dir" "$bid.execution_ref" "execution record rev '$erev' does not match inspected revision '$env_rev'"
          fi
        fi
      fi
      ;;
    conflict)
      for k in subject positions status; do
        bhas "$b" "$k" || fail "$obs_dir" "$bid.$k" "conflict missing required field"
      done
      n=0
      poss="$(bval "$b" positions)"
      OLDIFS="$IFS"; IFS='|'
      for p in $poss; do
        IFS="$OLDIFS"; p="$(printf '%s' "$p" | sed 's/^ *//;s/ *$//')"; IFS='|'
        [[ -z "$p" ]] && continue
        n=$((n + 1))
        loc="${p##*@}"
        [[ "$p" == *@* ]] && is_locator "$loc" \
          || fail "$obs_dir" "$bid.positions" "position '$p' lacks its own @locator"
      done
      IFS="$OLDIFS"
      [[ "$n" -ge 2 ]] || fail "$obs_dir" "$bid.positions" "conflict needs at least two positions"
      st="$(bval "$b" status)"
      [[ "$st" == "unresolved" ]] || fail "$obs_dir" "$bid.status" "conflicts are recorded unresolved; resolution is a human act elsewhere"
      ;;
    gap)
      for k in missing needed_from; do
        bhas "$b" "$k" || fail "$obs_dir" "$bid.$k" "gap missing required field"
      done
      if bhas "$b" source; then
        fail "$obs_dir" "$bid.source" "a gap has no evidence locator — record what was searched, not an invented source"
      fi
      ;;
    *) fail "$obs_dir" "$bid.kind" "unknown or missing block kind" ;;
  esac
done

# --- staleness ------------------------------------------------------------
repo="${2:-$env_repo}"
if [[ -d "$repo" ]]; then
  canon="$(cd "$repo" && pwd -P)"
  if [[ -n "$env_scope" && -n "$env_snap" ]]; then
    now="sha256:$(snapshot_manifest "$canon" "$env_scope" | sort | hash_stdin)"
    [[ "$now" == "$env_snap" ]] \
      || fail "$obs_dir" snapshot_id "stale observation — inspected content changed since snapshot"
  fi
  if [[ "$env_rev" != "none" ]] && git -C "$canon" rev-parse HEAD >/dev/null 2>&1; then
    head="$(git -C "$canon" rev-parse HEAD)"
    [[ "$head" == "$env_rev" ]] \
      || fail "$obs_dir" inspected_revision "stale observation — HEAD moved from '$env_rev' to '$head'"
  fi
fi

if [[ "$failures" -gt 0 ]]; then exit 1; fi
printf '%s: ok\n' "$obs_dir"
